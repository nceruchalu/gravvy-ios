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
#import "GRVUserTableViewCell.h"
#import "GRVAccountManager.h"
#import "GRVUser.h"
#import "GRVMembersContactPickerVC.h"
#import "MBProgressHUD.h"
#import <MessageUI/MessageUI.h>

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
static const NSInteger kMemberButtonIndexMessage = 0; // SMS user


@interface GRVMembersCDTVC () <UIActionSheetDelegate,
                                MFMessageComposeViewControllerDelegate>

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

@property (strong, nonatomic) MBProgressHUD *successProgressHUD;
@property (strong, nonatomic) MBProgressHUD *failureProgressHUD;

@end


@implementation GRVMembersCDTVC

#pragma mark - Properties
- (void)setVideo:(GRVVideo *)video
{
    _video = video;
    [self setupFetchedResultsController];
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


#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Silently refresh to pull in members
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

#pragma mark - Refresh
- (IBAction)refresh
{
    // Refresh activities from server
    [GRVMember refreshMembersOfVideo:self.video withCompletion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
            // Reload table to reflect changes in the members' related objects
            [self.tableView reloadData];
        });
    }];
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Member Cell"; // get the cell
    GRVUserTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
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
- (void)configureMemberCell:(GRVUserTableViewCell *)cell usingMember:(GRVMember *)member
{
    // Avatar first
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:member.user];
    cell.avatarView.thumbnail = avatarView.thumbnail;
    cell.avatarView.userInitials = avatarView.userInitials;
    
    // Display name
    BOOL memberIsMe = [member.user.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber];
    if (memberIsMe) {
        cell.displayNameLabel.text = kMemberDisplayNameMe;
    } else {
        cell.displayNameLabel.text = [GRVUserViewHelper userFullName:member.user];
    }
    
    // Phone number only displayed if in the address book
    if (member.user.contact || memberIsMe) {
        cell.phoneNumberLabel.text = [GRVUserViewHelper userPhoneNumber:member.user];
    } else {
        cell.phoneNumberLabel.text = @"";
    }
    
    // Cell can only be selected if in address book, or I'm the video owner
    // but not me
    if (([self isVideoOwner] || member.user.contact) && !memberIsMe) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        cell.selectionStyle = UITableViewCellEditingStyleNone;
    }
   
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
        
        NSString *messageMemberTitle = [NSString stringWithFormat:@"Message %@", memberShortName];
        NSString *destructiveButtonTitle = [NSString stringWithFormat:@"Remove %@", memberShortName];
        
        // Can only show message member if in address book
        // Video owner gets a different view of the members action sheet
        self.memberActionSheet = nil;
        if ([self isVideoOwner]) {
            if (videoMember.user.contact) {
                self.memberActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:messageMemberTitle, destructiveButtonTitle, nil];
            } else {
                self.memberActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:destructiveButtonTitle, nil];
            }
            self.memberActionSheet.destructiveButtonIndex = (self.memberActionSheet.numberOfButtons-2);
            
        } else if (videoMember.user.contact) {
            self.memberActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:messageMemberTitle, nil];
        }
        
        
        // Only show this action sheet if I didnt click on myself
        BOOL videoMemberIsMe = [[GRVAccountManager sharedManager].phoneNumber isEqualToString:videoMember.user.phoneNumber];
        if (!videoMemberIsMe) {
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
        [self showProgressHUDSuccessMessage:@"Success"];
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
                case kMemberButtonIndexMessage:
                    [self messageMember:videoMember];
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
 * Message video member
 */
- (void)messageMember:(GRVMember *)videoMember
{
    // You must check that the current device can send SMS messages before you
    // attempt to create an instance of MFMessageComposeViewController.  If the
    // device can not send SMS messages,
    // [[MFMessageComposeViewController alloc] init] will return nil.  Your app
    // will crash when it calls -presentViewController:animated:completion: with
    // a nil view controller.
    if ([MFMessageComposeViewController canSendText]) {
        // The device can send SMS.
        MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
        picker.messageComposeDelegate = self;
        [picker.navigationBar setTintColor:[UIColor whiteColor]];
        
        // You can specify one or more preconfigured recipients.  The user has
        // the option to remove or add recipients from the message composer view
        // controller.
        picker.recipients = @[videoMember.user.phoneNumber];
        
        [self presentViewController:picker animated:YES completion:NULL];
        
    } else {
        // The device can not send SMS.
        [self showProgressHUDFailureMessage:@"Device can't send SMS"];
    }
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
        if (result == MessageComposeResultFailed) {
            [self showProgressHUDFailureMessage:@"SMS failed to send"];
        }
    }];
}



@end
