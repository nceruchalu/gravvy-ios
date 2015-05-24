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
#import "SCRecorder.h"

#pragma mark - Constants
// RGB #282828
#define kGRVCameraViewNavigationBarColor [UIColor colorWithRed:40.0/255.0 green:40.0/255.0 blue:40.0/255.0 alpha:1.0]

/**
 * Countdown container view border radius
 */
static const CGFloat kCountdownContainerCornerRadius = 5.0f;

@interface GRVCameraViewController () <SCRecorderDelegate>

#pragma mark - Properties

#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIView *previewView;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet UIView *actionsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *minimumProgressIndicatorWidthLayoutConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *progressIndicatorWidthLayoutConstraint;

@property (weak, nonatomic) IBOutlet UIView *countdownBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *retakeButton;
@property (weak, nonatomic) IBOutlet UIButton *shootButton;

@property (strong, nonatomic) GRVCameraSlideUpView *slideUpView;
@property (strong, nonatomic) GRVCameraSlideDownView *slideDownView;
@property (strong, nonatomic) UIBarButtonItem *closeButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;

#pragma mark Private
/**
 * The duration of the recording, in seconds.
 */
@property (nonatomic) NSTimeInterval recordingDuration;

/**
 * Recorder and associated session
 */
@property (strong, nonatomic) SCRecorder *recorder;
@property (strong, nonatomic) SCRecordSession *recordSession;

@end


@implementation GRVCameraViewController

#pragma mark - Properties
- (void)setRecordingDuration:(NSTimeInterval)recordingDuration
{
    _recordingDuration = MIN(recordingDuration, kGRVClipMaximumDuration);;
    
    NSUInteger recordingTimeLeft = kGRVClipMaximumDuration - (NSUInteger)recordingDuration;
    self.countdownLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)recordingTimeLeft];
    
    self.progressIndicatorWidthLayoutConstraint.constant = self.view.frame.size.width *_recordingDuration/kGRVClipMaximumDuration;
    
    // Can only proceed to next page if recording duration has exceeded the
    // minimum
    self.doneButton.enabled = _recordingDuration >= kGRVClipMinimumDuration;
    
    // Can only retake recording if recording duration is > 0
    self.retakeButton.hidden = recordingDuration <= 0.0f;
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
    
    // Set navigation bar items, close and done buttons
    self.closeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancel)];
    self.navigationItem.leftBarButtonItem = self.closeButton;
    
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:@"NEXT" style:UIBarButtonItemStylePlain target:self action:@selector(done:)];
    self.navigationItem.rightBarButtonItem = self.doneButton;
    
    // Configure countdown background view border radius
    self.countdownBackgroundView.layer.cornerRadius = kCountdownContainerCornerRadius;
    self.countdownBackgroundView.clipsToBounds = YES;
    
    // Configure sliding views that are used to reveal the preview view
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    NSArray *slideUpNibViews = [bundle loadNibNamed:NSStringFromClass([GRVCameraSlideUpView class])
                                              owner:nil
                                            options:nil];
    self.slideUpView = [slideUpNibViews firstObject];
    
    NSArray *slideDownNibViews = [bundle loadNibNamed:NSStringFromClass([GRVCameraSlideDownView class])
                                              owner:nil
                                            options:nil];
    self.slideDownView = [slideDownNibViews firstObject];
    
    // Set marker for minimum recording duration
    self.minimumProgressIndicatorWidthLayoutConstraint.constant = self.view.frame.size.width * kGRVClipMinimumDuration/kGRVClipMaximumDuration;
    
    // Initialize recording duration to update outlets
    self.recordingDuration = 0.0f;
    
    // Setup recorder
    self.recorder = [SCRecorder recorder];
    self.recorder.captureSessionPreset = AVCaptureSessionPreset640x480;
    self.recorder.maxRecordDuration = CMTimeMake(kGRVClipMaximumDuration, 1);
    self.recorder.delegate = self;
    self.recorder.autoSetVideoOrientation = YES;
    self.recorder.initializeSessionLazily = NO;
    
    // Setup recorder's video configuration object
    SCVideoConfiguration *video = self.recorder.videoConfiguration;
    // Whether the video should be enabled or not
    video.enabled = YES;
    // The bitrate of the video video
    video.bitrate = 2000000; // 2Mbit/s
    // Size of the video output
    video.size = CGSizeMake(kGRVVideoSizeWidth, kGRVVideoSizeHeight);
    // Scaling if the output aspect ratio is different than the output one
    video.scalingMode = AVVideoScalingModeResizeAspectFill;
    // The timescale ratio to use. Higher than 1 makes a slow motion,
    // between 0 and 1 makes a timelapse effect
    video.timeScale = 1;
    // Whether the output video size should be infered so it creates a square video
    video.sizeAsSquare = YES;
    
    // Get the audio configuration object
    SCAudioConfiguration *audio = self.recorder.audioConfiguration;
    
    // Whether the audio should be enabled or not
    audio.enabled = YES;
    // the bitrate of the audio output is 128kbit/s
    audio.bitrate = 128000;
    // Number of audio output channels
    audio.channelsCount = 2;
    // The sample rate of the audio output should be the same as the input
    audio.sampleRate = 0;
    // The format of the audio output is AAC
    audio.format = kAudioFormatMPEG4AAC;
    
    // Setup preview view
    self.recorder.previewView = self.previewView;
    
    // Prepare recorder for use
    NSError *error;
    if (![self.recorder prepare:&error]) {
        NSLog(@"Prepare error: %@", error.localizedDescription);
    }
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
    
    [self.slideUpView addSlideToView:self.previewView
                         withOriginY:[self.slideUpView initialPositionWithView:self.previewView]];
    [self.slideDownView addSlideToView:self.previewView
                           withOriginY:[self.slideDownView initialPositionWithView:self.previewView]];
    
    // Prepare record session
    [self prepareSession];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Remove separator view as we start revealing capture view
    self.separatorView.hidden = YES;
    
    // Reveal capture view
    [GRVCameraSlideView hideSlideUpView:self.slideUpView
                          slideDownView:self.slideDownView
                                 atView:self.previewView
                             completion:^{
                                 // show action buttons and enable other buttons
                                 self.actionsView.hidden = NO;
                                 self.shootButton.enabled = YES;
                             }];
    
    [self.recorder startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.recorder stopRunning];
}


