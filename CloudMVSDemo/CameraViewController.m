//
//  CameraViewController.m
//  CloudMVSDemo
//
//  Created by Aleksander Niedziolko on 16/07/2013.
//  Copyright (c) 2013 Mobile Acuity. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()

@property (strong,nonatomic) AVCaptureSession *session;
@property (strong,nonatomic) UIImage *lastFrame;

@end

@implementation CameraViewController
@synthesize delegate,session,preview,lastFrame;


- (void)viewDidLoad{
    [super viewDidLoad];
    [self setUpCamera];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self startCamera];
}


- (IBAction)cameraPressed:(id)sender{
    DLog(@"Camera Pressed");
    [delegate cameraPressed];
    //Pass the last captured frame held in memory as the image
    [delegate imageTaken:lastFrame];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [session stopRunning];
    });
}

-(IBAction)configurationPressed:(id)sender{
    [delegate configurationPressed];
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection{
    //Hold every preview frame in memory as it is captured,
    //allowing for instantaneous retrieval once a frame is needed
    UIImage *image;
    image = [self imageFromColorBuffer:sampleBuffer];
                
    lastFrame = image;
}

#pragma mark - camera setup

-(void)setUpCamera{
    //Set up the AVCaptureSession
    session = [[AVCaptureSession alloc] init];
    session.sessionPreset = AVCaptureSessionPreset640x480;
         
    AVCaptureDevice *device =
    [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input =
    [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        // Handle the error appropriately.
    }
    [session addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    
    output.videoSettings =
    @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    
    [session addOutput:output];
    
    dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
}

-(void)startCamera{
    //Start capturing frames
    [session startRunning];
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    //Display the preview layer
    CGRect frame = CGRectMake(0.0f, 0.0f, self.preview.bounds.size.width,self.preview.bounds.size.height);
    captureVideoPreviewLayer.frame = frame;
    [self.preview.layer addSublayer:captureVideoPreviewLayer];
}


#pragma mark - Image extraction

- (UIImage *) imageFromColorBuffer:(CMSampleBufferRef) sampleBuffer{
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    //Lock the image buffer
    if(kCVReturnSuccess != CVPixelBufferLockBaseAddress(imageBuffer,0)){
        DLog(@"Unable to lock image buffer.");
    }
    //Get image info
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    //Unlock the image buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    //Create a CGImageRef from the CVImageBufferRef
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst);
    CGImageRef newImage = CGBitmapContextCreateImage(newContext);
    
    //Release unneeded components
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    //Crop image height by 25% creating a 480x480 image. ('width' is the height when correctly orientated)
    int newWidth = 75 * (width / 100.0);
    int xOffset = (width - newWidth)/2;
    CGRect croppedRect = CGRectMake(xOffset, 0, newWidth, height);
    CGImageRef croppedImage = CGImageCreateWithImageInRect(newImage, croppedRect);
    CGImageRelease(newImage);
    newImage = croppedImage;
    
    //Create a UIImage object to return
    UIImage *image = [UIImage imageWithCGImage:newImage scale:1.0 orientation:UIImageOrientationRight];
    
    //Relase the CGImageRef
    CGImageRelease(newImage);
    
    return (image);
}

@end
