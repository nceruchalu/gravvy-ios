//
//  GRVUser+AddressBook.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUser.h"

/**
 * This AddressBook category provides the methods for reusing GRVUser objects
 * as Core Data representations of Address Book Phone Numbers.
 */
@interface GRVUser (AddressBook)

#pragma mark - Class Methods
/**
 * Find-or-Create a user object
 *
 * @param phoneNumber    Phone Number string as acquired from an ABPerson reference
 * @param context        handle to database
 *
 * @return Initialized GRVUser instance
 */
+ (instancetype)userWithPhoneNumber:(NSString *)phoneNumber
             inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of user objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param phoneNumbers      Array of phone number strings, where each is as
 *                          acquired from ABPerson references.
 * @param context           handle to database
 *
 * @return Initiailized GRVUser instances (of course based on passed in phoneNumbers)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)usersWithPhoneNumberArray:(NSArray *)phoneNumbers
                inManagedObjectContext:(NSManagedObjectContext *)context;

@end
