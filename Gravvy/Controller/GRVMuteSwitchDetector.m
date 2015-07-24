//
//  GRVMuteSwitchDetector.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/23/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
//  Heavily based on http://sharkfood.com/content/Developers/content/Sound%20Switch/

#import "GRVMuteSwitchDetector.h"
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

#pragma mark - Constants
/**
 * Interval betten checks of silent switch state
 */
static const NSTimeInterval kMuteCheckDelay = 1.0f;

/**
 * Minimum play time for the sound file. If the sound is played for less time
 * then the silent switch is on and the phone is muted
 */
static const NSTimeInterval kDetectorSoundMinimumDuration = 0.2f;

/**
 * Silent Switch detection sound
 */
static NSString *const kDetectorSoundFile = @"mute";
static NSString *const kDetectorSoundFileExtension = @"caf";

@interface GRVMuteSwitchDetector ()

#pragma mark - Properties
#pragma mark Public
// Public properties are readwrite internally
@property (nonatomic, readwrite) BOOL muted;

#pragma mark Private
/**
 * Silent sound used for detecting the silent switch state
 */
@property (nonatomic) CFURLRef soundFileURLRef;
@property (nonatomic) SystemSoundID soundFileObject;

/**
 * Set to YES after the block has been set or during init.
 * Otherwise the block is called only when the switch value actually changes
 */
@property (nonatomic) BOOL forceHandlerCall;

/**
 * Is the detector paused?
 */
@property (nonatomic) BOOL paused;

/**
 * Is the detector currently playing a sound? 
 * Used when returning from the background (if went to background and foreground 
 * really quickly)
 */
@property (nonatomic) BOOL playing;


/**
 * Find out how fast the completion handler is called by tracking the datetime at
 * at which its played
 */
@property (strong, nonatomic) NSDate *playStartTime;

#pragma mark - Instance Methods
/**
 * Complete mute check. This should be called by the completion handler
 */
- (void)completeMuteCheck;

@end

#pragma mark - C Functions
/**
 * Function to be executed asynchronously when a specific system sound has
 * finished playing.
 *
 * @param ssID          The system sound that has finished playing.
 * @param clientData    Application data that you specified when registering
 *      the callback function.
 */
void MuteSwitchDetectorSoundCompletionProc(SystemSoundID ssID, void *clientData)
{
    GRVMuteSwitchDetector *detector = (__bridge GRVMuteSwitchDetector *)clientData;
    [detector completeMuteCheck];
}


@implementation GRVMuteSwitchDetector

#pragma mark - Properties
- (void)setDetectionHandler:(GRVMuteSwitchDetectorHandler)detectionHandler
{
    _detectionHandler = [detectionHandler copy];
    self.forceHandlerCall = YES;
}

- (void)setSuspended:(BOOL)suspended
{
    BOOL changedSuspended = _suspended != suspended;
    _suspended = suspended;
    if (changedSuspended) {
        self.forceHandlerCall = YES;
        if (!_suspended) {
            [self startRunning];
        }
    }
}

#pragma mark - Class Methods

// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedDetector
{
    static GRVMuteSwitchDetector *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

#pragma mark - Initializers
/*
 * ideally we would make the designated initializer of the superclass call
 * the new designated initializer, but that doesn't make sense in this case.
 * if a programmer calls [GRVMuteSwitchDetector alloc] init], let them know the
 * error of their ways.
 */
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[GRVMuteSwitchDetector sharedDetector]"
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
        // Setup object
        
        // Setup Detect source sound file
        // Create the URL for the source audio file.
        NSURL *detectorSound = [[NSBundle mainBundle] URLForResource:kDetectorSoundFile
                                                    withExtension:kDetectorSoundFileExtension];
        
        // Store the URL as a CFURLRef instance
        self.soundFileURLRef = (CFURLRef)CFBridgingRetain(detectorSound);
        
        // Create a system sound object representing the sound file.
        if (AudioServicesCreateSystemSoundID(self.soundFileURLRef, &_soundFileObject) == kAudioServicesNoError) {
            
            // Register a callback function to be called when the detector
            // sound finishes playing. Be sure to avoid capture self in callback
            GRVMuteSwitchDetector * __weak weakSelf = self;
            AudioServicesAddSystemSoundCompletion(self.soundFileObject, CFRunLoopGetMain(), kCFRunLoopDefaultMode, MuteSwitchDetectorSoundCompletionProc, (__bridge void *)(weakSelf));
            
            // Ensure that for the detector sound, the System Sound server
            // respects the user setting in the Sound Effects preference and is
            // silent when the user turns off sound effects.
            // Do this by kAudioServicesPropertyIsUISound to 1 for sound.
            UInt32 respectSoundEffectsPreference = 1;
            AudioServicesSetProperty(kAudioServicesPropertyIsUISound, sizeof(_soundFileObject), &_soundFileObject, sizeof(respectSoundEffectsPreference), &respectSoundEffectsPreference);
            
            // Force a call of the handler on the initial run
            self.forceHandlerCall = YES;
            
            self.playing = NO;
            self.paused = NO;
            self.suspended = NO;
            
            // Start by assuming initially muted
            self.muted = YES;
            
            // Finally start mute switch state check after some initial delay
            // to ensure we don't pickup an invalid initial state
            [self performSelector:@selector(startMuteCheck) withObject:nil afterDelay:1.0f];
            
        } else {
            self.soundFileObject = 0;
        }
        
        // Register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - Dealloc
- (void)dealloc
{
    // Release memory for the detector sound
    AudioServicesDisposeSystemSoundID(_soundFileObject);
    if (self.soundFileURLRef) {
        CFRelease(_soundFileURLRef);
        self.soundFileURLRef = NULL;
    }
    
    // Remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}


#pragma mark - Instance Methods
#pragma mark Public
- (void)startRunning
{
    self.paused = NO;
    if (!self.playing) {
        [self scheduleMuteCheck];
    }
}

#pragma mark Private
/**
 * Schedule a call to start the mute check
 */
- (void)scheduleMuteCheck
{
    // First cancel any previously scheduled calls
     [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startMuteCheck) object:nil];
    [self performSelector:@selector(startMuteCheck) withObject:nil afterDelay:kMuteCheckDelay];
}

/**
 * Start mute check by playing detector sound
 */
- (void)startMuteCheck
{
    if (!self.paused && !self.suspended) {
        self.playStartTime = [NSDate date];
        self.playing = YES;
        AudioServicesPlaySystemSound(self.soundFileObject);
    }
}

/**
 * Complete mute check. This should be called by the completion handler
 */
- (void)completeMuteCheck
{
    self.playing = NO;
    NSTimeInterval elapsedDuration = [[NSDate date] timeIntervalSinceDate:self.playStartTime];
    BOOL muted = elapsedDuration < kDetectorSoundMinimumDuration;
    if (muted != self.muted || self.forceHandlerCall) {
        self.forceHandlerCall = NO;
        self.muted = muted;
        if (self.detectionHandler) self.detectionHandler(muted);
    }
    [self scheduleMuteCheck];
}


#pragma mark - Notification Observer Methods
/**
 * App entering background, so pause
 */
- (void)appDidEnterBackground
{
    self.paused = YES;
}

/**
 * App entering foreground, so resume if not currently playing
 */
- (void)appWillEnterForeground
{
    [self startRunning];
}



@end
