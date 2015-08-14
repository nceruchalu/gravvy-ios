//
//  GRVRecorderManager.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/12/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVRecorderManager.h"
#import "GRVConstants.h"

@interface GRVRecorderManager ()

#pragma mark - Properties
/**
 * Already configured capture session once.
 */
@property (nonatomic) BOOL configuredCaptureSession;

@end

@implementation GRVRecorderManager

#pragma mark - Properties


#pragma mark - Class Methods
+ (instancetype)sharedManager
{
    static GRVRecorderManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

+ (SCRecorder *)recorderWithDelegate:(id<SCRecorderDelegate>)delegate
                      andPreviewView:(UIView *)previewView;
{
    // Setup recorder
    SCRecorder *recorder = [SCRecorder recorder];
    recorder.captureSessionPreset = AVCaptureSessionPreset640x480;
    recorder.maxRecordDuration = CMTimeMake(kGRVClipMaximumDuration, 1);
    recorder.delegate = delegate;
    recorder.autoSetVideoOrientation = YES;
    recorder.initializeSessionLazily = NO;
    
    // Setup recorder's video configuration object
    SCVideoConfiguration *video = recorder.videoConfiguration;
    // Whether the video should be enabled or not
    video.enabled = YES;
    // The bitrate of the video video
    video.bitrate = 1000000; // 1Mbit/s
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
    SCAudioConfiguration *audio = recorder.audioConfiguration;
    // Whether the audio should be enabled or not
    audio.enabled = YES;
    // the bitrate of the audio output is 128kbit/s
    audio.bitrate = 128000;
    // Number of audio output channels set to mono
    audio.channelsCount = 1;
    // The sample rate of the audio output should be the same as the input
    audio.sampleRate = 0;
    // The format of the audio output is AAC
    audio.format = kAudioFormatMPEG4AAC;
    
    // Setup preview view
    recorder.previewView = previewView;
    
    // Prepare recorder for use
    NSError *error;
    if (![recorder prepare:&error]) {
        NSLog(@"Prepare error: %@", error.localizedDescription);
    }
    
    return recorder;
}

+ (BOOL)authorized
{
    AVAuthorizationStatus videoAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    AVAuthorizationStatus audioAuthorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    return ((videoAuthorizationStatus == AVAuthorizationStatusAuthorized) &&
            (audioAuthorizationStatus == AVAuthorizationStatusAuthorized));
}


#pragma mark - Initializers
/*
 * ideally we would make the designated initializer of the superclass call
 *   the new designated initializer, but that doesn't make sense in this case.
 * if a programmer calls [GRVRecorderManager alloc] init], let them know the error
 *   of their ways.
 */
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[GRVRecorderManager sharedManager]"
                                 userInfo:nil];
    return nil;
}


// here is the real (secret) initializer
// this is the official designated initializer so call the designated
// initializer of the superclass
- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        // setup here
        _configuredCaptureSession = NO;
    }
    return self;
}


#pragma mark - Instance Methods
#pragma mark Public
- (void)configureCaptureSession
{
    if (!self.configuredCaptureSession) {
        dispatch_queue_t sessionQueue = dispatch_queue_create("GRVRecorderManager session queue", DISPATCH_QUEUE_SERIAL);
        dispatch_async(sessionQueue, ^{
            SCRecorder *recorder = [GRVRecorderManager recorderWithDelegate:nil andPreviewView:nil];
            [recorder startRunning];
            [recorder stopRunning];
        });
    }
    self.configuredCaptureSession = YES;
}



@end
