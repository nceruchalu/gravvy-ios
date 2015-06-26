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
#import "GRVUserViewHelper.h"
#import "GRVFormatterUtils.h"

#pragma mark - Constants
/**
 * Height of table view cell rows excluding the player view
 */
static CGFloat const kTableViewCellHeightNoPlayer = 153.0f;


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
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
    
    [self showOrHideEmptyStateView];
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Video Cell"; // get the cell
    GRVVideoTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    GRVVideo *video = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // Summary details first: Owner, Creation date and Play count
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:video.owner];
    cell.ownerAvatarView.thumbnail = avatarView.thumbnail;
    cell.ownerAvatarView.userInitials = avatarView.userInitials;
    
    cell.ownerNameLabel.text = [GRVUserViewHelper userFullNameOrPhoneNumber:video.owner];
    cell.createdAtLabel.text = [GRVFormatterUtils dayAndYearStringForDate:video.createdAt];
    cell.playsCountLabel.text = [GRVFormatterUtils numToString:video.playsCount];
    
    // Video details
    cell.titleLabel.text = video.title;
    
    NSString *likesCount = [GRVFormatterUtils numToString:video.likesCount];
    NSString *likesCountSuffix = ([video.likesCount integerValue] == 1) ? @"like" : @"likes";
    cell.likesCountLabel.text = [NSString stringWithFormat:@"%@ %@", likesCount, likesCountSuffix];
    
    NSString *likeButtonImageName = [video.liked boolValue] ? @"likeActive" : @"likeInactive";
    [cell.likeButton setImage:[UIImage imageNamed:likeButtonImageName] forState:UIControlStateNormal];
    
    // Configure the cell with data from the managed object
    return cell;
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
