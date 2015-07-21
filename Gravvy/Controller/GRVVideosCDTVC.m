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
#import "GRVUser.h"
#import "GRVVideoTableViewCell.h"
#import "GRVVideoSectionHeaderView.h"
#import "GRVUserViewHelper.h"
#import "GRVFormatterUtils.h"
#import "UIImageView+WebCache.h"
#import "GRVConstants.h"
#import "GRVMembersCDTVC.h"
#import "GRVAddClipCameraReviewVC.h"
#import "GRVAddClipCameraVC.h"
#import "GRVAccountManager.h"
#import "MBProgressHUD.h"

#import <FBSDKShareKit/FBSDKShareKit.h>
#import <FBSDKCoreKit/FBSDKConstants.h>
#import <Social/Social.h>
#import <MessageUI/MessageUI.h>

#pragma mark - Constants
/**
 * Height of table view cell rows excluding the player view
 * Including 8 pts for the content view's bottom padding
 */
static CGFloat const kTableViewCellHeightNoPlayer = 107.0f;

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
 * Segue identifier for showing Members TVC
 */
static NSString *const kSegueIdentifierShowMembers = @"showMembersVC";

/**
 * Segue identifier for showing Add Clip Camera VC
 */
static NSString *const kSegueIdentifierAddClip = @"showAddClipCameraVC";

/** 
 * Constants for the key-value observation context.
 */
static const NSString *PlayerItemStatusContext;
static const NSString *PlayerRateContext;
static const NSString *PlayerCurrentItemContext;

/**
 * button indices in more actions action sheet
 */
static const NSInteger kMoreActionsIndexShareFacebook   = 0; // Share on facebook
static const NSInteger kMoreActionsIndexShareTwitter    = 1; // Share on twitter
static const NSInteger kMoreActionsIndexShareSMS        = 2; // Share via SMS
static const NSInteger kMoreActionsIndexCopyLink        = 3; // Copy link

/**
 * Format string for creating a video's share URL
 */
static NSString *const kVideoShareURLFormatString = @"http://gravvy.nnoduka.com/v/%@/";


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
 * Skip refresh table view next time Table View appears
 */
@property (nonatomic) BOOL skipRefreshOnNextAppearance;

/**
 * Currently active video and video cell which might or might not be playing
 */
@property (strong, nonatomic) GRVVideo *activeVideo;
@property (strong, nonatomic) GRVVideoTableViewCell *activeVideoCell;

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

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Setup height of each tableview row
    CGFloat playerViewHeight = self.view.frame.size.width;
    self.tableView.rowHeight = kTableViewCellHeightNoPlayer + playerViewHeight;
    
    // Hide separator insets
    self.tableView.separatorColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Silently refresh to pull in recent video updates
    if (!self.skipRefreshOnNextAppearance) {
        [self refresh];
    }
    self.skipRefreshOnNextAppearance = NO;
    
    // register observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(mediaServicesWereReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
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
    
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVAudioSessionMediaServicesWereResetNotification
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
}


#pragma mark - Instance Methods
#pragma mark Private
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVVideo"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[@"owner", @"clips"];
        
        // fetch all ordered videos
        request.predicate = [NSPredicate predicateWithFormat:@"order > %d", kGRVVideoOrderNew];
        
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
 * Reload contents of tableview, but first cancel all downloads before doing so
 * to prevent hanging
 */
- (void)refreshTableView
{
    [[SDWebImageManager sharedManager] cancelAll];
    [self.tableView reloadData];
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
    
    // Get ordered clips of video
    // and creating an animated display
    NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    NSArray *clips = [self.activeVideo.clips sortedArrayUsingDescriptors:@[orderSd]];
    
    // Setup player items
    NSMutableArray *playerItems = [NSMutableArray array];
    for (GRVClip *clip in clips) {
        if (clip.mp4URL) {
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
        }
    }
    // Cache new player items while removing observers for old player items
    // and old player
    self.playerItems = [playerItems copy];
    
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
        [self configureCell:self.activeVideoCell withCurrentClip:(currentClipIndex+1) andClipsCount:[self.playerItems count]];
    } else {
        [self configureCell:self.activeVideoCell withCurrentClip:1 andClipsCount:[self.activeVideo.clips count]];
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
        if (([self.activeVideo.unseenLikesCount integerValue] > 0) ||
            ([self.activeVideo.unseenClipsCount integerValue] > 0) ||
            ([self.activeVideo.membership integerValue] <= GRVVideoMembershipInvited)) {
            [self.activeVideo clearNotifications:^{
                [self.activeVideo refreshVideo:nil];
            }];
        } else {
            [self.activeVideo refreshVideo:nil];
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
    // Video details
    [cell.previewImageView sd_setImageWithURL:[NSURL URLWithString:video.photoThumbnailURL]];
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
        [self configureCell:cell withCurrentClip:1 andClipsCount:[video.clips count]];
    }
    
}

