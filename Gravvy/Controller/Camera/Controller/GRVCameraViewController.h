//
//  GRVCameraViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/19/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SCRecordSession;

/**
 * GRVCameraViewController provides an Instagram-style Camera UI for recording
 * videos.
 */
@interface GRVCameraViewController : UIViewController

#pragma mark - Properties
/**
 * Preview image representing the recording
 */
@property (strong, nonatomic, readonly) UIImage *previewImage;

/**
 * Recorder's associated session
 */
@property (strong, nonatomic, readonly) SCRecordSession *recordSession;

#pragma mark - Instance Methods
#pragma mark Abstract
/**
 * Recording is done, process and possibly upload this session.
 * It would be prudent to pass this information along to a review VC.
 *
 * @param recordSession     Recording session that just completed
 * @param previewImage      Image snapshot representation of the video
 */
- (void)processCompletedSession:(SCRecordSession *)recordSession
               withPreviewImage:(UIImage *)previewImage;

@end
