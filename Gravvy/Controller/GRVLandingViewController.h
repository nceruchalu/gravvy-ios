//
//  GRVLandingViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContainerViewController.h"

@class GRVVideosCDTVC;

/**
 * GRVLandingViewController is the landing VC of the app.
 */
@interface GRVLandingViewController : GRVContainerViewController

#pragma mark - Properties
// Videos Table View Controller
@property (strong, nonatomic, readonly) GRVVideosCDTVC *videosVC;

@end
