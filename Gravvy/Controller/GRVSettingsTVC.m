//
//  GRVSettingsTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/19/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVSettingsTVC.h"
#import <MessageUI/MessageUI.h>
#import "GRVModelManager.h"

#pragma mark - Constants

/**
 * Constants for button indices in action sheets
 */
static const NSUInteger kTellAFriendMailButtonIndex = 0;    // Mail
static const NSUInteger kTellAFriendMessageButtonIndex = 1; // Message

/**
 * Constants for messages used to Tell Friends about the app
 */
static NSString *const kTellAFriendMailSubject = @"Gravvy iPhone App";
static NSString *const kTellAFriendMailBody = @"Hey,\n\nI just downloaded Gravvy on my iPhone.\n\nIt lets us create videos together.\n\nGet it now from http://gravvy.nnoduka.com and 'keep on playing'.";
static NSString *const kTellAFriendMessageBody = @"Check out Gravvy for your iPhone. Download it today from http://gravvy.nnoduka.com";

/**
 * Tell a friend action sheet title
 */
static NSString *const kTellAFriendActionSheetTitle = @"Tell a friend about Gravvy via...";

@interface GRVSettingsTVC () <UIActionSheetDelegate,
                                MFMailComposeViewControllerDelegate,
                                MFMessageComposeViewControllerDelegate>

#pragma mark - Properties
#pragma mark Outlets
// keep outlets to all cells in static table view so we know which is clicked.
@property (weak, nonatomic) IBOutlet UITableViewCell *profileCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *contactSupportCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *aboutCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *tellAFriendCell;

// Elements to be updated
@property (weak, nonatomic) IBOutlet UISwitch *soundsSwitch;


#pragma mark Private
// keep track of the multiple actionsheets so we know which we are handling
@property (strong, nonatomic) UIActionSheet *tellAFriendActionSheet;

@end

@implementation GRVSettingsTVC

#pragma mark - Properties
- (UIActionSheet *)tellAFriendActionSheet
{
    // lazy instantiation
    if (!_tellAFriendActionSheet) {
        _tellAFriendActionSheet = [[UIActionSheet alloc] initWithTitle:kTellAFriendActionSheetTitle
                                                              delegate:self
                                                     cancelButtonTitle:@"Cancel"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:@"Mail", @"Message", nil];
    }
    return _tellAFriendActionSheet;
}


#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Read sounds settings from storage
    self.soundsSwitch.on = [GRVModelManager sharedManager].userSoundsSetting;
}

#pragma mark - Instance Methods

#pragma mark - Target/Action Methods
- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleSoundsSetting:(UISwitch *)sender
{
    [GRVModelManager sharedManager].userSoundsSetting = sender.isOn;
}


#pragma mark Messaging Actions

// -------------------------------------------------------------------------------
//  showMailPicker:
//  Action for the Compose Mail button.
// -------------------------------------------------------------------------------
- (void)showMailPicker
{
    // You must check that the current device can send email messages before you
    // attempt to create an instance of MFMailComposeViewController.  If the
    // device can not send email messages,
    // [[MFMailComposeViewController alloc] init] will return nil.  Your app
    // will crash when it calls -presentViewController:animated:completion: with
    // a nil view controller.
    if ([MFMailComposeViewController canSendMail]) {
        // The device can send email.
        [self displayMailComposerSheet];
        
    } else {
        // The device can not send email.
        // This would be a good place to show a message saying device can't
        // send mail.
    }
}

// -------------------------------------------------------------------------------
//  showSMSPicker:
//  Action for the Compose SMS button.
// -------------------------------------------------------------------------------
- (IBAction)showSMSPicker
{
    // You must check that the current device can send SMS messages before you
    // attempt to create an instance of MFMessageComposeViewController.  If the
    // device can not send SMS messages,
    // [[MFMessageComposeViewController alloc] init] will return nil.  Your app
    // will crash when it calls -presentViewController:animated:completion: with
    // a nil view controller.
    if ([MFMessageComposeViewController canSendText]) {
        // The device can send email.
        [self displaySMSComposerSheet];
        
    } else {
        // The device can not send email.
        // This would be a good place to show a message saying device can't
        // send SMS.
    }
}

#pragma mark Compose Mail/SMS

// -------------------------------------------------------------------------------
//  displayMailComposerSheet
//  Displays an email composition interface inside the application.
//  Populates all the Mail fields.
// -------------------------------------------------------------------------------
- (void)displayMailComposerSheet
{
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:kTellAFriendMailSubject];
    
    // Set up recipients
    NSArray *toRecipients = @[];
    NSArray *ccRecipients = @[];
    NSArray *bccRecipients = @[];
    
    [picker setToRecipients:toRecipients];
    [picker setCcRecipients:ccRecipients];
    [picker setBccRecipients:bccRecipients];
    
    // Fill out the email body text
    NSString *emailBody = kTellAFriendMailBody;
    [picker setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:NULL];
}

// -------------------------------------------------------------------------------
//  displayMailComposerSheet
//  Displays an SMS composition interface inside the application.
// -------------------------------------------------------------------------------
- (void)displaySMSComposerSheet
{
    MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
    picker.messageComposeDelegate = self;
    
    // You can specify one or more preconfigured recipients.  The user has
    // the option to remove or add recipients from the message composer view
    // controller.
    /* picker.recipients = @[@"Phone number here"]; */
    
    // You can specify the initial message text that will appear in the message
    // composer view controller.
    picker.body = kTellAFriendMessageBody;
    
    [self presentViewController:picker animated:YES completion:NULL];
}


#pragma mark - MFMailComposeViewControllerDelegate

// -------------------------------------------------------------------------------
//  mailComposeController:didFinishWithResult:
//  Dismisses the email composition interface when users tap Cancel or Send.
//  Proceeds to update the message field with the result of the operation.
// -------------------------------------------------------------------------------
- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    // A good place to notify users about errors associated with the interface
    
    [self dismissViewControllerAnimated:YES completion:NULL];
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
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // get the selected cell
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Action to perform depends on clicked cell
    if (selectedCell == self.tellAFriendCell) {
        [self.tellAFriendActionSheet showInView:self.tableView];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.tellAFriendActionSheet) {
        // tell a friend about Gravvy either via Mail or SMS.
        switch (buttonIndex-actionSheet.firstOtherButtonIndex) {
            case kTellAFriendMailButtonIndex:
                [self showMailPicker];
                break;
                
            case kTellAFriendMessageButtonIndex:
                [self showSMSPicker];
                break;
                
            default:
                break;
        }
    }
}

@end
