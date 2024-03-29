//
//  XFViewController.m
//  XFQrcodeScanDemo
//
//  Created by orangeskiller on 14-9-3.
//  Copyright (c) 2014年 orangeskiller. All rights reserved.
//

#import "XFViewController.h"
#import "UIBezierPath+QrcodeScanFocusBoxPath.h"
#import "XFQrcodeScanFocusBoxDynamicShapeLayer.h"

@interface XFViewController ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) XFQrcodeScanFocusBoxDynamicShapeLayer *shapeLayer;
@end

@implementation XFViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    NSError *error;
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    _captureSession = [[AVCaptureSession alloc] init];
    [_captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.view.layer.bounds];
    [self.view.layer addSublayer:_videoPreviewLayer];
    
    [_captureSession startRunning];
    
    _shapeLayer = [[XFQrcodeScanFocusBoxDynamicShapeLayer alloc] initWithView:self.view];
    _shapeLayer.strokeColor = [[[UIColor whiteColor] colorWithAlphaComponent:1.0] CGColor];
    _shapeLayer.lineWidth = 2.0;
    _shapeLayer.fillColor = [[UIColor clearColor] CGColor];
    CGMutablePathRef fillPath = CGPathCreateMutable();
    CGPathAddRect(fillPath, NULL, CGRectMake(32.5, 249, 252, 72));
    _shapeLayer.path = fillPath;
    [self.view.layer addSublayer:_shapeLayer];
    [_shapeLayer startBoxAnimation];
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_captureSession stopRunning];
                
                AVMetadataMachineReadableCodeObject *transformed = (AVMetadataMachineReadableCodeObject *)[_videoPreviewLayer transformedMetadataObjectForMetadataObject:metadataObj];
                
                NSArray *translatedCorners = [XFQrcodeScanFocusBoxDynamicShapeLayer translatePoints:transformed.corners
                                                                                        fromLayer:_videoPreviewLayer toLayer:_shapeLayer ];
                CGPathRef path = [[UIBezierPath createPathFromPoints:translatedCorners] CGPath];
                [_shapeLayer fucosToPath:path];
            });
            
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
