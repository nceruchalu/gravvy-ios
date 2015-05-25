//
//  GRVProfileSettingsTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVProfileSettingsTVC.h"
#import "GRVAccountManager.h"
#import "GRVFormatterUtils.h"
#import "GRVHTTPManager.h"
#import "GRVConstants.h"
#import "GRVUser+HTTP.h"
#import "GRVModelManager.h"

#pragma mark - Constants
/**
 * Input border thickness
 */
const CGFloat kInputBorderThickness         = 1.0f;

/**
 * Input field border color
 */
#define kInputBorderColor [UIColor colorWithRed:212.0/255.0 green:212.0/255.0 blue:212.0/255.0 alpha:1.0]

/**
 * Avatar button corner radius: half of avatar button diameter
 */
const CGFloat kAvatarButtonCornerRadius     = 29.5f;

/**
 * Constants for button indices in action sheets
 */
static const NSInteger kAddPhotoTakeButtonIndex     = 0; // Take Photo
static const NSInteger kAddPhotoChooseButtonIndex   = 1; // Choose Existing

@interface GRVProfileSettingsTVC () <UIActionSheetDelegate,
                                        UINavigationControllerDelegate,
                                        UIImagePickerControllerDelegate,
                                        UITextFieldDelegate>

#pragma mark - Properties

#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIButton *avatarButton;
@property (weak, nonatomic) IBOutlet UITextField *displayNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

#pragma mark Private

// cache the values that come from the server so we can easily revert
// to this when necessary
@property (strong, nonatomic) UIImage *avatar;

// keep track of the multiple actionsheets so we know which we are handling
// Action sheet to modify avatar photo
@property (strong, nonatomic) UIActionSheet *addPhotoActionSheet;
// Action Sheet to confirm deletion
@property (strong, nonatomic) UIActionSheet *deleteConfirmationSheet;

@end

@implementation GRVProfileSettingsTVC

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // setup delegates
    self.displayNameTextField.delegate = self;
    
    // See `tableView:heightForHeaderInSection:` for why we hide an extra 1.0f
    self.tableView.contentInset = UIEdgeInsetsMake(-1.0f, 0.0f, 0.0f, 0.0f);
    
    // make avatarButton rounded and with a border
    self.avatarButton.layer.cornerRadius = kAvatarButtonCornerRadius;
    self.avatarButton.clipsToBounds = YES;
    self.avatarButton.layer.borderWidth = kInputBorderThickness;
    self.avatarButton.layer.borderColor = kInputBorderColor.CGColor;
    
    // setup avatar, username, display name, email
    [self populateProfileDetails];
}


#pragma mark - Instance Methods
#pragma mark Abstract
- (void)doneUpdatingName
{
    // Abstract. Do nothing.
}


#pragma mark Private
/**
 * Setup the View Controller's fields (avatar, display name) with data from
 * web servers.
 * Also cache these values in local instance variables to use in undoing changes
 * made during edit mode.
 */
- (void)populateProfileDetails
{
    // setup phone number that can't be edited
    self.phoneNumberLabel.text = [GRVFormatterUtils formatPhoneNumber:[GRVAccountManager sharedManager].phoneNumber
                                                         numberFormat:NBEPhoneNumberFormatNATIONAL
                                                        defaultRegion:[GRVAccountManager sharedManager].regionCode
                                                                error:NULL];
    
    self.displayNameTextField.enabled = NO;
    
    // get personal data (i.e. email from server)
    [self.spinner startAnimating];
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodGET
                                     forURL:kGRVRESTUser
                                 parameters:nil
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        // only enable text field if we have this data.
                                        self.displayNameTextField.enabled = YES;
                                        
                                        // Refresh VC elements
                                        [self refreshWithUserDictionary:responseObject];
                                        
                                        [self.spinner stopAnimating];
                                    }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                        // do nothing
                                        [self.spinner stopAnimating];
                                    }];
}


/**
 * Refresh VC with given User JSON object
 *
 * @param userDictionary        user JSON object as returned by the webserver
 */
- (void)refreshWithUserDictionary:(NSDictionary *)userDictionary
{
    // Refresh corresponding user object if there's a context
    NSManagedObjectContext *context = [GRVModelManager sharedManager].managedObjectContext;
    if (context) {
        GRVUser *correspondingUser = [GRVUser userWithUserInfo:userDictionary inManagedObjectContext:context];
        [correspondingUser updateThumbnailImage];
    }
    
    // set display name from server
    self.displayName = [userDictionary objectForKey:kGRVRESTUserFullNameKey];
    self.displayNameTextField.text = self.displayName;
    
    // Populate profile avatar
    NSString *avatarThumbnailURL = [userDictionary objectForKey:kGRVRESTUserAvatarThumbnailKey];
    if ([avatarThumbnailURL length]) {
        [[GRVHTTPManager sharedManager] imageFromURL:avatarThumbnailURL
                                             success:^(UIImage *image)
         {
             self.avatar = image;
             [self.avatarButton setImage:image forState:UIControlStateNormal];
         }
                                             failure:nil];
    } else {
        self.avatar = nil;
        [self.avatarButton setImage:nil forState:UIControlStateNormal];
    }
}


#pragma mark Public
- (void)undoProfileChanges
{
    // revert changes
    self.displayNameTextField.text = self.displayName;
    [self.avatarButton setImage:self.avatar forState:UIControlStateNormal];
}

/**
 * Update the profile's display name on the server using data in View Controller
 */
