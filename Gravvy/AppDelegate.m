//
//  AppDelegate.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "AppDelegate.h"
#import "GRVContact+AddressBook.h"
#import "GRVAccountManager.h"
#import "GRVAddressBookManager.h"
#import "GRVHTTPManager.h"
#import "GRVModelManager.h"
#import "GRVConstants.h"
#import "GRVUser+HTTP.h"
#import "GRVVideo+HTTP.h"
#import "GRVActivity+HTTP.h"
#import "GRVAlertBannerView.h"
#import "GRVAlertBannerManager.h"
#import "GRVUserViewHelper.h"
#import "GRVUserAvatarView.h"
#import "GRVRecorderManager.h"
#import "GRVLandingViewController.h"
#import "GRVVideosCDTVC.h"
#import "GRVFormatterUtils.h"
#import <AudioToolbox/AudioToolbox.h>
#import "AMPopTip.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>

#pragma mark - Constants
/**
 * Video hashKey key in Remote Notifications.
 */
static NSString *const kRemoteNotificationVideoHashKeyKey = @"video_hash_key";

/**
 * User Phone Number key in Remote Notifications.
 */
static NSString *const kRemoteNotificationUserPhoneNumberKey = @"user_phone_number";

/**
 * User Full Name key in Remote Notifications.
 */
static NSString *const kRemoteNotificationUserFullNameKey = @"user_full_name";

/**
 * Remote Notification Message key, that is to be displayed in the alert banner.
 * This is different from the aps alert message from the APS alert message
 * in that it allows for more flexibility.
 */
static NSString *const kRemoteNotificationMessageKey = @"video_message";

/**
 * Remote Notification Action Type key
 */
static NSString *const kRemoteNotificationTypeKey = @"action_type";

/**
 * Remote Notification Object Identifier Key
 */
static NSString *const kRemoteNotificationObjectIdentifierKey = @"object_identifier";

/**
 * Remote Notifications sound
 */
static NSString *const kRemoteNotificationSoundFile = @"notification";
static NSString *const kRemoteNotificationSoundFileExtension = @"caf";


@interface AppDelegate ()

/**
 * Indicator of if the app got into the Foreground from Background or
 * "Not running".
 * If YES then the previous state was Background, otherwise "Not running"
 *
 * @ref https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/TheAppLifeCycle/TheAppLifeCycle.html#//apple_ref/doc/uid/TP40007072-CH2-SW1
 */
@property (nonatomic) BOOL activatedFromBackground;

#pragma mark Remote Notifications
/**
 * Hash key of video associated with recent push notification
 */
@property (strong, nonatomic, readwrite) NSString *remoteNotificationVideoHashKey;

/**
 * Action type associated with recent push notification
 */
@property (nonatomic) GRVRemoteNotificationType remoteNotificationType;

@property (nonatomic) CFURLRef soundFileURLRef;
@property (nonatomic) SystemSoundID soundFileObject;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Initialize Fabric with Crashlytics Kit
    [Fabric with:@[CrashlyticsKit]];
    
    // Setup custom appearances
    [[UINavigationBar appearance] setBarTintColor:kGRVThemeColor];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    
    UIFont *titleFont = [UIFont fontWithName:kGRVThemeFontBold size:20.0f];
    NSDictionary *titleAttributes = @{NSFontAttributeName : titleFont,
                                      NSForegroundColorAttributeName: [UIColor whiteColor]};
    [[UINavigationBar appearance] setTitleTextAttributes:titleAttributes];
    
    // Remove the back button item title
    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60)
                                                         forBarMetrics:UIBarMetricsDefault];
    
    // Configure poptip appearance
    [self configurePopTipAppearance];
    
    // Starting app from "Not running" state.
    self.activatedFromBackground = NO;
    
    // Not yet registered for APNS Push Notifications. Will do so after
    // Authentication.
    [GRVAccountManager sharedManager].apnsRegistered = NO;
    
    // Setup Remote Notifications source sound file
    // Create the URL for the source audio file.
    NSURL *alertSound = [[NSBundle mainBundle] URLForResource:kRemoteNotificationSoundFile
                                                withExtension:kRemoteNotificationSoundFileExtension];
    
    // Store the URL as a CFURLRef instance
    self.soundFileURLRef = (CFURLRef)CFBridgingRetain(alertSound);
    
    // Create a system sound object representing the sound file.
    AudioServicesCreateSystemSoundID(self.soundFileURLRef, &_soundFileObject);
    
    // Handle Push Notifications
    NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    NSString *videoHashKey = [remoteNotif objectForKey:kRemoteNotificationVideoHashKeyKey];
    NSUInteger notificationType = [[remoteNotif objectForKey:kRemoteNotificationTypeKey] integerValue];
    
    // Why do I check for !self.remoteNotificationVideoHashKey? To ensure:
    // - We don't overwrite another pending remote notification process as this
    //   property is only set here and in application:didReceiveRemoteNotification:
    if ([videoHashKey length] && ![self.remoteNotificationVideoHashKey length]) {
        // Setup a video hash key to be looked at on successful authentication
        self.remoteNotificationVideoHashKey = videoHashKey;
        self.remoteNotificationType = notificationType;
        
        // Now we wait for the launch VC to finish its processing then call the
        // instance method: processPendingLaunchRemoteNotification
    }
    
    // Clear notifications from notification center
    // Unfortunately this requires decrementing the application icon badge number
    // @ref http://stackoverflow.com/a/9225972
    UIApplication *sharedApp = [UIApplication sharedApplication];
    if ([self canSetApplicationBadge]) {
        sharedApp.applicationIconBadgeNumber = 1;
        sharedApp.applicationIconBadgeNumber = 0;
    }
    [sharedApp cancelAllLocalNotifications];
    
    // Connect app delegate to FBSDKCoreKit
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    return YES;
}

