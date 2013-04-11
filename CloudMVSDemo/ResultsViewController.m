//
//  ViewController.m
//  CloudMVSDemo
//
//  Created by Aleksander Niedziolko on 28/01/2013.
//
//  Copyright (c) 2013 Mobile Acuity Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ResultsViewController.h"
#import "DetailViewController.h"

//segue identifiers
#define SEGUE_DETAIL @"showDetailView"

@interface ResultsViewController ()

@property (strong,nonatomic) NSDictionary *expandedResult;

@end


@implementation ResultsViewController
@synthesize resultsView,expandedResult,results;


#pragma mark - UI events

- (void)donePresed:(id)sender{
    DLog(@"camera pressed");
    results = nil;
    [resultsView setDataSource:nil];
    [resultsView setDelegate:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    int selectedRow = indexPath.row;
    expandedResult = [results objectAtIndex:selectedRow];
    [self performSegueWithIdentifier:SEGUE_DETAIL sender:self];
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (results==nil) return 0;
    return [results count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Set the data for this cell:
    NSDictionary *result = [results objectAtIndex:indexPath.row];
    
    cell.textLabel.text = [result objectForKey:RESULT_NAME_DATAKEY];
    cell.detailTextLabel.text = [result objectForKey:RESULT_SCORE_DATAKEY];
    // set the accessory view:
    cell.accessoryType =  UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - app management

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    DetailViewController *detailView = (DetailViewController*)[segue destinationViewController];
    [detailView setResultInfo:expandedResult];
}

@end
