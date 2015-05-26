//
//  GRVCreateVideoContactPickerVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContactPickerViewController.h"

/**
 * GRVCreateVideoContactPickerVC is the VC for the final step of video creation
 * where you complete the event creation process by inviting at least 1 contact.
 * Ideally you would navigate to this VC after specifying video details which
 * would then be passed along to this VC as inputs
 *
 * Upon unwinding, this VC will create the video object asynchronously.
 */
@interface GRVCreateVideoContactPickerVC : GRVContactPickerViewController

#pragma mark - Properties
#pragma mark Inputs
/**
 * Preview image snapshot representation of the record session.
 * This serves as the cover image of the mp4.
 */
@property (strong, nonatomic) UIImage *previewImage;

/**
 * MP4 data generated from the recording session
 */
@property (strong, nonatomic) NSData *mp4;

/**
 * Title of the video
 */
@property (strong, nonatomic) NSString *videoTitle;

/**
 * Duration of the recording session
 */
@property (nonatomic) NSTimeInterval duration;

@end
