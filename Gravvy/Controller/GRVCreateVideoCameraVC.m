//
//  GRVCreateVideoCameraVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/23/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCreateVideoCameraVC.h"
#import "GRVCreateVideoCameraReviewVC.h"

#pragma mark - Constants
/**
 * Segue identifier for previewing video clip and adding a title
 */
static NSString *const kSegueIdentifierReviewVideo = @"showCreateVideoCameraReviewVC";

@interface GRVCreateVideoCameraVC ()

@end

@implementation GRVCreateVideoCameraVC

#pragma mark - Instance Methods
#pragma mark Concrete
- (void)processCompletedSession:(SCRecordSession *)recordSession
               withPreviewImage:(UIImage *)previewImage
{
    // Take the user on to the review VC
    [self performSegueWithIdentifier:kSegueIdentifierReviewVideo sender:self];
}

#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
{
    if ([vc isKindOfClass:[GRVCreateVideoCameraReviewVC class]]) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:kSegueIdentifierReviewVideo]) {
            // prepare vc
            GRVCreateVideoCameraReviewVC *cameraReviewVC = (GRVCreateVideoCameraReviewVC *)vc;
            cameraReviewVC.recordSession = self.recordSession;
            cameraReviewVC.previewImage  = self.previewImage;
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
