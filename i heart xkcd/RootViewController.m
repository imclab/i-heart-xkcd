//
//  RootViewController.m
//  i heart xkcd
//
//  Created by Tom Elliott on 11/12/2012.
//  Copyright (c) 2012 Tom Elliott. All rights reserved.
//

#import "RootViewController.h"

#import "ModelController.h"
#import "Constants.h"

#import "AboutViewController.h"
#import "DataViewController.h"

#import "AltTextViewController.h"
#import "FavouritesViewController.h"
#import "SearchViewController.h"
#import "NavigationViewController.h"
#import "AboutViewController.h"

#define pageCoverAnimationTime 0.3
#define turnPageViewWidthPhone 20
#define turnPageViewWidthPad 50

@interface RootViewController ()

@property (readonly, strong, nonatomic) ModelController *modelController;
@property NSUInteger currentIndex;
@property DataViewController *currentViewController;
@property (readwrite, nonatomic) double lastTimeOverlaysToggled;

@end

@implementation RootViewController {
    NSInteger turnPageViewWidth;
    CGFloat altViewOverlayAndTabCentreDelta;
    CGPoint tabBarPullClosedOrigin;
    CGPoint tabBarPullOpenOrigin;
}

@synthesize modelController = _modelController;
@synthesize pageCover;
@synthesize currentIndex = _currentIndex;

