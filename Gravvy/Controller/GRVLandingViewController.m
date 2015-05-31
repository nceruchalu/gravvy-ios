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
static NSString *const kStoryboardIdentifierUpdates     = @"Updates";

@interface GRVLandingViewController ()

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIButton *videosButton;
@property (weak, nonatomic) IBOutlet UIView *videosButtonIndicator;
@property (weak, nonatomic) IBOutlet UIButton *updatesButton;
@property (weak, nonatomic) IBOutlet UIView *updatesButtonIndicator;

#pragma mark Outlets
// ordering of navigation buttons matches that of view controllers
@property (copy, nonatomic) NSArray *navigationButtons;

@end

@implementation GRVLandingViewController

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
    UIViewController *updatesVC = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:kStoryboardIdentifierUpdates];
    
    // ordering of the view controllers must match ordering of self.navigationButtons
    self.viewControllers = @[videosVC, updatesVC];

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
    self.navigationButtons = @[self.videosButton, self.updatesButton];
    
    // Setup button indicators
    self.videosButtonIndicator.backgroundColor = kGRVThemeColor;
    self.updatesButtonIndicator.backgroundColor = [UIColor clearColor];
    
    NSUInteger idx = 0;
    for (idx=0; idx < [self.navigationButtons count]; idx++) {
        UIButton *navigationButton = self.navigationButtons[idx];
        
        // Track button index in the tag attribute
        navigationButton.tag = idx;
        
        // Set up button target/action method
        [navigationButton addTarget:self action:@selector(navigationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Set all but the first button to an inacitve tint color
        UIColor *buttonColor = (idx == 0) ? kGRVThemeColor : kInactiveTintColor;
        [navigationButton setTitleColor:buttonColor forState:UIControlStateNormal];
    }
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.hidesBackButton = YES;
}


#pragma mark - Instance Methods
#pragma mark Concrete
/**
 * Update the selected navigation button, based on the selectedIndex @property,
 * and deselect all other navigation buttons.
 */
- (void)updateNavigationButtonSelection
{
    [self.navigationButtons enumerateObjectsUsingBlock:^(UIButton *navigationButton, NSUInteger idx, BOOL *stop) {
       BOOL navigationButtonSelected = self.viewControllers[idx] == self.selectedViewController;
        
        UIColor *buttonColor = navigationButtonSelected ? kGRVThemeColor : kInactiveTintColor;
        navigationButton.tintColor = buttonColor;
        [navigationButton setTitleColor:buttonColor forState:UIControlStateNormal];
        
        // Setup button indicators
        UIView *buttonIndicator = nil;
        if (navigationButton == self.videosButton) {
            buttonIndicator = self.videosButtonIndicator;
        } else if (navigationButton == self.updatesButton){
            buttonIndicator = self.updatesButtonIndicator;
        }
        UIColor *buttonIndicatorColor = navigationButtonSelected ? kGRVThemeColor : [UIColor clearColor];
        buttonIndicator.backgroundColor = buttonIndicatorColor;
    }];
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
