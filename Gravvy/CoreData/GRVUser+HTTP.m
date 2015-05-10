//
//  GRVUser+HTTP.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUser+HTTP.h"
#import "GRVUserThumbnail+Create.h"
#import "GRVFormatterUtils.h"
#import "GRVConstants.h"
#import "GRVCoreDataImport.h"
#import "GRVHTTPManager.h"
#import "GRVContact.h"
#import "GRVAccountManager.h"

@implementation GRVUser (HTTP)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new user
 *
 * @param userDictionary    User object with all attributes from server
 * @param context           handle to database
 */
+ (instancetype)newUserWithUserInfo:(NSDictionary *)userDictionary
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVUser *newUser = [NSEntityDescription insertNewObjectForEntityForName:@"GRVUser"
                                                     inManagedObjectContext:context];
    
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // Setup all the dates
    NSString *rfc3339UpdatedAt = [[userDictionary objectForKey:kGRVRESTUserUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // Get and save dictionary attributes being sure call the description method
    // incase dictionary values are NULL
    newUser.avatarThumbnailURL = [[userDictionary objectForKey:kGRVRESTUserAvatarThumbnailKey] description];
    newUser.fullName = [[userDictionary objectForKey:kGRVRESTUserFullNameKey] description];
    newUser.updatedAt = updatedAt;
    newUser.phoneNumber = [[userDictionary objectForKey:kGRVRESTUserPhoneNumberKey] description];
    
    if ([[GRVAccountManager sharedManager].phoneNumber isEqualToString:newUser.phoneNumber]) {
        newUser.relationshipType = @(GRVUserRelationshipTypeMe);
        // TODO: Unlikely to happen but find any other object with this relationship
        // type and delete
        
    } else {
        newUser.relationshipType = @(GRVUserRelationshipTypeUnknown);
    }
    
    [GRVUserThumbnail userThumbnailWithImage:nil associatedUser:newUser inManagedObjectContext:context];
    
    return newUser;
}

/**
 * Update an existing user with a given user object from server
 *
 * @param existingUser      Existing GRVUser object to be updated
 * @param userDictionary    User object with all attributes from server
 */
+ (void)syncUser:(GRVUser *)existingUser
    withUserInfo:(NSDictionary *)userDictionary
{
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // get lastModified date which is used for sync
    NSString *rfc3339UpdatedAt = [[userDictionary objectForKey:kGRVRESTUserUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // only perform a sync if there are any changes
    if (![updatedAt isEqualToDate:existingUser.updatedAt]) {
        
        // get properties that will be sync'd
        NSString *fullName = [userDictionary[kGRVRESTUserFullNameKey] description];
        NSString *avatarThumbnailURL = [userDictionary[kGRVRESTUserAvatarThumbnailKey] description];
        
        // only update fullName if it changed
        if (![fullName isEqualToString:existingUser.fullName]) {
            existingUser.fullName = fullName;
        }
        
        // only change thumbnail data if thumbnail URL changes
        if (![avatarThumbnailURL isEqualToString:existingUser.avatarThumbnailURL]) {
            existingUser.avatarThumbnailURL = avatarThumbnailURL;
            [GRVUserThumbnail userThumbnailWithImage:nil
                                      associatedUser:existingUser
                              inManagedObjectContext:existingUser.managedObjectContext];
        }
        
        // finally update updatedAt
        existingUser.updatedAt = updatedAt;
    }
}


#pragma mark Public
+ (instancetype)userWithUserInfo:(NSDictionary *)userDictionary
          inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectWithObjectInfo:userDictionary
                            inManagedObjectContext:context
                                          forClass:[GRVUser class]
                                     withPredicate:^NSPredicate *{
                                         // get the user object's unique identifier
                                         // call description incase dictionary values are NULL
                                         NSString *phoneNumber = [[userDictionary objectForKey:kGRVRESTUserPhoneNumberKey] description];
                                         return [NSPredicate predicateWithFormat:@"phoneNumber == %@", phoneNumber];
                                         
                                     } usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                         return [GRVUser newUserWithUserInfo:objectDictionary inManagedObjectContext:context];
                                         
                                     } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                         [GRVUser syncUser:(GRVUser *)existingObject withUserInfo:objectDictionary];
                                         
                                     }];
}

+ (NSArray *)usersWithUserInfoArray:(NSArray *)userDicts
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectsWithObjectInfoArray:userDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVUser class]
                                usingAdditionalPredicate:nil
                                 withObjectIdentifierKey:@"phoneNumber"
                                    andDictIdentifierKey:kGRVRESTUserPhoneNumberKey
                                       usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                           return [GRVUser newUserWithUserInfo:objectDictionary inManagedObjectContext:context];
                                           
                                       } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                           [GRVUser syncUser:(GRVUser *)existingObject withUserInfo:objectDictionary];
                                           
                                       }];
}

+ (instancetype)findUserWithPhoneNumber:(NSString *)phoneNumber
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectWithObjectInfo:nil
                            inManagedObjectContext:context
                                          forClass:[GRVUser class]
                                     withPredicate:^NSPredicate *{
                                         return [NSPredicate predicateWithFormat:@"phoneNumber ==[c] %@", phoneNumber];
                                         
                                     } usingCreateObject:nil
                                        syncObject:nil];
}


#pragma mark - Instance Methods
#pragma mark Public
- (void)updateThumbnailImage
{
    // Only update thumbnail image if there isn't an avatar thumbnail iamge,
    // there's an avatar thumbnail URL, and this image isn't already being fetched
    if (!self.avatarThumbnail.image && self.avatarThumbnailURL &&
        ![self.avatarThumbnail.loadingInProgress boolValue]) {
        
        self.avatarThumbnail.loadingInProgress = @(YES);
        
        [[GRVHTTPManager sharedManager] imageFromURL:self.avatarThumbnailURL
                                             success:^(UIImage *image)
         {
             // update thumbnail-sized avatar image
             [self.managedObjectContext performBlock:^{
                 self.avatarThumbnail.loadingInProgress = @(NO);
                 
                 // Don't bother triggering KVO if we are only going to clear out an image
                 // that doesn't exist
                 if (self.avatarThumbnail.image || image) {
                     [GRVUserThumbnail userThumbnailWithImage:image associatedUser:self inManagedObjectContext:self.managedObjectContext];
                 }
             }];
         }
                                             failure:^(NSError *error)
         {
             [self.managedObjectContext performBlock:^{
                 self.avatarThumbnail.loadingInProgress = @(NO);
             }];
         }];
    }
}


@end
