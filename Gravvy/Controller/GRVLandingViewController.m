//
//  GRVLandingViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVLandingViewController.h"
#import "GRVCreateVideoContactPickerVC.h"
#import "GRVConstants.h"
#import "GRVPanGestureInteractiveTransition.h"
#import "GRVPrivateTransitionContextDelegate.h"
#import "GRVExtendedCoreDataTableViewController.h"
#import "MBProgressHUD.h"
#import "GRVVideosCDTVC.h"
#import "GRVBadgeView.h"
#import "GRVModelManager.h"
#import "AMPopTip.h"
//#import "UIViewController+ScrollingNavbar.h"

#pragma mark - Constants

/**
 * Comment this out to use the ScrollingNavBar
 */
//#define GRV_USE_SCROLLING_NAVBAR


/**
 * Segue identifier for starting video creation workflow
 */
static NSString *const kSegueIdentifierCreateVideo = @"showCreateVideoCameraController";

/**
 * Inactive button tint color: #404040
 */
#define kInactiveTintColor [UIColor colorWithRed:64.0/255.0 green:64.0/255.0 blue:64.0/255.0 alpha:1.0]

/**
 * Storyboard name
 */
static NSString *const kStoryboardName                  = @"Main";

/**
 * Child view controllers' storyboard identifiers
 */
static NSString *const kStoryboardIdentifierVideos      = @"Videos";
static NSString *const kStoryboardIdentifierActivities  = @"Activities";


#ifdef GRV_USE_SCROLLING_NAVBAR
// scrolling nav bar delay
static CGFloat const scrollingNavBarDelay = 480.0f;
#endif

@interface GRVLandingViewController () <GRVPrivateTransitionContextDelegate,
                                        NSFetchedResultsControllerDelegate>

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIButton *videosButton;
@property (weak, nonatomic) IBOutlet UIButton *activitiesButton;
@property (weak, nonatomic) IBOutlet GRVBadgeView *badgeView;
@property (weak, nonatomic) IBOutlet UIButton *createVideoButton;

/**
 * Horizontal position of center of button indicator in the navigation buttons
 * container
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *currentButtonIndicatorHorizontalCenterLayout;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topLayoutConstraint;

#pragma mark Private
// ordering of navigation buttons matches that of view controllers
@property (copy, nonatomic) NSArray *navigationButtons;
// Percentage offset of current position of button indicator, with 0 implying
// videosButton, and 1 implying activitiesButton
@property (nonatomic) CGFloat buttonIndicatorOffset;

@property (strong, nonatomic) MBProgressHUD *successProgressHUD;

@property (strong, nonatomic) AMPopTip *popTip;


#pragma mark Notifications Badge
@property (nonatomic) NSUInteger badgeValue;

/**
 * The controller (this class) fetches nothing if this is not set
 */
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

/**
 * Handle to the database
 */
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation GRVLandingViewController

#pragma mark - Properties
- (void)setButtonIndicatorOffset:(CGFloat)buttonIndicatorOffset
{
    _buttonIndicatorOffset = buttonIndicatorOffset;
    
    CGFloat videosButtonCenter = self.videosButton.frame.origin.x + self.videosButton.frame.size.width/2.0f;
    CGFloat activitiesButtonCenter = self.activitiesButton.frame.origin.x + self.activitiesButton.frame.size.width/2.0f;
    
    self.currentButtonIndicatorHorizontalCenterLayout.constant = (activitiesButtonCenter - videosButtonCenter)*buttonIndicatorOffset + videosButtonCenter;
    
    // Emphasize appropriate button based on button indicator
    NSUInteger emphasizedButtonIndex = 0;
    if (_buttonIndicatorOffset == 0.0) {
        emphasizedButtonIndex = 0;
        
    } else if (_buttonIndicatorOffset == 1.0) {
        emphasizedButtonIndex = 1;
    
    } else {
        // Start by assuming emphasized button won't change
        emphasizedButtonIndex = self.selectedIndex;
        
        // Determine what the max change has to be for the current button to change
        CGFloat offsetDelta = kGRVPanGestureInteractiveMinimumPercentComplete * [self.navigationButtons count];
        BOOL goingRight = (self.selectedIndex == 0);
        if (goingRight && _buttonIndicatorOffset > offsetDelta) {
            emphasizedButtonIndex = 1;
        } else if (!goingRight && (1 - _buttonIndicatorOffset) > offsetDelta) {
            emphasizedButtonIndex = 0;
        }
    }
    
    UIButton *emphasizedButton = self.navigationButtons[emphasizedButtonIndex];
    UIButton *mutedButton = self.navigationButtons[1-emphasizedButtonIndex];
    [emphasizedButton setTitleColor:kGRVThemeColor forState:UIControlStateNormal];
    [mutedButton setTitleColor:kInactiveTintColor forState:UIControlStateNormal];
}