#pragma mark - Instance Methods
#pragma mark Abstract
- (void)processCompletedSession:(SCRecordSession *)recordSession
{
    // Abstract
}

#pragma mark Private
/**
 * Prepare recording session if this hasn't already been done
 */
- (void)prepareSession
{
    if (!self.recorder.session) {
        self.recordSession = [SCRecordSession recordSession];
        self.recordSession.fileType = AVFileTypeMPEG4;
        
        self.recorder.session = self.recordSession;
    }
    
    [self updateRecordingDuration];
}

/**
 * Recording is done, process and possibly upload this session
 */
- (void)processSession:(SCRecordSession *)recordSession
{
    self.recordSession = recordSession;
    [self processCompletedSession:recordSession];
}


/**
 * Update recording duration from the recording's session
 */
- (void)updateRecordingDuration
{
    if (self.recorder.session) {
        self.recordingDuration = CMTimeGetSeconds(self.recorder.session.duration);
    } else {
        self.recordingDuration = 0;
    }
}

#pragma mark - Target/Action Methods
- (IBAction)flipCamera:(UIButton *)sender
{
    [self.recorder switchCaptureDevices];
    
    // Flash goes off when camera device is switched
    //self.recorder.flashMode = SCFlashModeOff;
    //[self.flashButton setImage:[UIImage imageNamed:@"flashOff"] forState:UIControlStateNormal];
}

- (IBAction)toggleFlash:(UIButton *)sender
{
    // Don't bother if the capture device doesn't have flash
    if (!self.recorder.deviceHasFlash) {
        return;
    }
    
    NSString *flashImage = nil;
    switch (self.recorder.flashMode) {
        case SCFlashModeOff:
            flashImage = @"flashOn";
            self.recorder.flashMode = SCFlashModeLight;
            break;
        case SCFlashModeLight:
            flashImage = @"flashOff";
            self.recorder.flashMode = SCFlashModeOff;
            break;
        default:
            break;
    }
    [self.flashButton setImage:[UIImage imageNamed:flashImage] forState:UIControlStateNormal];
}

/**
 * Started holding down shoot button
 */
- (IBAction)startRecording:(UIButton *)sender
{
    // Begin appending video/audio buffers to the session
    [self.recorder record];
}

/**
 * Let go of shoot button
 */
- (IBAction)pauseRecording:(UIButton *)sender
{
    // Stop appending video/audio buffers to the session
    [self.recorder pause];
}

/**
 * Retake button tapped
 */
- (IBAction)retakeRecording:(UIButton *)sender
{
    SCRecordSession *recordSession = self.recorder.session;
    if (recordSession) {
        self.recorder.session = nil;
        [recordSession cancelSession:nil];
    }
    
    [self prepareSession];
}


- (IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(UIBarButtonItem *)sender
{
    [self.recorder pause:^{
        [self processSession:self.recorder.session];
    }];
}


#pragma mark - SCRecorderDelegate
- (void)recorder:(SCRecorder *)recorder didInitializeAudioInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    if (error) {
        NSLog(@"Failed to initialize audio in record session: %@", error.localizedDescription);
    } else {
        NSLog(@"Initialized audio in record session");
    }
}

- (void)recorder:(SCRecorder *)recorder didInitializeVideoInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    if (error) {
        NSLog(@"Failed to initialize video in record session: %@", error.localizedDescription);
    } else {
        NSLog(@"Initialized video in record session");
    }
}

- (void)recorder:(SCRecorder *)recorder didBeginSegmentInSession:(SCRecordSession *)recordSession error:(NSError *)error {
    NSLog(@"Began record segment: %@", error);
}

- (void)recorder:(SCRecorder *)recorder didCompleteSegment:(SCRecordSessionSegment *)segment inSession:(SCRecordSession *)recordSession error:(NSError *)error {
    NSLog(@"Completed record segment at %@: %@ (frameRate: %f)", segment.url, error, segment.frameRate);
}

- (void)recorder:(SCRecorder *)recorder didAppendVideoSampleBufferInSession:(SCRecordSession *)session
{
    [self updateRecordingDuration];
}

- (void)recorder:(SCRecorder *)recorder didCompleteSession:(SCRecordSession *)recordSession
{
    NSLog(@"didCompleteSession:");
    [self processSession:recordSession];
}

@end
