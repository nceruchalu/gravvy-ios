//
//  GRVVideosCDTVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVExtendedCoreDataTableViewController.h"

@class GRVVideo;

/**
 * GRVVideosCDTVC is a class that represents a Core Data TableViewController
 * which is specialized to displaying a list of Videos.
 */
@interface GRVVideosCDTVC : GRVExtendedCoreDataTableViewController

#pragma mark - Properties
/**
 * Currently active video which might or might not be playing
 */
@property (strong, nonatomic, readonly) GRVVideo *activeVideo;

#pragma mark - Instance Methods
/**
 * Setup the fetchedResultsController @property of the VC
 */
- (void)setupFetchedResultsController;

/**
 * Stop the player and discard all player resources. Do this to prevent the
 * existence of multiple player instances when about to present the camera VC.
 *
 * @discussion Playing two items at the same time, can cause the exhaustion of
 *      resources allocated to the iOS Internal Media Services. Thus causing a
 *      AVAudioSessionMediaServicesWereResetNotification notification.
 *
 */
- (void)stop;

/**
 * Refresh and show spinner after scrolling to the top
 */
- (void)refreshAndShowSpinner;

@end
