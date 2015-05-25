//
//  GRVCameraReviewViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/24/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraReviewViewController.h"
#import "SCRecordSession.h"

@interface GRVCameraReviewViewController ()

@end

@implementation GRVCameraReviewViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /*NSTimeInterval duration = CMTimeGetSeconds(recordSession.duration);
     [NSData dataWithContentsOfURL:url]*/
}

#pragma mark - Instance Methods
#pragma mark Abstract
- (void)completedReviewingRecording:(NSData *)mp4
                       previewImage:(UIImage *)previewImage
                           duration:(NSTimeInterval)duration
{
    // abstract
}

@end
