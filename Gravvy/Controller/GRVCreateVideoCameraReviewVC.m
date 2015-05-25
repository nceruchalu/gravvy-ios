//
//  GRVCreateVideoCameraReviewVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/24/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCreateVideoCameraReviewVC.h"
#import "GRVHTTPManager.h"
#import "SCRecordSession.h"

@interface GRVCreateVideoCameraReviewVC () <UITextFieldDelegate>

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareButton;
@property (strong, nonatomic) IBOutlet UIToolbar *accessoryView;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;

/**
 * This text field is used to trigger the the display of the accessory
 * view that contains the title text field
 */
@property (weak, nonatomic) IBOutlet UITextField *hiddenTitleTextField;


@end

@implementation GRVCreateVideoCameraReviewVC

#pragma mark - Class Methods
#pragma mark Private
/**
 * Set placeholder of a textField and use a custom color
 *
 * @param text  placeholder text string
 * @param color placeholder text color
 */
+ (void)setPlaceholder:(UITextField *)textField usingText:(NSString *)text andColor:(UIColor *)color
{
    NSDictionary *attributes = @{NSForegroundColorAttributeName : color,
                                 NSFontAttributeName : [UIFont fontWithName:kGRVThemeFontBold size:18.0f]};
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    // Disable share button till recording is validated
    self.shareButton.enabled = NO;
    
    [super viewDidLoad];
    
    // Setup title text field accessory view
    self.hiddenTitleTextField.inputAccessoryView = self.accessoryView;
    
    // set self as title text field delegate so we can enforce a max length on it
    self.titleTextField.delegate = self;
    self.titleTextField.tintColor = [UIColor whiteColor];
    
    // Set placeholder color of title text field
    if ([self.titleTextField.placeholder length]) {
        [GRVCreateVideoCameraReviewVC setPlaceholder:self.titleTextField
                                           usingText:self.titleTextField.placeholder
                                            andColor:[UIColor whiteColor]];
    }
}

#pragma mark - Instance Methods
#pragma mark Concrete
- (void)recordingValidated
{
    self.shareButton.enabled = YES;
}

#pragma mark Private
/**
 * Recording has been reviewed and user would like to upload the generated
 * mp4 file, with its associated photo, and duration.
 */
- (void)completedReviewingRecording
{
    // Upload video to server
    
    // Extract record session duration
    NSTimeInterval duration = CMTimeGetSeconds(self.recordSession.duration);
    // Key for the duration object in the lead clip
    NSString *durationKey = [NSString stringWithFormat:@"%@.%@", kGRVRESTVideoLeadClipKey, kGRVRESTClipDurationKey];
    // Parameters required for video upload
    
    NSMutableDictionary *parameters = [@{durationKey: @(duration)} mutableCopy];
    if ([self.titleTextField.text length]) {
        parameters[kGRVRESTVideoTitleKey] = self.titleTextField.text;
    }
    
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
                                                 NSLog(@"response: %@", responseObject);
                                                 
                                                 // Done creating video so unwind this VC
                                             }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                                 [GRVHTTPManager alertWithFailedResponse:nil withAlternateTitle:@"Can't create video." andMessage:@"Something went wrong. Please try again."];
                                             }
                                 operationDependency:nil];
}


#pragma mark - Target/Action Methods
/**
 * display title text field by first bringing up the keyboard that has the title
 * text field as an accessory view, then making the title text field the first
 * responder.
 */
- (IBAction)beginTitleEntry:(UIButton *)sender
{
    [self.hiddenTitleTextField becomeFirstResponder];
    [self.titleTextField becomeFirstResponder];
}

/**
 * Hide title text field by dismissing the keyboards for both the title text 
 * field and the hidden text field.
 */
- (IBAction)endTitleEntry:(UIControl *)sender
{
    // force view to resignFirstResponder status for both text fields
    [self.view endEditing:YES];
    [self.view endEditing:YES];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.titleTextField) {
        if(range.length + range.location > textField.text.length) {
            return NO;
        }
        
        NSUInteger newLength = [textField.text length] + [string length] - range.length;
        return (newLength > kGRVVideoTitleMaxLength) ? NO : YES;
        
    } else {
        return YES;
    }
}


@end
