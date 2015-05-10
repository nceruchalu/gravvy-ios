//
//  GRVAlertBannerView.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
//  Heavily based on ALAlertBanner, https://github.com/alobi/ALAlertBanner

#import <UIKit/UIKit.h>

#pragma mark - Typedefs
/**
 * Alert banner position
 */
typedef enum : NSUInteger {
    GRVAlertBannerViewPositionTop = 0,
    GRVAlertBannerViewPositionBottom,
    GRVAlertBannerViewPositionUnderNavBar
} GRVAlertBannerViewPosition;

/**
 * Alert banner state
 */
typedef enum : NSUInteger {
    GRVAlertBannerViewStateShowing = 0,
    GRVAlertBannerViewStateHiding,
    GRVAlertBannerViewStateMovingForward,
    GRVAlertBannerViewStateMovingBackward,
    GRVAlertBannerViewStateVisible,
    GRVAlertBannerViewStateHidden
} GRVAlertBannerViewState;


/**
 * GRVAlertBannerView is a custom alert banner designed to be non-distruptive to
 * the app user's experience, as would be the case with a regular UIAlertView.
 */
@interface GRVAlertBannerView : UIView

#pragma mark - Properties
/**
 * Current banner state
 */
@property (nonatomic, readonly) GRVAlertBannerViewState state;
@property (nonatomic, readonly) GRVAlertBannerViewPosition position;

/**
 * Length of time, in seconds, that a banner should show before auto-hiding.
 * A value == 0 will disable auto-hiding.
 */
@property (nonatomic) NSTimeInterval secondsToShow;

/**
 * The length of time it takes a banner to transition on-screen.
 */
@property (nonatomic) NSTimeInterval showAnimationDuration;

/**
 * The length of time it takes a banner to transition off-screen.
 */
@property (nonatomic) NSTimeInterval hideAnimationDuration;

/**
 * Banner opacity, between 0 and 1.
 */
@property (nonatomic) CGFloat bannerOpacity;

#pragma mark - Class Methods
/**
 * Customize and display a banner.
 *
 * @param view
 *      View to display the banner from, which could (and probably should)
 *      be a UIWindow
 * @param title
 *      String that appears in receiver's title bar
 * @param message
 *      Descriptive text that provides more details than the title
 * @param avatarThumbnail
 *      Thumbnail image to be used for an avatar view
 * @param userInitials
 *      If thumbnail image isn't available, then create an avatar based off the
 *      user initials
 * @param tappedBlock
 *      Block to be called upon a tap of the banner. This block has no return
 *      value and takes an argument of the tapped banner.
 * @param closeButtonTappedBlock
 *      Block to be called upon a tap of the banner close button. This block
 *      has no return value and takes an argument of the tapped banner.
 */
+ (GRVAlertBannerView *)alertBannerForView:(UIView *)view
                                     title:(NSString *)title
                                   message:(NSString *)message
                           avatarThumbnail:(UIImage *)avatarThumbnail
                              withInitials:(NSString *)userInitials
                               tappedBlock:(void (^)(GRVAlertBannerView *alertBanner))tappedBlock
                 andCloseButtonTappedBlock:(void (^)(GRVAlertBannerView *alertBanner))closeButtonTappedBlock;

/**
 * Returns an array of all banners within a certain view.
 *
 * @param view  UIView under consideration
 *
 * @return an array of alert banners
 */
+ (NSArray *)alertBannersInView:(UIView *)view;

/**
 * Immediately hides all alert banners in all views, forgoing their secondsToShow
 * values.
 */
+ (void)hideAllAlertBanners;

/**
 * Immediately hides all alert banners in a certain view, forgoing their
 * secondsToShow values.
 *
 * @param view  UIView under consideration
 */
+ (void)hideAlertBannersInView:(UIView *)view;

/**
 * Immediately force hide all alert banners, forgoing their dismissal animations.
 * Call this in viewWillDisappear: of your view controller if necessary.
 *
 * @param view  UIView under consideration
 */
+ (void)forceHideAllAlertBannersInView:(UIView *)view;


#pragma mark - Instance Methods
/**
 * Show the alert banner
 */
- (void)show;

/**
 * Immediately hide this alert banner, forgoing the secondsToShow value.
 */
- (void)hide;

@end
