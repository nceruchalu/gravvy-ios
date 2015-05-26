//
//  GRVContactPickerViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "ExtendedTableViewController.h"
#import "GRVMultiContactPickerDelegate.h"

/**
 * GRVContactPickerViewController provides a Whatsapp-style Contact Picker.
 * The contacts to be selected from are those in the phone's address book only.
 * The contact picker allows for search and selection of one contact at a time.
 * To aid in multi-contact selection you could select the button to present the
 * GRVMultiContactPickerViewController.
 */
@interface GRVContactPickerViewController : ExtendedTableViewController

#pragma mark - Properties
/**
 * Selected GRVUser objects
 */
@property (copy, nonatomic, readonly) NSArray *selectedContacts; // of GRVUser *

/**
 * Phone numbers to users to exclude from the contact picker
 */
@property (copy, nonatomic) NSArray *excludedContactPhoneNumbers; // of NSString *

/**
 * Show or hide the Groups Buttons: `My Groups`, `Save as Group`
 * This defaults to NO, so groups buttons are hidden by default
 */
@property (nonatomic) BOOL showGroupsButtons;

#pragma mark - Instance Methods
#pragma mark Concrete
/**
 * Methods to control built-in spinner for indicating server activity
 */
- (void)startSpinner;
- (void)stopSpinner;

#pragma mark Public
/**
 * This method is called when the selected contacts have changed.
 */
- (void)selectedContactsChanged;

@end
