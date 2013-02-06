//
//  DataViewController.h
//  i heart xkcd
//
//  Created by Tom Elliott on 11/12/2012.
//  Copyright (c) 2012 Tom Elliott. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ComicData.h"
#import "ModelController.h"
#import "NavigationViewController.h"

#define pageOverlayToggleAnimationTime 0.300

@interface DataViewController : UIViewController <UIScrollViewDelegate, UIPopoverControllerDelegate, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingView;

@property (strong, nonatomic) ComicData *dataObject;

@property (strong, nonatomic) id<NavigationViewControllerProtocol> delegate;
@property (strong, nonatomic) NavigationViewController *navViewController;

@end