- (void)configureCell:(GRVVideoTableViewCell *)cell
      withCurrentClip:(NSUInteger)currentClipIndex
        andClipsCount:(NSUInteger)clipsCount
{
    cell.currentClipIndexLabel.text = [NSString stringWithFormat:@"%lu/%lu", (unsigned long)currentClipIndex, (unsigned long)clipsCount];
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
    //headerView.createdAtLabel.text = [GRVFormatterUtils dayAndYearStringForDate:video.createdAt];
    headerView.createdAtLabel.text = [NSString stringWithFormat:@"mem:%@ | par:%@ | unC:%@ | unL:%@ | sco:%@", video.membership, video.participation, video.unseenClipsCount, video.unseenLikesCount, video.score];
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
 * isn't already playing
 */
- (void)scrollViewDoneScrolling
{
    [self autoPlayVideo];
}

#pragma mark - Refresh
- (IBAction)refresh
{
    self.suspendAutomaticTrackingOfChangesInManagedObjectContext = YES;
    // Refresh videos from server
    [GRVVideo refreshVideos:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
            self.suspendAutomaticTrackingOfChangesInManagedObjectContext = NO;
            [self.tableView reloadData];
            
            self.activeVideo = nil;
            self.activeVideoCell = nil;
            [self autoPlayVideo];
        });
    }];
}

- (void)refreshAndShowSpinner
{
    [self.refreshControl beginRefreshing];
    [self.tableView setContentOffset:CGPointMake(0, 0.0 - self.tableView.contentInset.top - self.refreshControl.frame.size.height) animated:YES];
    [self refresh];
}


#pragma mark - Target/Action Methods
- (IBAction)playOrPause
{
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

- (IBAction)addClip:(UIButton *)sender
{
    // quit if camera is not available for recording videos
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    // Stop player before continuing
    [self stop];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Give the avplayer cleanup some time to occur before presenting camera VC
        [self performSegueWithIdentifier:kSegueIdentifierAddClip sender:sender];
    });
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
    } else {
        destructiveButtonTitle = @"Remove Video";
    }
    
    self.moreActionsActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:destructiveButtonTitle, nil];
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
                case kMoreActionsIndexShareFacebook:
                    [self shareOnFacebook:video];
                    break;
                    
                case kMoreActionsIndexShareTwitter:
                    [self shareOnTwitter:video];
                    break;
                    
                case kMoreActionsIndexShareSMS:
                    [self shareViaSMS:video];
                    break;
                    
                case kMoreActionsIndexCopyLink:
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
                destructiveButtonTitle = @"Remove Video";
            }
            
            self.removeConfirmationActionSheet = [[UIActionSheet alloc] initWithTitle:@"Confirm Deletion"
                                                                             delegate:self
                                                                    cancelButtonTitle:@"Cancel"
                                                               destructiveButtonTitle:destructiveButtonTitle
                                                                    otherButtonTitles:nil];
            [self.removeConfirmationActionSheet showInView:self.view];
        }
        
    } else if (actionSheet == self.removeConfirmationActionSheet) {
        
        // check if user confirmed desire to leave/delete a video
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // user indeed wants to leave/delete a video
            
            [self.spinner startAnimating];
            [video revokeMembershipWithCompletion:^{
                [self.spinner stopAnimating];
                [self refresh];
            }];
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
    // If this is the currently active row, then don't allow a reload
    GRVVideo *video = (GRVVideo *)anObject;
    if ([video.hashKey isEqualToString:self.activeVideo.hashKey]) {
        // on active cell, so be careful to not reload entire cell.
        // Update header and cell when object updates
        indexPath = [self mapIndexPathFromFetchedResultsController:indexPath];
        newIndexPath = [self mapIndexPathFromFetchedResultsController:newIndexPath];
        
        if (!self.suspendAutomaticTrackingOfChangesInManagedObjectContext) {
            switch (type) {
                case NSFetchedResultsChangeInsert:
                    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                          withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeDelete:
                    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                          withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                case NSFetchedResultsChangeUpdate:
                {
                    //GRVVideoSectionHeaderView *headerView = self.sectionHeaderViews[video.hashKey];
                    //[self configureSectionHeaderView:headerView withVideo:video];
                    [self configureCell:self.activeVideoCell withVideo:video];
                }
                    break;
                    
                case NSFetchedResultsChangeMove:
                    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                          withRowAnimation:UITableViewRowAnimationFade];
                    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                          withRowAnimation:UITableViewRowAnimationFade];
                    break;
                    
                default:
                    break;
            }
        }

    } else {
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
    
    if (playedItem == [self.playerItems firstObject]) {
        [self.activeVideo play:nil];
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
        //GRVAddClipCameraReviewVC *cameraReviewVC = (GRVAddClipCameraReviewVC *)segue.sourceViewController;
        // Updated video is now at the top of the tableview, so scroll to top
        [self.tableView setContentOffset:CGPointMake(0.0, 0.0 - self.tableView.contentInset.top)
                                animated:YES];
        [self showProgressHUDSuccessMessage:@"Clip Added"];
    }
}


@end
