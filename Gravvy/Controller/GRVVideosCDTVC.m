//
//  GRVVideosCDTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideosCDTVC.h"
#import "GRVVideo+HTTP.h"
#import "GRVClip.h"
#import "GRVUser+HTTP.h"
#import "GRVVideoTableViewCell.h"
#import "GRVVideoSectionHeaderView.h"
#import "GRVUserViewHelper.h"
#import "GRVFormatterUtils.h"
#import "UIImageView+WebCache.h"
#import "GRVConstants.h"
#import "GRVMembersCDTVC.h"
#import "GRVLikersCDTVC.h"
#import "GRVAddClipCameraReviewVC.h"
#import "GRVAddClipCameraVC.h"
#import "GRVAccountManager.h"
#import "GRVModelManager.h"
#import "MBProgressHUD.h"
#import "AMPopTip.h"
#import "GRVMuteSwitchDetector.h"
#import "GRVClipBrowser.h"

#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKConstants.h>
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>

#pragma mark - Constants
/**
 * Height of table view cell rows excluding the player view
 * Including 8 pts for the content view's bottom padding
 */
static CGFloat const kTableViewCellHeightNoPlayer = 112.0f;

/**
 * Table section header view's height
 */
static CGFloat const kTableViewSectionHeaderViewHeight = 54.0f;

/**
 * Table section footer view's height
 */
static CGFloat const kTableViewSectionFooterViewHeight = 0.0f;

/**
 * Minimum percentage of the height of a cell's player view that has to be visible
 * for it to be deemed the currently active cell.
 */
static CGFloat const kActiveCellPlayerHeightCutoff = 0.1f;

/**
 * Time interval for animations of showing or hiding notification indicator view
 */
static NSTimeInterval const kNotificationIndicatorAnimationInterval = 2.00f;

/**
 * Minimum time interval between display of pop tips.
 */
static NSTimeInterval const kMinimumDelayBetweenPopTips = 60.0f;

/**
 * Segue identifier for showing Members TVC
 */
static NSString *const kSegueIdentifierShowMembers = @"showMembersVC";

/**
 * Segue identifier for showing Add Clip Camera VC
 */
static NSString *const kSegueIdentifierAddClip = @"showAddClipCameraVC";

/**
 * Segue identifier for showing Likers TVC
 */
static NSString *const kSegueIdentifierShowLikers = @"showLikersVC";

/** 
 * Constants for the key-value observation context.
 */
static const NSString *PlayerItemStatusContext;
static const NSString *PlayerRateContext;
static const NSString *PlayerCurrentItemContext;

/**
 * button indices in share actions action sheet
 */
static const NSInteger kShareActionsIndexShareFacebook  = 0; // Share on facebook
static const NSInteger kShareActionsIndexShareTwitter   = 1; // Share on twitter
static const NSInteger kShareActionsIndexShareSMS       = 2; // Share via SMS
static const NSInteger kShareActionsIndexCopyLink       = 3; // Copy link

/**
 * button indices in more actions action sheet
 */
static const NSInteger kMoreActionsIndexEditClips       = 0; // Edit clips

/**
 * Format string for creating a video's share URL
 */
static NSString *const kVideoShareURLFormatString = @"http://gravvy.co/v/%@/";


@interface GRVVideosCDTVC () <UIActionSheetDelegate,
                                FBSDKSharingDelegate,
                                MFMessageComposeViewControllerDelegate>

#pragma mark - Properties
/**
 * All section header views stored in memory, with dictionary
 * keys being video hash keys and values being the views
 * This makes it easy to retrieve and update section headers without reloading
 * sections or the entire tableview
 */
@property (strong, nonatomic) NSMutableDictionary *sectionHeaderViews;

/**
 * Have you performed the initial refresh (with reorder of videos) on view load?
 *
 * @discussion
 *      We could do this on app authentication or in viewDidLoad, but if this
 *      happens the tableView won't be aware and will be tracking changes to the
 *      managedObjectContext. This creates a situation where the app starts up
 *      and after some time (when refresh with reorder completes) a new video is 
 *      added and has a mismatched section header, as the tableView isn't reloaded.
 *      With this variable, we only perform this reload (once) on view appearance
 *      and have the ability to do a proper refresh.
 */
@property (nonatomic) BOOL performedInitialRefresh;

/**
 * Skip the next play reporting event. This means the play has already been
 * recorded earlier in this loop
 */
@property (nonatomic) BOOL skipNextPlayReporting;

/**
 * Currently active video, and associated clips and cell cell which might or
 * might not be playing
 */
@property (strong, nonatomic) GRVVideo *activeVideo;
@property (copy, nonatomic) NSArray *activeVideoClips;
@property (strong, nonatomic) GRVVideoTableViewCell *activeVideoCell;

/**
 * activeVideo's currentClipIndex when it first started being played.
 */
@property (nonatomic) NSUInteger activeVideoAnchorIndex;

/**
 * Are we currently playing a video?
 */
@property (nonatomic, getter=isPlaying) BOOL playing;

/**
 * When the player is loaded, an autoplay will be attempted. This has to be done
 * only once so will keep the status in a property
 */
@property (nonatomic) BOOL performedAutoPlay;

/**
 * Player for use in playback of a number of items in sequence
 */
@property (strong, nonatomic) AVQueuePlayer *player;

/**
 * Player items to manage the presentation state of the currently playing
 * assets with which they are associated. These represent the clips of the
 * currently playing video.
 */
@property (strong, nonatomic) NSArray *playerItems; // of AVPlayerItem *

/**
 * Observer to track changes in the position of the playhead in the player object.
 * This will provide us with the means to update the UI with information about
 * time elapsed or time remaining
 */
@property (strong, nonatomic) id playerObserver;

/**
 * Player volume
 */
@property (nonatomic) float playerVolume;

/**
 * Action sheet shown on share button tap
 */
@property (strong, nonatomic) UIActionSheet *shareActionSheet;

/**
 * Action sheet shown on more actions tap
 */
@property (strong, nonatomic) UIActionSheet *moreActionsActionSheet;
/**
 * Action Sheet to confirm video removal
 */
@property (strong, nonatomic) UIActionSheet *removeConfirmationActionSheet;

/**
 * Index Path of cell that action sheet was triggered from
 */
@property (strong, nonatomic) NSIndexPath *actionSheetIndexPath;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) MBProgressHUD *successProgressHUD;
@property (strong, nonatomic) MBProgressHUD *failureProgressHUD;

@property (strong, nonatomic) AMPopTip *addClipPopTip;

@property (strong, nonatomic) NSDate *addClipPopTipDismissTime;

@end

@implementation GRVVideosCDTVC

