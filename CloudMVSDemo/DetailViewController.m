//
//  DetailViewController.m
//  CloudMVSDemo
//
//  Created by Aleksander Niedziolko on 26/03/2013.
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

#import "DetailViewController.h"
#import "WebViewController.h"

#define INFO_TITLES [NSArray arrayWithObjects:@"Result",@"ID",@"Match score", @"Center", nil]
#define INFO_DATAKEYS [NSArray arrayWithObjects:RESULT_NAME_DATAKEY, RESULT_ID_DATAKEY, RESULT_SCORE_DATAKEY, RESULT_CENTRE_DATAKEY, nil]
#define SEGUE_WEB @"showWeb"


@interface DetailViewController ()

@property (strong,nonatomic) NSArray *infoTitles;
@property (strong,nonatomic) NSArray *infoKeys;

@property (strong,nonatomic) NSURLRequest *resultRequest;

@end

@implementation DetailViewController
@synthesize resultInfo,infoKeys,infoTitles,resultRequest;

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    infoKeys = INFO_DATAKEYS;
    infoTitles = INFO_TITLES;
}

#pragma mark - UI events

-(void)donePressed:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    WebViewController *webview = (WebViewController*)[segue destinationViewController];
    [webview setRequest:resultRequest];
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:SEGUE_WEB sender:self];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [infoTitles count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    int rowIndex = indexPath.row;
    cell.textLabel.text = [infoTitles objectAtIndex:rowIndex];
    cell.detailTextLabel.text = [resultInfo objectForKey:[infoKeys objectAtIndex:rowIndex]];
    
    //if result row, and result is link, make the row clickable
    if (rowIndex==0) {
        NSString *urlString = [resultInfo objectForKey:[infoKeys objectAtIndex:rowIndex]];
        NSURL *url = [NSURL URLWithString: urlString];
        if(url!=nil && [urlString hasPrefix:@"http"]){
            cell.accessoryType =  UITableViewCellAccessoryDetailDisclosureButton;
            resultRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:180.0];
        }
    }
    
    return cell;
}


@end
