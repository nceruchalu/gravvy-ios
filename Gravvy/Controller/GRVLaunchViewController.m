//
//  GRVLaunchViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVLaunchViewController.h"
#import "GRVAccountManager.h"
#import "GRVHTTPManager.h"
#import "GRVModelManager.h"
#import "Reachability.h"
#import "GRVConstants.h"
#import "AppDelegate.h"

#pragma mark - Constants
// Segue Identifiers
static NSString *const kSegueIdentifierRegistrationVC = @"showRegistrationVC";
static NSString *const kSegueIdentifierVideosVC = @"showVideosVC";
static NSString *const kSegueIdentifierProfileSettingsVC = @"showProfileSettingsPostActivationVC";

// Actively attempting a connection
static NSString *const kConnectionStatusConnecting = @"Connecting ...";

// Connection failed because server is down
static NSString *const kConnectionStatusServerDown = @"Can't connect. Please try again later";

// Connection failed because device isn't connected to the internet
static NSString *const kConnectionStatusCantReach = @"Can't connect. Device offline.";


@interface GRVLaunchViewController ()

/**
 * BOOLean indicating if a connection attempt is already underway
 */
@property (nonatomic, getter=isConnecting) BOOL connecting;

/**
 * String representation of current connection status
 */
@property (weak, nonatomic) IBOutlet UILabel *connectionStatusLabel;

@property (strong, nonatomic) Reachability *internetReachability;

@end

@implementation GRVLaunchViewController

#pragma - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.connecting = NO;
    self.internetReachability = [Reachability reachabilityForInternetConnection];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Want this VC to look very much like the LaunchScreen
    self.navigationController.navigationBarHidden = YES;
    
    // Ideally would simply register for authentication notification, but
    // we also need the Managed Object Context to be ready and this is setup
    // after authentication so register for that
    if ([GRVModelManager sharedManager].profileConfiguredPostActivation) {
        // Perform the extra check for profile configured post activation to
        // ensure we don't perform the Managed Object Context Ready segue
        // while user is trying to configure profile
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextReady:)
                                                     name:kGRVMOCAvailableNotification
                                                   object:nil];
    }
    
    // Observe the kNetworkReachabilityChangedNotification. When that
    // notification is posted, the method reachabilityChanged will be called.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    [self.internetReachability startNotifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (kGRVReachabilityRequired) {
        // Check for internet reachability before attempting to connect
        [self updateInterfaceWithReachability:self.internetReachability];
    } else {
        // Attempt connecting regardless of internet connection availability.
        [self connect];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Want this VC to look very much like the LaunchScreen however
    // need the navigation bar on every other VC
    self.navigationController.navigationBarHidden = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // Remove notifications
    [self.internetReachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kReachabilityChangedNotification
                                                  object:nil];
    
    if ([GRVModelManager sharedManager].profileConfiguredPostActivation) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:kGRVMOCAvailableNotification
                                                      object:nil];
    }
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Attempt connecting to server and authenticating the. If successful then either
 * go to the landing page or prompt for registration.
 */
- (void)connect
{
    // If already connecting then tap out now.
    if (self.isConnecting) return;
    
    // Now about to connect
    self.connecting = YES;
    
    // silently attempt authenticating the user if possible
    [[GRVAccountManager sharedManager] authenticateWithSuccess:^{
        
        self.connecting = NO; // Done connecting
        
        
        if ([GRVModelManager sharedManager].profileConfiguredPostActivation) {
            // Proceed further after getting the Managed Object Context is ready
            // Notification. This is necessary incase there is any pending
            // remote notification.
            
        } else {
            // Still need to setup profile following activation
            [self performSegueWithIdentifier:kSegueIdentifierProfileSettingsVC sender:self];
            
            // TODO: So discard any pending remote notification;
            
        }
        
    } failure:^(NSUInteger statusCode) {
        self.connecting = NO; // Done connecting
        
        // a Client Error indicates user isnt registered so give user a chance to
        // fix this.
        if ([GRVHTTPManager statusCodeIs400ClientError:statusCode]) {
            [self performSegueWithIdentifier:kSegueIdentifierRegistrationVC sender:self];
        } else {
            // The most likely error at this point is being unable to connect to
            // the server so show a message to try again later.
            self.connectionStatusLabel.text = kConnectionStatusServerDown;
        }
        
    }];
}


/**
 * Update VC with provided reachability object. If network can be accessed
 * attempt a connection, else inform user of the unreachable network.
 */
- (void)updateInterfaceWithReachability:(Reachability *)reachability
{
    if (reachability == self.internetReachability) {
        NetworkStatus netStatus = [reachability currentReachabilityStatus];
        if (netStatus == NotReachable) {
            // If network cant be reached, inform user to fix this
            self.connectionStatusLabel.text = kConnectionStatusCantReach;
            
        } else {
            // if network can be reached, then attempt connecting
            self.connectionStatusLabel.text = kConnectionStatusConnecting;
            [self connect];
        }
    }
}


#pragma mark - Notification handlers
/**
 * Called by Reachability whenever status changes.
 */
- (void)reachabilityChanged:(NSNotification *)aNotification
{
    Reachability* curReach = [aNotification object];
    NSParameterAssert([curReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:curReach];
}

/**
 * Called whenever managed object context is ready
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    // If not in the middle of a connection and the user is now authenticated
    // go ahead and segue to the landing page.
    if (!self.connecting && [GRVAccountManager sharedManager].isAuthenticated) {
        // Go to landing page
        [self performSegueWithIdentifier:kSegueIdentifierVideosVC sender:self];
        
        // Work hand-in-hand with the app delegate to show any pending remote
        // remote notification.
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        if ([appDelegate.remoteNotificationVideoHashKey length]) {
            [appDelegate processPendingLaunchRemoteNotification];
        }
    }
}

@end
