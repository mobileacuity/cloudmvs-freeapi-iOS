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

#import "CameraViewController.h"
#import "URLConnection.h"
#import "UIImage+Resize.h"
#import "URLConnection.h"
#import "MAAuthHelper.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <QuartzCore/QuartzCore.h>
#import "WebViewController.h"
#import "DetailViewController.h"
#import "ResultsViewController.h"

//search URL
#define MA_BASE_URL @"http://api.mobileacuity.net/v1/search/test/"

//segue identifiers
#define SEGUE_WEB @"showWeb"
#define SEGUE_DETAIL @"showSingleResult"
#define SEGUE_LIST @"showMultipleResults"

@interface CameraViewController(){
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

@implementation CameraViewController
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
    DLog(@"view did appear");
    [super viewDidAppear:animated];
    if (!justDismissedCamera) {
        [self setUpCamera];
        return;
    }
    justDismissedCamera=NO;
    if(justTookPicture){
        justTookPicture=NO;
        UIImage *imageToDisplay = NULL;
        if(lastTakenImage.imageOrientation != UIImageOrientationRight){
            imageToDisplay =
            [UIImage imageWithCGImage:[lastTakenImage CGImage]
                                scale:1.0
                          orientation: UIImageOrientationRight];
        }else{
            imageToDisplay = lastTakenImage;
        }
    
        [imagePreview setImage:imageToDisplay];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
            [self sendImageForMatching:lastTakenImage];
        });
    }
}

#pragma mark - UI events (relayed from CameraOverlayView & alerts)

- (void)cameraPressed{
    DLog(@"camera pressed");
    [imagePicker takePicture];
    justTookPicture=YES;
}

-(void)configurationPressed{
    DLog(@"configuration pressed");
    justDismissedCamera=YES;
    [self dismissViewControllerAnimated:NO completion:^(void){
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

-(void)reconfigurePressed{
    DLog(@"Reconfigure.. pressed");
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) {
        lastTakenImage = info[UIImagePickerControllerOriginalImage];
    }
    [self dismissCamera];
    DLog(@"dismissed camera")
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [self dismissCamera];
}

-(void)dismissCamera{
    justDismissedCamera=YES;
    [self dismissViewControllerAnimated:NO completion:nil];
}


- (UIImage *) shrinkImage: (UIImage *) image {
    //shrink the size of the image
    float width = image.size.width;
    float height = image.size.height;
    int newHeight;
    int newWidth;
    if(height>width){
        newHeight = 960;
        newWidth = (int) ((image.size.width * 960.0f / image.size.height) + 0.5);
    }else{
        newWidth = 960;
        newHeight = (int) ((image.size.height * 960.0f / image.size.width) + 0.5);
    }
    DLog(@"width: %f height: %f newWidth: %d newHeight: %d", image.size.width, image.size.height, newWidth, newHeight);
    return [image resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                       bounds:CGSizeMake(newWidth, newHeight)
                         interpolationQuality:kCGInterpolationDefault];
}

#pragma mark - Camera set up

- (void)setUpCamera{
    [imagePreview setImage:nil];
    //bring up customized image picker
    if ([UIImagePickerController isSourceTypeAvailable:
         UIImagePickerControllerSourceTypeCamera]){
        imagePicker = [[UIImagePickerController alloc] init];
        imagePicker.delegate = self;
        imagePicker.sourceType =
        UIImagePickerControllerSourceTypeCamera;
        imagePicker.showsCameraControls = NO;
        imagePicker.mediaTypes = @[(NSString *) kUTTypeImage];
        imagePicker.allowsEditing = NO;
        
        NSString *nibName;
        //separate overlay interface nibs with different top/bottom bar heights for different iphones
        if(IS_IPHONE_5) nibName = @"CameraOverlayView5";
        else nibName = @"CameraOverlayView";
        
        NSArray *nibs = [[NSBundle mainBundle] loadNibNamed:nibName
                                                      owner:nil
                                                    options:nil];
        if([nibs count]){
            id nib = [nibs objectAtIndex:0];
            if([nib isKindOfClass:[CameraOverlayView class]]){
                CameraOverlayView *view = (CameraOverlayView*)nib;
                view.delegate = self;
                imagePicker.cameraOverlayView = view;
            }
        }
        
        [self presentViewController:imagePicker
                           animated:NO completion:nil];
    }
}

#pragma mark - matching images with server, connection handling

- (void)sendImageForMatching:(UIImage *)image{
    
    NSMutableURLRequest *request = [self buildAuthorisedRequest:[self shrinkImage:image]];
    
    //send a request to the server with the image we've taken
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        app.networkActivityIndicatorVisible = YES;
        [self promptWaitForResponse];
        openConnection = [URLConnection asyncConnectionWithRequest:request
                                                   completionBlock:^(NSData *data) {
                                                       [self checkResponse:data];
                                                   } errorBlock:^(NSError *error) {
                                                       [self downloadFailedWithError:error];
                                                   } notFoundBlock:^(void){
                                                       [self datasetNotFoundOnServer];
                                                   }
                                                         dataBlock:nil];
    });
}

