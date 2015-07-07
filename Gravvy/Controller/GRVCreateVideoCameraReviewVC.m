//
//  GRVCreateVideoCameraReviewVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/24/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCreateVideoCameraReviewVC.h"
#import "GRVCreateVideoContactPickerVC.h"
#import "GRVConstants.h"
#import "SCRecordSession.h"

#pragma mark - Constants
/**
 * Segue Identifier for showing contact picker
 */
static NSString *const kSegueIdentifierShowContactPicker = @"showInvitePeopleVC";

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

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // Superclass does some good work in this method
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.destinationViewController isKindOfClass:[GRVCreateVideoContactPickerVC class]]) {
        if ([segue.identifier isEqualToString:kSegueIdentifierShowContactPicker]) {
            // preload VC with parameters to be used for video creation upon
            // successful selection of contacts.
            GRVCreateVideoContactPickerVC *contactPickerVC = (GRVCreateVideoContactPickerVC *)segue.destinationViewController;
            contactPickerVC.previewImage = self.previewImage;
            contactPickerVC.mp4 = self.mp4;
            contactPickerVC.videoTitle = self.titleTextField.text;
            contactPickerVC.duration = CMTimeGetSeconds(self.recordSession.duration);
        }
    }
}




@end