#pragma mark Helper
/**
 * Customize the appearance of the pop tips to be used in the app
 */
- (void)configurePopTipAppearance
{
    AMPopTip *appearance = [AMPopTip appearance];
    appearance.font = [UIFont fontWithName:@"Avenir-Medium" size:14.0f];
    appearance.textColor = [UIColor whiteColor];
    appearance.textAlignment = NSTextAlignmentLeft;
    appearance.popoverColor = kGRVDarkThemeColor;
    appearance.offset = 2.0f; // Offset between the popover and the origin
    appearance.edgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    appearance.actionAnimation = AMPopTipActionAnimationPulse;
    appearance.edgeMargin = 5.0f;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state.
    // This can occur for certain types of temporary interruptions (such as an
    // incoming phone call or SMS message) or when the user quits the application
    // and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down
    // OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate
    // timers, and store enough application state information to restore your
    // application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called
    // instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state;
    // here you can undo many of the changes made on entering the background.
    
    // Starting app from Background state.
    self.activatedFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the
    // application was inactive. If the application was previously in the
    // background, optionally refresh the user interface.
    
    // Clear any application badges
    if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    
    // A lot could have changed since user last went into the background
    if (self.activatedFromBackground) {
        
        // Authenticate the user if necessary.
        BOOL httpIsAuthenticated = [GRVAccountManager sharedManager].isAuthenticated;
        BOOL httpIsRegistered = [GRVAccountManager sharedManager].isRegistered;
        BOOL profileIsConfigured = [GRVModelManager sharedManager].profileConfiguredPostActivation;
        
        if (httpIsRegistered && profileIsConfigured) {
            
            if (!httpIsAuthenticated) {
                [[GRVAccountManager sharedManager] authenticateWithSuccess:nil failure:^(NSUInteger statusCode) {
                    // Force the user to restart by going to the app's launch view controller
                    UINavigationController *rootNVC = (UINavigationController *)self.window.rootViewController;
                    [rootNVC dismissViewControllerAnimated:YES completion:nil];
                    [rootNVC popToRootViewControllerAnimated:NO];
                }];
            } else {
                // Already authenticated so refresh content
                [GRVActivity refreshActivities:nil];
            }
            
        }
    }
    
    // If authorized for address book access attempt performing a sync.
    // We only check for authorization here so as not to trigger a request for
    // Address Book access.
    // Do this on background thread else the App will be killed for failing to
    // resume in time
    dispatch_queue_t q = dispatch_queue_create("Contacts Refresh Queue", NULL);
    dispatch_async(q, ^{
        if ([GRVAddressBookManager authorized]) [GRVContact refreshContacts:nil];
    });
    
    // Run AVCaptureSession once so that future launches of camera VC are snappy
    [[GRVRecorderManager sharedManager] configureCaptureSession];
    
    // Connect app delegate to FBSDKCoreKit
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate.
    // See also applicationDidEnterBackground:.
    
    // Release memory for the alert sound
    AudioServicesDisposeSystemSoundID(_soundFileObject);
    if (self.soundFileURLRef) {
        CFRelease(_soundFileURLRef);
        self.soundFileURLRef = NULL;
    }
}

