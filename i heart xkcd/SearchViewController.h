//
//  SearchViewController.h
//  i heart xkcd
//
//  Created by Tom Elliott on 06/05/2013.
//  Copyright (c) 2013 Tom Elliott. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AltViewController.h"
#import "RecentSearchesController.h"

#import "SearchViewControllerProtocol.h"

@interface SearchViewController : AltViewController<UISearchBarDelegate, UIPopoverControllerDelegate, RecentSearchesDelegate, UITableViewDataSource, UITableViewDelegate> {
    UISearchBar *searchBar;
    UITableView *resultsTable;
    
    RecentSearchesController *recentSearchesController;
    UIPopoverController *recentSearchesPopoverController;
    
    UILabel *noResultsLabel;
}

@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) IBOutlet UITableView *resultsTable;

@property (nonatomic, strong) RecentSearchesController *recentSearchesController;
@property (nonatomic, strong) UIPopoverController *recentSearchesPopoverController;

@property (nonatomic, strong) IBOutlet UILabel *noResultsLabel;

@property (strong, nonatomic) id<SearchViewControllerProtocol> delegate;

@end
