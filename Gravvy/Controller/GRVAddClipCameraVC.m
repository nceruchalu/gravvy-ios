//
//  GRVAddClipCameraVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/7/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVAddClipCameraVC.h"
#import "GRVAddClipCameraReviewVC.h"

#pragma mark - Constants
/**
 * Segue identifier for previewing video clip
 */
static NSString *const kSegueIdentifierReviewClip = @"showAddClipCameraReviewVC";

@interface GRVAddClipCameraVC ()

@end

@implementation GRVAddClipCameraVC

#pragma mark - Instance Methods
#pragma mark Concrete
- (void)processCompletedSession:(SCRecordSession *)recordSession
               withPreviewImage:(UIImage *)previewImage
{
    // Take the user on to the review VC
    [self performSegueWithIdentifier:kSegueIdentifierReviewClip sender:self];
}

#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
{
    if ([vc isKindOfClass:[GRVAddClipCameraReviewVC class]]) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:kSegueIdentifierReviewClip]) {
            // prepare vc
            GRVAddClipCameraReviewVC *cameraReviewVC = (GRVAddClipCameraReviewVC *)vc;
            cameraReviewVC.recordSession = self.recordSession;
            cameraReviewVC.previewImage  = self.previewImage;
            cameraReviewVC.video = self.video;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Grab the destination View Controller
    id destinationVC = segue.destinationViewController;
    
    // Account for the destination VC being embedded in a UINavigationController
    // which happens when this is a modal presentation segue
    if ([destinationVC isKindOfClass:[UINavigationController class]]) {
        destinationVC = [((UINavigationController *)destinationVC).viewControllers firstObject];
    }
    
    [self prepareViewController:destinationVC
                       forSegue:segue.identifier];
}

@end
