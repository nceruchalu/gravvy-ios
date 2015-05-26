//
//  GRVLandingViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVLandingViewController.h"
#import "GRVCreateVideoContactPickerVC.h"
#import "GRVConstants.h"

#pragma mark - Constants
/**
 * Segue identifier for starting video creation workflow
 */
static NSString *const kSegueIdentifierCreateVideo = @"showCreateVideoCameraController";

@interface GRVLandingViewController ()

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
    // quit if camera is not available for recording videos
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    [self performSegueWithIdentifier:kSegueIdentifierCreateVideo sender:self];
}


#pragma mark - Navigation
#pragma mark Modal Unwinding
/**
 * Created a video. Nothing to do here really as we use an NSFetchedResultsController
 * that will pick up any new event
 */
- (IBAction)createdVideo:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[GRVCreateVideoContactPickerVC class]]) {
        //GRVCreateVideoContactPickerVC *contactPickerVC = (GRVCreateVideoContactPickerVC *)segue.sourceViewController;
    }
}


@end
