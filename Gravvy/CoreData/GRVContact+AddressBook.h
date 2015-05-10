//
//  GRVContact+AddressBook.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContact.h"
#import <AddressBook/AddressBook.h>

/**
 * Using this file as a location to document the GRVContact model which is what
 * represents an Address Book Contact, ABPerson.
 *
 * Property             Purpose
 * avatarThumbnail      Thumbnail image
 * firstName            First Name
 * lastName             Last name
 * recordId             Record identifier in address book.
 * updatedAt            Modification date
 *
 * Relationship         Purpose
 * phoneNumbers         All GRVUser objects this contact is linked to by having
 *                      matching saved phone numbers.
 *
 */
@interface GRVContact (AddressBook)

#pragma mark - Class Methods
/**
 * Find-or-Create a contact object
 *
 * @param personRecord      ABPerson record
 * @param context           handle to database
 *
 * @return Initialized GRVContact instance
 */
+ (instancetype)contactWithPersonRecord:(ABRecordRef)personRecord
                 inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of contact objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param peopleRecords     Array of ABPerson records
 * @param context           handle to database
 *
 * @return Initiailized GRVContact instances (based on passed in ABPerson records)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)contactsWithPersonRecordArray:(CFArrayRef)peopleRecords
                    inManagedObjectContext:(NSManagedObjectContext *)context;


/**
 * Update the Core Data GRVContact objects to be sync'd with the information in the
 * Address Book Database.
 * This sync is done on a background thread context so as to not block the
 * main thread.
 *
 * If not authorized to access address book an authorization access request is made
 * before attempting to execute the refresh.
 *
 * @warning Only call this method when managedObjectContext is setup
 *
 * @param contactsAreSynced     block to be called after syncing contacts. This
 *      is run on the main queue.
 */
+ (void)refreshContacts:(void (^)())contactsAreRefreshed;



#pragma mark - Instance Methods
/**
 * Generate a full name of format '<firstName> <lastName>'
 *
 * @return string representing full name.
 */
- (NSString *)fullName;

@end
