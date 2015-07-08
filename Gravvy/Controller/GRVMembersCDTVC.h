//
//  GRVMembersCDTVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/6/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVExtendedCoreDataTableViewController.h"

@class GRVVideo;

/**
 * GRVMembersCDTVC is a class that represents a Core Data TableViewController
 * which is specialized to displaying a list of Video Members.
 */
@interface GRVMembersCDTVC : GRVExtendedCoreDataTableViewController

#pragma mark - Properties
/**
 * The members are specific to an video, making this the View Controller's
 * model.
 * This property should be set before seguing to this VC.
 */
@property (strong, nonatomic) GRVVideo *video;

@end
