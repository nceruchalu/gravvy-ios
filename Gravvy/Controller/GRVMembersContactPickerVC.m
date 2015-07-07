//
//  GRVMembersContactPickerVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/7/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVMembersContactPickerVC.h"
#import "GRVMember+HTTP.h"
#import "GRVVideo.h"
#import "GRVUser.h"
#import "GRVModelManager.h"
#import "GRVConstants.h"
#import "GRVRestUtils.h"
#import "GRVHTTPManager.h"

#pragma mark - Constants
/**
 * Unwind Segue Identifier
 */
static NSString *const kUnwindSegueIdentifier = @"addedMembers";


@interface GRVMembersContactPickerVC ()

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@end

@implementation GRVMembersContactPickerVC

#pragma mark - Properties
- (void)setVideo:(GRVVideo *)video
{
    _video = video;
    [self configureExcludedUsers];
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self selectedContactsChanged];
}

#pragma mark - Instance Methods
#pragma mark Public (Overrides)
- (void)selectedContactsChanged
{
    [super selectedContactsChanged];
    self.addButton.enabled = ([self.selectedContacts count] > 0) && [GRVModelManager sharedManager].managedObjectContext;
}

#pragma mark Private
/**
 * Configure the excluded users to be all the video members
 */
- (void)configureExcludedUsers
{
    NSMutableArray *memberPhoneNumbers = [NSMutableArray array];
    for (GRVMember *videoMember in self.video.members) {
        [memberPhoneNumbers addObject:videoMember.user.phoneNumber];
    }
    self.excludedContactPhoneNumbers = [memberPhoneNumbers copy];
}


#pragma mark - Target/Action Methods
- (IBAction)cancel:(UIBarButtonItem *)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addContacts:(UIBarButtonItem *)sender
{
    // Create the video members JSON object
    NSMutableArray *videoMembersJSON = [NSMutableArray array];
    for (GRVUser *selectedUser in self.selectedContacts) {
        NSDictionary *phoneNumberJSON = @{kGRVRESTUserPhoneNumberKey : selectedUser.phoneNumber};
        [videoMembersJSON addObject:phoneNumberJSON];
    }
    
    // Generate complete video details parameters
    NSDictionary *parameters = @{kGRVRESTVideoUsersKey : videoMembersJSON};
    
    self.addButton.enabled = NO;
    
    // Hide keyboard if showing
    [self.view endEditing:YES];
    
    // inform user of server activity.
    [self startSpinner];
    
    NSString *videoMemberListURL = [GRVRestUtils videoMemberListURL:self.video.hashKey];
    
    // Now make request to add users to video
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodPOST
                                     forURL:videoMemberListURL
                                 parameters:parameters
                                    success:^(NSURLSessionDataTask *task, id responseObject)
    {
        // What we get in this response is a list of user objects
        // While I could try parsing this, it's a lot easier to
        // just refresh video members and pull the appropriate
        // member JSON objects.
        [GRVMember refreshMembersOfVideo:self.video withCompletion:^{
            // No need to refresh create button or
            // stop spinner as we unwind VC
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSegueWithIdentifier:kUnwindSegueIdentifier sender:self];
            });
        }];
    }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject)
    {
        [GRVHTTPManager alertWithFailedResponse:nil
                             withAlternateTitle:@"Couldn't update video"
                                     andMessage:@"Contacts could not be invited to video."];
        
        // refresh create button
        [self selectedContactsChanged];
        
        // inform user server activity is done
        [self stopSpinner];
    }];
}


@end
