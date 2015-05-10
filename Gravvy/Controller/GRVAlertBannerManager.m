//
//  GRVAlertBannerManager.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
//  Heavily based on ALAlertBanner, https://github.com/alobi/ALAlertBanner

#import "GRVAlertBannerManager.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "GRVAlertBannerView+Private.h"

# pragma mark - Categories for Convenience
@interface UIView (GRVAlertBannerConvenience)

@property (nonatomic, strong) NSMutableArray *alertBanners;

@end

@implementation UIView (GRVAlertBannerConvenience)

@dynamic alertBanners;

- (void)setAlertBanners:(NSMutableArray *)alertBanners
{
    objc_setAssociatedObject(self, @selector(alertBanners), alertBanners, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableArray *)alertBanners
{
    NSMutableArray *alertBannersArray = objc_getAssociatedObject(self, @selector(alertBanners));
    if (!alertBannersArray) {
        alertBannersArray = [NSMutableArray array];
        [self setAlertBanners:alertBannersArray];
    }
    return alertBannersArray;
}

@end


@interface GRVAlertBannerManager () <GRVAlertBannerViewDelegate>

#pragma mark - Properties
@property (nonatomic) dispatch_semaphore_t topPositionSemaphore;
@property (nonatomic) dispatch_semaphore_t bottomPositionSemaphore;
@property (nonatomic) dispatch_semaphore_t navBarPositionSemaphore;
@property (nonatomic, strong) NSMutableArray *bannerViews;

/**
 * Cached window level of system status bar as the actual window level
 * will be modified to ensure the status bar doesn't overlap the alert banner
 */
@property (nonatomic) UIWindowLevel cachedWindowLevel;

@end


@implementation GRVAlertBannerManager

#pragma mark - Class Methods
#pragma mark Public
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static GRVAlertBannerManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

#pragma mark - Initialization
- (id)init
{
    self = [super init];
    if (self) {
        
        //let's make sure only one animation happens at a time
        _topPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_topPositionSemaphore);
        _bottomPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_bottomPositionSemaphore);
        _navBarPositionSemaphore = dispatch_semaphore_create(0);
        dispatch_semaphore_signal(_navBarPositionSemaphore);
        
        _bannerViews = [NSMutableArray new];
        _cachedWindowLevel =  [[UIApplication sharedApplication].delegate window].windowLevel;
        
        // register observers
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidRotate:)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Object Lifecycle
- (void)dealloc
{
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidChangeStatusBarOrientationNotification
                                                  object:nil];
}


# pragma mark - Instance Methods
#pragma mark Public
- (NSArray *)alertBannersInView:(UIView *)view
{
    return [NSArray arrayWithArray:view.alertBanners];
}

- (void)hideAlertBannersInView:(UIView *)view
{
    for (GRVAlertBannerView *alertBanner in [self alertBannersInView:view]) {
        [self hideAlertBanner:alertBanner forced:NO];
    }
}

- (void)hideAllAlertBanners
{
    for (UIView *view in self.bannerViews) {
        [self hideAlertBannersInView:view];
    }
}

- (void)forceHideAllAlertBannersInView:(UIView *)view
{
    for (GRVAlertBannerView *alertBanner in [self alertBannersInView:view]) {
        [self hideAlertBanner:alertBanner forced:YES];
    }
}


# pragma mark - GRVAlertBannerViewDelegate
- (void)showAlertBanner:(GRVAlertBannerView *)alertBanner hideAfter:(NSTimeInterval)delay
{
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case GRVAlertBannerViewPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case GRVAlertBannerViewPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case GRVAlertBannerViewPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_main_queue(), ^{
            [alertBanner showAlertBanner];
            
            if (delay > 0) {
                [self performSelector:@selector(hideAlertBanner:) withObject:alertBanner afterDelay:delay];
            }
        });
    });
    
    // Update windowLevel to make sure status bar does not interfere with the notification
    [[UIApplication sharedApplication].delegate window].windowLevel = UIWindowLevelStatusBar+1;
}

- (void)hideAlertBanner:(GRVAlertBannerView *)alertBanner
{
    [self hideAlertBanner:alertBanner forced:NO];
}

- (void)hideAlertBanner:(GRVAlertBannerView *)alertBanner forced:(BOOL)forced
{
    if (alertBanner.isScheduledToHide) {
        return;
    }
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideAlertBanner:) object:alertBanner];
    
    if (forced) {
        alertBanner.shouldForceHide = YES;
        [alertBanner hideAlertBanner];
    }
    else {
        alertBanner.scheduledToHide = YES;
        
        dispatch_semaphore_t semaphore;
        switch (alertBanner.position) {
            case GRVAlertBannerViewPositionTop:
                semaphore = self.topPositionSemaphore;
                break;
            case GRVAlertBannerViewPositionBottom:
                semaphore = self.bottomPositionSemaphore;
                break;
            case GRVAlertBannerViewPositionUnderNavBar:
                semaphore = self.navBarPositionSemaphore;
                break;
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            dispatch_async(dispatch_get_main_queue(), ^{
                [alertBanner hideAlertBanner];
            });
        });
    }
    
    // Reset windowLevel of status bar back to the default
    [[UIApplication sharedApplication].delegate window].windowLevel = self.cachedWindowLevel;
}

