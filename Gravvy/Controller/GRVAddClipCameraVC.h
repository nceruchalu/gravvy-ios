//
//  GRVAddClipCameraVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/7/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraViewController.h"

@class GRVVideo;

/**
 * GRVAddClipCameraVC is a Camera View Controller class for recording additional
 * clips for a pre-existing video. If a video clip is successfully recorded,
 * the VC will be dismissed
 */
@interface GRVAddClipCameraVC : GRVCameraViewController

#pragma mark - Properties
/**
 * The video that the new clip will be added to, making this the
 * View Controller's model.
 * This property should be set before seguing to this VC.
 */
@property (strong, nonatomic) GRVVideo *video;

@end
