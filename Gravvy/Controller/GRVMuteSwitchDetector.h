//
//  GRVMuteSwitchDetector.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/23/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
//  Heavily based on http://sharkfood.com/content/Developers/content/Sound%20Switch/

#import <Foundation/Foundation.h>

typedef void(^GRVMuteSwitchDetectorHandler)(BOOL muted);

/**
 * GRVMuteSwitchDetector is used for detecting the silent switch state state of 
 * iOS device.
 *
 * @discussion The summary of how it works is, it frequently plays a system sound,
 *      measures the amount of time it took for the sound to complete playing and
 *      based on that determines if we're in silent mode or not. This check is
 *      run frequently to give "close to real time" detection.
 */
@interface GRVMuteSwitchDetector : NSObject

#pragma mark - Properties
/**
 * Is the silent button currently on? If so the device is muted.
 */
@property (nonatomic,readonly) BOOL muted;

/**
 * Suspend the running of this detector
 */
@property (nonatomic) BOOL suspended;

/**
 * Callback block to be called whenever the silent switch state changes.
 */
@property (copy, nonatomic) GRVMuteSwitchDetectorHandler detectionHandler;

#pragma mark - Class Methods
/**
 * Single instance.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized GRVMuteSwitchDetector object.
 */
+ (instancetype)sharedDetector;

#pragma mark - Instance Methods
/**
 * Start running the detector if it isn't already running
 */
- (void)startRunning;

@end
