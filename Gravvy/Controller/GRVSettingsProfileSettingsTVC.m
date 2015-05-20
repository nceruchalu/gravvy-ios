//
//  GRVSettingsProfileSettingsTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/19/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVSettingsProfileSettingsTVC.h"

@interface GRVSettingsProfileSettingsTVC ()

#pragma mark - Properties
@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;

@end

@implementation GRVSettingsProfileSettingsTVC

#pragma mark - Properties
- (UIBarButtonItem *)cancelButton
{
    // lazy instantiation
    if (!_cancelButton) {
        _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelEditing)];
    }
    return _cancelButton;
}

- (UIBarButtonItem *)doneButton
{
    // lazy instantiation
    if (!_doneButton) {
        _doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(updateUserDisplayName)];
    }
    return _doneButton;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.doneButton.enabled = NO;
}


#pragma mark - Instance Methods
#pragma mark Concrete


#pragma mark Private
- (void)showEditingButtons
{
    // replace back button with a Cancel button
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    self.navigationItem.hidesBackButton = YES;
    
    // show Done button
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)hideEditingButtons
{
    // replace Cancel button with the back button
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.hidesBackButton = NO;
    
    // hide Done button
    self.navigationItem.rightBarButtonItem = nil;
    
    // hide keyboard
    [self.view endEditing:YES];
}


#pragma mark Target/Action Methods
/**
 * Cancel the editing of user's profile
 */
- (void)cancelEditing
{
    [self hideEditingButtons];
    [self undoProfileChanges];
}

- (IBAction)textFieldDidChange:(UITextField *)sender
{
    self.doneButton.enabled = ([sender.text length] > 0);
}

#pragma mark - Overrides
- (void)updateUserDisplayName
{
    [self hideEditingButtons];
    [super updateUserDisplayName];
}


#pragma mark - UITextFieldDelegate
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self showEditingButtons];
}

@end
