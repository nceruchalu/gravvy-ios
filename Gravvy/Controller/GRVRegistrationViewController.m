//
//  GRVRegistrationViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVRegistrationViewController.h"
#import "NBPhoneNumberUtil+Shared.h"
#import "NBPhoneNumber.h"
#import "GRVAccountManager.h"
#import "GRVConstants.h"
#import "GRVFormatterUtils.h"
#import "GRVCountrySelectTVC.h"
#import "GRVRegion.h"

#pragma mark - Constants
// maximum number of digits in an E.164 number's country code
static NSInteger const kE164CountryCodeMaxLength  = 3;

// maximum number of digits in an E.164 number's national number
// Should just be 14 characters. But added 6 more to make room for formatting
static NSInteger const kE164NationalNumberMaxLength = 20;

// Default Country Code is United States
static NSString * const kDefaultCountryCode = @"1";

static NSString * const kSegueIdentifierVerificationVC = @"showVerificationVC";


@interface GRVRegistrationViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@property (weak, nonatomic) IBOutlet UIButton *countryNameButton;
@property (weak, nonatomic) IBOutlet UITextField *countryCodeTextField;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumberTextField;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@property (strong, nonatomic) NSString *countryCode;
@property (strong, nonatomic) NSString *phoneNumber;

// Region Code derived from Country Code
@property (strong, nonatomic, readonly) NSString *regionCode;

@end

@implementation GRVRegistrationViewController

#pragma mark - Properties
- (void)setCountryCode:(NSString *)countryCode
{
    _countryCode = countryCode;
    
    // Reflect this country code in the UI
    self.countryCodeTextField.text = countryCode;
    
    // When the country code is updated, update the associated country name
    NSString *regionCode = self.regionCode;
    UIColor *buttonColor;
    NSString *region;
    if (regionCode == kGRVUnknownRegionCode) {
        region = @"Invalid Country Code";
        buttonColor = [UIColor redColor];
    } else {
        NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: regionCode}];
        region = [[GRVFormatterUtils unitedStatesLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
    }
    [self.countryNameButton setTitle:region forState:UIControlStateNormal];
    [self.countryNameButton setTitleColor:buttonColor forState:UIControlStateNormal];
    
    // Dont forget to reformat the phone number if necessary
    [self formatPhoneNumberTextField];
}

- (void) setPhoneNumber:(NSString *)phoneNumber
{
    _phoneNumber = phoneNumber;
    // updating phone number requires reformatting
    [self formatPhoneNumberTextField];
}

- (NSString *)regionCode
{
    NSNumber *countryCodeNum = [GRVFormatterUtils stringToNum:self.countryCode];
    NSString *regionCode = [[NBPhoneNumberUtil sharedUtilInstance] getRegionCodeForCountryCode:countryCodeNum];
    return regionCode;
}


#pragma mark - View LifeCycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This should appear as a root VC in the NavigationVC, so hide back button
    self.navigationItem.hidesBackButton = YES;
    
    self.countryCode = kDefaultCountryCode;
    
    // Loading this view means we aren't registered
    [GRVAccountManager sharedManager].registered = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    // This should appear as a root VC in the NavigationVC, so hide back button
    self.navigationItem.hidesBackButton = YES;
    
    // If user already has saved phone number and password, but we are here
    // then it means user has probably already registered with application but
    // simply needs to verify the credentials.
    GRVAccountManager *accountManager = [GRVAccountManager sharedManager];
    
    if ([accountManager.phoneNumber length]) {
        // First populate the appropriate fields.
        self.countryCode = [accountManager.phoneNumberObj.countryCode stringValue];
        self.phoneNumber = [accountManager.phoneNumberObj.nationalNumber stringValue];
        
        [self performSegueWithIdentifier:kSegueIdentifierVerificationVC sender:self];
    } else {
        [self.phoneNumberTextField becomeFirstResponder];
    }
}


#pragma mark - Instance Methods
#pragma mark Private

/**
 * Format phone number so it looks presentable for the given region.
 * This will turn a US phone number string "5551234678" to "(555) 123-4678"
 *
 * A valid phone number will also enable the done button, else button is disabled.
 */
