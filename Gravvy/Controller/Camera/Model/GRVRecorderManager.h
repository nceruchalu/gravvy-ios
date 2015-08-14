//
//  GRVRecorderManager.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/12/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SCRecorder.h"
#import "SCRecorderDelegate.h"

/**
 * GRVRecorderManager is a singleton class that ensures we have just one instance
 * of the RecorderManager throughout this application.
 * This class handles the consistent configuration of SCRecorder objects, and
 * convenient initialization of AVCaptureSession configuration.
 */
@interface GRVRecorderManager : NSObject

#pragma mark - Properties


#pragma mark - Class Methods
/**
 * Single instance.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized GRVRecorderManager object.
 */
+ (instancetype)sharedManager;

/**
 * Create, setup and prepare a recorder for use
 *
 * @param delegate SCRecorder delegate
 * @param previewView   View for presenting camera preview
 *
 * @return instantiated SCRecorder instance
 */
+ (SCRecorder *)recorderWithDelegate:(id<SCRecorderDelegate>)delegate
                      andPreviewView:(UIView *)previewView;

/**
 * Is app authorized to access camera?
 *
 * @return boolean indicating if app is authorized for video and microphone access
 */
+ (BOOL)authorized;


#pragma mark - Initalizers


#pragma mark - Instance Methods
/**
 * Configure, start and stop a capture session that will be disposed of.
 *
 * This serves the purpose of putting the camera in a state that won't have it
 * changing configurations when trying to present the Camera VC the first time.
 * This speeds up future runs of the capture session.
 */
- (void)configureCaptureSession;

@end
