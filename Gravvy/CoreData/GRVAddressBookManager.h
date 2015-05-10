//
//  GRVAddressBookManager.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class UIImage;

/**
 * GRVAddressBookManager is a singleton class that ensures we have just one
 * instance of a manager handling interactions between an ABAddressBook and
 * the GRVContacts objects
 * This class handles address book authorization and GRVContacts importing and
 * syncing.
 *
 * @ref https://github.com/jlaws/JLAddressBook
 * @ref https://github.com/heardrwt/RHAddressBook
 */
@interface GRVAddressBookManager : NSObject

#pragma mark - Class Methods
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * Note that if the app user doesnt allow access to the Address Book then
 * this instance is of no use hence it will be a nil object.
 *
 * @return An initialized GRVAddressBookManager object.
 */
+ (instancetype)sharedManager;

#pragma mark Authorization
/**
 * Is app authorized to access address book database?
 *
 * @return boolean indicating if app is authorized for address book access
 */
+ (BOOL)authorized;

/**
 * Get the authorization status code.
 *
 * @return ABAuthorizationStatus ENUM value
 */
+ (ABAuthorizationStatus)authorizationStatus;


#pragma mark User Preferences
/**
 * Return the user's chosen contact sort ordering
 *
 * @return ABPersonSortOrdering ENUM value
 */
+ (ABPersonSortOrdering)sortOrdering;

/**
 * Has user chosen to have users sorted by first name?
 */
+ (BOOL)orderByFirstName;

/**
 * Has user chosen to have users sorted by last name?
 */
+ (BOOL)orderByLastName;


/**
 * Return the user's default composite name format.
 *
 * @return ABPersonCompositeNameFormat ENUM value
 */
+ (ABPersonCompositeNameFormat)compositeNameFormat;

/**
 * Does default composite name format have first name before last name?
 */
+ (BOOL)compositeNameFormatFirstNameFirst;

/**
 * Does default composite name format have last name before first name?
 */
+ (BOOL)compositeNameFormatLastNameFirst;


#pragma mark Public (Reading ABPersonRef)
/**
 * Convert properties into string, array, image, date, number
 */
+ (NSString *)stringProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef;
+ (NSArray *)arrayProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef;
+ (UIImage *)imagePropertyFromRecord:(ABRecordRef)recordRef asThumbnail:(BOOL)asThumbnail;
+ (NSDate *)dateProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef;
+ (NSNumber *)numberProperty:(ABPropertyID)property fromRecord:(ABRecordRef)recordRef;

#pragma mark - Instance Methods
// If you are not authorized to access the address book then these methods return
// nil or don't actually execute.

/**
 * Method to be invoked when the Address Book database is modified by
 * another address book instance.
 * This will sync all the address book database with Core Data.
 *
 * @param addressBook   Address book used to interact with the Address Book database.
 */
- (void)addressBookChanged:(ABAddressBookRef)addressBook;

/**
 * Request authorized access to the Address Book database.
 * You only need to do this if not authorized, i.e. [GRVAddressBookmanager authorized] == NO
 *
 * @param completion
 *      The block to be run when the access request has completed. This block
 *      has no return value and takes two parameters: the authorization status
 *      and an error if authorization failed. If there's an error its code will
 *      be equivalent to the appropriate ABAuthorizationStatus code.
 */
- (void)requestAuthorizationWithCompletion:(void (^)(BOOL authorized, NSError *error))completion;

@end
