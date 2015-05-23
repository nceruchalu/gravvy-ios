//
//  GRVCameraViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/19/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraViewController.h"
#import "GRVCameraSlideUpView.h"
#import "GRVCameraSlideDownView.h"
#import "GRVConstants.h"

#pragma mark - Constants
// RGB #282828
#define kGRVCameraViewNavigationBarColor [UIColor colorWithRed:40.0/255.0 green:40.0/255.0 blue:40.0/255.0 alpha:1.0]

/**
 * Countdown container view border radius
 */
static const CGFloat kCountdownContainerCornerRadius = 5.0f;

@interface GRVCameraViewController ()

#pragma mark - Properties

#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIView *captureView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIView *actionsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressIndicatorWidthLayoutConstraint;

@property (weak, nonatomic) IBOutlet UIView *countdownBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
@property (weak, nonatomic) IBOutlet UIButton *shootButton;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;

@property (strong, nonatomic) GRVCameraSlideUpView *slideUpView;
@property (strong, nonatomic) GRVCameraSlideDownView *slideDownView;
@property (strong, nonatomic) UIBarButtonItem *closeButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;

#pragma mark Private
/**
 * The duration of the recording, in seconds.
 */
@property (nonatomic) NSTimeInterval recordingDuration;

@end

@implementation GRVCameraViewController

#pragma mark - Properties
- (void)setRecordingDuration:(NSTimeInterval)recordingDuration
{
    _recordingDuration = MIN(recordingDuration, kGRVClipMaximumDuration);;
    
    NSUInteger recordingTimeLeft = kGRVClipMaximumDuration - (NSUInteger)recordingDuration;
    self.countdownLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)recordingTimeLeft];
    
    self.progressIndicatorWidthLayoutConstraint.constant =   (self.view.frame.size.width *_recordingDuration/kGRVClipMaximumDuration);
    
    // Can only proceed to next page if recording duration has exceeded the
    // minimum
    self.doneButton.enabled = recordingDuration >= kGRVClipMinimumDuration;
}

#pragma mark - Class Methods
+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([GRVCameraViewController class])
                          bundle:[NSBundle mainBundle]];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    // Load all subviews and setup outlets before calling superclass' viewDidLoad
    [[[self class] nib] instantiateWithOwner:self options:nil];
    [super viewDidLoad];
    
    // Style navigation bar so this looks respectable
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barTintColor = kGRVCameraViewNavigationBarColor;
    
    // Set navigation bar items, close and next buttons
    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = self.closeButton;
    
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"NEXT" style:UIBarButtonItemStylePlain target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    // Configure countdown background view border radius
    self.countdownBackgroundView.layer.cornerRadius = kCountdownContainerCornerRadius;
    self.countdownBackgroundView.clipsToBounds = YES;
    
    // Configure sliding views
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    NSArray *slideUpNibViews = [bundle loadNibNamed:NSStringFromClass([GRVCameraSlideUpView class])
                                              owner:nil
                                            options:nil];
    self.slideUpView = [slideUpNibViews firstObject];
    
    NSArray *slideDownNibViews = [bundle loadNibNamed:NSStringFromClass([GRVCameraSlideDownView class])
                                              owner:nil
                                            options:nil];
    self.slideDownView = [slideDownNibViews firstObject];
    
    // Initialize recording duration to update outlets
    self.recordingDuration = 0.5f;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Prepare to animate the reveal of the capture view by showing the
    // separator of the sliding views
    self.separatorView.hidden = NO;
    
    // Hide action buttons and disable buttons not in action view till we are
    // done revealing the capture view
    self.actionsView.hidden = YES;
    self.shootButton.enabled = NO;
    
    [self.slideUpView addSlideToView:self.captureView
                         withOriginY:[self.slideUpView initialPositionWithView:self.captureView]];
    [self.slideDownView addSlideToView:self.captureView
                           withOriginY:[self.slideDownView initialPositionWithView:self.captureView]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Remove separator view as we start revealing capture view
    self.separatorView.hidden = YES;
    
    // Reveal capture view
    [GRVCameraSlideView hideSlideUpView:self.slideUpView
                          slideDownView:self.slideDownView
                                 atView:self.captureView
                             completion:^{
                                 // show action buttons and enable other buttons
                                 self.actionsView.hidden = NO;
                                 self.shootButton.enabled = YES;
                             }];
}


#pragma mark - Instance Methods


#pragma mark - Target/Action Methods
- (IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(UIBarButtonItem *)sender
{
    NSLog(@"tapped next");
}



@end
