//
//  ViewController.m
//  TOScrollBarExample
//
//  Created by Tim Oliver on 5/11/16.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOScrollBar.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20);
    
    TOScrollBar *scrollBar = [[TOScrollBar alloc] init];
    [scrollBar addToScrollView:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 100000;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"MyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %ld", indexPath.row+1];
    cell.layoutMargins = UIEdgeInsetsMake(0, 0, 0, 35);
    return cell;
}

@end
