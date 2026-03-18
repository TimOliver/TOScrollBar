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

@property (nonatomic, assign) BOOL hidden;

- (void)hideButtonTapped:(id)sender;

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

    // Add a button to toggle showing the scroll bar
    UIBarButtonItem *hideItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStylePlain target:self action:@selector(hideButtonTapped:)];
    self.navigationItem.leftBarButtonItem = hideItem;

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    if (@available(iOS 26.0, *)) {}
    else { scrollBar.insetForLargeTitles = YES; }

    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    self.navigationItem.searchController = searchController;
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
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    cell.textLabel.text = [NSString stringWithFormat:@"Cell %ld", indexPath.row+1];
    cell.layoutMargins = [tableView.to_scrollBar adjustedTableViewCellLayoutMarginsForMargins:cell.layoutMargins manualOffset:0.0f];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
