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

#pragma mark - Constants
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

@interface GRVLandingViewController () <GRVPrivateTransitionContextDelegate>

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIButton *videosButton;
@property (weak, nonatomic) IBOutlet UIButton *activitiesButton;

/**
 * Horizontal position of center of button indicator in the navigation buttons
 * container
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *currentButtonIndicatorHorizontalCenterLayout;

#pragma mark Private
// ordering of navigation buttons matches that of view controllers
@property (copy, nonatomic) NSArray *navigationButtons;
// Percentage offset of current position of button indicator, with 0 implying
// videosButton, and 1 implying activitiesButton
@property (nonatomic) CGFloat buttonIndicatorOffset;

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
}

- (void)viewDidAppear:(BOOL)animated
{
    // To ensure button indicator is setup properly
    // Noticed invalid frame sizes in viewDidLoad when using simulator
    self.buttonIndicatorOffset = self.buttonIndicatorOffset;
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
}

#pragma mark Target/Action methods
- (IBAction)recordVideo:(UIButton *)sender
{
    [self startCameraController];
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
    
    [self performSegueWithIdentifier:kSegueIdentifierCreateVideo sender:self];
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
    }
}


@end
