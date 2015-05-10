//
//  GRVContact+AddressBook.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContact+AddressBook.h"
#import "GRVModelManager.h"
#import "GRVAddressBookManager.h"
#import "GRVUser+AddressBook.h"
#import "GRVCoreDataImport.h"
#import "GRVConstants.h"

#pragma mark - Constants
/**
 * To use the GRVCoreDataImport methods we need to create dictionary objects
 * that contain just a recordId. This will be the key of the record Ids.
 */
static NSString *const kGRVAddressBookPersonRecordIdKey = @"recordId";

@implementation GRVContact (AddressBook)

#pragma mark - Class Methods
#pragma mark Private

/**
 * Create a new contact
 *
 * @param personRecord      ABPerson record
 * @param context           handle to database
 */
+ (instancetype)newContactWithPersonRecord:(ABRecordRef)personRecord
                    inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVContact *newContact = [NSEntityDescription insertNewObjectForEntityForName:@"GRVContact" inManagedObjectContext:context];
    
    newContact.avatarThumbnail = [GRVAddressBookManager imagePropertyFromRecord:personRecord
                                                                    asThumbnail:YES];
    newContact.firstName = [GRVAddressBookManager stringProperty:kABPersonFirstNameProperty
                                                      fromRecord:personRecord];
    newContact.lastName = [GRVAddressBookManager stringProperty:kABPersonLastNameProperty
                                                     fromRecord:personRecord];
    newContact.recordId = @((NSInteger)ABRecordGetRecordID(personRecord));
    newContact.updatedAt = [GRVAddressBookManager dateProperty:kABPersonModificationDateProperty
                                                       fromRecord:personRecord];
    
    // Setup the associated phoneNumbers as GRVUsers
    NSArray *personRecordPhoneNumbers = [GRVAddressBookManager arrayProperty:kABPersonPhoneProperty
                                                                  fromRecord:personRecord];
    NSArray *phoneNumbers = [GRVUser usersWithPhoneNumberArray:personRecordPhoneNumbers
                                        inManagedObjectContext:context];
    for (GRVUser *user in phoneNumbers) {
        if ([user.relationshipType integerValue] != GRVUserRelationshipTypeMe) {
            user.relationshipType = @(GRVUserRelationshipTypeContact);
        }
    }
    newContact.phoneNumbers = [NSSet setWithArray:phoneNumbers];
    
    return newContact;
}

/**
 * Update an existing contact with a given Address Book Person record
 * Note that all properties but recordId are syncd
 *
 * @param existingContact   Existing GRVContact object to be updated
 * @param personRecord      ABPerson record
 */
+ (void)syncContact:(GRVContact *)existingContact withPersonRecord:(ABRecordRef)personRecord
{
    // get updatedAt, firstName, and lastName which are used for sync
    NSDate *updatedAt = [GRVAddressBookManager dateProperty:kABPersonModificationDateProperty fromRecord:personRecord];
    NSString *firstName = [GRVAddressBookManager stringProperty:kABPersonFirstNameProperty
                                                     fromRecord:personRecord];
    NSString *lastName = [GRVAddressBookManager stringProperty:kABPersonLastNameProperty
                                                    fromRecord:personRecord];
    
    // only perform a sync if there are any changes
    //
    // Observe that we also check for changes to lastName and firstName to adhere
    // to apple's recommendation on long-term references to records.
    // We are to lookup records by ID and compare the record's name with our
    // stored name. If they don't match, use the stored name to find the record
    // We handle this by simply ensure ID and name are in sync.
    //
    // Observe the check for names covers the nil case by assuming equality if
    // compared strings are both nil.
    if (!([updatedAt isEqualToDate:existingContact.updatedAt] &&
          ((!firstName && !existingContact.firstName) || [firstName isEqualToString:existingContact.firstName]) &&
          ((!lastName && !existingContact.lastName) || [lastName isEqualToString:existingContact.lastName]))) {
        // set properties that will be sync'd
        existingContact.avatarThumbnail = [GRVAddressBookManager imagePropertyFromRecord:personRecord
                                                                             asThumbnail:YES];
        existingContact.firstName = firstName;
        existingContact.lastName = lastName;
        existingContact.updatedAt = [GRVAddressBookManager dateProperty:kABPersonModificationDateProperty
                                                                fromRecord:personRecord];
        
        // Update the associated phone numbers
        NSArray *personRecordPhoneNumbers = [GRVAddressBookManager arrayProperty:kABPersonPhoneProperty
                                                                      fromRecord:personRecord];
        NSArray *phoneNumbers = [GRVUser usersWithPhoneNumberArray:personRecordPhoneNumbers
                                            inManagedObjectContext:existingContact.managedObjectContext];
        
        // first mark old users as unknown
        for (GRVUser *user in existingContact.phoneNumbers) {
            if ([user.relationshipType integerValue] != GRVUserRelationshipTypeMe) {
                user.relationshipType = @(GRVUserRelationshipTypeUnknown);
            }
        }
        // then mark old and new users as known contacts
        for (GRVUser *user in phoneNumbers) {
            if ([user.relationshipType integerValue] != GRVUserRelationshipTypeMe) {
                user.relationshipType = @(GRVUserRelationshipTypeContact);
            }
        }
        // finally update the collection of associated users
        existingContact.phoneNumbers = [NSSet setWithArray:phoneNumbers];
        
        // finally update updatedAt
        existingContact.updatedAt = updatedAt;
    }
}


