//
//  GRVFeedbackFormViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/19/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVFeedbackFormViewController.h"
#import "GRVHTTPManager.h"

#pragma mark - Constants
/**
 * maximum number of characters in feedback message
 */
static const NSUInteger kMaxFeedbackBodyLength = 1000;

@interface GRVFeedbackFormViewController ()

#pragma mark - Properties
#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation GRVFeedbackFormViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Send button will only be enabled when there is text
    self.sendButton.enabled = NO;
    self.maxLength = kMaxFeedbackBodyLength;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textView becomeFirstResponder];
}

#pragma mark - Target/Action Methods
- (IBAction)sendFeedback:(UIBarButtonItem *)sender
{
    [self.spinner startAnimating];
    NSDictionary *parameters = @{kGRVRESTFeedbackBodyKey: self.textView.text};
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodPOST
                                     forURL:kGRVRESTFeedbacks
                                 parameters:parameters
                                    success:^(NSURLSessionDataTask *task, id responseObject) {
                                        [self.spinner stopAnimating];
                                        [self.navigationController popViewControllerAnimated:YES];
                                    }
                                    failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                                        [self.spinner stopAnimating];
                                        [GRVHTTPManager alertWithFailedResponse:responseObject withAlternateTitle:@"Couldn't submit feedback" andMessage:@"Please try again later."];
                                    }];
}


#pragma mark - UITextViewDelegate
- (void)textViewDidChange:(UITextView *)textView
{
    [super textViewDidChange:textView];
    // can only send feedback if you indeed have content
    self.sendButton.enabled = ([textView.text length] > 0);
}


@end
