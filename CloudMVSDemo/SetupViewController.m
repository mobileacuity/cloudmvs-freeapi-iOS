//
//  SetupViewController.m
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

#import "SetupViewController.h"
#import "VisualSearchViewController.h"

#define IS_SETUP_SETTING @"isSetUp"
#define SEGUE_CAMERA @"launchCamera"

@interface SetupViewController ()
@property (nonatomic) BOOL isLoadAuto;
@property (nonatomic) BOOL isAlreadySetup;

@property CGRect originalScrollViewFrame;
@end

@implementation SetupViewController
@synthesize isLoadAuto,isAlreadySetup,datasetTextField,autoSwitch,scrollView,originalScrollViewFrame,cancel,save;

#pragma mark - view lifecycle

- (void)viewDidLoad{
    [super viewDidLoad];
    
    [cancel setEnabled:NO];
    [save setEnabled:NO];

    [self initialize];
    
    [datasetTextField setKeyboardType:UIKeyboardTypeURL];
    [datasetTextField setReturnKeyType:UIReturnKeyDone];
    [datasetTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
    [datasetTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
}

- (void)viewWillAppear:(BOOL)animated {
    DLog(@"view will appear");
    [self populateTextFields];
	[super viewWillAppear:animated];
	[self registerForNotifications];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self deregisterFromNotifications];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
	scrollView.contentSize = [self originalScrollFrame].size;
    [autoSwitch setOn:isLoadAuto];
}

- (void)viewDidUnload {
	[self setDatasetTextField:nil];
	[self setScrollView:nil];
	[super viewDidUnload];
}

#pragma mark - UI events

-(IBAction)followLinksToggled:(id)sender{
    UISwitch *ctrl = (UISwitch*) sender;
    isLoadAuto = [ctrl isOn];
}

-(void)savePressed:(id)sender{
    [cancel setEnabled:YES];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setBool: YES forKey: IS_SETUP_SETTING];
    [settings setBool: isLoadAuto forKey: IS_AUTOLOAD_SETTING];
	[settings setObject: datasetTextField.text forKey:MA_DATASET_KEY];
    [settings synchronize];
    [self performSegueWithIdentifier:SEGUE_CAMERA sender:self];
}

-(void)cancelPressed:(id)sender{
    [save setEnabled:YES];
    [self performSegueWithIdentifier:SEGUE_CAMERA sender:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
	[textField resignFirstResponder];
	return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField{
	double delayInSeconds = 0.1;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[scrollView scrollRectToVisible:textField.frame animated:NO];
	});
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    //limit characters to only those allowed in dataset name
    NSCharacterSet *base64 = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890+/\n "] invertedSet];
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    //only allow saving if dataset name entered
    if(newString.length>1){
        [save setEnabled:YES];
    }else{
        [save setEnabled:NO];
    }
    
    if ([[string stringByTrimmingCharactersInSet:base64] length] != [string length]) {
        return NO;
    }else{
        return YES;
    }
}

#pragma mark - App management

-(void)populateTextFields {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    isLoadAuto = [settings boolForKey: IS_AUTOLOAD_SETTING];
	datasetTextField.text = [settings objectForKey:MA_DATASET_KEY];
    [autoSwitch setOn:isLoadAuto];
}

- (void)initialize{
    DLog(@"Initializing app");
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    isAlreadySetup = [settings boolForKey : IS_SETUP_SETTING];
    if (isAlreadySetup){
        //Not running app for the first time- run camera
        [cancel setEnabled:YES];
        [save setEnabled:YES];
        [self performSegueWithIdentifier: SEGUE_CAMERA sender:self];
    }
}

#pragma mark - Keyboard behavior

-(CGRect)originalScrollFrame {
	if (CGRectIsEmpty(originalScrollViewFrame)) {
		originalScrollViewFrame = scrollView.frame;
	}
	return originalScrollViewFrame;
}

-(void)keyboardWillShow:(NSNotification*)note {
	CGRect keyboardFrame = [[note.userInfo objectForKey:@"UIKeyboardBoundsUserInfoKey"] CGRectValue];
	CGRect scrollViewFrameWhenKeyboardVisible = [self originalScrollFrame];
	scrollViewFrameWhenKeyboardVisible.size.height = [self originalScrollFrame].size.height - keyboardFrame.size.height;
	[self animateScrollViewToFrame:scrollViewFrameWhenKeyboardVisible];
}

-(void)keyboardWillHide:(NSNotification*)note {
	[self animateScrollViewToFrame:[self originalScrollFrame]];
}

-(void)animateScrollViewToFrame:(CGRect)newFrame {
	[UIView animateWithDuration:0.25
					 animations:^{
						 scrollView.frame = newFrame;
					 }];
}
-(void)registerForNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
    
}

-(void)deregisterFromNotifications {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