- (void)formatPhoneNumberTextField
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedUtilInstance];
    NSError *error = nil;
    NBPhoneNumber *phoneNumber = [phoneUtil parse:self.phoneNumber
                                    defaultRegion:self.regionCode
                                            error:&error];
    
    if (!error) {
        // For a valid E.164 phone number, this sets a nicely formatted number,
        // else it sets a plain number string. This is a good indicator to the
        // user that they are on the right track.
        self.phoneNumberTextField.text = [phoneUtil format:phoneNumber
                                              numberFormat:NBEPhoneNumberFormatNATIONAL
                                                     error:&error];
        self.doneButton.enabled = [phoneUtil isValidNumber:phoneNumber];
    } else {
        // Can arrive here for reasons like no country code specified.
        self.doneButton.enabled = NO;
    }
}

/**
 * Modify the UI to indicate to the user that the registration is underway.
 * Show the spinner and change color of text field.
 */
- (void)startRegistration
{
    [self.spinner startAnimating];
    self.phoneNumberTextField.textColor = [UIColor grayColor];
    self.countryCodeTextField.textColor = [UIColor grayColor];
}

/**
 * Modify the UI to indicate to the user that registration is done (successful
 * or not). Hide the spinner and reset the color of text field.
 */
- (void)endRegistration
{
    [self.spinner stopAnimating];
    self.phoneNumberTextField.textColor = [UIColor blackColor];
    self.countryCodeTextField.textColor = [UIColor blackColor];
}


#pragma mark - Target-Action Methods
/**
 * (Re)Register phone number on the server.
 */
- (IBAction)registerAccount:(UIBarButtonItem *)sender
{
    // Get a complete E.164 format phone number
    NSError *error = nil;
    NSString *e164PhoneNumber = [GRVFormatterUtils formatPhoneNumber:self.phoneNumber
                                                        numberFormat:NBEPhoneNumberFormatE164
                                                       defaultRegion:self.regionCode
                                                               error:&error];
    if (!error && [e164PhoneNumber length]) {
        [self startRegistration];
        GRVAccountManager *accountManager = [GRVAccountManager sharedManager];
        [accountManager registerAccount:e164PhoneNumber
                                success:^{
                                    [self endRegistration];
                                    
                                    // navigate user to verification screen.
                                    [self performSegueWithIdentifier:kSegueIdentifierVerificationVC sender:self];
                                }
                                failure:^{
                                    [self endRegistration];
                                }];
    }
}



#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // Enforce maxlengths on both text fields.
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    NSUInteger maxLength = (textField == self.countryCodeTextField) ? kE164CountryCodeMaxLength : kE164NationalNumberMaxLength;
    BOOL returnKeyPressed = [string rangeOfString:@"\n"].location != NSNotFound;
    
    return (newLength <= maxLength) || returnKeyPressed;
}

- (IBAction)textFieldDidChange:(UITextField *)textField {
    // save the updated country code or phone number
    if (textField == self.countryCodeTextField) {
        // Too many side effects from changing country code... so only do this
        // when necessary
        NSString *newCountryCode = textField.text;
        if(![newCountryCode isEqualToString:self.countryCode])  self.countryCode = newCountryCode;
        
    } else if (textField == self.phoneNumberTextField) {
        self.phoneNumber = textField.text;
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:kSegueIdentifierVerificationVC]) {
        self.title = @"Edit number";
    }
}


#pragma mark Modal Unwinding
- (IBAction)selectedCountry:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[GRVCountrySelectTVC class]]) {
        GRVCountrySelectTVC *countrySelectVC = (GRVCountrySelectTVC *)segue.sourceViewController;
        
        GRVRegion *selectedRegion = countrySelectVC.selectedRegion;
        if (selectedRegion) {
            // if a region was selected use it to set the appropriate country code
            // and country name. Seems weird to set the country name, but multiple
            // regions share the same country code so need to use the appropriate
            // value.
            self.countryCode = [selectedRegion.countryCode stringValue];
            [self.countryNameButton setTitle:selectedRegion.regionName forState:UIControlStateNormal];
        }
    }
}

@end
