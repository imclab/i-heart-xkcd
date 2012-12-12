//
//  ModelController.m
//  i heart xkcd
//
//  Created by Tom Elliott on 11/12/2012.
//  Copyright (c) 2012 Tom Elliott. All rights reserved.
//

#import "ModelController.h"

#import <AFNetworking/AFNetworking.h>

#import "DataViewController.h"
#import "ComicData.h"

/*
 A controller object that manages a simple model -- a collection of month names.
 
 The controller serves as the data source for the page view controller; it therefore implements pageViewController:viewControllerBeforeViewController: and pageViewController:viewControllerAfterViewController:.
 It also implements a custom method, viewControllerAtIndex: which is useful in the implementation of the data source methods, and in the initial configuration of the application.
 
 There is no need to actually create view controllers for each page in advance -- indeed doing so incurs unnecessary overhead. Given the data model, these methods create, configure, and return a new view controller on demand.
 
 XKCD JSON API returns results like (without a callback specified):
 
 {
   "day": "12",
   "month": "12",
   "year": "2012",
   "num": 1146,
   "link": "",
   "news": "",
   "safe_title": "Honest",
   "transcript": "",
   "alt": "I didn't understand what you meant. I still don't. But I'll figure it out soon!",
   "img": "http:\/\/imgs.xkcd.com\/comics\/honest.png",
   "title": "Honest"
 }
 
 */

NSString *const XKCD_API = @"http://dynamic.xkcd.com/api-0/jsonp/";


@interface ModelController()
@property (nonatomic) NSInteger latestPage;
@property (nonatomic) NSInteger lastUpdateTime;
@property (readonly, strong, nonatomic) NSDictionary *comicsData;
@end


@implementation ModelController

- (id)init
{
    self = [super init];
    if (self) {
        // Create the data model.
        _comicsData = [[NSMutableDictionary alloc] initWithCapacity:1];
        _latestPage = 0;
        _lastUpdateTime = -1; // TODO: We should save this to disk and re-read

        [self configureComicDataFromXkcd];
        
        [self.comicsData setValue:[self generateLoadingComic] forKey:[NSString stringWithFormat:@"%d", 0]];
    }
    return self;
}

- (void)configureComicDataFromXkcd
{
    [self configureComicDataFromXkcdForComidID:NSNotFound andAddToViewController:Nil andSetAsView:YES];
}

- (void)configureComicDataFromXkcdForComidID:(NSInteger) comicID andAddToViewController:(DataViewController *)dataViewController andSetAsView:(BOOL) setView
{
    NSString *comicIDPathSegment = @"";
    if (comicID != NSNotFound) {
        comicIDPathSegment = [NSString stringWithFormat:@"/%d", comicID];
    }
    
    DataViewController *dataVC = dataViewController;
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@comic%@", XKCD_API, comicIDPathSegment]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        ComicData *comicData = [self.comicsData objectForKey:[JSON valueForKeyPath:@"num"]];
        if (!comicData) {
            comicData = [[ComicData alloc] initWithJSON:JSON];
            [self.comicsData setValue:comicData forKey:[JSON valueForKeyPath:@"num"]];
        } else {
            [comicData updateDataWithValuesFromAPI:JSON];
        }
        
        if (dataVC != Nil) {
            dataVC.dataObject = comicData;
        }
        
        if (setView) {
            
        }
    } failure:nil];
    
    [operation start];
}

- (ComicData *)generateLoadingComic
{
    // Setup a blank comic
    ComicData *blankComicData = [[ComicData alloc] init];
    
    [blankComicData setDay:NSNotFound];
    [blankComicData setMonth:NSNotFound];
    [blankComicData setYear:NSNotFound];
    
    [blankComicData setComicID:0];
    
    [blankComicData setLink:@""];
    [blankComicData setNews:@""];
    [blankComicData setTitle:@"Loading comic from XKCD. Please be patient!"];
    [blankComicData setSafeTitle:@""];
    [blankComicData setTranscript:@""];
    [blankComicData setAlt:@""];
    [blankComicData setImageURL:Nil];
    
    return blankComicData;
}

- (DataViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard
{   
    // Return the data view controller for the given index.
    if ((self.lastUpdateTime > -1 && index >= self.latestPage) || (index >= [self.comicsData count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    DataViewController *dataViewController = [storyboard instantiateViewControllerWithIdentifier:@"DataViewController"];
    
    ComicData *data = [self.comicsData objectForKey:[NSString stringWithFormat:@"%d", index]];
    if (!data || [data comicID] == 0) {
        [self configureComicDataFromXkcdForComidID:index andAddToViewController:dataViewController andSetAsView:NO];
        data = [self generateLoadingComic];
    }
    
    dataViewController.dataObject = data;
    return dataViewController;
}

- (NSUInteger)indexOfViewController:(DataViewController *)viewController
{   
    return viewController.dataObject.comicID;
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self indexOfViewController:(DataViewController *)viewController];
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.comicsData count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
}

@end
