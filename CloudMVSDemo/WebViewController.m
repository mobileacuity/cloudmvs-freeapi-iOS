//
//  WebViewController.m
//  SDKOverlayDemo
//
//  Created by Aleksander Niedziolko on 09/11/2012.
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

#import "WebViewController.h"

@interface WebViewController (){
    BOOL completedLoad;
    BOOL duringInitialLoad;
}

@property (strong,nonatomic) UIAlertView *downloading;
@property (strong,nonatomic)UIAlertView *failed;

@end

@implementation WebViewController
@synthesize webview,downloading,failed,request;

#pragma mark - view lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    //set up the appropriate initial request
    [webview loadRequest:request];
    if(downloading==nil)[self promptWaitForResponse];
    completedLoad = NO;
    duringInitialLoad = YES;
}

- (void)viewWillUnload{
    [downloading setDelegate:nil];
    [failed setDelegate:nil];
    [webview setDelegate:nil];
    webview = nil;
}

/*-(void)pause{
    DLog(@"webview pause");
    [webview stopLoading];
    [self stopWaitForResponse];
}

-(void)resume{
    DLog(@"webview resume");
    if (completedLoad) return;
    [webview loadRequest:request];
}*/

#pragma mark - UI events

-(void)openInSafariPressed:(id)sender{
	[[UIApplication sharedApplication] openURL:[request URL]];
}

-(void)donePressed:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma  mark - WebView delegate

-(void)webViewDidStartLoad:(UIWebView *)webView{
    DLog(@"webViewdidStartLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    completedLoad = NO;
    if(duringInitialLoad){
        //only display waiting prompt during the intial bulk load of the website, once the user already has
        //a website to browse, the status bar loading icon is sufficient
        if(downloading==nil)[self promptWaitForResponse];
        duringInitialLoad = NO;
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView{
    DLog(@"webViewdidFinishLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    completedLoad = YES;
    [self stopWaitForResponse];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    DLog(@"webViewdidFinishLoad");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self stopWaitForResponse];
    [self informLoadFailed];
}

#pragma mark - loading alert

- (void)promptWaitForResponse{
    //display a message while webpage loads in background
    if (downloading!=nil) {
        return;
    }
    
    downloading = [[UIAlertView alloc] initWithTitle:nil message:@"Loading.." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [downloading show];
}

- (void)informLoadFailed{
    //display a message while webpage loads in background
    if (downloading!=nil) {
        return;
    }
    failed = [[UIAlertView alloc] initWithTitle:nil message:@"Failed to reach website." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [failed show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    if(alertView==failed){
       [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)willPresentAlertView:(UIAlertView *)alertView{
    if(alertView!=downloading) return;
    
    //add a loading indicator to the view
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    [indicator startAnimating];
    [downloading addSubview:indicator];
    // Adjust the indicator so it is up a few pixels from the bottom of the alert
    indicator.center = CGPointMake(downloading.bounds.size.width / 2, downloading.bounds.size.height - 50);
}

- (void)stopWaitForResponse{
    if(downloading!=nil) [downloading dismissWithClickedButtonIndex:0 animated:YES];
    downloading = nil;
}


@end
