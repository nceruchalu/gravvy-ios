//
//  GRVScrollViewContainer.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVScrollViewContainer.h"

@interface GRVScrollViewContainer ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (strong, nonatomic) IBOutletCollection(UITextField) NSArray *inputTextFieldsCollection;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scrollViewTrailingConstraint;


// property tracks currently active text field
@property (strong, nonatomic) UITextField *activeTextField;

// cached scrollView contentInset (prior to keyboard being shown)
@property (nonatomic) UIEdgeInsets cachedContentInset;

// Due to a bug in UIScrollView that has content offset behaving unexpectedly
// when navigating back to a VC, we need to cache the content offset before
// leaving screen
// By unexpected behavior I mean that your scrollview content will be shifted
// along the y-axis and this is disturbing.
@property (nonatomic) CGPoint previousContentOffset;

@end

@implementation GRVScrollViewContainer

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // set input field borders and set VC as its delegate
    for (UITextField *textField in self.inputTextFieldsCollection) {
        textField.delegate = self;
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.scrollView.contentOffset = CGPointMake(0, self.previousContentOffset.y);
    
    // the contentsize needs to be updated to take up the full screen sans margins.
    CGFloat contentWidth = self.view.frame.size.width - self.scrollViewLeadingConstraint.constant - self.scrollViewTrailingConstraint.constant;
    self.contentViewWidthConstraint.constant = contentWidth;
    
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.scrollView.contentOffset = CGPointZero;
    
    // Register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.previousContentOffset = self.scrollView.contentOffset;
    
    // Remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


#pragma mark - Keyboard Notification handlers
/**
 * Called when the UIKeyboardDidShowNotification is sent.
 *
 * Apple's implementation has a bug such that when you rotate the device to landscape
 * it reports the keyboard as the wrong size as if it was still in portrait mode.
 *
 * This version gets around that by getting the rectangle from the NSNotification object,
 * and transforming the coordinates into the view's coordinate system.
 */
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    kbRect = [self.view convertRect:kbRect fromView:nil];
    CGSize kbSize = kbRect.size;
    
    self.cachedContentInset = self.scrollView.contentInset;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeTextField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeTextField.frame animated:YES];
    }
}

/**
 * Called when the UIKeyboardWillHideNotification is sent
 */
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = self.cachedContentInset; //UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}


#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
}


#pragma mark - Target/Action methods
- (IBAction)backgroundTapped:(id)sender {
    // force view to resignFirstResponder status
    [self.view endEditing:YES];
}

@end