#pragma mark - Handling Remote Notifications
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [GRVAccountManager sharedManager].apnsRegistered = YES;
    [self sendProviderDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // Ignore an error in registration. This is non-essential
}

#pragma mark After Notification Delivery
/**
 * User taps a custom action button in an iOS8 notification.
 * Method provides the identifier of the action so that you can determine which
 * button the user tapped. You also get either the remote or local notification
 * object, so that you can retrieve any information you need to handle the action.
 */
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
    [self application:application didReceiveRemoteNotification:userInfo];
}

/**
 * Called if the notification is delivered when the app is running in the foreground
 * Or the application was paused in the background.
 */
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    // Clear notifications from notification center
    // Unfortunately this requires decrementing the application icon badge number
    // @ref http://stackoverflow.com/a/9225972
    UIApplication *sharedApp = [UIApplication sharedApplication];
    if ([self canSetApplicationBadge]) {
        sharedApp.applicationIconBadgeNumber = 1;
        sharedApp.applicationIconBadgeNumber = 0;
    }
    [sharedApp cancelAllLocalNotifications];
    
    // Why do I check for remoteNotificationVideoHashKey? To ensure:
    // - We don't overwrite another pending remote notification process as this
    //   property is only set here and in application:didReceiveRemoteNotification:
    if ([self.remoteNotificationVideoHashKey length]) {
        return;
    }
    
    NSDictionary *remoteNotif = [userInfo objectForKey:@"aps"];
    NSString *remoteNotificationAlert = [remoteNotif objectForKey:@"alert"];
    
    // Get video hash key, notification type user phone number, and user fullName
    NSString *videoHashKey = [userInfo objectForKey:kRemoteNotificationVideoHashKeyKey];
    NSUInteger notificationType = [[userInfo objectForKey:kRemoteNotificationTypeKey] integerValue];
    NSString *userPhoneNumber = [userInfo objectForKey:kRemoteNotificationUserPhoneNumberKey];
    NSString *userFullName = [userInfo objectForKey:kRemoteNotificationUserFullNameKey];
    id notificationObjectIdentifier = [userInfo objectForKey:kRemoteNotificationObjectIdentifierKey];
    
    // Get notification message, which is the aps dictionary alert string
    NSString *remoteNotificationMessage = [userInfo objectForKey:kRemoteNotificationMessageKey];
    
    NSManagedObjectContext *context = [GRVModelManager sharedManager].managedObjectContext;
    if (context) {
        // We only bother with this if there is indeed a context
        // Now go get the appropriate video either from local storage or the server
        [GRVVideo fetchVideoWithVideoHashKey:videoHashKey inManagedObjectContext:context withCompletion:^(GRVVideo *video) {
            if (video) {

                // if app user has been kicked out of the video, delete it
                if (notificationType == GRVRemoteNotificationTypeRemovedMember) {
                    if ([notificationObjectIdentifier isKindOfClass:[NSString class]]) {
                        NSString *phoneNumber = (NSString *)notificationObjectIdentifier;
                        if ([phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber]) {
                            [context deleteObject:video];
                        }
                    }
                }
                
                if (application.applicationState == UIApplicationStateInactive ||
                    application.applicationState == UIApplicationStateBackground) {
                    // If app was launched by a remote notification when app was
                    // in the background, process this like we would for a
                    // remote notification received on application startup.
                    
                    // Only cache event name when necessary.
                    self.remoteNotificationVideoHashKey = videoHashKey;
                    self.remoteNotificationType = notificationType;
                    [self processPendingLaunchRemoteNotification];
                    
                } else {
                    // The notification was delivered when app is running in the
                    // foreground so show an alert banner for the specific event
                    // if not already in the event view for that event
                    
                    // Check if already showing the video view for the video in
                    // the remote notification
                    BOOL alreadyShowingVideoView = NO;
                    UIViewController *topVC = [self topMostViewController];
                    if ([topVC isKindOfClass:[GRVLandingViewController class]]) {
                        GRVLandingViewController *landingVC = (GRVLandingViewController *)topVC;
                        if ((UIViewController *)landingVC.videosVC == landingVC.selectedViewController) {
                            // Is the videos VC the selected VC? if so check
                            // if the currently active video is the push
                            // notification video
                            if ([landingVC.videosVC.activeVideo.hashKey isEqualToString:videoHashKey]) {
                                alreadyShowingVideoView = YES;
                                // TODO: Pass this notification to the videos VC
                            }
                        }
                    }
                    
                    if ([remoteNotificationAlert length]) {
                        // If remote notification has an alert, show an alert banner
                        
                        // Get alert title
                        NSString *alertTitle;
                        if ([video.title length]) {
                            alertTitle = [NSString stringWithFormat:@"\"%@\"", video.title];
                        } else {
                            NSString *owner = [GRVUserViewHelper userFirstName:video.owner];
                            NSString *createdAt = [GRVFormatterUtils dayAndYearStringForDate:video.createdAt];
                            alertTitle = [NSString stringWithFormat:@"%@'s %@ video", owner, createdAt];
                        }
                        
                        // Get user's name
                        GRVUser *videoUser = [GRVUser findUserWithPhoneNumber:userPhoneNumber inManagedObjectContext:context];
                        NSString *senderName = userPhoneNumber;
                        if (videoUser) {
                            senderName = [GRVUserViewHelper userFullNameOrPhoneNumber:videoUser];
                        } else if ([userFullName length]) {
                            senderName = userFullName;
                        }
                        
                        // Use user's name as part of alert message
                        NSString *alertMessage = [NSString stringWithFormat:@"%@: %@", senderName, remoteNotificationMessage];
                        
                        // Get alert avatar data
                        GRVUserAvatarView *userAvatarView = [GRVUserViewHelper userAvatarView:videoUser];
                        
                        // Cache notification type as this will be used when
                        // displaying video view
                        self.remoteNotificationType = notificationType;
                        __weak AppDelegate *weakSelf = self;
                        GRVAlertBannerView *banner =
                        [GRVAlertBannerView alertBannerForView:[self viewForBannerAlert]
                                                         title:alertTitle message:alertMessage
                                               avatarThumbnail:userAvatarView.thumbnail
                                                  withInitials:userAvatarView.userInitials
                                                   tappedBlock:^(GRVAlertBannerView *alertBanner)
                        {
                            // Hide alert banner
                            [alertBanner hide];
                            
                            // Display video's details
                            [weakSelf displayVideoView:videoHashKey withAnimation:YES];
                            
                            // Clear remote notification references that will be
                            //  reconfigured on next notification
                            weakSelf.remoteNotificationVideoHashKey = nil;
                            weakSelf.remoteNotificationType = GRVRemoteNotificationTypeDefault;
                        }
                                     andCloseButtonTappedBlock:^(GRVAlertBannerView *alertBanner)
                        {
                            // Dismiss event by hiding alert banner
                            [alertBanner hide];
                            
                            // Clear remote notification references that will be
                            //  reconfigured on next notification
                            weakSelf.remoteNotificationVideoHashKey = nil;
                            weakSelf.remoteNotificationType = GRVRemoteNotificationTypeDefault;
                        }];
                        
                        // Hide previous alert banners and show new banner
                        [[GRVAlertBannerManager sharedManager] hideAllAlertBanners];
                        [banner show];
                        
                        // Play sound if user allows this
                        // TODO: Vary sounds by remote notification types
                        if ([GRVModelManager sharedManager].userSoundsSetting) {
                            AudioServicesPlaySystemSound(self.soundFileObject);
                            // Could vibrate by uncommenting the below:
                            // AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                        }
                        
                        // Would cache alert and video hashkey for future
                        // reference but that's unnecessary given that the
                        // block captures the event name
                        
                    } // end if (!alreadyShowingVideoView)
                    
                } // end check for if app is coming from background
                
            } // end if(video)
            
        }]; // end fetchVideoWithVideoHashKey:inManagedObjectContext:withCompletion:
        
    } // end if(context)
}