/**
 * Delete GRVContact objects not in a provided array of event person records.
 *
 * @param peopleRecords     Array of ABPerson records
 * @param context           handle to database
 *
 * @return Initiailized GRVEvent instances (of course based on passed in eventDicts)
 */
+ (void)deleteContactsNotInPersonRecordArray:(CFArrayRef)peopleRecords
                      inManagedObjectContext:(NSManagedObjectContext *)context
{
    // Get all unique identifier values from the the people records.
    NSMutableArray *recordIds = [[NSMutableArray alloc] init];
    CFIndex peopleRecordsCount =  CFArrayGetCount(peopleRecords);
    
    for (CFIndex i=0; i<peopleRecordsCount; i++) {
        ABRecordRef personRecord = CFArrayGetValueAtIndex(peopleRecords, i);
        NSUInteger recordId = (NSInteger)ABRecordGetRecordID(personRecord);
        [recordIds addObject:@(recordId)];
    }
    
    // Create the fetch request to get all GRVContacts not matching the recordIds
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"GRVContact" inManagedObjectContext:context]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"NOT (recordId IN %@)", recordIds]];
    
    // finally, execute the fetch
    NSError *error;
    NSArray *contactsNotMatchingRecordIds = [context executeFetchRequest:fetchRequest error:&error];
    
    // now remove all contacts that should no longer exist
    for (GRVContact *contact in contactsNotMatchingRecordIds) {
        // first mark associated users as unknown
        for (GRVUser *user in contact.phoneNumbers) {
            if ([user.relationshipType integerValue] != GRVUserRelationshipTypeMe) {
                user.relationshipType = @(GRVUserRelationshipTypeUnknown);
            }
        }
        [context deleteObject:contact];
    }
}


/**
 * Given an array of ABPerson records find the one with a given recordId
 *
 * @param recordId          ABRecordID of ABPerson of intersst.
 * @param peopleRecords     ABPerson records to search through
 *
 * @return  the found ABPerson record or NULL if doesnt exit in the array of records.
 */
+ (ABRecordRef)findPersonWithRecordId:(ABRecordID)recordId inPersonRecordArray:(CFArrayRef)peopleRecords
{
    ABRecordRef foundPersonRecord = NULL;
    
    CFIndex peopleRecordsCount =  CFArrayGetCount(peopleRecords);
    
    for (CFIndex i=0; i<peopleRecordsCount; i++) {
        ABRecordRef personRecord = CFArrayGetValueAtIndex(peopleRecords, i);
        ABRecordID personRecordId = ABRecordGetRecordID(personRecord);
        if (personRecordId == recordId) {
            foundPersonRecord = personRecord;
            break;
        }
    }
    
    return foundPersonRecord;
}


#pragma mark Public
+ (instancetype)contactWithPersonRecord:(ABRecordRef)personRecord
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSNumber *recordId = @((NSInteger)ABRecordGetRecordID(personRecord));
    
    // To aid with code re-use this will be packaged as a userDictionary object
    NSDictionary *contactDictionary = @{kGRVAddressBookPersonRecordIdKey: recordId};
    return [GRVCoreDataImport objectWithObjectInfo:contactDictionary
                            inManagedObjectContext:context
                                          forClass:[GRVContact class]
                                     withPredicate:^NSPredicate *{
                                         // get the user object's unique identifier
                                         NSNumber *recordId = [contactDictionary objectForKey:kGRVAddressBookPersonRecordIdKey];
                                         return [NSPredicate predicateWithFormat:@"recordId == %@", recordId];
                                         
                                     }
                                 usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                     return [GRVContact newContactWithPersonRecord:personRecord inManagedObjectContext:context];
                                     
                                 } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                     [GRVContact syncContact:(GRVContact *)existingObject withPersonRecord:personRecord];
                                 }];
    
}

