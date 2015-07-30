//
//  GRVUser+AddressBook.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUser+AddressBook.h"
#import "GRVCoreDataImport.h"
#import "GRVFormatterUtils.h"
#import "GRVAccountManager.h"

#pragma mark - Constants
/**
 * To use the GRVCoreDataImport methods we need to create dictionary objects
 * that contain just a phone number. This will be the key of the phone numbers.
 */
static NSString *const kGRVAddressBookUserPhoneNumberKey = @"phoneNumber";

@implementation GRVUser (AddressBook)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new user
 *
 * @param phoneNumber    Phone Number string
 * @param context        handle to database
 */
+ (instancetype)newUserWithPhoneNumber:(NSString *)phoneNumber
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVUser *newUser = [NSEntityDescription insertNewObjectForEntityForName:@"GRVUser" inManagedObjectContext:context];
    newUser.phoneNumber = phoneNumber;
    
    return newUser;
}

/**
 * Convert a phone number string from an ABPerson phone number to an E.164
 * formatted phone number
 *
 * @param phoneNumber   phone number string to be formatted
 *
 * @return return E.164 formatted phone number
 */
+ (NSString *)e164PhoneNumber:(NSString *)phoneNumber
{
    // Default region is user's region.
    NSString *defaultRegion = [GRVAccountManager sharedManager].regionCode;
    return [GRVFormatterUtils formatPhoneNumber:phoneNumber
                                   numberFormat:NBEPhoneNumberFormatE164
                                  defaultRegion:defaultRegion
                                          error:NULL];
}


#pragma mark - Public
+ (instancetype)userWithPhoneNumber:(NSString *)phoneNumber
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    // clean up the phone number object
    NSString *cleanedPhoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"\u00a0" withString:@""];
    
    // Get the E.164 formatted phone number
    NSString *e164PhoneNumber = [GRVUser e164PhoneNumber:cleanedPhoneNumber];
    
    // Don't proceed if we couldnt get a valid e164 phone number
    if (![e164PhoneNumber length]) return nil;
    
    // To aid with code re-use this will be packaged as a userDictionary object
    NSDictionary *userDictionary = @{kGRVAddressBookUserPhoneNumberKey: e164PhoneNumber};
    
    return [GRVCoreDataImport objectWithObjectInfo:userDictionary
                            inManagedObjectContext:context
                                          forClass:[GRVUser class]
                                     withPredicate:^NSPredicate *{
                                         // get the user object's unique identifier
                                         NSString *phoneNumber = [userDictionary objectForKey:kGRVAddressBookUserPhoneNumberKey];
                                         return [NSPredicate predicateWithFormat:@"phoneNumber == %@", phoneNumber];
                                         
                                     } usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                         NSString *e164PhoneNumber = [userDictionary objectForKey:kGRVAddressBookUserPhoneNumberKey];
                                         return [GRVUser newUserWithPhoneNumber:e164PhoneNumber inManagedObjectContext:context];
                                         
                                     } syncObject:nil];
}


+ (NSArray *)usersWithPhoneNumberArray:(NSArray *)phoneNumbers
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    // To aid with code re-use the phone numbers will be packaged as
    // userDictionary objects
    NSMutableArray *userDicts = [NSMutableArray array];
    
    for (NSString *phoneNumber in phoneNumbers) {
        // clean up the phone number object
        NSString *cleanedPhoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"\u00a0" withString:@""];
        NSString *e164PhoneNumber = [GRVUser e164PhoneNumber:cleanedPhoneNumber];
        
        if ([e164PhoneNumber length]) {
            NSDictionary *userDictionary = @{kGRVAddressBookUserPhoneNumberKey : e164PhoneNumber};
            [userDicts addObject:userDictionary];
        }
    }
    
    return [GRVCoreDataImport objectsWithObjectInfoArray:userDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVUser class]
                                usingAdditionalPredicate:nil
                                 withObjectIdentifierKey:@"phoneNumber"
                                    andDictIdentifierKey:kGRVAddressBookUserPhoneNumberKey
                                       usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                           NSString *phoneNumber = [objectDictionary objectForKey:kGRVAddressBookUserPhoneNumberKey];
                                           return [GRVUser newUserWithPhoneNumber:phoneNumber inManagedObjectContext:context];
                                           
                                       } syncObject:nil];
}

@end
