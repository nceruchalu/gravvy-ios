//
//  GRVLikersCDTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/29/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVLikersCDTVC.h"
#import "GRVUser+HTTP.h"
#import "GRVUserViewHelper.h"
#import "GRVUserTableViewCell.h"
#import "GRVAccountManager.h"

#pragma mark - Constants
/**
 * Member display name string when member user is current app user
 */
static NSString *const kMemberDisplayNameMe = @"You";


@interface GRVLikersCDTVC ()

#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation GRVLikersCDTVC

#pragma mark - Properties
- (void)setVideo:(GRVVideo *)video
{
    _video = video;
    [self setupFetchedResultsController];
}

#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Silently refresh to pull in likers
    [self refresh];
}

#pragma mark - Instance Methods
#pragma mark Concrete
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVUser"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[ @"contact"];
        
        request.sortDescriptors = [GRVUserViewHelper userNameSortDescriptors];
        request.predicate = [NSPredicate predicateWithFormat:@"%@ IN likedVideos", self.video];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
    [self showOrHideEmptyStateView];
}

#pragma mark - Refresh
- (IBAction)refresh
{
    // Refresh activities from server
    [GRVUser refreshLikersOfVideo:self.video withCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
        });
    }];
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Liker Cell"; // get the cell
    GRVUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    // Configure the cell with data from the managed object
    GRVUser *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell...
    [self configureUserCell:cell usingUser:user];
    
    return cell;
}

#pragma mark Helpers
/**
 * Configure member cell using an EVTMember object
 */
- (void)configureUserCell:(GRVUserTableViewCell *)cell usingUser:(GRVUser *)user
{
    // Avatar first
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:user];
    cell.avatarView.thumbnail = avatarView.thumbnail;
    cell.avatarView.userInitials = avatarView.userInitials;
    
    // Display name
    BOOL memberIsMe = [user.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber];
    if (memberIsMe) {
        cell.displayNameLabel.text = kMemberDisplayNameMe;
    } else {
        cell.displayNameLabel.text = [GRVUserViewHelper userFullName:user];
    }
    
    // Phone number only displayed if in the address book
    if (user.contact || memberIsMe) {
        cell.phoneNumberLabel.text = [GRVUserViewHelper userPhoneNumber:user];
    } else {
        cell.phoneNumberLabel.text = @"";
    }
}


@end
