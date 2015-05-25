//
//  GRVCameraReviewViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/24/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraReviewViewController.h"
#import "SCRecordSession.h"
#import "GRVPlayerView.h"

#pragma mark - Constants
// Define these constant for the key-value observation context.
static const NSString *PlayerItemStatusContext;
static const NSString *PlayerRateContext;

@interface GRVCameraReviewViewController ()

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet GRVPlayerView *playerView;

#pragma mark Private
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;

/**
 * Is player now ready to play?
 */
@property (nonatomic) BOOL playerReadyToPlay;

@end

@implementation GRVCameraReviewViewController
#pragma mark - Properties
- (void)setPlayerReadyToPlay:(BOOL)playerReadyToPlay
{
    _playerReadyToPlay = playerReadyToPlay;
    
    // If player started, and an mp4 has been extracted then this recording
    // has been validated
    if (_playerReadyToPlay && self.mp4) {
        [self recordingValidated];
    }
}

- (void)setMp4:(NSData *)mp4
{
    _mp4 = mp4;
    
    // If player started, and an mp4 has been extracted then this recording
    // has been validated
    if (self.playerReadyToPlay && _mp4) {
        [self recordingValidated];
    }
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.playerReadyToPlay = NO;
    [self syncPlayerWithControls];
    [self loadVideoFromRecordSession];
    
    [self.recordSession mergeSegmentsUsingPreset:AVAssetExportPreset640x480
                               completionHandler:^(NSURL *url, NSError *error) {
                                   if (!error) {
                                       self.mp4 = [NSData dataWithContentsOfURL:url];
                                   }
                               }];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupVCOnAppear];
    
    // register observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self.player pause];
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    // Ideally would remove observers in viewDidDisappear: but that is only
    // reasonable for observers that were added in viewWillAppear.
    // These observers were effectively added during initialization so have to
    // remove them when completely done with the VC, which is here in dealloc
    
    // remove observers
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
    
    [self.player removeObserver:self forKeyPath:@"rate"];
}


#pragma mark - Instance Methods
#pragma mark Abstract
- (void)recordingValidated
{
    // abstract
}

#pragma mark AudioVisual Player
/**
 * Sync the player state with buttons, timers and progress sliders
 */
- (void)syncPlayerWithControls
{
    // No controls for now, so this function does nothing
}

- (void)loadVideoFromRecordSession
{
    // Create an instance of the AVPlayerItem
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.recordSession.assetRepresentingSegments];
    
    // Observe the player item "status" key to determine when it is ready to play.
    // Ensure that observing the status property is done before the playerItem
    // is associated with the player
    [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&PlayerItemStatusContext];
    
    // The item is played only once. After playback, the player's head is set to
    // the end of the item, and further invocations of the play method will have
    // no effect. To position the playhead back at the beginning of the item, we
    // register to receive an AVPlayerItemDidPlayToEndTimeNotification from the
    // item. In the notification's callback method, we will invoke
    // seekToTime: with the argument kCMTimeZero
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];
    
    // Associate player item with the player
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    // Finally associate player with the player view
    [self.playerView setPlayer:self.player];
    // And configure the aspect ratio of player view to fill the screen
    ((AVPlayerLayer *)(self.playerView.layer)).videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // Add rate observers
    [self.player addObserver:self forKeyPath:@"rate" options:0 context:&PlayerRateContext];
}

#pragma mark Error Handling: Preparing Assets for Playback Failed

/**
 * Called when an asset fails to prepare for playback for any of
 * the following reasons:
 *
 * 1) values of asset keys did not load successfully,
 * 2) the asset keys did load successfully, but the asset is not playable
 * 3) the item did not become ready to play.
 */
-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
    /* Display the error. */
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription]
                                                        message:[error localizedFailureReason]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}


#pragma mark Appearance/Disappearance Setup
/**
 * Setup player when VC appears
 */
- (void)setupVCOnAppear
{
    // if player isn't playing, continue playing
    [self.player play];
}

/**
 * Stop the player to free up resources
 */
- (void)cleanupVCOnDisappear
{
    [self.player pause];
}


#pragma mark - Notification Observer Methods
/**
 * Done playing video, so reset player's head and restart playing
 */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    [self.player seekToTime:kCMTimeZero];
    [self.player play];
}


/**
 * When the player item's status changes, the view controller receives a key-value
 * observing change notification. AV Foundation does not specify what thread the
 * notification is sent on. Since we want to update the user interface, we must
 * make sure that any relevant code is invoked on the main thread.
 *
 * In this method we use dispatch_async to queue a message on the main thread
 * to synchronize the user interface.
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == &PlayerItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncPlayerWithControls];
            
            AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
            switch (status)
            {
                case AVPlayerItemStatusUnknown:
                {
                    // Indicates that the status of the player is not yet known because
                    // has not tried to load new media resources for playback
                    // This is a good place to disable player buttons
                }
                    break;
                    
                case AVPlayerItemStatusReadyToPlay:
                {
                    // Once the AVPlayerItem becomes ready to play, its duration
                    // can be fetched from the item.
                    // This is a good place to enable player buttons
                }
                    break;
                    
                case AVPlayerItemStatusFailed:
                {
                    AVPlayerItem *playerItem = (AVPlayerItem *)object;
                    [self assetFailedToPrepareForPlayback:playerItem.error];
                }
                    break;
            }
        });
        
    } else if (context == &PlayerRateContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerReadyToPlay = YES;
            [self syncPlayerWithControls];
        });
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    return;
}


/**
 * App entering background, so stop the player
 */
- (void)appDidEnterBackground
{
    [self cleanupVCOnDisappear];
}

/**
 * App entering foreground, so setup player
 */
- (void)appWillEnterForeground
{
    [self setupVCOnAppear];
}



@end