+ (void)initialize {
    NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithInt:1], iheartxkcd_UserDefaultLatestPage,
                              [NSNumber numberWithInt:0], iheartxkcd_UserDefaultLastUpdate,
                              nil];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Configure the page view controller and add it as a child view controller.
    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    self.pageViewController.delegate = self;
    
    [self.modelController setDelegate:self];
    
    int latestPage = [[NSUserDefaults standardUserDefaults] integerForKey:iheartxkcd_UserDefaultLatestPage];
    self.currentIndex = latestPage; // Don't go via the setter here

    DataViewController *startingViewController = [self.modelController viewControllerAtIndex:self.currentIndex storyboard:self.storyboard];
    self.currentViewController = startingViewController;
    NSArray *viewControllers = @[startingViewController];
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];

    self.pageViewController.dataSource = self.modelController;

    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    
    // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
    CGRect pageViewRect = self.view.bounds;
    self.pageViewController.view.frame = pageViewRect;

    [self.pageViewController didMoveToParentViewController:self];
    
    // Configure overlay
    pageCover = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, self.view.bounds.size.width)];
    pageCover.backgroundColor = [UIColor whiteColor];
    pageCover.alpha = 0.0;
    [self.view addSubview:pageCover];
    
    // Move the page forward/backward gestures to their own view, so we can show/hide the tab bar separately
    turnPageViewWidth = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? turnPageViewWidthPad : turnPageViewWidthPhone;
    
    turnPageBackView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, turnPageViewWidth, self.view.bounds.size.height)];
    [self.view addSubview:turnPageBackView];
    
    turnPageForwardView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-turnPageViewWidth, 0, turnPageViewWidth, self.view.frame.size.height)];
    [self.view addSubview:turnPageForwardView];
    
    [turnPageBackView setGestureRecognizers:self.pageViewController.gestureRecognizers];
    [turnPageForwardView setGestureRecognizers:self.pageViewController.gestureRecognizers];

    // Add the tab bar pull
    self.tabBarPull = [[TabBarDraggerViewController alloc] initWithDelegate:self];
    CGRect tabBarPullRect = self.tabBarPull.view.frame;

    tabBarPullClosedOrigin.x = self.view.bounds.size.width - tabBarPullRect.size.width;
    tabBarPullClosedOrigin.y = self.view.bounds.size.height - tabBarPullRect.size.height;
    tabBarPullOpenOrigin = tabBarPullClosedOrigin;
    tabBarPullOpenOrigin.x -= self.view.bounds.size.width;

    tabBarPullRect.origin = tabBarPullClosedOrigin;
    [self.tabBarPull.view setFrame:tabBarPullRect];
    [self.view addSubview:self.tabBarPull.view];
    
    // Remove gesture recognizers from their original view, and set the Root VC as their delegate
    for (UIGestureRecognizer *gr in self.pageViewController.gestureRecognizers) {
        [self.pageViewController.view removeGestureRecognizer:gr];
        [self.view removeGestureRecognizer:gr];
        
        gr.delegate = self;
    }
    
    // Tab Bar for navigation
    AltTextViewController *altTextViewController = [[AltTextViewController alloc] init];
    [altTextViewController setDelegate:self];
    FavouritesViewController *favouritesViewController = [[FavouritesViewController alloc] init];
    [favouritesViewController setDelegate:self];
    SearchViewController *searchViewController = [[SearchViewController alloc] init];
    [searchViewController setDelegate:self];
    NavigationViewController *navigationViewController = [[NavigationViewController alloc] init];
    [navigationViewController setDelegate:self];
    AltViewController *aboutViewController = [[AboutViewController alloc] init];
    [aboutViewController setDelegate:self];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[
                                              altTextViewController,
                                              favouritesViewController,
                                              searchViewController,
                                              navigationViewController,
                                              aboutViewController];

    // Set the tab bar frame so it doesn't overlap the title bar, and hide off screen so we 'slide' it over
    // FIXME: float titleBarHeight = self.titleLabel.frame.size.height;
    float titleBarHeight = 20;
    CGRect tabBarFrame = self.view.frame;
    tabBarFrame.origin.y = titleBarHeight;
    tabBarFrame.origin.x = self.view.frame.size.width;
    tabBarFrame.size.height = tabBarFrame.size.height - titleBarHeight;
    [self.tabBarController.view setFrame:tabBarFrame];
    [self.view addSubview:self.tabBarController.view];
    
    altViewOverlayAndTabCentreDelta = self.tabBarController.view.center.x - self.tabBarPull.view.center.x;

    
    // Setup gesture recognisers
    UISwipeGestureRecognizer *tabBarViewTapRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tabBarViewTapRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    tabBarViewTapRecognizer.numberOfTouchesRequired = 1;
    [self.tabBarController.view addGestureRecognizer:tabBarViewTapRecognizer];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // This is a little hacky. For some reason, even tho the gr is removed from the main view in
    // viewDidLoad, it still fires when we swipe outside of the page turning views. So check it's
    // within one of those views (and that it's not the tab bar swipe gesture), and handle accordingly
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        // We only want to mess with the swipes
        UIPanGestureRecognizer *panGR = (UIPanGestureRecognizer *)gestureRecognizer;
        
        if (CGRectContainsPoint(turnPageBackView.bounds, [touch locationInView:turnPageBackView])) { // &&
//            [panGR velocityInView:self.view].x > 0.0f) {
            // If we swipe on the left edge of the screen, all good (unless it's the first page)
            return self.currentIndex > 1;
        }
        
        if (CGRectContainsPoint(turnPageForwardView.bounds, [touch locationInView:turnPageForwardView])) { // &&
//          [panGR velocityInView:self.view].x < 0.0f) {
            return self.currentIndex < [self.modelController indexOfLastComic];
        }
        
        return NO;
    } else {
        return YES;
    }
}

- (void)loadPageAtIndex:(NSInteger)index forDirection:(UIPageViewControllerNavigationDirection) direction andAnimation:(BOOL)animated {
    DataViewController *viewController = [self.modelController viewControllerAtIndex:index storyboard:self.storyboard];
    NSArray *viewControllers = @[viewController];
    [self.pageViewController setViewControllers:viewControllers direction:direction animated:animated completion:NULL];
    
    [UIView animateWithDuration:pageCoverAnimationTime
                     animations:^{pageCover.alpha = 0.0;}
                     completion:^(BOOL finished){
                         if (finished) {
                             [self setCurrentIndex:index];
                             self.currentViewController = viewController;
                             [self hideTabBar];
                         }
                     }];
}

- (NSUInteger)currentIndex
{
    return _currentIndex;
}