- (MBProgressHUD *)successProgressHUD
{
    if (!_successProgressHUD) {
        // Lazy instantiation
        _successProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:_successProgressHUD];
        
        _successProgressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
        // Set custom view mode
        _successProgressHUD.mode = MBProgressHUDModeCustomView;
        
        _successProgressHUD.minSize = CGSizeMake(120, 120);
        _successProgressHUD.minShowTime = 1;
    }
    return _successProgressHUD;
}

- (GRVVideosCDTVC *)videosVC
{
    GRVVideosCDTVC *vc = nil;
    if ([self.viewControllers count]) {
       vc = [self.viewControllers objectAtIndex:0];
    }
    return vc;
}

- (void)setBadgeValue:(NSUInteger)badgeValue
{
    _badgeValue = badgeValue;
    self.badgeView.badgeValue = badgeValue;
    
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    [self setupFetchedResultsController];
}

// setup new fetchResultsController property
//   set delegate (as self)
//   call performFetch if we got a new fetchResultsController
//      or clear badge view if this was removed
- (void)setFetchedResultsController:(NSFetchedResultsController *)newfrc
{
    // only bother changing the fetchedResultsController if receiving a new one.
    NSFetchedResultsController *oldfrc = _fetchedResultsController;
    if (newfrc != oldfrc) {
        _fetchedResultsController = newfrc;
        newfrc.delegate = self;
        
        // either fetch new data or clear out badge view.
        if (newfrc) {
            [self performFetch];
        } else {
            self.badgeValue = 0;
        }
    }
}

- (AMPopTip *)popTip
{
    if (!_popTip) {
        // lazy instantiation
        _popTip = [AMPopTip popTip];
        _popTip.shouldDismissOnTap = YES;
    }
    return _popTip;
}


#pragma mark - Initialization
#pragma mark Concrete Helpers
/**
 * Set up the `GRVContainerViewController` object with child controllers by
 * instantiating the viewControllers @property
 *
 * @note This method is called in the initialization method so it's required.
 */
- (void)setupViewControllers
{
    // First grab storyboard to grab view controllers
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardName bundle:nil];
    
    // Instantiate and initialize view controllers
    UIViewController *videosVC = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:kStoryboardIdentifierVideos];
    UIViewController *activitiesVC = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:kStoryboardIdentifierActivities];
    
    // ordering of the view controllers must match ordering of self.navigationButtons
    self.viewControllers = @[videosVC, activitiesVC];

}

/**
 * Setup a collection of navigation buttons to:
 *   - Use same ordering as viewControllers
 *   - Track button index in the button's tag property
 *   - Set up button target/action method to call the navigationButtonTapped:
 *     method
 *
 * @note This method is called in viewDidLoad and is required for a consistent
 *      user interface.
 */
