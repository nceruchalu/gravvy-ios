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
 * GRVCameraViewController provides an Instagram-style Camera UI.
 */
@interface GRVCameraViewController : UIViewController

#pragma mark - Instance Methods
#pragma mark Abstract
/**
 * Recording is done, process and possibly upload this session
 */
- (void)processCompletedSession:(SCRecordSession *)recordSession;

@end