- (NSMutableURLRequest *) buildRequest: (UIImage *) shrunkImage  {
    //create a request with the shrunken image
    //TODO hardwired test URL for now
    NSURL* postURL = [NSURL URLWithString:[self requestURLString]];
    
    NSData *imageData = UIImageJPEGRepresentation(shrunkImage, 0.4);
    
    DLog(@"length %d", [imageData length]);
    NSString* requestDataLengthString = [NSString stringWithFormat:@"%d", [imageData length]];
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:postURL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:imageData];
    [request setValue:requestDataLengthString forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setTimeoutInterval:10];
    return request;//accept application/JSON
}

- (NSMutableURLRequest*)buildAuthorisedRequest:(UIImage*)shrunkImage {
	NSMutableURLRequest *unauthorisedRequest = [self buildRequest:shrunkImage];
	NSMutableURLRequest *authorisedRequest = [MAAuthHelper addAuthHeadersToRequest:unauthorisedRequest];
	return authorisedRequest;
}


-(void) checkResponse:(NSData*)response{
    //retrieve information from server response to our request
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
    //first file download to fail close all other connections and set state
    
    UIAlertView *failed = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"NOINTERNET", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"TRYAGAIN", nil) otherButtonTitles:nil];
    [failed setTag:1];
    
    [self stopWaitForResponse];
    [failed show];
    
}

- (void)datasetNotFoundOnServer{
    app.networkActivityIndicatorVisible = NO;
    
    DLog(@"Failed to find dataset on server");
    
    UIAlertView *failed = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"DATASETNOTFOUNDLABEL", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", nil) otherButtonTitles:NSLocalizedString(@"RECONFIGURE", nil), nil];
    [failed setTag:2];
    
    [self stopWaitForResponse];
    [failed show];
}

- (void)promptUnmatchedAndErrorOccured:(BOOL)isError{
    NSString *msg = NSLocalizedString(@"NOMATCHFOUND", nil);
    if(isError) msg = NSLocalizedString(@"ERRORCONNECTING", nil);
    UIAlertView *prompt = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [prompt setTag:1];
    [prompt show];
}

- (void)promptWaitForResponse{
    //display a message while we await a response from the server
    if (downloading!=nil) {
        return;
    }
    
    downloading = [[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"ANALYZINGIMAGE", nil) delegate:self cancelButtonTitle:nil otherButtonTitles:nil];
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
        //reconfigure pressed
        [self reconfigurePressed];
        return;
    }
    if (alertView.tag==1 || alertView.tag==2) {
        //either no match, or some error occured. Pull up camera again
        [self setUpCamera];
    }
}

-(NSString*)requestURLString {
	NSString *string = [NSString stringWithFormat:@"%@%@",MA_BASE_URL,dataset];
	DLog(@"Request URL String = %@",string);
	return string;
}

#pragma mark - app management

-(void)showResults{
    //present results from server in an appropriate manner. Either a list view, detail view or web view.
    
    //follow link automatically if included in top result and option set
    if(isLoadAuto){
        NSDictionary *result = [results objectAtIndex:0];
        NSString *resultName = [result objectForKey:RESULT_NAME_DATAKEY];
        NSURL *url = [NSURL URLWithString:resultName];
        if (url!=nil && [resultName hasPrefix:@"http"]) {
            resultRequest = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:180.0];
            [self performSegueWithIdentifier:SEGUE_WEB sender:self];
            return;
        }
    }//go straight into detail view if only one resut (and it wasn't a web result)
    if([results count]==1){
        expandedResult = [results objectAtIndex:0];
        [self performSegueWithIdentifier:SEGUE_DETAIL sender:self];
        return;
    }
    
    //on multiple results, go into list view
    [self performSegueWithIdentifier:SEGUE_LIST sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:SEGUE_WEB]){
        WebViewController *webview = (WebViewController*)[segue destinationViewController];
        [webview setRequest:resultRequest];
    }else if([segue.identifier isEqualToString:SEGUE_DETAIL]){
        DetailViewController *detailView = (DetailViewController*)[segue destinationViewController];
        [detailView setResultInfo:expandedResult];
    }else{
        ResultsViewController *listView = (ResultsViewController*)[segue destinationViewController];
        [listView setResults:results];
    }
}

@end