- (void)setCurrentIndex:(NSUInteger)index
{
    _currentIndex = index;

    NSNumber *indexObject = [NSNumber numberWithInt:index];
    NSDictionary *data = [[NSDictionary alloc] initWithObjectsAndKeys:
                          indexObject, ComicLoadedAtIndexNotificationIndexKey,
                          self.currentViewController.dataObject, ComicLoadedAtIndexNotificationDataKey,
                          nil];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    NSNotification *note = [NSNotification notificationWithName:ComicLoadedAtIndexNotificationName object:self userInfo:data];
    [nc postNotification:note];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (ModelController *)modelController
{
    if (!_modelController) {
        _modelController = [[ModelController alloc] init];
    }
    return _modelController;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    pageCover.alpha = 1.0;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [UIView animateWithDuration:pageCoverAnimationTime
                     animations:^{pageCover.alpha = 0.0;}
                     completion:nil];
    
    [self loadPageAtIndex:self.currentIndex forDirection:UIPageViewControllerNavigationDirectionForward andAnimation:NO];
}

#pragma mark - Handle gestures and touches

- (BOOL)canToggleOverlays
{
    double timeNow = CACurrentMediaTime();
    if (timeNow - self.lastTimeOverlaysToggled < pageOverlayToggleBounceLimit) {
        return NO;
    }
    return YES;
}

- (void)handleTap:(UIGestureRecognizer *)sender {
    if ([self canToggleOverlays]) {
        self.lastTimeOverlaysToggled = CACurrentMediaTime();
        
        [self toggleTabBar];
    }
}

- (void)toggleTabBar
{
    if (self.tabBarController.view.frame.origin.x == 0) {
        [self hideTabBar];
    } else {
        [self showTabBar];
    }
}

- (void)showTabBar
{
    [self.view addSubview:self.tabBarController.view];
    CGPoint viewLocation = self.tabBarController.view.center;
    viewLocation.x = self.view.center.x;
    
    CGRect tabBarPullRect = self.tabBarPull.view.frame;
    tabBarPullRect.origin.x = tabBarPullOpenOrigin.x;
    tabBarPullRect.origin.y = tabBarPullOpenOrigin.y;
    
    [self.currentViewController showTitle];
    
    UIViewController *selectedVC = [self.tabBarController selectedViewController];
    if ([selectedVC isKindOfClass:AltViewController.class]) {
        [(AltViewController *)selectedVC handleToggleAnimatingOpen:(viewLocation)];
    }
    
    [UIView animateWithDuration:pageOverlayToggleAnimationTime
                     animations:^{
                         self.tabBarController.view.center = viewLocation;
                         self.tabBarPull.view.frame = tabBarPullRect;
                     }
                     completion:nil];
}

- (void)hideTabBar
{
    CGPoint viewLocation = self.tabBarController.view.center;
    viewLocation.x = self.view.bounds.size.width + self.tabBarController.view.bounds.size.width/2;
    
    CGRect tabBarPullRect = self.tabBarPull.view.frame;
    tabBarPullRect.origin.x = tabBarPullClosedOrigin.x;
    tabBarPullRect.origin.y = tabBarPullClosedOrigin.y;
    
    [self.currentViewController hideTitle];
    
    UIViewController *selectedVC = [self.tabBarController selectedViewController];
    if ([selectedVC isKindOfClass:AltViewController.class]) {
        [(AltViewController *)selectedVC handleToggleAnimatingClosed:(viewLocation)];
    }
    
    [UIView animateWithDuration:pageOverlayToggleAnimationTime
                     animations:^{
                         self.tabBarController.view.center = viewLocation;
                         self.tabBarPull.view.frame = tabBarPullRect;
                     }
                     completion:^ (BOOL finished){
                         if (finished) {
                             [self.tabBarController.view removeFromSuperview];
                         }
                     }];
}

#pragma mark - UIPageViewController delegate methods

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    DataViewController *currentViewController = [[pageViewController viewControllers] objectAtIndex:0];
    [self setCurrentIndex:[[currentViewController dataObject] comicID]];
    self.currentViewController = currentViewController;
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    self.pageViewController.doubleSided = NO;
    return UIPageViewControllerSpineLocationMin;
}

#pragma mark - UIPageViewController delegate methods end