#pragma mark Helpers
/**
 * Register device token against app user with the web server
 */
- (void)sendProviderDeviceToken:(NSData *)deviceToken
{
    // Create a device token by removing open and closing angles and whitespaces
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    NSDictionary *parameters = @{kGRVRESTPushRegistrationIdKey : token};
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodPOST forURL:kGRVRESTPushRegister parameters:parameters success:nil failure:nil];
}

/**
 * Check if app is authorized to set the badge the application icon. If not
 * authorized and we try this, we get this message:
 *      Attempting to badge the application icon but haven't received permission
 *      from the user to badge the application
 */
- (BOOL)canSetApplicationBadge
{
    BOOL authorized;
    
    UIApplication *application = [UIApplication sharedApplication];
    if ([application respondsToSelector:@selector(currentUserNotificationSettings)]) {
        // iOS8 and greater
        UIUserNotificationSettings *notificationSettings = [application currentUserNotificationSettings];
        authorized = notificationSettings.types & UIUserNotificationTypeBadge;
        
    } else {
        // iOS7 and earlier doesn't provide a way to check permissions so
        // assume YES
        authorized = YES;
    }
    
    return authorized;
}

/**
 * Get the topmost container VC  without drilling down Navigation Controllers
 * and Tab Bar Controllers. However we do drill for Modal container VCs.
 * This means returning the ancestor VC of the topMostViewController
 */
