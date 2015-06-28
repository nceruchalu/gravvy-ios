//
//  GRVVideosCDTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideosCDTVC.h"
#import "GRVVideo+HTTP.h"
#import "GRVVideoTableViewCell.h"
#import "GRVVideoHeaderTableViewCell.h"
#import "GRVUserViewHelper.h"
#import "GRVFormatterUtils.h"
#import "UIImageView+WebCache.h"

#pragma mark - Constants
/**
 * Height of table view cell rows excluding the player view
 */
static CGFloat const kTableViewCellHeightNoPlayer = 99.0f;

/**
 * Table section header view's height
 */
static CGFloat const kTableViewSectionHeaderViewHeight = 54.0f;

/**
 * Table section footer view's height
 */
static CGFloat const kTableViewSectionFooterViewHeight = 8.0f;


@interface GRVVideosCDTVC ()

@end

@implementation GRVVideosCDTVC


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


#pragma mark - Instance Methods
#pragma mark Private
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVVideo"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[@"owner", @"clips"];
        
        // fetch all our videos so no predicate
        
        // Show latest videos first (updatedAt storted descending)
        NSSortDescriptor *updatedAtSort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
        request.sortDescriptors = @[updatedAtSort];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"hashKey" cacheName:nil];
        
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


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Video Cell"; // get the cell
    GRVVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Video details
    [cell.previewImageView sd_setImageWithURL:[NSURL URLWithString:video.photoThumbnailURL]];
    cell.titleLabel.text = video.title;
    
    NSString *likesCount = [GRVFormatterUtils numToString:video.likesCount];
    NSString *likesCountSuffix = ([video.likesCount integerValue] == 1) ? @"like" : @"likes";
    cell.likesCountLabel.text = [NSString stringWithFormat:@"%@ %@", likesCount, likesCountSuffix];
    
    NSString *likeButtonImageName = [video.liked boolValue] ? @"likeActive" : @"likeInactive";
    [cell.likeButton setImage:[UIImage imageNamed:likeButtonImageName] forState:UIControlStateNormal];
    
    // Configure the cell with data from the managed object
    return cell;
}


#pragma mark Sections
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    // Don't want an index list
    return nil;
}


#pragma mark - UITableViewDelegate
#pragma mark Custom Section Headers
/**
 * Custom section header using logic from: http://stackoverflow.com/a/11396643
 */
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    static NSString *cellIdentifier = @"Video Header Cell"; // get the cell
    GRVVideoHeaderTableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    // Get the video
    NSString *hashKey = [[[self.fetchedResultsController sections] objectAtIndex:section] name];
    GRVVideo *video = [GRVVideo videoWithVideoHashKey:hashKey inManagedObjectContext:self.managedObjectContext];
    
    // Create view with summary details: Owner, Creation date and Play count
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:video.owner];
    headerView.ownerAvatarView.thumbnail = avatarView.thumbnail;
    headerView.ownerAvatarView.userInitials = avatarView.userInitials;
    
    headerView.ownerNameLabel.text = [GRVUserViewHelper userFullNameOrPhoneNumber:video.owner];
    headerView.createdAtLabel.text = [GRVFormatterUtils dayAndYearStringForDate:video.createdAt];
    headerView.playsCountLabel.text = [GRVFormatterUtils numToString:video.playsCount];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kTableViewSectionHeaderViewHeight;
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


#pragma mark - Refresh
- (IBAction)refresh
{
    // Refresh videos from server
    [GRVVideo refreshVideos:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
        });
    }];
}

@end