#pragma mark - Properties
- (NSMutableDictionary *)sectionHeaderViews
{
    // lazy instantiation
    if (!_sectionHeaderViews) {
        _sectionHeaderViews = [NSMutableDictionary dictionary];
    }
    return _sectionHeaderViews;
}
- (void)setActiveVideoCell:(GRVVideoTableViewCell *)activeVideoCell
{
    // Show preview image of old video cell
    _activeVideoCell.previewImageView.hidden = NO;
    _activeVideoCell.playerView.player = nil;
    
    _activeVideoCell = activeVideoCell;
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

- (MBProgressHUD *)failureProgressHUD
{
    if (!_failureProgressHUD) {
        // Lazy instantiation
        _failureProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:_failureProgressHUD];
        
        _failureProgressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"errorCross"]];
        // Set custom view mode
        _failureProgressHUD.mode = MBProgressHUDModeCustomView;
        _failureProgressHUD.color = [kGRVRedColor colorWithAlphaComponent:_failureProgressHUD.opacity];
        _failureProgressHUD.minSize = CGSizeMake(120, 120);
        _failureProgressHUD.minShowTime = 1;
    }
    return _failureProgressHUD;
}

- (void)setPlayerItems:(NSArray *)playerItems
{
    // Remove observers from old player items
    for (AVPlayerItem *playerItem in _playerItems) {
        [playerItem removeObserver:self forKeyPath:@"status"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:playerItem];
    }
    
    // Remove observers from player associated with old player items
    [self.player removeObserver:self forKeyPath:@"rate"];
    [self.player removeObserver:self forKeyPath:@"currentItem"];
    // Stop player from loading old player items
    [self.player removeAllItems];
    
    // Set new player items
    _playerItems = [playerItems copy];
}

- (void)setPlayer:(AVQueuePlayer *)player
{
    _player = player;
    _player.volume = self.playerVolume;
}

- (void)setPlayerVolume:(float)playerVolume
{
    _playerVolume = playerVolume;
    self.player.volume = _playerVolume;
}

- (AMPopTip *)addClipPopTip
{
    if (!_addClipPopTip) {
        // lazy instantiation
        _addClipPopTip = [AMPopTip popTip];
        _addClipPopTip.shouldDismissOnTap = YES;
        // Don't capture self in a block
        GRVVideosCDTVC* __weak weakSelf = self;
        _addClipPopTip.dismissHandler = ^{
            weakSelf.addClipPopTipDismissTime = [NSDate date];
        };
    }
    return _addClipPopTip;
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    [super setManagedObjectContext:managedObjectContext];
    
    // Perform initial refresh if not already done so
    if (managedObjectContext && !self.performedInitialRefresh) {
        if (self.detailsVideo) {
            // Initial refresh for video Details VC doesn't need to reorder
            self.performedInitialRefresh = YES;
            [self refreshWithoutReorder];
        } else {
            // Refresh and reorder while showing spinner for a collection of videos
            // Don't capture self in a block
            GRVVideosCDTVC* __weak weakSelf = self;
            [self refreshAndShowSpinnerWithCompletion:^{
                weakSelf.performedInitialRefresh = YES;
                [weakSelf autoPlayVideo];
            }];
        }
    }
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Set page title if serving as Video Details VC
    if (self.detailsVideo) {
        self.navigationItem.title = @"Video";
    }
    
    self.performedInitialRefresh = NO;
    
    // Setup height of each tableview row
    CGFloat playerViewHeight = self.view.frame.size.width;
    self.tableView.rowHeight = kTableViewCellHeightNoPlayer + playerViewHeight;
    
    // Hide separator insets and table view's bottom white line
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.separatorColor = [UIColor groupTableViewBackgroundColor];
    
    // Start by assuming mute until proven otherwise
    self.playerVolume = 0.0f;
    // Don't capture self in the callback
    GRVVideosCDTVC* __weak weakSelf = self;
    [GRVMuteSwitchDetector sharedDetector].detectionHandler = ^(BOOL muted) {
        [weakSelf configurePlayerVolumeWithMute:muted];
    };
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Silently refresh to pull in recent video updates if already performed
    // initial refresh
    if (self.performedInitialRefresh && !self.skipRefreshOnNextAppearance) {
        [self refreshWithoutReorder];
    }
    self.skipRefreshOnNextAppearance = NO;
    
    
    [GRVMuteSwitchDetector sharedDetector].suspended = NO;
    
    // register observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaServicesWereReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(audioRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:nil];
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
    [super viewWillDisappear:animated];
    // Pause VC as we switch screen
    [self pause];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [GRVMuteSwitchDetector sharedDetector].suspended = YES;
    
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionMediaServicesWereResetNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionRouteChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

- (void)dealloc
{
    // Ideally would remove observers in viewDidDisappear: but that is only
    // reasonable for observers that were added in viewWillAppear.
    // These observers were effectively added during regular operation so have
    // to remove them when completely done with the VC, which is here in dealloc
    
    // remove observers
    self.playerItems = nil;
    
    [_addClipPopTip hide];
    _addClipPopTip = nil;
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Reload contents of tableview, but first cancel all downloads before doing so
 * to prevent hanging
 */
- (void)refreshTableView
{
    [[SDWebImageManager sharedManager] cancelAll];
    [self.tableView reloadData];
}

/**
 * Clear pending notifications in active video then slowly hide the notification
 * indicator view.
 */
- (void)clearPendingNotificationsInActiveCell
{
    if ([self.activeVideo hasPendingNotifications]) {
        GRVVideoSectionHeaderView *headerView = [self.sectionHeaderViews objectForKey:self.activeVideo.hashKey];
        
        [self.activeVideo clearNotifications:^{
            [self.activeVideo refreshVideo:nil];
            
            // delay the hiding of the notification indicator
            [headerView.notificationIndicatorView stopPulsingAnimation];
            [UIView animateWithDuration:kNotificationIndicatorAnimationInterval
                             animations:^{
                                 headerView.notificationIndicatorView.alpha = 0.0f;
                             } completion:^(BOOL finished) {
                                 headerView.notificationIndicatorView.hidden = YES;
                             }];
        }];
    }
}

/**
 * Possibly show a pop tip that shows users how to add clips
 */
- (void)showAddClipPopTip
{
    // if the minimum duration between display of pop tips hasnt passed then
    // ignore this
    if (self.addClipPopTipDismissTime &&
        ([[NSDate date] timeIntervalSinceDate:self.addClipPopTipDismissTime] < kMinimumDelayBetweenPopTips)) {
        return;
    }
    
    // Show video creation poptip
    if (![GRVModelManager sharedManager].acknowledgedClipAdditionTip) {
        
        // Get the active video's section header
        if (self.activeVideo) {
            GRVVideoSectionHeaderView *headerView = [self.sectionHeaderViews objectForKey:self.activeVideo.hashKey];
            if (headerView) {
                if (!self.addClipPopTip.containerView || !self.addClipPopTip.isVisible) {
                    [self.addClipPopTip showText:@"Tap button to add video clip"
                                       direction:AMPopTipDirectionDown
                                        maxWidth:100.0f
                                          inView:self.view
                                       fromFrame:headerView.addClipButton.frame
                                        duration:kGRVPopTipMaximumDuration];
                }
            }
        }
    }
}


/**
 * Play video in the active video cell
 */
- (void)playVideoInActiveCell
{
    // Show preview image in current cell while we wait to start playing
    self.activeVideoCell.previewImageView.hidden = NO;
    
    // Prepare to play video
    [self.player pause];
    self.playing = NO;
    self.performedAutoPlay = NO;
    
    // Get ordered clips of video for creating an animated display
    NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    NSArray *clips = [self.activeVideo.clips sortedArrayUsingDescriptors:@[orderSd]];
    NSUInteger clipsCount = [clips count];
    // Setup the anchor index, and make sure it doesn't overrun. If too large,
    // set it to the last index, and of course make sure it isn't below zero
    self.activeVideoAnchorIndex = [self.activeVideo.currentClipIndex integerValue];
    if (self.activeVideoAnchorIndex >= clipsCount) {
        self.activeVideoAnchorIndex = MAX(0, (clipsCount - 1));
    }
    
    // We want the clips to be ordered from anchor index and continue in
    // ASC order, wrapping around at 0. So if the anchor index is 3 and
    // there are 5 clips, we expect the ordering of clips to be [3,4,0,1,2]
    NSMutableArray *clipsStartingAtAnchorIndex = [NSMutableArray array];
    
    for (NSUInteger i=0; i<clipsCount; i++) {
        NSUInteger offsetClipIndex = (i + self.activeVideoAnchorIndex) % clipsCount;
        GRVClip *offsetClip = [clips objectAtIndex:offsetClipIndex];
        [clipsStartingAtAnchorIndex addObject:offsetClip];
    }
    clips = [clipsStartingAtAnchorIndex copy];
    
    
    // Setup player items
    NSMutableArray *playerItems = [NSMutableArray array];
    NSMutableArray *playerItemClips = [NSMutableArray array];
    for (GRVClip *clip in clips) {
        NSURL *url = [NSURL URLWithString:clip.mp4URL];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];
        // ensure that observing the status property is done before the
        // playerItem is associated with the player
        [playerItem addObserver:self forKeyPath:@"status" options:0 context:&PlayerItemStatusContext];
        
        // The item is played only once. After playback, the player's head is set to
        // the end of the item, and further invocations of the play method will have
        // no effect. To position the playhead back at the beginning of the item, we
        // register to receive an AVPlayerItemDidPlayToEndTimeNotification from the
        // item. In the notification's callback method, we will invoke
        // seekToTime: with the argument kCMTimeZero
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playerItemDidReachEnd:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:playerItem];
        
        [playerItems addObject:playerItem];
        [playerItemClips addObject:clip];
    }
    // Cache new player items while removing observers for old player items
    // and old player
    self.playerItems = [playerItems copy];
    self.activeVideoClips = [playerItemClips copy];
    
    // Associate the player items with the player, so they start to become
    // ready to play
    self.player = [AVQueuePlayer queuePlayerWithItems:self.playerItems];
    
    // Finally associate the player with the player view
    [self.activeVideoCell.playerView setPlayer:self.player];
    
    // And configure the aspect ratio of player view to fill the screen
    ((AVPlayerLayer *)(self.activeVideoCell.playerView.layer)).videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    // Add observers
    [self.player addObserver:self forKeyPath:@"rate" options:0 context:&PlayerRateContext];
    [self.player addObserver:self forKeyPath:@"currentItem" options:0 context:&PlayerCurrentItemContext];
    
    [self syncPlayerWithUI];
}