- (void)updateUserDisplayName
{
    // save changes
    NSString *newDisplayName = self.displayNameTextField.text;
    
    NSDictionary *parameters = @{kGRVRESTUserFullNameKey : newDisplayName};
    
    [self.spinner startAnimating];
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodPUT
                                     forURL:kGRVRESTUser
                                 parameters:parameters
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        [self.spinner stopAnimating];
                                        // save this name in the local cache
                                        self.displayName = [responseObject objectForKey:kGRVRESTUserFullNameKey];
                                        [self doneUpdatingName];
                                    }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                        [self.spinner stopAnimating];
                                        [GRVHTTPManager alertWithFailedResponse:responseObject withAlternateTitle:@"Couldn't update profile" andMessage:@"That name didn't seem to work."];
                                    }];
}


#pragma mark Target/Action methods
- (IBAction)addAvatar:(UIButton *)sender
{
    NSString *destructiveButtonTitle = self.avatar ? @"Delete" : nil;
    // save this action sheet for future reference
    self.addPhotoActionSheet =[[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"Take Photo", @"Choose Existing", destructiveButtonTitle,  nil];
    if (destructiveButtonTitle) {
        self.addPhotoActionSheet.destructiveButtonIndex = (self.addPhotoActionSheet.numberOfButtons-2);
    }
    [self.addPhotoActionSheet showInView:self.view];
}

/**
 * Update user's avatar on the server
 *
 * @param image     new source image for user's avatar. If this is nil then avatar
 *      is deleted
 */
- (void)uploadUserAvatar:(UIImage *)image
{
    if (image) {
        // there's an image to upload
        [self.spinner startAnimating];
        [[GRVHTTPManager sharedManager] operationRequest:GRVHTTPMethodPATCH
                                                  forURL:kGRVRESTUser
                                              parameters:nil
                               constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                   
                                   // Come up with a random file name. Doesn't have to be
                                   // unique as the server will handle that
                                   NSString *fileName = @"avatar.jpg";
                                   [formData appendPartWithFileData:UIImageJPEGRepresentation(image, 0.4f)
                                                               name:kGRVRESTUserAvatarKey
                                                           fileName:fileName
                                                           mimeType:@"image/jpeg"];
                               }
                                                 success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                                     [self.spinner stopAnimating];
                                                     [self refreshWithUserDictionary:responseObject];
                                                 }
                                                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                     [self.spinner stopAnimating];
                                                 }
                                     operationDependency:nil];
        
    } else {
        // delete image on server
        [self.spinner startAnimating];
        NSDictionary *parameters = @{kGRVRESTUserAvatarKey: @""};
        [[GRVHTTPManager sharedManager] request:GRVHTTPMethodPATCH
                                         forURL:kGRVRESTUser
                                     parameters:parameters
                                        success:^(NSURLSessionDataTask *task, id responseObject) {
                                            [self.spinner stopAnimating];
                                            [self refreshWithUserDictionary:responseObject];
                                        }
                                        failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                            [self.spinner stopAnimating];
                                        }];
    }
}


#pragma mark - UITableViewDelegate
#pragma mark Sections
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    // Simple trick to hide section header of first section.
    //
    // 0.0f as the first section header's height doesnt work, so return the
    // smallest acceptable multiple of a pixel's size, 1.0f.
    // To compensate for this 1.0f, in viewDidLoad use the contentInset to hide
    // this 1px height underneath the navigation bar
    //
    // To return the default header height for other sections return -1
    return (section == 0) ? 1.0f : -1.0f;
}


#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet == self.addPhotoActionSheet) {
        // perform appropriate action on avatar
        
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // Request a confirmation first
            self.deleteConfirmationSheet = [[UIActionSheet alloc] initWithTitle:@"Delete avatar?"
                                                                       delegate:self
                                                              cancelButtonTitle:@"Cancel"
                                                         destructiveButtonTitle:@"Delete"
                                                              otherButtonTitles:nil];
            [self.deleteConfirmationSheet showInView:self.view];
            
        } else if (buttonIndex != actionSheet.cancelButtonIndex) {
            switch (buttonIndex-actionSheet.firstOtherButtonIndex) {
                case kAddPhotoTakeButtonIndex:
                    [self startCameraController:UIImagePickerControllerSourceTypeCamera];
                    break;
                    
                case kAddPhotoChooseButtonIndex:
                    [self startCameraController:UIImagePickerControllerSourceTypePhotoLibrary];
                    break;
                    
                default:
                    break;
            }
        }
        
    } else if (actionSheet == self.deleteConfirmationSheet) {
        // User has tapped a button on the delete confirmation action sheet.
        
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // user has confirmed delete so do it
            [self uploadUserAvatar:nil];
        }
    }
}

#pragma mark Photo Upload Helpers

/**
 * Take photo or choose existing from photo library
 *
 * @param sourceType    UIImagePickerControllerSourceType
 */
- (void)startCameraController:(UIImagePickerControllerSourceType)sourceType
{
    // quit if camera or photo library is not available
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    
    // camera/photo library available so set it up.
    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
    cameraUI.sourceType = sourceType;
    
    // Show the controls for moving & scaling pictures
    cameraUI.allowsEditing = YES;
    
    cameraUI.delegate = self;
    
    [self presentViewController:cameraUI animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate
// For responding to the user tapping Cancel
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

// For responding to the user accepting a newly captured picture.
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    // get picked image from info dictionary
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    
    UIImage *imageToSave = editedImage ? editedImage : originalImage;
    
    // Save a newly taken image to the camera roll
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(imageToSave, nil, nil, nil);
    }
    
    // Now upload this new image
    // Now work with this new image
    [self uploadUserAvatar:imageToSave];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.displayNameTextField) {
        if(range.length + range.location > textField.text.length) {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > kGRVUserFullNameMaxLength) ? NO : YES;
        
    } else {
        return YES;
    }
}

@end
