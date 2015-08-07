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

/**
 * The View Controller's model that should be set when this VC is being used
 * as a `Details VC` that will only display a specific video.
 * If using this property then it should be set before seguing to this VC.
 */
@property (strong, nonatomic) GRVVideo *detailsVideo;

/**
 * Skip refresh table view next time Table View appears
 */
@property (nonatomic) BOOL skipRefreshOnNextAppearance;

#pragma mark - Instance Methods
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