/**
 * Determine the currently active video cell from the collection of currently
 * displayed tableview cells that meet the following requirements in priority:
 * - If first visible cell has over kActiveCellPlayerHeightCutoff of the vertical
 *   height visible beneath the section header, then it is the active cell
 * - Else, the second visible cell is the active cell
 */
- (GRVVideoTableViewCell *)determineActiveVideoCell
{
    GRVVideoTableViewCell *activeVideoCell;
    NSArray *visibleCells = [self.tableView visibleCells];
    
    if ([visibleCells count] == 0) {
        activeVideoCell = nil;
        
    } else if ([visibleCells count] == 1) {
        activeVideoCell = [visibleCells firstObject];
        
    } else { // [visibleCells count] > 1
        // Check for visible height of first cell's player view
        GRVVideoTableViewCell *cell = [visibleCells firstObject];
        
        // Get associated player view's coordinates
        CGPoint playerViewOrigin = [cell.playerView convertPoint:cell.playerView.frame.origin
                                                          toView:self.view];
        CGFloat playerViewHeight = cell.playerView.frame.size.height;
        
        // Get player view's visible height beneath the section header
        CGFloat playerViewBottomOffset = playerViewOrigin.y + playerViewHeight;
        CGFloat visiblePlayerViewHeight = playerViewBottomOffset -kTableViewSectionHeaderViewHeight;
        
        // Use this visible height to decide if the first or second sell will
        // be the active cell
        if ((visiblePlayerViewHeight/playerViewHeight) > kActiveCellPlayerHeightCutoff) {
            activeVideoCell = cell;
        } else {
            activeVideoCell = visibleCells[1];
        }
    }
    
    return activeVideoCell;
}

#pragma mark Action Progress
- (void)showProgressHUDSuccessMessage:(NSString *)message
{
    self.successProgressHUD.labelText = message;
    [self.successProgressHUD show:YES];
    [self.successProgressHUD hide:YES afterDelay:1.5];
}

- (void)showProgressHUDFailureMessage:(NSString *)message
{
    self.failureProgressHUD.labelText = message;
    [self.failureProgressHUD show:YES];
    [self.failureProgressHUD hide:YES afterDelay:1.5];
}

#pragma mark AudioVisual Player
/**
 * Sync the player state with currently active cell
 */
- (void)syncPlayerWithUI
{
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        
        self.playing = (self.player.rate != 0.0);
        
    } else {
        self.playing = NO;
    }
    
    // Update current clip index and count
    NSInteger currentClipIndex = NSNotFound;
    if (self.player.currentItem && [self.playerItems count]) {
        currentClipIndex =  [self.playerItems indexOfObject:self.player.currentItem];
    }
    if (currentClipIndex != NSNotFound) {
        [self configureCell:self.activeVideoCell withCurrentClip:currentClipIndex totalClipsCount:[self.playerItems count] andVideo:self.activeVideo];
    } else {
        [self configureCell:self.activeVideoCell withCurrentClip:0 totalClipsCount:[self.activeVideo.clips count] andVideo:self.activeVideo];
    }
    
}

