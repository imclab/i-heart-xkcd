//
//  AboutViewController.m
//  i heart xkcd
//
//  Created by Tom Elliott on 03/01/2013.
//  Copyright (c) 2013 Tom Elliott. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.aboutXkcdTitle setNumberOfLines:1];
    [self.aboutIHeartXkcdTitle setNumberOfLines:1];

    
    UIBarButtonItem *doneItem = [[UIBarButtonItem alloc]
                                 initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                 target:self
                                 action:@selector(done:)];
    [[self navigationItem] setRightBarButtonItem:doneItem];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.aboutXkcdBody sizeToFit];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)done: (id)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

@end