- (void)alertBannerWillShow:(GRVAlertBannerView *)alertBanner inView:(UIView *)view
{
    //keep track of all views we've added banners to, to deal with rotation events and hideAllAlertBanners
    if (![self.bannerViews containsObject:view]) {
        [self.bannerViews addObject:view];
    }
    
    //make copy so we can set shadow before pushing banners
    NSArray *bannersToPush = [NSArray arrayWithArray:view.alertBanners];
    NSMutableArray *bannersArray = view.alertBanners;
    
    [bannersArray addObject:alertBanner];
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    
    //set shadow before pushing other banners, because the banner push may be delayed by the fade in duration (which is set at the same time as the shadow) on iOS7
    alertBanner.showShadow = (bannersInSamePosition.count > 1 ? NO : YES);
    
    for (GRVAlertBannerView *banner in bannersToPush) {
        if (banner.position == alertBanner.position) {
            [banner pushAlertBanner:alertBanner.frame.size.height forward:YES delay:alertBanner.fadeInDuration];
        }
    }
}

- (void)alertBannerDidShow:(GRVAlertBannerView *)alertBanner inView:(UIView *)view
{
    dispatch_semaphore_t semaphore;
    switch (alertBanner.position) {
        case GRVAlertBannerViewPositionTop:
            semaphore = self.topPositionSemaphore;
            break;
        case GRVAlertBannerViewPositionBottom:
            semaphore = self.bottomPositionSemaphore;
            break;
        case GRVAlertBannerViewPositionUnderNavBar:
            semaphore = self.navBarPositionSemaphore;
            break;
    }
    dispatch_semaphore_signal(semaphore);
}

- (void)alertBannerWillHide:(GRVAlertBannerView *)alertBanner inView:(UIView *)view
{
    NSMutableArray *bannersArray = view.alertBanners;
    NSArray *bannersInSamePosition = [bannersArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", alertBanner.position]];
    NSUInteger index = [bannersInSamePosition indexOfObject:alertBanner];
    if (index != NSNotFound && index > 0) {
        NSArray *bannersToPush = [bannersInSamePosition subarrayWithRange:NSMakeRange(0, index)];
        
        for (GRVAlertBannerView *banner in bannersToPush)
            [banner pushAlertBanner:-alertBanner.frame.size.height forward:NO delay:0.f];
    }
    
    else if (index == 0) {
        if (bannersInSamePosition.count > 1) {
            GRVAlertBannerView *nextAlertBanner = (GRVAlertBannerView *)[bannersInSamePosition objectAtIndex:1];
            [nextAlertBanner setShowShadow:YES];
        }
        
        [alertBanner setShowShadow:NO];
    }
}

- (void)alertBannerDidHide:(GRVAlertBannerView *)alertBanner inView:(UIView *)view
{
    NSMutableArray *bannersArray = view.alertBanners;
    [bannersArray removeObject:alertBanner];
    if (bannersArray.count == 0) {
        [self.bannerViews removeObject:view];
    }
    if (!alertBanner.shouldForceHide) {
        dispatch_semaphore_t semaphore;
        switch (alertBanner.position) {
            case GRVAlertBannerViewPositionTop:
                semaphore = self.topPositionSemaphore;
                break;
            case GRVAlertBannerViewPositionBottom:
                semaphore = self.bottomPositionSemaphore;
                break;
            case GRVAlertBannerViewPositionUnderNavBar:
                semaphore = self.navBarPositionSemaphore;
                break;
        }
        dispatch_semaphore_signal(semaphore);
    }
}


#pragma mark - Notification Observer Methods
- (void)applicationDidRotate:(NSNotification *)aNotification
{
    for (UIView *view in self.bannerViews) {
        
        NSArray *topBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", GRVAlertBannerViewPositionTop]];
        CGFloat topYCoord = 0.f;
        
        if ([topBanners count] > 0) {
            GRVAlertBannerView *firstBanner = (GRVAlertBannerView *)[topBanners objectAtIndex:0];
            id nextResponder = [firstBanner nextAvailableViewController:firstBanner];
            if (nextResponder) {
                UIViewController *vc = nextResponder;
                if (!(vc.automaticallyAdjustsScrollViewInsets && [vc.view isKindOfClass:[UIScrollView class]])) {
                    topYCoord += [vc topLayoutGuide].length;
                }
            }
        }
        
        for (GRVAlertBannerView *alertBanner in [topBanners reverseObjectEnumerator]) {
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            [alertBanner updatePositionAfterRotationWithY:topYCoord animated:YES];
            topYCoord += alertBanner.layer.bounds.size.height;
        }
        
        NSArray *bottomBanners = [view.alertBanners filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.position == %i", GRVAlertBannerViewPositionBottom]];
        CGFloat bottomYCoord = view.bounds.size.height;
        for (GRVAlertBannerView *alertBanner in [bottomBanners reverseObjectEnumerator]) {
            //update frame size before animating to new position
            [alertBanner updateSizeAndSubviewsAnimated:YES];
            bottomYCoord -= alertBanner.layer.bounds.size.height;
            [alertBanner updatePositionAfterRotationWithY:bottomYCoord animated:YES];
        }
    }
}

@end
