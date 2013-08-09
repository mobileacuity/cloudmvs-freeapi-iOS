//
//  CameraOverlayView.m
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

#import "VisualSearchViewController.h"
#import "URLConnection.h"
#import "URLConnection.h"
#import "MAAuthHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import "WebViewController.h"
#import "DetailViewController.h"
#import "ResultsViewController.h"

//search URL
#define MA_BASE_URL @"http://api.mobileacuity.net/v1/search/test/"

@interface VisualSearchViewController(){
    BOOL justDismissedCamera;
    BOOL justTookPicture;
    BOOL isLoadAuto;
}

@property (strong,nonatomic) UIAlertView *downloading;

@property (strong,nonatomic) URLConnection *openConnection;

@property (strong,nonatomic) UIImagePickerController *imagePicker;

@property (strong,nonatomic) NSString *dataset;

@property (strong,nonatomic) UIApplication *app;

@property (strong,nonatomic) NSArray *results;

@property (strong,nonatomic) NSURLRequest *resultRequest;

@property (strong,nonatomic) NSDictionary *expandedResult;

@property (strong,nonatomic) UIImage *lastTakenImage;

@end

@implementation VisualSearchViewController
@synthesize downloading,openConnection,imagePicker,dataset,app,results,imagePreview,resultRequest,expandedResult,lastTakenImage;

#pragma mark - View lifecycle

