//
//  GRVMembersCDTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/6/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVMembersCDTVC.h"
#import "GRVVideo+HTTP.h"
#import "GRVMember+HTTP.h"
#import "GRVUserViewHelper.h"
#import "GRVMemberTableViewCell.h"
#import "GRVAccountManager.h"
#import "GRVUser.h"
#import "GRVMembersContactPickerVC.h"

#pragma mark - Constants
/**
 * Member display name string when member user is current app user
 */
static NSString *const kMemberDisplayNameMe = @"You";

/**
 * Segue identifier to show contact picker
 */
static NSString *const kSegueIdentifierShowContactPicker = @"showInvitePeopleVC";

/**
 * button indices in member action sheet
 */
static const NSInteger kMemberButtonIndexCall       = 0; // Call user


@interface GRVMembersCDTVC () <UIActionSheetDelegate>

#pragma mark - Properties

#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;


#pragma mark Member Actions
/**
 * Currently tracked row of members section. This is used for performing actions
 * on current members, such as removing from video.
 */
@property (strong, nonatomic) NSIndexPath *currentMemberIndexPath;

/**
 * Action sheet shown on member selection
 */
@property (strong, nonatomic) UIActionSheet *memberActionSheet;
/**
 * Action Sheet to confirm member removal
 */
@property (strong, nonatomic) UIActionSheet *removeConfirmationActionSheet;

@end


@implementation GRVMembersCDTVC

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
    
    // Silently refresh to pull in recent activities
    [self refresh];
}

#pragma mark - Instance Methods
#pragma mark Concrete
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVMember"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[@"user", @"user.contact"];
        
        request.sortDescriptors = [GRVUserViewHelper userNameSortDescriptorsWithRelationshipKey:@"user"];
        request.predicate = [NSPredicate predicateWithFormat:@"video == %@", self.video];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
    
    [self showOrHideEmptyStateView];
}

#pragma mark Private
/**
 * Is app user this video's owner?
 */
- (BOOL)isVideoOwner
{
    return [self.video.owner.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber];
}


#pragma mark - Refresh
- (IBAction)refresh
{
    // Refresh activities from server
    [GRVMember refreshMembersOfVideo:self.video withCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
            // Reload table to reflect changes in the activities' related objects
            [self.tableView reloadData];
        });
    }];
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Member Cell"; // get the cell
    GRVMemberTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    // Configure the cell with data from the managed object
    GRVMember *member = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell...
    [self configureMemberCell:cell usingMember:member];
    
    return cell;
}

#pragma mark Helpers
/**
 * Configure member cell using an EVTMember object
 */
- (void)configureMemberCell:(GRVMemberTableViewCell *)cell usingMember:(GRVMember *)member
{
    // Avatar first
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:member.user];
    cell.avatarView.thumbnail = avatarView.thumbnail;
    cell.avatarView.userInitials = avatarView.userInitials;
    
    // Display name
    if ([member.user.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber]) {
        cell.displayNameLabel.text = kMemberDisplayNameMe;
    } else {
        cell.displayNameLabel.text = [GRVUserViewHelper userFullName:member.user];
    }
    
    // Phone number
    cell.phoneNumberLabel.text = [GRVUserViewHelper userPhoneNumber:member.user];
}

#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
{
    if ([vc isKindOfClass:[GRVMembersContactPickerVC class]]) {
        if (![segueIdentifier length] || [segueIdentifier isEqualToString:kSegueIdentifierShowContactPicker]) {
            // prepare vc
            GRVMembersContactPickerVC *contactPickerVC = (GRVMembersContactPickerVC *)vc;
            contactPickerVC.video = self.video;
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
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
        
    } else {
        // This is on the iPhone, so check for taps on video members
        self.currentMemberIndexPath = indexPath;
        GRVMember *videoMember = [self.fetchedResultsController objectAtIndexPath:indexPath];
        NSString *memberShortName = [GRVUserViewHelper userFirstNameOrPhoneNumber:videoMember.user];
        
        NSString *callMemberTitle = [NSString stringWithFormat:@"Call %@", memberShortName];
        NSString *destructiveButtonTitle = [NSString stringWithFormat:@"Remove %@", memberShortName];
        
        // Video owner gets a different view of the members action sheet
        if ([self isVideoOwner]) {
            self.memberActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:callMemberTitle, destructiveButtonTitle, nil];
            self.memberActionSheet.destructiveButtonIndex = (self.memberActionSheet.numberOfButtons-2);
            
        } else {
            self.memberActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:callMemberTitle, nil];
        }
        
        
        
        // Only show this action sheet if I didnt click on myself
        if (![[GRVAccountManager sharedManager].phoneNumber isEqualToString:videoMember.user.phoneNumber]) {
            [self.memberActionSheet showInView:self.view];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Modal Unwinding
/**
 * Invited users to the video. Nothing to do here really as we use an
 * NSFetchedResultsController that will pick up any new members
 */
- (IBAction)addedMembers:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[GRVMembersContactPickerVC class]]) {
        //GRVMembersContactPickerVC *contactPickerVC = (GRVMembersContactPickerVC *)segue.sourceViewController;
    }
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Get member object
    NSIndexPath *indexPath = [self mapIndexPathToFetchedResultsController:self.currentMemberIndexPath];
    GRVMember *videoMember = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    if (actionSheet == self.memberActionSheet) {
        // is this a revoke request on a member? if so show a confirmation action
        // sheet
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            NSString *userFirstName = [GRVUserViewHelper userFirstNameOrPhoneNumber:videoMember.user];
            NSString *confirmationTitle;
            if ([self.video.title length]) {
                confirmationTitle = [NSString stringWithFormat:@"Remove %@ from the \"%@\" video?", userFirstName, self.video.title];
            } else {
                confirmationTitle = [NSString stringWithFormat:@"Remove %@ from the video?", userFirstName];
            }

            self.removeConfirmationActionSheet = [[UIActionSheet alloc] initWithTitle:confirmationTitle
                                                                             delegate:self
                                                                    cancelButtonTitle:@"Cancel"
                                                               destructiveButtonTitle:@"Remove"
                                                                    otherButtonTitles:nil];
            [self.removeConfirmationActionSheet showInView:self.view];
            
        } else if (buttonIndex != actionSheet.cancelButtonIndex) {
            switch (buttonIndex-actionSheet.firstOtherButtonIndex) {
                case kMemberButtonIndexCall:
                    [self callMember:videoMember];
                    break;
                    
                default:
                    break;
            }
        }
        
    } else if (actionSheet == self.removeConfirmationActionSheet) {
        
        // check if user confirmed desire to revoke a user's membership
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // user indeed wants to revoke a given user's video membership
            [self revokeMembership:videoMember];
        }
    }
}

#pragma mark Helpers
/**
 * Revoke membership of video member
 */
- (void)revokeMembership:(GRVMember *)videoMember
{
    [self.spinner startAnimating];
    [self.video revokeMembership:videoMember withCompletion:^{
        [self.spinner stopAnimating];
    }];
}

/**
 * Call video member
 */
- (void)callMember:(GRVMember *)videoMember
{
    NSString *phoneNumber = [NSString stringWithFormat:@"tel:%@", videoMember.user.phoneNumber];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:phoneNumber]];
}


@end
