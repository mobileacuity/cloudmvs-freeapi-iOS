//
//  CameraViewController.h
//  CloudMVSDemo
//
//  Created by Aleksander Niedziolko on 16/07/2013.
//  Copyright (c) 2013 Mobile Acuity. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraViewControllerDelegate <NSObject>

- (void)cameraPressed;

- (void)imageTaken:(UIImage*)image;

- (void)configurationPressed;

@end

@interface CameraViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) NSObject<CameraViewControllerDelegate> *delegate;

@property (weak,nonatomic) IBOutlet UIView *preview;

//Camera Button pressed- notifies CameraOverlayViewDelegate
-(IBAction)cameraPressed:(id)sender;
//Configuration Button pressed - notifies CameraOverlayViewDelegate
-(IBAction)configurationPressed:(id)sender;


@end