/**
 * When player is initially loaded attempt an autoplay the first time a player
 * item is ready to play
 */
- (void)attemptAutoPlay
{
    // Don't bother and pause if the view is not visible
    if(!self.view.window) {
        [self pause];
        return;
    }
    
    // Hide preview image of video cell
    self.activeVideoCell.previewImageView.hidden = YES;
    
    if (!self.performedAutoPlay) {
        if (!self.isPlaying) {
            [self playOrPause];
        }
        
        // Refresh video on first autoplay
        // If unread notifications as of the first play, clear those here
        if ([self.activeVideo hasPendingNotifications]) {
            [self clearPendingNotificationsInActiveCell];
        } else {
            [self.activeVideo refreshVideo:nil];
        }
        
        // If you're the video owner then you need to have at least 1 play so
        // make that happen right now, so you don't end up with 0 plays if you
        // don't make it to the end of the first clip
        if ([self.activeVideo isVideoOwner] && ([self.activeVideo.playsCount integerValue] == 0)) {
            [self.activeVideo play:nil];
            self.skipNextPlayReporting = YES;
        }
        
        self.performedAutoPlay = YES;
    }
}

/**
 * Determine the currently active video cell that should be played and if it
 * is changed from the last active video cell, then play new video cell.
 *
 * This uses the following logic
 * - Get the currently active video.
 * - If active video has changed, then save a reference to this cell
 *   and start playing the video in the cell
 */
- (void)autoPlayVideo
{
    // If the VC hasn't peformed initial refresh yet don't bother
    if (!self.performedInitialRefresh) {
        return;
    }
    
    // Don't bother and pause if the view is not visible
    if(!self.view.window) {
        [self pause];
        return;
    }
    
    GRVVideoTableViewCell *currentActiveVideoCell = [self determineActiveVideoCell];
    NSIndexPath *currentActiveIndexPath = [self.tableView indexPathForCell:currentActiveVideoCell];
    GRVVideo *currentActiveVideo = [self.fetchedResultsController objectAtIndexPath:currentActiveIndexPath];
    
    if (!self.activeVideo ||
        ![currentActiveVideo.hashKey isEqualToString:self.activeVideo.hashKey]) {
        // A change in active video means start playing the new active video
        self.activeVideo = currentActiveVideo;
        self.activeVideoCell = currentActiveVideoCell;
        [self playVideoInActiveCell];
    } else {
        // Continue playing already active video by revealing the player which
        // might have gotten hidden by the preview image as the cell was re-used
        self.activeVideoCell.previewImageView.hidden = YES;
    }
}

/**
 * Pause the active player
 */
- (void)pause
{
    if (self.isPlaying) [self playOrPause];
}

/**
 * Set player volume based on mute switch detector and current audio route
 */
- (void)configurePlayerVolume
{
    [self configurePlayerVolumeWithMute:[GRVMuteSwitchDetector sharedDetector].muted];
}

/**
 * Set player volume based on given mute state and current audio route
 *
 * @param muted mute switch detector's current state
 */
- (void)configurePlayerVolumeWithMute:(BOOL)muted
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL deviceIsPluggedIn = [self isDevicePluggedIn:[audioSession currentRoute]];
    self.playerVolume = (muted && !deviceIsPluggedIn) ? 0.0f : 1.0f;
}

#pragma mark AudioSession
/**
 * Check if a given route indicates headset or bluetooth is plugged in
 *
 * @param route Audio Route to use in determining if a device is plugged in
 *
 * @return BOOL indicator of if a headset is plugged in
 */
- (BOOL)isDevicePluggedIn:(AVAudioSessionRouteDescription *)route
{
    BOOL headsetIsPluggedIn = NO;
    BOOL bluetoothIsPluggedIn = NO;
    for (AVAudioSessionPortDescription *desc in route.outputs) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortHeadphones]) {
            headsetIsPluggedIn = YES;
            break;
        } else if ([self isBluetoothDevice:[desc portType]]) {
            bluetoothIsPluggedIn = YES;
            break;
        }
    }
    
    // In case both headphones and bluetooth are connected, detect bluetooth by
    // inputs
    // Condition: iOS7 and Bluetooth input available
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if (!bluetoothIsPluggedIn && !headsetIsPluggedIn &&
        [audioSession respondsToSelector:@selector(availableInputs)]) {
        for (AVAudioSessionPortDescription *input in [audioSession availableInputs]){
            if ([self isBluetoothDevice:[input portType]]){
                bluetoothIsPluggedIn = YES;
                break;
            }
        }
    }
    
    return (headsetIsPluggedIn || bluetoothIsPluggedIn);
}

- (BOOL)isBluetoothDevice:(NSString*)portType {
    
    return ([portType isEqualToString:AVAudioSessionPortBluetoothA2DP] ||
            [portType isEqualToString:AVAudioSessionPortBluetoothHFP]);
}

#pragma mark Core Data
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVVideo"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[@"owner", @"clips"];
        
        if (self.detailsVideo) {
            // fetch specific video
            request.predicate = [NSPredicate predicateWithFormat:@"hashKey == %@", self.detailsVideo.hashKey];
        } else {
            // fetch all ordered videos with clips
            request.predicate = [NSPredicate predicateWithFormat:@"(order > %d) AND (clips.@count > 0)", kGRVVideoOrderNew];
        }
        
        // Show latest videos first (updatedAt storted descending)
        NSSortDescriptor *orderSort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
        request.sortDescriptors = @[orderSort];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"order" cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
    
    [self showOrHideEmptyStateView];
}

/**
 * User has confirmed deletion of a particular video so handle it
 */
- (void)deleteVideo:(GRVVideo *)video
{
    [video revokeMembershipWithCompletion:^{
        if (self.detailsVideo) {
            // If operating as a details VC exit the VC
            [self.navigationController popViewControllerAnimated:YES];
            
        } else {
            [self.spinner stopAnimating];
            [self refresh];
        }
    }];
}

#pragma mark Public
- (CGFloat)tableViewFooterHeight
{
    // When serving as a details VC, there's no need for a footer as there's no
    // obstructed Create Video button
    if (self.detailsVideo) {
        return 0.0f;
    } else {
        return [super tableViewFooterHeight];
    }
    
}