- (void)setupNavigationButtons
{
    // Ordering of the navigation buttons must match ordering of self.viewControllers
    self.navigationButtons = @[self.videosButton, self.activitiesButton];
    
    NSUInteger idx = 0;
    for (idx=0; idx < [self.navigationButtons count]; idx++) {
        UIButton *navigationButton = self.navigationButtons[idx];
        
        // Track button index in the tag attribute
        navigationButton.tag = idx;
        
        // Set up button target/action method
        [navigationButton addTarget:self action:@selector(navigationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // Setup button indicator
    self.buttonIndicatorOffset = 0.0;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
    self.buttonIndicatorOffset = 0;
    
    self.badgeValue = 0;
    
#ifdef GRV_USE_SCROLLING_NAVBAR
    // Setup Scrollable UINavigationBar that follows the scrolling of a UIScrollView
    self.navigationController.navigationBar.translucent = NO;
    [self followScrollView:((GRVExtendedCoreDataTableViewController *)self.selectedViewController).tableView
        usingTopConstraint:self.topLayoutConstraint withDelay:scrollingNavBarDelay];
    self.navigationController.navigationBar.translucent = YES;
    [self setShouldScrollWhenContentFits:YES];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // setup the managedObjectContext @property
    self.managedObjectContext = [GRVModelManager sharedManager].managedObjectContext;
    
    // register observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextReady:)
                                                 name:kGRVMOCAvailableNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    // To ensure button indicator is setup properly
    // Noticed invalid frame sizes in viewDidLoad when using simulator
    self.buttonIndicatorOffset = self.buttonIndicatorOffset;
    
    // Show video creation poptip
    if (![GRVModelManager sharedManager].acknowledgedVideoCreationTip) {
        [self.popTip showText:@"Tap button to create video"
                    direction:AMPopTipDirectionLeft
                     maxWidth:100.0f
                       inView:self.view
                    fromFrame:self.createVideoButton.frame
                     duration:kGRVPopTipMaximumDuration];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
#ifdef GRV_USE_SCROLLING_NAVBAR
    [self showNavBarAnimated:NO];
#endif
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kGRVMOCAvailableNotification
                                                  object:nil];
}



- (void)dealloc
{
#ifdef GRV_USE_SCROLLING_NAVBAR
    [self stopFollowingScrollView];
#endif
    
    [self.popTip hide];
    self.popTip = nil;
}



#pragma mark - Instance Methods
#pragma mark Concrete
/**
 * Update the selected navigation button, based on the selectedIndex @property,
 * and deselect all other navigation buttons.
 */
- (void)updateNavigationButtonSelection
{
    self.buttonIndicatorOffset = (CGFloat)self.selectedIndex;
    
    // Switch the scroll view being followed as this is only called when
    // switching tabs
#ifdef GRV_USE_SCROLLING_NAVBAR
    [self switchFollowingScrollView];
#endif
}

#ifdef GRV_USE_SCROLLING_NAVBAR
- (void)switchFollowingScrollView {
    [self showNavBarAnimated:YES];
    [self stopFollowingScrollView];
    self.navigationController.navigationBar.translucent = NO;
    [self followScrollView:((GRVExtendedCoreDataTableViewController *)self.selectedViewController).tableView
        usingTopConstraint:self.topLayoutConstraint withDelay:scrollingNavBarDelay];
    self.navigationController.navigationBar.translucent = YES;
}
#endif

#pragma mark Action Progress
- (void)showProgressHUDSuccessMessage:(NSString *)message
{
    self.successProgressHUD.labelText = message;
    [self.successProgressHUD show:YES];
    [self.successProgressHUD hide:YES afterDelay:1.5];
}


#pragma mark - Target/Action methods
- (IBAction)recordVideo:(UIButton *)sender
{
    [self startCameraController];
    if (![GRVModelManager sharedManager].acknowledgedVideoCreationTip) {
        [GRVModelManager sharedManager].acknowledgedVideoCreationTip = YES;
        [self.popTip hide];
    }
}

#pragma mark Video Recording Helpers

/**
 * Start camera controller for recording a video
 */
- (void)startCameraController
{
    // quit if camera is not available for recording videos
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    // Stop player before continuing
    [self.videosVC stop];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // Give the avplayer cleanup some time to occur before presenting camera VC
        [self performSegueWithIdentifier:kSegueIdentifierCreateVideo sender:self];
    });
}


#pragma mark - GRVPrivateTransitionContextDelegate
- (void)transitionContext:(GRVPrivateTransitionContext *)transitionContext didUpdateInteractiveTransition:(CGFloat)percentComplete goingRight:(BOOL)goingRight
{
    // Scale the percent complete to a 0 to 1 scale
    CGFloat scaledPercentComplete = percentComplete * [self.navigationButtons count];
    if (!goingRight) {
        scaledPercentComplete = 1 - scaledPercentComplete;
    }
    self.buttonIndicatorOffset = scaledPercentComplete;
}

- (void)transitionContext:(GRVPrivateTransitionContext *)transitionContext didFinishInteractiveTransitionGoingRight:(BOOL)goingRight
{
    self.buttonIndicatorOffset = goingRight ? 1.0 : 0.0;
}

- (void)transitionContext:(GRVPrivateTransitionContext *)transitionContext didCancelInteractiveTransitionGoingRight:(BOOL)goingRight
{
    self.buttonIndicatorOffset = goingRight ? 0.0 : 1.0;
}


#pragma mark - Navigation
#pragma mark Modal Unwinding
/**
 * Created a video. Nothing to do here really as we use an NSFetchedResultsController
 * that will pick up any new event
 */
- (IBAction)createdVideo:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[GRVCreateVideoContactPickerVC class]]) {
        //GRVCreateVideoContactPickerVC *contactPickerVC = (GRVCreateVideoContactPickerVC *)segue.sourceViewController;

        // Updated video is now at the top of the video TVC, so scroll to top
        [self.videosVC.tableView setContentOffset:CGPointMake(0.0, 0.0 - self.videosVC.tableView.contentInset.top)
                                         animated:YES];
        
        
        [self showProgressHUDSuccessMessage:@"Created Video"];
    }
}


#pragma mark - Fetching
// perform fetch on fetchedResultsController @property
- (void)performFetch
{
    if (self.fetchedResultsController) {
        NSError *error;
        [self.fetchedResultsController performFetch:&error];
    }
}

- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVVideo"];
        // fetch all new videos or videos with unseen notifications
        request.predicate = [NSPredicate predicateWithFormat:@"(unseenClipsCount > 0) OR (unseenLikesCount > 0) OR (membership <= %d)", GRVVideoMembershipInvited];
        
        // Sort videos because an instance of NSFetchedResultsController requires
        // a fetch request with sort descriptors
        NSSortDescriptor *orderSort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:YES];
        request.sortDescriptors = @[orderSort];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
}

#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // Get number of videos with notifications
    self.badgeValue = [self.fetchedResultsController.fetchedObjects count];
}


#pragma mark - Notification Observer Methods
/**
 * ManagedObjectContext now available from EVTModelManager so update local copy
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    self.managedObjectContext = [GRVModelManager sharedManager].managedObjectContext;
}


@end