- (void) switchToPageViewControllerWithoutPageTurnForIndex:(NSInteger) index
{
    if (self.currentIndex == index) return;
    
    RootViewController *this = self;
    [UIView animateWithDuration:pageCoverAnimationTime
                     animations:^{pageCover.alpha = 1.0;}
                     completion:^(BOOL finished){
                         [this loadPageAtIndex:index forDirection:UIPageViewControllerNavigationDirectionForward andAnimation:NO];
                     }];
}

#pragma mark - ModelController delegate methods

- (void) handleLatestComicLoaded:(NSInteger) index
{
    [self switchToPageViewControllerWithoutPageTurnForIndex:index];
}

#pragma mark - DataViewController delegate methods

- (void)loadFirstComic
{
    [self switchToPageViewControllerWithoutPageTurnForIndex:1];
}

- (void)loadLastComic
{
    NSLog(@"Loading %d", [self.modelController indexOfLastComic]);
    [self switchToPageViewControllerWithoutPageTurnForIndex:[self.modelController indexOfLastComic]];
}

- (void)loadPreviousComic
{
    if (self.currentIndex <= 1) {
        return;
    }
    
    [self loadPageAtIndex:self.currentIndex-1 forDirection:UIPageViewControllerNavigationDirectionReverse andAnimation:YES];
}

- (void)loadRandomComic
{
    NSInteger randomIndex = arc4random() % [self.modelController indexOfLastComic];
    
    [self switchToPageViewControllerWithoutPageTurnForIndex:randomIndex];
}

- (void)loadNextComic
{
    if (self.currentIndex >= [self.modelController indexOfLastComic]) {
        return;
    }
    
    [self loadPageAtIndex:self.currentIndex+1 forDirection:UIPageViewControllerNavigationDirectionForward andAnimation:YES];
}

- (void)loadComicAtIndex:(NSInteger)index
{
    [self loadPageAtIndex:index forDirection:UIPageViewControllerNavigationDirectionForward andAnimation:NO];
}

#pragma mark AltViewControllerProtocol methods

- (ComicData *)comicData
{
    return self.currentViewController.dataObject;
}

- (UIImageView *)comicImage
{
    return self.currentViewController.imageView;
}

- (CGPoint)comicOffset
{
    return [self.currentViewController comicOffset];
}

- (CGSize)comicSize
{
    return [self.currentViewController comicSize];
}

#pragma mark TabBarDraggerProtocol methods

- (void)handleTabBarDragged:(UIPanGestureRecognizer *)sender {
    UIViewController *selectedVC = [self.tabBarController selectedViewController];
    
    if ([sender state] == UIGestureRecognizerStateBegan) {
        if ([selectedVC isKindOfClass:AltViewController.class]) {
            [(AltViewController *)selectedVC handleToggleStarted];
        }
        [self.view addSubview:self.tabBarController.view];
    }
    
    if ([sender state] == UIGestureRecognizerStateEnded) {
        CGFloat velocityX = [sender velocityInView:self.view].x;
        CGFloat stoppedVelocity = 100.0f;
        
        // Determine if tab should be open or closed, and make the appropriate change
        if (-1*stoppedVelocity <= velocityX && velocityX <= stoppedVelocity) {
            // Close if the user stopped panning and removed finger
            [self hideTabBar];
        } else if (velocityX < stoppedVelocity) {
            // Sliding to the left, open
            [self showTabBar];
        } else {
            // Sliding to the right
            [self hideTabBar];
        }
    } else {
        // Move tab and view under finger
        CGPoint pullLocation = self.tabBarPull.view.center;
        pullLocation.x = [sender locationInView:self.view].x;
        CGPoint viewLocation = self.tabBarController.view.center;
        viewLocation.x = pullLocation.x + altViewOverlayAndTabCentreDelta;
        
        self.tabBarPull.view.center = pullLocation;
        self.tabBarController.view.center = viewLocation;
        
        if ([selectedVC isKindOfClass:AltViewController.class]) {
            [(AltViewController *)selectedVC handleViewMoved:(viewLocation)];
        }
    }    
}

- (void)handleTabBarTapped:(UITapGestureRecognizer *)sender {
    [self handleTap:sender];
}

@end