#pragma mark Public: AudioVisual Player
- (void)stop
{
    // first pause the active player
    [self.player pause];
    self.playing = NO;
    self.performedAutoPlay = NO;
    
    // Remove player items, associated observers and player observers
    self.playerItems = nil;
    // Stop old player from loading by removing all items and re-initializng
    [self.player removeAllItems];
    self.player = [AVQueuePlayer playerWithURL:[NSURL URLWithString:@""]];
    self.player = nil;
    
    // Now that nothing is playing, release all trackers of the active video
    self.activeVideo = nil;
    self.activeVideoClips = nil;
    self.activeVideoCell = nil;
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Video Cell"; // get the cell
    GRVVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    // Configure the cell with data from the managed object
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    [self configureCell:cell withVideo:video];
    return cell;
}

#pragma mark Helper
- (void)configureCell:(GRVVideoTableViewCell *)cell withVideo:(GRVVideo *)video
{
    // Video preview image is set to that of the current clip
    NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    NSArray *clips = [video.clips sortedArrayUsingDescriptors:@[orderSd]];
    NSUInteger clipsCount = [clips count];
    NSUInteger clipIndex = [video.currentClipIndex integerValue];
    if (clipIndex >= clipsCount) {
        clipIndex = MAX(0, (clipsCount-1));
    }
    GRVClip *currentClip = [clips objectAtIndex:clipIndex];
    NSString *photoThumbnailURL = currentClip.photoThumbnailURL ? currentClip.photoThumbnailURL : video.photoThumbnailURL;
    [cell.previewImageView sd_setImageWithURL:[NSURL URLWithString:photoThumbnailURL]];
    
    // video title
    cell.titleLabel.text = video.title;
    
    NSString *likesCount = [GRVFormatterUtils numToString:video.likesCount];
    NSString *likesCountSuffix = ([video.likesCount integerValue] == 1) ? @"like" : @"likes";
    cell.likesCountLabel.text = [NSString stringWithFormat:@"%@ %@", likesCount, likesCountSuffix];
    
    NSString *playsCount = [GRVFormatterUtils numToString:video.playsCount];
    NSString *playsCountSuffix = ([video.playsCount integerValue] == 1) ? @"play" : @"plays";
    cell.playsCountLabel.text = [NSString stringWithFormat:@"%@ %@", playsCount, playsCountSuffix];
    
    NSString *likeButtonImageName = [video.liked boolValue] ? @"likeActive" : @"likeInactive";
    [cell.likeButton setImage:[UIImage imageNamed:likeButtonImageName] forState:UIControlStateNormal];
    
    if ([self.activeVideo.hashKey isEqualToString:video.hashKey]) {
        // if on the active video's cell, don't block player with preview image
        cell.previewImageView.hidden = YES;
        
    } else {
        // if not on the active video's cell, show preview image so we don't see
        // video playing in reused cells
        cell.previewImageView.hidden = NO;
        // Since preview image is showing, we must be on first clip
        [self configureCell:cell withCurrentClip:[video.currentClipIndex integerValue] totalClipsCount:[video.clips count] andVideo:video];
    }
    
}

/**
 * Configure a cell which is playing a clip at the given 0-based index of clips
 */
- (void)configureCell:(GRVVideoTableViewCell *)cell
      withCurrentClip:(NSUInteger)currentClipIndex
        totalClipsCount:(NSUInteger)clipsCount
             andVideo:(GRVVideo *)video
{
    // Determine actual clip index based off of video's anchor index
    // for video's currently playing
    NSUInteger actualClipIndex;
   
    // The collection of clips associated with current video
    NSArray *clips;

    if ([video.hashKey isEqualToString:self.activeVideo.hashKey]) {
        clips = self.activeVideoClips;
        actualClipIndex = (self.activeVideoAnchorIndex + currentClipIndex) % clipsCount;
    
    } else {
        NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
        clips = [video.clips sortedArrayUsingDescriptors:@[orderSd]];
        actualClipIndex = currentClipIndex;
    }
    
    // Display actual clip index
    cell.currentClipIndexLabel.text = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)(actualClipIndex+1), (unsigned long)clipsCount];
    
    // Get current clip and display its owner
    clipsCount = [clips count];
    if (currentClipIndex >= clipsCount) {
        currentClipIndex = MAX(0, (clipsCount-1));
    }
    GRVClip *currentClip = nil;
    if (clipsCount) {
        currentClip = [clips objectAtIndex:currentClipIndex];
    }
    GRVUser *owner = currentClip.owner ? currentClip.owner : video.owner;
    cell.currentClipOwnerLabel.text = [GRVUserViewHelper userFullName:owner];
}


#pragma mark Sections
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionIdentifier = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    return [NSString stringWithFormat:@"%@: %@", video.hashKey, sectionIdentifier];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // Don't want an index list
    return nil;
}


#pragma mark - UITableViewDelegate
#pragma mark Configuring Rows for the Table View
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Auto-play video on display of first row
    if (!self.activeVideoCell) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self autoPlayVideo];
            [self showAddClipPopTip];
        });
    }
}

#pragma mark Custom Section Headers
/**
 * Custom section header using storyboards
 * 
 * @ref http://stackoverflow.com/a/11396643
 * @ref http://stackoverflow.com/a/24044628
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    GRVVideoSectionHeaderView *headerView = [[GRVVideoSectionHeaderView alloc] initWithFrame:CGRectZero];
    // Get the video
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:indexPath];

    [self configureSectionHeaderView:headerView withVideo:video];
    
    // Cache section
    headerView.addClipButton.tag = section;
    
    // Add target-action method but first remove previously added ones
    [headerView.addClipButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [headerView.addClipButton addTarget:self action:@selector(addClip:) forControlEvents:UIControlEventTouchUpInside];
    
    self.sectionHeaderViews[video.hashKey] = headerView;
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kTableViewSectionHeaderViewHeight;
}

#pragma mark Helper
- (void)configureSectionHeaderView:(GRVVideoSectionHeaderView *)headerView withVideo:(GRVVideo *)video
{
    // Configure view with summary details: Owner, Creation date and Play count
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:video.owner];
    headerView.ownerAvatarView.thumbnail = avatarView.thumbnail;
    headerView.ownerAvatarView.userInitials = avatarView.userInitials;
    
    headerView.ownerNameLabel.text = [GRVUserViewHelper userFullNameOrPhoneNumber:video.owner];
    headerView.createdAtLabel.text = [GRVFormatterUtils dayAndYearStringForDate:video.createdAt];
    
    // Indicate if video has a notification
    headerView.notificationIndicatorView.hidden = ![video hasPendingNotifications];
    if ([video hasPendingNotifications]) {
        [headerView.notificationIndicatorView startPulsingAnimation];
    }
}

#pragma mark Custom Section Footers
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    // Create custom view
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kTableViewSectionFooterViewHeight;
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self scrollViewDoneScrolling];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDoneScrolling];
}

#pragma mark Helper
/**
 * Scroll view done scrolling so autoplay the current displayed video if it
 * isn't already playing.
 */