-(void)viewDidLoad{
    app = [UIApplication sharedApplication];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    isLoadAuto = [settings boolForKey: IS_AUTOLOAD_SETTING];
    dataset = [settings objectForKey:MA_DATASET_KEY];
    justDismissedCamera=NO;
    justTookPicture=NO;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (!justDismissedCamera) {
        imagePreview.image = nil;
        return;
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (!justDismissedCamera){
        [self setUpCamera];
        return;
    }
    justDismissedCamera=NO;
    if(justTookPicture){
        justTookPicture=NO;
        [imagePreview setImage:lastTakenImage];
    }
}

#pragma mark - UI events (relayed from CameraView & alerts)

- (void)cameraPressed{
    DLog(@"Camera pressed");
}

-(void)configurationPressed{
    DLog(@"Configuration pressed");
    justDismissedCamera=YES;
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)reconfigurePressed{
    DLog(@"Reconfigure pressed");
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)imageTaken:(UIImage *)image{
    lastTakenImage = image;
    [self sendImageForMatching:lastTakenImage];
    justTookPicture=YES;
    justDismissedCamera = YES;
    [self.navigationController popViewControllerAnimated:NO];
    DLog(@"Image taken. Dismissed camera")
}

#pragma mark - Camera set up

- (void)setUpCamera{
    [imagePreview setImage:nil];
    [self performSegueWithIdentifier:SEGUE_AV_CAMERA_LAUNCH sender:self];
}

#pragma mark - Matching images with server, connection handling

- (void)sendImageForMatching:(UIImage *)image{

    NSMutableURLRequest *request = [self buildAuthorisedRequest:image];
    
    //Send a request to the server with the image we've taken
    openConnection = [URLConnection asyncConnectionWithRequest:request
                                               completionBlock:^(NSData *data) {
                                                   [self checkResponse:data];
                                               } errorBlock:^(NSError *error) {
                                                   [self downloadFailedWithError:error];
                                               } notFoundBlock:^(void){
                                                   [self datasetNotFoundOnServer];
                                               }
                                                     dataBlock:nil];
    
    app.networkActivityIndicatorVisible = YES;
    [self promptWaitForResponse];

}

- (NSMutableURLRequest *) buildRequest: (UIImage *) image  {
    //create a request with the image
    NSURL* postURL = [NSURL URLWithString:[self requestURLString]];
    
    NSData *imageData = UIImageJPEGRepresentation(image, 0.4);
    
    DLog(@"length %d", [imageData length]);
    NSString* requestDataLengthString = [NSString stringWithFormat:@"%d", [imageData length]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:postURL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:imageData];
    [request setValue:requestDataLengthString forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setTimeoutInterval:10];
    return request;
}

- (NSMutableURLRequest*)buildAuthorisedRequest:(UIImage*)image {
	NSMutableURLRequest *unauthorisedRequest = [self buildRequest:image];
	NSMutableURLRequest *authorisedRequest = [MAAuthHelper addAuthHeadersToRequest:unauthorisedRequest];
	return authorisedRequest;
}

-(NSString*)requestURLString {
	NSString *string = [NSString stringWithFormat:@"%@%@",MA_BASE_URL,dataset];
	DLog(@"Request URL String = %@",string);
	return string;
}

#pragma mark - Matching images with server, response handling

-(void) checkResponse:(NSData*)response{
    //retrieve information from server in response to our request
    app.networkActivityIndicatorVisible = NO;
    [self stopWaitForResponse];
    
    results = [NSJSONSerialization JSONObjectWithData: response options:kNilOptions error:nil];
    
    if(results==nil){
        DLog(@"Error parsing JSON - probably malformed");
        [self promptUnmatchedAndErrorOccured:YES];
        return;
    }else if ([results count]==0) {
        DLog(@"Empty response from server. No match found.");
        [self promptUnmatchedAndErrorOccured:NO];
        return;
    }
    //we have valid results. Show them
    [self showResults];
}

-(void)downloadFailedWithError:(NSError*)error{
    
    app.networkActivityIndicatorVisible = NO;
    
    DLog(@"Failed to get response : %@", [error localizedFailureReason]);
    
    UIAlertView *failed = [[UIAlertView alloc] initWithTitle:nil message:@"Failed to connect to server.\nPlease check your internet connection." delegate:self cancelButtonTitle:@"Try Again" otherButtonTitles:nil];
    [failed setTag:1];
    
    [self stopWaitForResponse];
    [failed show];
    
}

- (void)datasetNotFoundOnServer{
    app.networkActivityIndicatorVisible = NO;
    
    DLog(@"Failed to find dataset on server");
    
    UIAlertView *failed = [[UIAlertView alloc] initWithTitle:nil message:@"Dataset not found on server.\nCheck customer and service settings in the configuration options." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reconfigure..", nil];
    [failed setTag:2];
    
    [self stopWaitForResponse];
    [failed show];
}

#pragma mark - Matching images with server, UI

- (void)promptUnmatchedAndErrorOccured:(BOOL)isError{
    NSString *msg = @"No match found.";
    if(isError) msg = @"Error connecting to server. Please try again.";
    UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [prompt setTag:1];
    [prompt show];
}

- (void)promptWaitForResponse{
    //display a message while we await a response from the server
    if (downloading!=nil) {
        return;
    }
    
    downloading = [[UIAlertView alloc] initWithTitle:nil message:@"Analyzing Image.." delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
    [downloading show];
    
    //add a loading indicator to the view
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    
    // Adjust the indicator so it is up a few pixels from the bottom of the alert
    indicator.center = CGPointMake(downloading.bounds.size.width / 2, downloading.bounds.size.height - 50);
    [indicator startAnimating];
    [downloading addSubview:indicator];
}

- (void)stopWaitForResponse{
    if(downloading!=nil) [downloading dismissWithClickedButtonIndex:0 animated:YES];
    downloading = nil;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{

    if(alertView.tag==2 && buttonIndex==1){
        //Reconfigure pressed
        [self reconfigurePressed];
        return;
    }
    if (alertView.tag==1 || alertView.tag==2) {
        //Either no match, or some error occured. Pull up camera again
        [self setUpCamera];
    }
}

#pragma mark - App management

-(void)showResults{
    //Present results from server in an appropriate manner. Either a list view, detail view or web view.
    
    //Follow link automatically if included in top result and option set
    if(isLoadAuto){
        NSDictionary *result = [results objectAtIndex:0];
        NSString *resultName = [result objectForKey:RESULT_NAME_DATAKEY];
        NSURL *url = [NSURL URLWithString:resultName];
        if (url!=nil && [resultName hasPrefix:@"http"]) {
            resultRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:180.0];
            [self performSegueWithIdentifier:SEGUE_WEB sender:self];
            return;
        }
    }//Go straight into detail view if only one resut (and it wasn't a load auto result)
    if([results count]==1){
        expandedResult = [results objectAtIndex:0];
        [self performSegueWithIdentifier:SEGUE_SINGLE sender:self];
        return;
    }
    
    //On multiple results, go into list view
    [self performSegueWithIdentifier:SEGUE_LIST sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:SEGUE_WEB]){
        WebViewController *webview = (WebViewController*)[segue destinationViewController];
        [webview setRequest:resultRequest];
    }else if([segue.identifier isEqualToString:SEGUE_SINGLE]){
        DetailViewController *detailView = (DetailViewController*)[segue destinationViewController];
        [detailView setResultInfo:expandedResult];
    }else if([segue.identifier isEqualToString:SEGUE_MULTIPLE]){
        ResultsViewController *listView = (ResultsViewController*)[segue destinationViewController];
        [listView setResults:results];
    }else{
        CameraViewController *camera = (CameraViewController*)[segue destinationViewController];
        camera.delegate = self;
    }
}

@end