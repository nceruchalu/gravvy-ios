//
//  AppDelegate.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

#pragma mark - Properties
@property (strong, nonatomic) UIWindow *window;

#pragma mark Remote Notifications
/**
 * Indicator of availabily of remote notifications that are pending processing
 */
@property (strong, nonatomic, readonly) NSString *remoteNotificationVideoHashKey;

#pragma mark - Instance Methods
/**
 * Finish processing remote notification received on application startup.
 * This is to be called by the Launch View Controller immediately after
 * successful authentication and setup of the Managed Object Context.
 */
- (void)processPendingLaunchRemoteNotification;

@end