- (void)scrollViewDoneScrolling
{
    // before autoplaying currently displayed video, clear pending notifications
    // in currently active cell if not refreshing
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
        [self clearPendingNotificationsInActiveCell];
    }
    [self autoPlayVideo];
    [self showAddClipPopTip];
}

#pragma mark - Refresh
/**
 * Do a complete refresh and re-ordering of the table
 */
- (IBAction)refresh
{
    [self refreshWithCompletion:nil];
}

/**
 * Do a complete refresh and re-ordering of the table with a callback block
 *
 * @param refreshIsCompleted     block to be called after refreshing videos. This
 *      is run on the main queue. If this isn't provided the default callback
 *      will call [self autoPlayVideo]
 */
- (void)refreshWithCompletion:(void (^)())refreshIsCompleted
{
    // During refresh don't modify table for changes in managed object contexxt
    self.suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    // Refresh videos from server
    [GRVVideo refreshVideos:YES withCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
            self.suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
            [self.tableView reloadData];
            
            self.activeVideo = nil;
            self.activeVideoClips = nil;
            self.activeVideoCell = nil;
            
            if (refreshIsCompleted) {
                refreshIsCompleted();
            } else {
                [self autoPlayVideo];
            }
        });
    }];
}

/**
 * Do a complete refresh and re-ordering of the table while programmatically
 * showing the refresh control spinner
 */
- (void)refreshAndShowSpinner
{
    [self refreshAndShowSpinnerWithCompletion:nil];
}

/**
 * Do a complete refresh and re-ordering of the table while programmatically
 * showing the refresh control spinner
 *
 * @param refreshIsCompleted     block to be called after refreshing videos. This
 *      is run on the main queue. If this isn't provided the default callback
 *      will call [self autoPlayVideo]
 */
- (void)refreshAndShowSpinnerWithCompletion:(void (^)())refreshIsCompleted
{
    [self.refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, 0.0 - self.tableView.contentInset.top - self.refreshControl.frame.size.height) animated:YES];
    [self refreshWithCompletion:refreshIsCompleted];
}

/**
 * Refresh without reordering
 */
- (void)refreshWithoutReorder
{
    // During refresh don't modify table for changes in managed object contexxt
    self.suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    // Refresh videos from server
    [GRVVideo refreshVideos:NO withCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            self.suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
            [self.tableView reloadData];
            
            // We dont reset the active video and force an autoplay here so
            // that users can continue playing from where they left off.
        });
    }];
}


#pragma mark - Target/Action Methods
- (IBAction)playOrPause
{
    // Adjust the volume
    [self configurePlayerVolume];
    
    if (self.isPlaying) {
        [self.player pause];
    } else {
        [self.player play];
    }
    self.playing = !self.isPlaying;
}

- (IBAction)toggleLike:(UIButton *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    // to ensure the button indeed is in a cell: I know this is overkill...
    if (indexPath) {
        GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
        sender.enabled = NO;
        [video toggleLike:^{
            sender.enabled = YES;
        }];
    }
}

- (IBAction)showMembers:(UIButton *)sender
{
    [self performSegueWithIdentifier:kSegueIdentifierShowMembers sender:sender];
}

- (IBAction)showLikers:(UIButton *)sender
{
    [self performSegueWithIdentifier:kSegueIdentifierShowLikers sender:sender];
}

- (IBAction)addClip:(UIButton *)sender
{
    // quit if camera is not available for recording videos
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        if (![GRVModelManager sharedManager].acknowledgedClipAdditionTip) {
            [GRVModelManager sharedManager].acknowledgedClipAdditionTip = YES;
            [self.addClipPopTip hide];
        }
        return;
    }
    
    // Stop player before continuing
    [self stop];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Give the avplayer cleanup some time to occur before presenting camera VC
        [self performSegueWithIdentifier:kSegueIdentifierAddClip sender:sender];
    });
    
    if (![GRVModelManager sharedManager].acknowledgedClipAdditionTip) {
        [GRVModelManager sharedManager].acknowledgedClipAdditionTip = YES;
        [self.addClipPopTip hide];
    }
}


- (IBAction)showShareActions:(UIButton *)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
        self.actionSheetIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    }
    
    self.shareActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                        delegate:self
                                               cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil
                                               otherButtonTitles:@"Share on Facebook", @"Share on Twitter", @"Share via SMS", @"Copy Link", nil];
    [self.shareActionSheet showInView:self.view];
}


- (IBAction)showMoreActions:(UIButton *)sender
{
    if ([sender isKindOfClass:[UIButton class]]) {
        CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
        self.actionSheetIndexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    }
    
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:self.actionSheetIndexPath];
    NSString *destructiveButtonTitle;
    if ([video isVideoOwner]) {
        destructiveButtonTitle = @"Delete Video";
        self.moreActionsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:@"Edit Clips", destructiveButtonTitle, nil];
    } else {
        destructiveButtonTitle = @"Exit Video";
        self.moreActionsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                  delegate:self
                                                         cancelButtonTitle:@"Cancel"
                                                    destructiveButtonTitle:nil
                                                         otherButtonTitles:destructiveButtonTitle, nil];
    }
    
    self.moreActionsActionSheet.destructiveButtonIndex = (self.moreActionsActionSheet.numberOfButtons-2);
    [self.moreActionsActionSheet showInView:self.view];
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Get video
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:self.actionSheetIndexPath];

    if (actionSheet == self.shareActionSheet) {
        // Is this a request to share content
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            switch (buttonIndex-actionSheet.firstOtherButtonIndex) {
                case kShareActionsIndexShareFacebook:
                    [self shareOnFacebook:video];
                    break;
                    
                case kShareActionsIndexShareTwitter:
                    [self shareOnTwitter:video];
                    break;
                    
                case kShareActionsIndexShareSMS:
                    [self shareViaSMS:video];
                    break;
                    
                case kShareActionsIndexCopyLink:
                    [self copyShareLink:video];
                    break;
                    
                default:
                    break;
            }
        }
        
    } else if (actionSheet == self.moreActionsActionSheet) {
        // is this a revoke request on a video? if so show a confirmation action
        // sheet
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            NSString *destructiveButtonTitle;
            if ([video isVideoOwner]) {
                destructiveButtonTitle = @"Delete Video";
            } else {
                destructiveButtonTitle = @"Exit Video";
            }
            
            self.removeConfirmationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Confirm Deletion"
                                                                             delegate:self
                                                                    cancelButtonTitle:@"Cancel"
                                                               destructiveButtonTitle:destructiveButtonTitle
                                                                    otherButtonTitles:nil];
            [self.removeConfirmationActionSheet showInView:self.view];
            
        } else if (buttonIndex != actionSheet.cancelButtonIndex) {
            switch (buttonIndex-actionSheet.firstOtherButtonIndex) {
                case kMoreActionsIndexEditClips:
                    [self showClipEditor:video];
                    break;
                    
                default:
                    break;
            }
        }
        
    } else if (actionSheet == self.removeConfirmationActionSheet) {
        
        // check if user confirmed desire to leave/delete a video
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // user indeed wants to leave/delete a video
            [self.spinner startAnimating];
            
            [self deleteVideo:video];
            
        }
    }
}

