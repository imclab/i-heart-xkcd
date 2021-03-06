//
//  CartoonData.h
//  i heart xkcd
//
//   XKCD JSON API returns results like (without a callback specified):
//
//  {
//      "day": "12",
//      "month": "12",
//      "year": "2012",
//      "num": 1146,
//      "link": "",
//      "news": "",
//      "safe_title": "Honest",
//      "transcript": "",
//      "alt": "I didn't understand what you meant. I still don't. But I'll figure it out soon!",
//      "img": "http:\/\/imgs.xkcd.com\/comics\/honest.png",
//      "title": "Honest"
//  }
//
//  Created by Tom Elliott on 12/12/2012.
//  Copyright (c) 2012 Tom Elliott. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ComicData : NSObject <NSCoding> {
    NSInteger _day;
    NSInteger _month;
    NSInteger _year;
    
    NSUInteger _comicID;
    
    NSString *_link;
    NSString *_news;
    NSString *_title;
    NSString *_safeTitle;
    NSString *_transcript;
    NSString *_alt;
    NSURL    *_imageURL;
    
    BOOL      _isLoaded;
    BOOL      _isFavourite;
}

@property (nonatomic) NSInteger day;
@property (nonatomic) NSInteger month;
@property (nonatomic) NSInteger year;

@property (nonatomic) NSUInteger comicID;

@property (nonatomic, strong) NSString *link;
@property (nonatomic, strong) NSString *news;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *safeTitle;
@property (nonatomic, strong) NSString *transcript;
@property (nonatomic, strong) NSString *alt;
@property (nonatomic, strong) NSURL    *imageURL;

@property (nonatomic) BOOL isLoaded;
@property (nonatomic) BOOL isFavourite;

- (id)initWithJSON:(id)json;
- (id)initWithIndex:(NSUInteger)index;
- (void)updateDataWithValuesFromAPI:(id)json;

@end
