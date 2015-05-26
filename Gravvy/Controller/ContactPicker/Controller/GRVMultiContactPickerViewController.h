//
//  GRVMultiContactPickerViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "ExtendedCoreDataTableViewController.h"
#import "GRVMultiContactPickerDelegate.h"

/**
 * GRVMultiContactPickerViewController is a contact picker that allows for
 * selection of multiple address book contacts with selection circles before 
 * dismissing the VC.
 *
 * On return it sets its outputs appropriately
 */
@interface GRVMultiContactPickerViewController : ExtendedCoreDataTableViewController

#pragma  mark - Properties
/**
 * Selected GRVUser objects. This is both an input and an output.
 * When it's an output (i.e. after the done button is pressed) it returns the
 * Users sorted in the same order as they were presented (alphabetical sort of
 * corresponding Address Book Contact full names).
 */
@property (copy, nonatomic) NSArray *selectedContacts; // of GRVUser *

/**
 * Phone numbers to users to exclude from the contact picker
 */
@property (copy, nonatomic) NSArray *excludedContactPhoneNumbers; // of NSString *

/**
 * Delegate that is informed when contacts were selected and given the
 * newly selected contacts.
 *
 * Delegate has to implement the GRVMultiContactPickerProtocol
 */
@property (strong, nonatomic) id <GRVMultiContactPickerDelegate> delegate;

@end
