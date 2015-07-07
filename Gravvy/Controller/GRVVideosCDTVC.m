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
#import "GRVVideoTableViewCell.h"
#import "GRVVideoSectionHeaderView.h"
#import "GRVUserViewHelper.h"
#import "GRVFormatterUtils.h"
#import "UIImageView+WebCache.h"
#import "GRVConstants.h"

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
 * Constants for the key-value observation context.
 */
static const NSString *PlayerItemStatusContext;
static const NSString *PlayerRateContext;
static const NSString *PlayerCurrentItemContext;

@interface GRVVideosCDTVC ()

#pragma mark - Properties
/**
 * All section header views stored in memory, with dictionary
 * keys being video hash keys and values being the views
 * This makes it easy to retrieve and update section headers without reloading
 * sections or the entire tableview
 */
@property (strong, nonatomic) NSMutableDictionary *sectionHeaderViews;

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
    [self refresh];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // Pause VC as we switch screen
    if (self.isPlaying) [self playOrPause];
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
    [self syncPlayerWithUI];
    
    // Get ordered clips of video
    // and creating an animated display
    NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    NSArray *clips = [self.activeVideo.clips sortedArrayUsingDescriptors:@[orderSd]];
    
    // Setup player items
    NSMutableArray *playerItems = [NSMutableArray array];
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
}

/**
 * When player is initially loaded attempt an autoplay the first time a player
 * item is ready to play
 */
- (void)attemptAutoPlay
{
    // Hide preview image of video cell
    self.activeVideoCell.previewImageView.hidden = YES;
    
    if (!self.performedAutoPlay) {
        if (!self.isPlaying) {
            [self playOrPause];
        }
        [self.activeVideo play];
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
    
    NSString *likeButtonImageName = [video.liked boolValue] ? @"likeActive" : @"likeInactive";
    [cell.likeButton setImage:[UIImage imageNamed:likeButtonImageName] forState:UIControlStateNormal];
    
    // if not on the active video's cell, show preview image so we don't see video
    // playing in reused cells
    cell.previewImageView.hidden = [self.activeVideo.hashKey isEqualToString:video.hashKey];
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
    headerView.playsCountLabel.text = [GRVFormatterUtils numToString:video.playsCount];
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
            [self autoPlayVideo];
        });
    }];
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
                    GRVVideoSectionHeaderView *headerView = self.sectionHeaderViews[video.hashKey];
                    [self configureSectionHeaderView:headerView withVideo:video];
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
    
    if (playedItem == [self.playerItems lastObject]) {
        [self.activeVideo play];
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


@end