#pragma mark Helpers
/**
 * Generate URL to be used when sharing a video
 * 
 * @param video Video to be shared
 *
 * @return a string of the web-URL of a video
 */
- (NSString *)videoShareURL:(GRVVideo *)video
{
    return [NSString stringWithFormat:kVideoShareURLFormatString, video.hashKey];
}

/**
 * Generate Title to be used when sharing a video
 *
 * @param video Video to be shared
 *
 * @return a string of the title of a video
 */
- (NSString *)videoShareTitle:(GRVVideo *)video
{
    NSString *title;
    if ([video.title length]) {
        title = [NSString stringWithFormat:@"Gravvy App Video: \"%@\"", video.title];
    } else {
        title = @"Gravvy App Video";
    }
    return title;
}

/**
 * Share a video using the Facebook SDK
 *
 * @param video Video to be shared
 */
- (void)shareOnFacebook:(GRVVideo *)video
{
    // Create share content
    FBSDKShareLinkContent *content = [[FBSDKShareLinkContent alloc] init];
    content.contentURL = [NSURL URLWithString:[self videoShareURL:video]];
    content.imageURL = [NSURL URLWithString:video.photoThumbnailURL];
    content.contentTitle = [self videoShareTitle:video];
    
    // Use a share dialog
    [FBSDKShareDialog showFromViewController:self withContent:content delegate:self];
}

/**
 * Share a video on twitter
 *
 * @param video Video to be shared
 */
- (void)shareOnTwitter:(GRVVideo *)video
{
    NSString *tweetTitle = [NSString stringWithFormat:@"#np %@", [self videoShareTitle:video]];
    NSString *tweetURL = [self videoShareURL:video];
    
    // Check if twitter account is available on phone
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        // Compose a post for twitter
        __block SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet setInitialText:tweetTitle];
        [tweetSheet addURL:[NSURL URLWithString:tweetURL]];
        
        if ([video.hashKey isEqualToString:self.activeVideo.hashKey]) {
            UIImage *tweetImage = self.activeVideoCell.previewImageView.image;
            [tweetSheet addImage:tweetImage];
            [self presentViewController:tweetSheet animated:YES completion:nil];
            
        } else {
            SDWebImageManager *manager = [SDWebImageManager sharedManager];
            [manager downloadImageWithURL:[NSURL URLWithString:video.photoThumbnailURL]
                                  options:0
                                 progress:nil
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                    if (image && finished) {
                                        [tweetSheet addImage:image];
                                    }
                                    [self presentViewController:tweetSheet animated:YES completion:nil];
                                }];
        }
        
    } else {
        // twitter account not available so we will open a link in the browser
        NSString *encodedTweetTitle = [GRVFormatterUtils urlEncode:tweetTitle];
        NSString *encodedTweetURL = [GRVFormatterUtils urlEncode:tweetURL];
        NSString *tweetShareURL = [NSString stringWithFormat:@"https://twitter.com/share?text=%@&url=%@", encodedTweetTitle, encodedTweetURL];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:tweetShareURL]];
    }
}

/**
 * Share a video via SMS
 *
 * @param video Video to be shared
 */
- (void)shareViaSMS:(GRVVideo *)video
{
    NSString *webURL = [self videoShareURL:video];
    
    if ([MFMessageComposeViewController canSendText]) {
        // The device can send SMS.
        MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;
        [picker.navigationBar setTintColor:[UIColor whiteColor]];

        picker.body = [NSString stringWithFormat:@"You might like my Gravvy video: %@", webURL];
        [self presentViewController:picker animated:YES completion:NULL];
        
    } else {
        // The device can not send SMS.
        [self showProgressHUDFailureMessage:@"Device can't send SMS"];
    }
}

/**
 * Copy video's share link to the clipboard
 *
 * @param video Video to be shared
 */
- (void)copyShareLink:(GRVVideo *)video
{
    NSString *webURL = [self videoShareURL:video];
    [UIPasteboard generalPasteboard].string = webURL;
    [self showProgressHUDSuccessMessage:@"Copied Link"];
}

/**
 * Show clip editor for a given video
 *
 * @param video Video to be edited
 */
- (void)showClipEditor:(GRVVideo *)video
{
    GRVClipBrowser *browser = [[GRVClipBrowser alloc] initWithDelegate:nil];
    browser.video = video;
    
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:browser];
    nvc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    // Stop player before continuing
    [self stop];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Give the avplayer cleanup some time to occur before presenting clip browser
        [self presentViewController:nvc animated:YES completion:nil];
    });
}


