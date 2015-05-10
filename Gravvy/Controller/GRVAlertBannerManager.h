//
//  GRVAlertBannerManager.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
//  Heavily based on ALAlertBanner, https://github.com/alobi/ALAlertBanner

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * A singleton class that manages the presentation and dismissal of alert banners.
 * Having just one instance of this class throughout the application ensures all
 *   data stays synced.
 */
@interface GRVAlertBannerManager : NSObject
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized GRVAlertBannerManager object.
 */
+ (instancetype)sharedManager;

/**
 * Returns an array of all banners within a certain view.
 *
 * @param view  UIView under consideration
 *
 * @return an array of alert banners
 */
- (NSArray *)alertBannersInView:(UIView *)view;

/**
 * Hides all alert banners in all views,   their secondsToShow
 * values.
 */
- (void)hideAllAlertBanners;

/**
 * Immediately hides all alert banners in a certain view, forgoing their
 * secondsToShow values.
 *
 * @param view  UIView under consideration
 */
- (void)hideAlertBannersInView:(UIView *)view;

/**
 * Immediately force hide all alert banners, forgoing their dismissal animations.
 * Call this in viewWillDisappear: of your view controller if necessary.
 *
 * @param view  UIView under consideration
 */
- (void)forceHideAllAlertBannersInView:(UIView *)view;

@end
