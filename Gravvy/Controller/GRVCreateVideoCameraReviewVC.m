//
//  GRVCreateVideoCameraReviewVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/24/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCreateVideoCameraReviewVC.h"
#import "GRVHTTPManager.h"

@interface GRVCreateVideoCameraReviewVC () <UITextFieldDelegate>

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;

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
    [super viewDidLoad];
    
    // set self as title text field delegate so we can enforce a max length on it
    self.titleTextField.delegate = self;
    
    // Set placeholder color of title text field
    [GRVCreateVideoCameraReviewVC setPlaceholder:self.titleTextField
                                       usingText:self.titleTextField.placeholder
                                        andColor:[UIColor whiteColor]];
}


#pragma mark - Instance Methods
#pragma mark Constant
- (void)completedReviewingRecording:(NSData *)mp4
                       previewImage:(UIImage *)previewImage
                           duration:(NSTimeInterval)duration
{
    // Upload video to server
    
    // Key for the duration object in the lead clip
    NSString *durationKey = [NSString stringWithFormat:@"%@.%@", kGRVRESTVideoLeadClipKey, kGRVRESTClipDurationKey];
    // Parameters required for video upload
    NSDictionary *parameters = @{kGRVRESTVideoTitleKey: @"test video from app",
                                 durationKey: @(duration)};
    
    [[GRVHTTPManager sharedManager] operationRequest:GRVHTTPMethodPOST
                                              forURL:kGRVRESTVideos
                                          parameters:parameters
                           constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                               
                               // Keys for mp4 and photo object in request
                               NSString *mp4Key = [NSString stringWithFormat:@"%@.%@", kGRVRESTVideoLeadClipKey, kGRVRESTClipMp4Key];
                               NSString *photoKey = [NSString stringWithFormat:@"%@.%@", kGRVRESTVideoLeadClipKey, kGRVRESTClipPhotoKey];
                               
                               // Come up with a random file name. Doesn't have
                               // to be unique as the server will handle that
                               NSString *baseFileName = [[[NSUUID UUID] UUIDString] substringToIndex:8];
                               NSString *mp4FileName = [NSString stringWithFormat:@"%@.mp4", baseFileName];
                               NSString *photoFileName = [NSString stringWithFormat:@"%@.jpg", baseFileName];
                               
                               [formData appendPartWithFileData:mp4
                                                           name:mp4Key
                                                       fileName:mp4FileName
                                                       mimeType:@"video/mp4"];
                               [formData appendPartWithFileData:UIImageJPEGRepresentation(previewImage, 0.4f)
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
- (IBAction)textFieldDidChange:(UITextField *)sender
{
    
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