#pragma mark - FBSDKSharingDelegate

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results
{
    [self showProgressHUDSuccessMessage:@"Shared on Facebook"];
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error
{
    NSString *message = error.userInfo[FBSDKErrorLocalizedDescriptionKey] ?:
    @"There was a problem sharing, please try again later.";
    NSString *title = error.userInfo[FBSDKErrorLocalizedTitleKey] ?: @"Oops!";
    
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer
{
    // Do nothing
}

#pragma mark - MFMessageComposeViewControllerDelegate
// -------------------------------------------------------------------------------
//  messageComposeViewController:didFinishWithResult:
//  Dismisses the message composition interface when users tap Cancel or Send.
//  Proceeds to update the feedback message field with the result of the
//  operation.
// -------------------------------------------------------------------------------
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    // A good place to notify users about errors associated with the interface
    [self dismissViewControllerAnimated:YES completion:^{
        if (result ==  MessageComposeResultSent) {
            [self showProgressHUDSuccessMessage:@"Shared via SMS"];
            
        } else if (result == MessageComposeResultFailed) {
            [self showProgressHUDFailureMessage:@"SMS failed to send"];
        }
    }];
}


#pragma mark - NSFetchedResultsControllerDelegate
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    // Override the logic on fetched video object's update to ensure section
    // header view is refreshed, and active video cell isn't reloaded
    if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext &&
        type == NSFetchedResultsChangeUpdate) {
        
        // Get the video and  refresh its corresponding section header view
        GRVVideo *video = (GRVVideo *)anObject;
        GRVVideoSectionHeaderView *headerView = [self.sectionHeaderViews objectForKey:video.hashKey];
        [self configureSectionHeaderView:headerView withVideo:video];
        
        if ([video.hashKey isEqualToString:self.activeVideo.hashKey]) {
            // on active cell, so be careful to not reload entire cell.
            [self configureCell:self.activeVideoCell withVideo:video];
        } else {
            // Fallback to superclass implementation for cases not handled
            [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
        }
        
    } else {
        // Fallback to superclass implementation for cases not handled
        [super controller:controller didChangeObject:anObject atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}


#pragma mark - Notification Observer Methods
/**
 * Media services were reset so reinitialize player
 */
- (void)mediaServicesWereReset:(NSNotification *)aNotification
{
    self.activeVideo = nil;
    self.activeVideoCell = nil;
    [self autoPlayVideo];
}


/**
 * Done playing item, advance to the next and add item back to the end of
 * playing queue. This way we implement infinite looping of player items and
 * prevent a black screen at the end of it all.
 */
- (void)playerItemDidReachEnd:(NSNotification *)notification
{
    AVPlayerItem *playedItem = [notification object];
    [playedItem seekToTime:kCMTimeZero];
    
    [self.player advanceToNextItem];
    [self.player insertItem:playedItem afterItem:nil];
    
    NSUInteger indexOfPlayedItem = [self.playerItems indexOfObject:playedItem];
    indexOfPlayedItem = (indexOfPlayedItem + self.activeVideoAnchorIndex) % [self.playerItems count];
    NSUInteger indexOfNextItem = (indexOfPlayedItem + 1) % [self.playerItems count];
    self.activeVideo.currentClipIndex = @(indexOfNextItem);
    
    if (playedItem == [self.playerItems firstObject]) {
        if (!self.skipNextPlayReporting) {
            [self.activeVideo play:nil];
        }
        self.skipNextPlayReporting = NO;
    }
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
            [self syncPlayerWithUI];
            [self attemptAutoPlay];
        });
      
    } else if (context == &PlayerRateContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncPlayerWithUI];
        });
        
    } else if (context == &PlayerCurrentItemContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self syncPlayerWithUI];
        });
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
    return;
}

/**
 * App entering background, so pause the player
 */
- (void)appDidEnterBackground
{
    [self pause];
}

/**
 * App entering foreground, so refresh content but don't reorder
 */
- (void)appWillEnterForeground
{
    [self refreshWithoutReorder];
}


#pragma mark - AVAudioSession Notification Observer Methods
/**
 * System's audio route changed
 *
 * Pause player (if playing) when headset is unplugged.
 */
- (void)audioRouteChange:(NSNotification *)notification
{
    // Reconfigure player volume to account for audio route changes
    [self configurePlayerVolume];
    
}


#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
{
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([vc isKindOfClass:[GRVMembersCDTVC class]]) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:kSegueIdentifierShowMembers]) {
            // prepare vc
            GRVMembersCDTVC *membersVC = (GRVMembersCDTVC *)vc;
            membersVC.video = video;
            
            // Don't refresh next time this vc appears
            self.skipRefreshOnNextAppearance = YES;
        }
        
    } else if ([vc isKindOfClass:[GRVLikersCDTVC class]]) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:kSegueIdentifierShowLikers]) {
            // prepare vc
            GRVLikersCDTVC *likersVC = (GRVLikersCDTVC *)vc;
            likersVC.video = video;
            
            // Don't refresh next time this vc appears
            self.skipRefreshOnNextAppearance = YES;
        }
        
    } else if ([vc isKindOfClass:[GRVAddClipCameraVC class]]) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:kSegueIdentifierAddClip]) {
            // prepare vc
            GRVAddClipCameraVC *cameraVC = (GRVAddClipCameraVC *)vc;
            cameraVC.video = video;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    
    } else if ([sender isKindOfClass:[UIButton class]]) {
        if ([segue.identifier isEqualToString:kSegueIdentifierAddClip]) {
            UIButton *addClipButton = (UIButton *)sender;
            indexPath = [NSIndexPath indexPathForItem:0 inSection:addClipButton.tag];

        } else {
            CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
            indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
        }
    }
    
    // Grab the destination View Controller
    id destinationVC = segue.destinationViewController;
    
    // Account for the destination VC being embedded in a UINavigationController
    // which happens when this is a modal presentation segue
    if ([destinationVC isKindOfClass:[UINavigationController class]]) {
        destinationVC = [((UINavigationController *)destinationVC).viewControllers firstObject];
    }
    
    [self prepareViewController:destinationVC
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailVC = [self.splitViewController.viewControllers lastObject];
    if ([detailVC isKindOfClass:[UINavigationController class]]) {
        detailVC = [((UINavigationController *)detailVC).viewControllers firstObject];
        [self prepareViewController:detailVC
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}

#pragma mark Modal Unwinding
/**
 * Added clip to the video.
 */
- (IBAction)addedClip:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[GRVAddClipCameraReviewVC class]]) {
         GRVAddClipCameraReviewVC *cameraReviewVC = (GRVAddClipCameraReviewVC *)segue.sourceViewController;
        
        // Set video's current index to start at the newly added clip
        GRVVideo *video = cameraReviewVC.video;
        GRVClip *addedClip = cameraReviewVC.addedClip;
        NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
        NSArray *clips = [video.clips sortedArrayUsingDescriptors:@[orderSd]];
        NSUInteger newClipIndex = 0;
        for (GRVClip *clip in clips) {
            if ([clip.identifier integerValue] == [addedClip.identifier integerValue]) {
                // Have found current clip
                break;
            }
            newClipIndex++;
        }
        video.currentClipIndex = @(newClipIndex);
        
        // Updated video is now at the top of the tableview, so scroll to top
        [self.tableView setContentOffset:CGPointMake(0.0, 0.0 - self.tableView.contentInset.top)
                                animated:YES];
        [self showProgressHUDSuccessMessage:@"Clip Added"];
        
        // Give video an order that ensures it appears at the top of the tableview
        // This works because when the viewWillAppear: method is called, a
        // video refresh is done without re-ordering the videos
        // However we need to ensure no two videos have this same special order,
        // So first re-order all videos loaded by the fetched results controller
        // then set a special video order for this
        [GRVVideo reorderVideos:self.fetchedResultsController.fetchedObjects];
        video.order = @(kGRVVideoOrderAddedClip);
        
        // Refresh recent contacts as that might have changed
        [GRVUser refreshFavorites:nil];
    }
}


@end