+ (NSArray *)contactsWithPersonRecordArray:(CFArrayRef)peopleRecords
                    inManagedObjectContext:(NSManagedObjectContext *)context
{
    // To aid with code re-use the ABPerson record Ids will be packaged as
    // contactDictionary objects
    NSMutableArray *contactDicts = [NSMutableArray array];
    CFIndex peopleRecordsCount =  CFArrayGetCount(peopleRecords);
    
    for (CFIndex i=0; i<peopleRecordsCount; i++) {
        ABRecordRef personRecord = CFArrayGetValueAtIndex(peopleRecords, i);
        NSNumber *recordId = @((NSInteger)ABRecordGetRecordID(personRecord));
        [contactDicts addObject:@{kGRVAddressBookPersonRecordIdKey : recordId}];
    }
    
    return [GRVCoreDataImport objectsWithObjectInfoArray:contactDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVContact class]
                                usingAdditionalPredicate:nil
                                 withObjectIdentifierKey:@"recordId"
                                    andDictIdentifierKey:kGRVAddressBookPersonRecordIdKey
                                       usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                           NSString *recordIdString = [objectDictionary objectForKey:kGRVAddressBookPersonRecordIdKey];
                                           ABRecordID recordId = (ABRecordID)[recordIdString integerValue];
                                           ABRecordRef personRecord = [GRVContact findPersonWithRecordId:recordId inPersonRecordArray:peopleRecords];
                                           return [GRVContact newContactWithPersonRecord:personRecord inManagedObjectContext:context];
                                           
                                       } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                           NSString *recordIdString = [objectDictionary objectForKey:kGRVAddressBookPersonRecordIdKey];
                                           ABRecordID recordId = (ABRecordID)[recordIdString integerValue];
                                           ABRecordRef personRecord = [GRVContact findPersonWithRecordId:recordId inPersonRecordArray:peopleRecords];
                                           [GRVContact syncContact:(GRVContact *)existingObject withPersonRecord:personRecord];
                                       }];
}


+ (void)refreshContacts:(void (^)())contactsAreRefreshed
{
    if ([GRVAddressBookManager authorized]) {
        [GRVContact syncContacts:contactsAreRefreshed];
    } else {
        [[GRVAddressBookManager sharedManager] requestAuthorizationWithCompletion:^(BOOL authorized, NSError *error) {
            if (authorized) [GRVContact syncContacts:contactsAreRefreshed];
        }];
    }
}

/**
 * Update the Core Data GRVContact objects to be sync'd with the information in the
 * Address Book Database.
 * This sync is done on a background thread context so as to not block the
 * main thread.
 * The difference between this and `refreshContacts:` is that it doesnt
 * attempt to request authorization if not authorized.
 *
 * @warning Only call this method when managedObjectContext is setup and authorized
 *      to access the Address Book Database
 *
 * @param contactsAreSynced     block to be called after syncing contacts. This
 *      is run on the main queue.
 */
+ (void)syncContacts:(void (^)())contactsAreSynced
{
    // don't proceed if managedObjectContext isn't setup or no access to Address Book database
    if (![GRVModelManager sharedManager].managedObjectContext || ![GRVAddressBookManager authorized]) {
        // execute the callback block
        if (contactsAreSynced) contactsAreSynced();
        return;
    }
    
    // Use worker context for background execution
    // Use the context specific to the Address Book, as this will take some time.
    NSManagedObjectContext *workerContext = [GRVModelManager sharedManager].workerContextLongRunning;
    if (workerContext) {
        [workerContext performBlock:^{
            
            // Create an address book specific to this thread.
            CFErrorRef error = NULL;
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
            CFArrayRef contactsFromAddressBook = ABAddressBookCopyArrayOfAllPeople(addressBook);
            
            // Delete contacts that no longer exist in Address Book database
            [GRVContact deleteContactsNotInPersonRecordArray:contactsFromAddressBook inManagedObjectContext:workerContext];
            
            // Now refresh your contacts
            [GRVContact contactsWithPersonRecordArray:contactsFromAddressBook
                               inManagedObjectContext:workerContext];
            
            // Release memory
            if (contactsFromAddressBook) CFRelease(contactsFromAddressBook);
            if (addressBook) CFRelease(addressBook);
            
            
            // Push changes up to main thread context. Alternatively,
            // could turn all objects into faults but this is easier.
            [workerContext save:NULL];
            
            // ensure context is cleaned up for next use.
            [workerContext reset];
            
            // finally execute the callback block on main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                if (contactsAreSynced) contactsAreSynced();
            });
        }];
        
    } else {
        // No worker context available so execute callback block
        if (contactsAreSynced) contactsAreSynced();
    }
}

#pragma mark - Instance Methods
#pragma mark Public
- (NSString *)fullName
{
    NSString *name = nil;
    
    if ([self.firstName length] && [self.lastName length]) {
        name = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    } else if ([self.firstName length]) {
        name = self.firstName;
    } else {
        name = self.lastName;
    }
    
    return name;
}

- (NSString *)description
{
    NSMutableArray *phoneNumberStrings = [NSMutableArray array];
    NSSet *phoneNumbers = self.phoneNumbers;
    for (GRVUser *user in phoneNumbers) {
        [phoneNumberStrings addObject:user.phoneNumber];
    }
    
    return [NSString stringWithFormat: @"id : %@, name : %@ %@, modified : %@ numbers : %@", self.recordId, self.firstName, self.lastName, self.updatedAt, phoneNumberStrings];
    
}

@end
