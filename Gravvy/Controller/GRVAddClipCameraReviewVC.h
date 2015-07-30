//
//  GRVAddClipCameraReviewVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/7/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraReviewViewController.h"

@class GRVVideo;
@class GRVClip;

/**
 * GRVAddClipCameraReviewVC is the VC used to review a clip to be added to a
 * video.
 */
@interface GRVAddClipCameraReviewVC : GRVCameraReviewViewController

/**
 * The video that the new clip will be added to, making this the
 * View Controller's model.
 * This property should be set before seguing to this VC.
 */
@property (strong, nonatomic) GRVVideo *video;

/**
 * The newly added clip
 */
@property (strong, nonatomic, readonly) GRVClip *addedClip;

@end
