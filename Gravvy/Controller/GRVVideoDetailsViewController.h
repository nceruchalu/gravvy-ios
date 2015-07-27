//
//  GRVVideoDetailsViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/27/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideosCDTVC.h"

@class GRVVideo;

/**
 * GRVVideoDetailsViewController provides details on a specific video
 */
@interface GRVVideoDetailsViewController : GRVVideosCDTVC

/**
 * The View Controller's model.
 * This property should be set before seguing to this VC.
 */
@property (strong, nonatomic) GRVVideo *video;

@end
