//
//  GRVAlertBannerView+Private.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
//  Heavily based on ALAlertBanner, https://github.com/alobi/ALAlertBanner

#import "GRVAlertBannerView.h"

@class GRVAlertBannerView;

/**
 * Convenience methods on UIApplication to determine the navigation bar and
 * status bar heights
 */
@interface UIApplication (GRVApplicationBarHeights)

+ (CGFloat)navigationBarHeight;
+ (CGFloat)statusBarHeight;

@end

/**
 * Protocol to be implemented by any delegate of GRVAlertBannerView
 */
@protocol GRVAlertBannerViewDelegate <NSObject>
@required
/**
 * Show alert banner and hide after a given delay
 *
 * @param alertBanner   Alert banner view to be shown
 * @param delay         Time, in seconds, alert banner view should be visible
 */
- (void)showAlertBanner:(GRVAlertBannerView *)alertBanner hideAfter:(NSTimeInterval)delay;

/**
 * Hide alert banner with or without dismissal animations
 *
 * @param alertBanner   Alert banner view to be shown
 * @param forced        Hide banner immediately and don't wait for a scheduled hide
 *      event, by forgoing its dismissal animations?
 */
- (void)hideAlertBanner:(GRVAlertBannerView *)alertBanner forced:(BOOL)forced;

/**
 * Alert banner will show in a view
 *
 * @param alertBanner   Alert banner view about to be shown
 * @param view          View the alert banner will be shown in.
 */
- (void)alertBannerWillShow:(GRVAlertBannerView *)alertBanner inView:(UIView *)view;

/**
 * Alert banner did show in a view
 *
 * @param alertBanner   Alert banner view that was shown
 * @param view          View the alert banner was shown in.
 */
- (void)alertBannerDidShow:(GRVAlertBannerView *)alertBanner inView:(UIView *)view;

/**
 * Alert banner is about to be hidden in a view.
 *
 * @param alertBanner   Alert banner view about to be hidden.
 * @param view          View the alert banner will be hidden in.
 */
- (void)alertBannerWillHide:(GRVAlertBannerView *)alertBanner inView:(UIView *)view;

/**
 * Alert banner was hidden in a view
 *
 * @param alertBanner   Alert banner view that was hidden
 * @param view          View the alert banner was hidden in.
 */
- (void)alertBannerDidHide:(GRVAlertBannerView *)alertBanner inView:(UIView *)view;
@end

@interface GRVAlertBannerView ()

#pragma mark - Properties
@property (weak, nonatomic) id <GRVAlertBannerViewDelegate> delegate;
@property (nonatomic, getter=isScheduledToHide) BOOL scheduledToHide;
@property (copy, nonatomic) void(^tappedBlock)(GRVAlertBannerView *alertBanner);
@property (copy, nonatomic) void(^closeButtonTappedBlock)(GRVAlertBannerView *alertBanner);
@property (nonatomic) NSTimeInterval fadeInDuration;
@property (nonatomic) BOOL showShadow;
@property (nonatomic) BOOL shouldForceHide;

#pragma mark - Instance Methods
/**
 * show alert banner view
 */
- (void)showAlertBanner;

/**
 * hide alert banner view
 */
- (void)hideAlertBanner;

/**
 * Move alert banner a given distance, forward or backwards after a time delay
 *
 * @param distance  Distance to move alert banner by
 * @param forward   YES for forward, NO for backwards
 * @param delay     Delay in seconds before starting the move.
 */
- (void)pushAlertBanner:(CGFloat)distance
                forward:(BOOL)forward
                  delay:(NSTimeInterval)delay;

/**
 * Update alert banner frame size and layout with/without an animation
 *
 * @param animated  Should the update be animated?
 */
- (void)updateSizeAndSubviewsAnimated:(BOOL)animated;

/**
 * Update alert banner y position with/without an animation
 *
 * @param yPos      new y position
 * @param animated  Shoudl the update be animated?
 */
- (void)updatePositionAfterRotationWithY:(CGFloat)yPos animated:(BOOL)animated;

/**
 * The parent view controller that manages a given view. If this view is
 * a subview of another view, then this returns the view controller that manages
 * the superview.
 * Essentially this is the first View Controller found by making a series of
 * nextResponder method calls.
 */
- (id)nextAvailableViewController:(id)view;

@end