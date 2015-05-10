//
//  GRVVerificationViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVerificationViewController.h"
#import "GRVAccountManager.h"
#import "GRVModelManager.h"
#import "GRVFormatterUtils.h"

#pragma mark - Constants
// expected (and max) number of digits in verification code
static NSInteger const kVerificationCodeLength  = 4;

static NSString * const kSegueIdentifierProfileSettings = @"postActivationShowProfileSettings";


@interface GRVVerificationViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *verificationCodeTextField;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSNumber *verificationCode;

@end

@implementation GRVVerificationViewController

#pragma mark - View LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Making it to this view means we will need to setup profile details
    // post-activation
    [GRVModelManager sharedManager].profileConfiguredPostActivation = NO;
    
    // Get an International format phone number
    NSError *error = nil;
    GRVAccountManager *account = [GRVAccountManager sharedManager];
    NSString *formattedNumber = [GRVFormatterUtils formatPhoneNumber:account.phoneNumber
                                                        numberFormat:NBEPhoneNumberFormatINTERNATIONAL
                                                       defaultRegion:account.regionCode
                                                               error:&error];
    self.navigationItem.title = formattedNumber;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.verificationCodeTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) {
        // back button was pressed. We know this is true because self is no
        // longer in the navigation stack.
        
        // If user is going back then delete the credentials, as user now wants
        // to edit the saved phone number.
        [[GRVAccountManager sharedManager] resetCredentials];
    }
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Modify the UI to indicate to the user that the verification is underway.
 * Show the spinner and change color of text field.
 */
- (void)startVerification
{
    [self.spinner startAnimating];
    self.verificationCodeTextField.textColor = [UIColor grayColor];
}

/**
 * Modify the UI to indicate to the user that verification is done (successful
 * or not). Hide the spinner and reset the color of text field.
 */
- (void)endVerification
{
    [self.spinner stopAnimating];
    self.verificationCodeTextField.textColor = [UIColor blackColor];
}


#pragma mark - Target-Action Methods
/**
 * Verify account on the server.
 */
- (IBAction)verifyAccount:(UIBarButtonItem *)sender
{
    [self startVerification];
    GRVAccountManager *accountManager = [GRVAccountManager sharedManager];
    [accountManager activateWithCode:self.verificationCode success:^{
        
        // succesfully verified account so authenticate and go to profile settings
        [[GRVAccountManager sharedManager] authenticateWithSuccess:^{
            [self endVerification];
            [self performSegueWithIdentifier:kSegueIdentifierProfileSettings sender:self];
            
        } failure:nil];
        
        
    } failure:^{
        [self endVerification];
    }];
    
}


#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Enforce maxlengths on verification code text field.
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKeyPressed = [string rangeOfString:@"\n"].location != NSNotFound;
    
    return (newLength <= kVerificationCodeLength) || returnKeyPressed;
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    NSNumber *verificationCode = [GRVFormatterUtils stringToNum:textField.text];
    self.verificationCode = verificationCode;
    
    self.doneButton.enabled = ([textField.text length] == kVerificationCodeLength);
}

@end
