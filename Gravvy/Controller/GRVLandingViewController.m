//
//  GRVLandingViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVLandingViewController.h"
#import "GRVConstants.h"

@interface GRVLandingViewController () <UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate>

@end

@implementation GRVLandingViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
}


#pragma mark - Instance Methods

#pragma mark Target/Action methods
- (IBAction)recordVideo:(UIButton *)sender
{
    [self startCameraController];
}

#pragma mark Video Recording Helpers

/**
 * Start camera controller for recording a video
 */
- (void)startCameraController
{
    // We will only be recording videos
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    
    // quit if camera is not available
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    
    // camera available so set it up to capture only movies
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = sourceType;
    
    //cameraUI.mediaTypes = @[(NSString *)kUTTypeMovie];
    cameraUI.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    
    // Don't show the controls for trimming videos and use custom controls
    cameraUI.allowsEditing = NO;
    //cameraUI.showsCameraControls = NO;
    
    cameraUI.videoMaximumDuration = kGRVClipMaximumDuration;
    cameraUI.videoQuality = UIImagePickerControllerQualityTypeMedium;
    cameraUI.delegate = self;
    [self presentViewController:cameraUI animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate
// For responding to the user tapping Cancel
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// For responding to the user accepting a newly captured picture.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *moviePath = info[UIImagePickerControllerMediaURL];
    
    // Save newly taken video to camera roll
    if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(moviePath)) {
        UISaveVideoAtPathToSavedPhotosAlbum(moviePath, nil, nil, nil);
    }

    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
