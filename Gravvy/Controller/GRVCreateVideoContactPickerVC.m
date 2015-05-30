//
//  GRVCreateVideoContactPickerVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCreateVideoContactPickerVC.h"
#import "GRVModelManager.h"
#import "GRVHTTPManager.h"
#import "GRVUser.h"

#pragma mark - Constants
/**
 * Unwind Segue Identifier
 */
static NSString *const kUnwindSegueIdentifier = @"createdVideo";

@interface GRVCreateVideoContactPickerVC ()

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem *createButton;

@end

@implementation GRVCreateVideoContactPickerVC

#pragma mark - Instance Methods
#pragma mark Public (Overrides)
- (void)selectedContactsChanged
{
    [super selectedContactsChanged];
    self.createButton.enabled = ([self.selectedContacts count] > 0) && [GRVModelManager sharedManager].managedObjectContext;
}


#pragma mark - Target/Action Methods
- (IBAction)createVideo:(UIBarButtonItem *)sender
{
    // Create the video users JSON object
    NSMutableArray *videoUsersJSON = [NSMutableArray array];
    for (GRVUser *selectedUser in self.selectedContacts) {
        NSDictionary *phoneNumberJSON = @{kGRVRESTUserPhoneNumberKey : selectedUser.phoneNumber};
        [videoUsersJSON addObject:phoneNumberJSON];
    }
    
    // Key for the duration object in the lead clip
    NSString *durationKey = [NSString stringWithFormat:@"%@.%@", kGRVRESTVideoLeadClipKey, kGRVRESTClipDurationKey];
    // Parameters required for video upload
    
    NSMutableDictionary *parameters = [@{durationKey: @(self.duration),
                                         kGRVRESTVideoUsersKey: videoUsersJSON} mutableCopy];
    if ([self.videoTitle length]) {
        parameters[kGRVRESTVideoTitleKey] = self.videoTitle;
    }
    
    // temporarily disable create button
    self.createButton.enabled = NO;
    
    // Hide keyboard if showing
    [self.view endEditing:YES];
    
    // inform user of server activity.
    [self startSpinner];
    
    // Upload video to the server
    [[GRVHTTPManager sharedManager] operationRequest:GRVHTTPMethodPOST
                                              forURL:kGRVRESTVideos
                                          parameters:[parameters copy]
                           constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                               
                               // Keys for mp4 and photo object in request
                               NSString *mp4Key = [NSString stringWithFormat:@"%@.%@", kGRVRESTVideoLeadClipKey, kGRVRESTClipMp4Key];
                               NSString *photoKey = [NSString stringWithFormat:@"%@.%@", kGRVRESTVideoLeadClipKey, kGRVRESTClipPhotoKey];
                               
                               // Come up with a random file name. Doesn't have
                               // to be unique as the server will handle that
                               NSString *baseFileName = [[[NSUUID UUID] UUIDString] substringToIndex:8];
                               NSString *mp4FileName = [NSString stringWithFormat:@"%@.mp4", baseFileName];
                               NSString *photoFileName = [NSString stringWithFormat:@"%@.jpg", baseFileName];
                               
                               [formData appendPartWithFileData:self.mp4
                                                           name:mp4Key
                                                       fileName:mp4FileName
                                                       mimeType:@"video/mp4"];
                               [formData appendPartWithFileData:UIImageJPEGRepresentation(self.previewImage, 0.4f)
                                                           name:photoKey
                                                       fileName:photoFileName
                                                       mimeType:@"image/jpeg"];
                           }
                                             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                 // TODO: Sync new video
                                                 
                                                 // No need to refresh create button or
                                                 // stop spinner as we unwind VC
                                                 [self performSegueWithIdentifier:kUnwindSegueIdentifier sender:self];
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [GRVHTTPManager alertWithFailedResponse:nil withAlternateTitle:@"Can't create video." andMessage:@"Something went wrong. Please try again."];
                                                 
                                                 // refresh create button
                                                 [self selectedContactsChanged];
                                                 
                                                 // inform user server activity is done
                                                 [self stopSpinner];
                                             }
                                 operationDependency:nil];
}

@end