- (UIViewController *)topMostViewControllerAncestor
{
    UIViewController *topController = self.window.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}


/**
 * Get the topmost/visible VC with checks for Navigation Controllers, Tab Bar Controllers,
 * Modal VCs.
 */
- (UIViewController *)topMostViewController
{
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

/**
 * Get the topmost View Controller given a root view controller
 * @ref http://stackoverflow.com/a/17578272
 */
- (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)rootViewController
{
    
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        // Handling UITabBarController
        UITabBarController* tabBarController = (UITabBarController*)rootViewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
        
    } else if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        // Handling UINavigationController
        UINavigationController* navigationController = (UINavigationController*)rootViewController;
        return [self topViewControllerWithRootViewController:navigationController.visibleViewController];
        
    } else if (rootViewController.presentedViewController) {
        // Handling Modal VCs
        UIViewController* presentedViewController = rootViewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
        
    } else {
        // Handling UIViewController's added as subviews to some other views.
        for (UIView *view in [rootViewController.view subviews]) {
            id subViewController = [view nextResponder];    // Key property which most of us are unaware of / rarely use.
            if ( subViewController && [subViewController isKindOfClass:[UIViewController class]]) {
                return [self topViewControllerWithRootViewController:subViewController];
            }
        }
        return rootViewController;
    }
}

/**
 * View to be used for displaying banner alert, as it differs between iOS7 and
 * iOS8
 *
 * @return Top level UIView that responds to rotations and orientations
 *
 * @ref https://github.com/MPGNotification/MPGNotification
 */
- (UIView *)viewForBannerAlert
{
    UIView *window;
    if (GRV_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        // if on iOS8 then can use the app's singular window
        window = self.window;
        
    } else {
        // if on iOS7, the app delegate's window won't work in landscape mode so
        // use the top app window's top subview.
        UIWindow *topAppWindow = ([UIApplication sharedApplication].keyWindow) ?: [[UIApplication sharedApplication].windows lastObject];
        window =[topAppWindow.subviews lastObject];
    }
    return window;
}

/**
 * Present an Video View for a video of a given hash key
 *
 * @warning If the video isn't in local storage by the time this is called,
 *      it will do a server fetch first
 *
 * @param videoHashKey      identifier of video to be displayed
 * @param animated          Should the presentation be animated?
 */
- (void)displayVideoView:(NSString *)videoHashKey withAnimation:(BOOL)animated
{
    
    // Some basic error checking for an argument
    if (![videoHashKey length]) {
        return;
    }
    
    UIViewController *topVC = [self topMostViewController];
    if ([topVC isKindOfClass:[GRVLandingViewController class]]) {
        GRVLandingViewController *landingVC = (GRVLandingViewController *)topVC;
        
        // Navigate to videosVC and refresh
        landingVC.selectedIndex = 0;
        [landingVC.videosVC refreshAndShowSpinner];
    }
}


#pragma mark - Processing the User Notification Settings
- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    // Continue registration for push notifications
    [application registerForRemoteNotifications];
}


#pragma mark - Opening a URL Resource
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    // Connect app delegate to FBSDKCoreKit
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}


#pragma mark - Instance Methods
#pragma mark Public
- (void)processPendingLaunchRemoteNotification
{
    [self displayVideoView:self.remoteNotificationVideoHashKey withAnimation:YES];
    
    // Clear remote notification references that will be reconfigured on
    // next notification
    self.remoteNotificationVideoHashKey = nil;
    self.remoteNotificationType = GRVRemoteNotificationTypeDefault;
}

@end
