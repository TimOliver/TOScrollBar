//
//  ViewController.m
//  TOScrollBarExample
//
//  Created by Tim Oliver on 5/11/16.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOScrollBar.h"

@interface ViewController () <UISearchResultsUpdating>

@property (nonatomic, assign) BOOL darkMode;
@property (nonatomic, assign) BOOL hidden;

- (void)darkModeButtonTapped:(id)sender;
- (void)hideButtonTapped:(id)sender;

- (void)configureStyleForDarkMode:(BOOL)darkMode;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create a scroll bar object
    TOScrollBar *scrollBar = [[TOScrollBar alloc] init];
    
    // Uncomment this to disable tapping the track view to jump around
    // scrollBar.handleExclusiveInteractionEnabled = YES;
    
    // Add the scroll bar to the table view
    [self.tableView to_addScrollBar:scrollBar];
    
    //Adjust the table separators so they won't underlap the scroll bar
    self.tableView.separatorInset = [scrollBar adjustedTableViewSeparatorInsetForInset:self.tableView.separatorInset];
    
    // ========================================================================
    
    // Make sure it's not nil before we start styling
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    // Add a button to toggle dark mode
    UIBarButtonItem *darkItem = [[UIBarButtonItem alloc] initWithTitle:@"Dark" style:UIBarButtonItemStylePlain target:self action:@selector(darkModeButtonTapped:)];
    self.navigationItem.rightBarButtonItem = darkItem;
    
    // Add a button to toggle showing the scroll bar
    UIBarButtonItem *hideItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStylePlain target:self action:@selector(hideButtonTapped:)];
    self.navigationItem.leftBarButtonItem = hideItem;

    if (@available(iOS 11.0, *)) {
        self.navigationController.navigationBar.prefersLargeTitles = YES;
        scrollBar.insetForLargeTitles = YES;

        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        self.navigationItem.searchController = searchController;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1000;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"MyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    
    cell.textLabel.textColor = self.darkMode ? [UIColor whiteColor] : [UIColor blackColor];
    cell.textLabel.backgroundColor = self.tableView.backgroundColor;
    cell.backgroundColor = self.tableView.backgroundColor;
    
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %ld", indexPath.row+1];
    cell.layoutMargins = [tableView.to_scrollBar adjustedTableViewCellLayoutMarginsForMargins:cell.layoutMargins manualOffset:0.0f];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)darkModeButtonTapped:(id)sender
{
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    self.darkMode = !self.darkMode;
    button.title = self.darkMode ? @"Light" : @"Dark";
    [self configureStyleForDarkMode:self.darkMode];
}

- (void)configureStyleForDarkMode:(BOOL)darkMode
{
    self.navigationController.navigationBar.barStyle = darkMode ? UIBarStyleBlack : UIBarStyleDefault;
    self.tableView.backgroundColor = darkMode ? [UIColor colorWithWhite:0.09f alpha:1.0f] : [UIColor whiteColor];
    self.view.window.tintColor = darkMode ? [UIColor colorWithRed:90.0f/255.0f green:120.0f/255.0f blue:218.0f/255.0f alpha:1.0f] : nil;
    self.tableView.separatorColor = darkMode ? [UIColor colorWithWhite:0.3f alpha:1.0f] : nil;
    [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationNone];
    self.tableView.to_scrollBar.style = darkMode ? TOScrollBarStyleDark : TOScrollBarStyleDefault;
}

- (void)hideButtonTapped:(id)sender
{
    UIBarButtonItem *button = (UIBarButtonItem *)sender;
    self.hidden = !self.hidden;
    button.title = self.hidden ? @"Show" : @"Hide";
    [self.tableView.to_scrollBar setHidden:self.hidden animated:YES];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {

}

@end
