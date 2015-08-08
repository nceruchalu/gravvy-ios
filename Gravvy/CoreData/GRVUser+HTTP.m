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
#import "GRVModelManager.h"
#import "GRVRestUtils.h"
#import "GRVVideo+HTTP.h"

@implementation GRVUser (HTTP)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new user
 *
 * @param userDictionary    User object with all attributes from server
 * @param context           handle to database
 *
 * @return GRVUser instance
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
    
    // get updatedAt date which is used for sync
    NSString *rfc3339UpdatedAt = [[userDictionary objectForKey:kGRVRESTUserUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // Get avatarThumbnailURL to be used for syncing in the event of CDN changes
    NSString *avatarThumbnailURL = [userDictionary[kGRVRESTUserAvatarThumbnailKey] description];
    
    // only perform a sync if there are any changes and also account for CDN changes
    if (![updatedAt isEqualToDate:existingUser.updatedAt] ||
        ![avatarThumbnailURL isEqualToString:existingUser.avatarThumbnailURL]) {
        
        // get properties that will be sync'd
        NSString *fullName = [userDictionary[kGRVRESTUserFullNameKey] description];
        
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
    
    // Ensure relationship type is right
    if ([existingUser.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber] &&
        ([existingUser.relationshipType integerValue] != GRVUserRelationshipTypeMe)) {
        existingUser.relationshipType = @(GRVUserRelationshipTypeMe);
    }
    
    if ([existingUser.relationshipType integerValue] != GRVUserRelationshipTypeMe) {
        if (existingUser.contact && [existingUser.relationshipType integerValue] != GRVUserRelationshipTypeContact) {
            existingUser.relationshipType = @(GRVUserRelationshipTypeContact);
        }
        
        if (!existingUser.contact && [existingUser.relationshipType integerValue] != GRVUserRelationshipTypeUnknown) {
            existingUser.relationshipType = @(GRVUserRelationshipTypeUnknown);
        }
    }
}

/**
 * Unmark GRVUsers as favorited if not in a provided array of user JSON
 * objects.
 *
 * @param userDicts     Array of userDictionary objects, where each contains
 *                      JSON data as expected from server.
 * @param context       handle to database
 */
+ (void)unmarkFavoritedUsersNotInUserInfoArray:(NSArray *)userDicts
                        inManagedObjectContext:(NSManagedObjectContext *)context

{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GRVUser"];
    if ([userDicts count]) {
        // Get all unique identifier values from the object dictionaries.
        NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
        for (NSDictionary *userDictionary in userDicts) {
            NSString *phoneNumber = [[userDictionary valueForKeyPath:kGRVRESTUserPhoneNumberKey] description];
            [phoneNumbers addObject:phoneNumber];
        }
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"GRVUser"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(favorited == YES) AND (NOT (phoneNumber IN[c] %@))", phoneNumbers];
    } else {
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"favorited == YES"];
    }
    
    NSError *error;
    NSArray *outdatedUsers = [context executeFetchRequest:fetchRequest error:&error];
    for (GRVUser *user in outdatedUsers) {
        user.favorited = @(NO);
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

+ (void)refreshFavorites:(void (^)())favoritesAreRefreshed
{
    // don't proceed if managedObjectContext isn't setup or user isn't authenticated
    if (![GRVModelManager sharedManager].managedObjectContext || ![GRVAccountManager sharedManager].isAuthenticated) {
        // execute the callback block
        if (favoritesAreRefreshed) favoritesAreRefreshed();
        return;
    }
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodGET
                  forURL:kGRVRESTUserRecentContacts
              parameters:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     
                     // get array of user dictionaries in response
                     NSArray *usersJSON = [responseObject objectForKey:kGRVRESTListResultsKey];
                     
                     // Use worker context for background execution
                     NSManagedObjectContext *workerContext = [GRVModelManager sharedManager].workerContext;
                     if (workerContext) {
                         [workerContext performBlock:^{
                             
                             // Update users that are no longer recent contacts
                             [GRVUser unmarkFavoritedUsersNotInUserInfoArray:usersJSON inManagedObjectContext:workerContext];
                             
                             // Refresh the corresponding users
                             NSArray *favoritedUsers = [GRVUser usersWithUserInfoArray:usersJSON inManagedObjectContext:workerContext];
                             for (GRVUser *user in favoritedUsers) {
                                 user.favorited = @(YES);
                             }
                            
                             // Push changes up to main thread context. Alternatively,
                             // could turn all objects into faults but this is easier.
                             [workerContext save:NULL];
                             
                             // ensure context is cleaned up for next use.
                             [workerContext reset];
                             
                             // finally execute the callback block on main queue
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if (favoritesAreRefreshed) favoritesAreRefreshed();
                             });
                         }];
                         
                     } else {
                         // No worker context available so execute callback block
                         if (favoritesAreRefreshed) favoritesAreRefreshed();
                     }
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // do nothing but execute the callback block
                     if (favoritesAreRefreshed) favoritesAreRefreshed();
                 }];
}

+ (void)refreshLikersOfVideo:(GRVVideo *)video withCompletion:(void (^)())likersAreRefreshed
{
    // don't proceed if there's no video, managedObjectContext isn't setup or
    // user isn't authenticated
    if (!video || ![GRVModelManager sharedManager].managedObjectContext ||
        ![GRVAccountManager sharedManager].isAuthenticated) {
        // execute the callback block
        if (likersAreRefreshed) likersAreRefreshed();
        return;
    }
    
    NSString *videoLikerListURL = [GRVRestUtils videoLikerListURL:video.hashKey];
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodGET
                  forURL:videoLikerListURL
              parameters:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     
                     // get array of user dictionaries in response
                     NSArray *usersJSON = [responseObject objectForKey:kGRVRESTListResultsKey];
                     
                     // Use main thread context as this won't be too many objects
                     NSManagedObjectContext *workerContext = [GRVModelManager sharedManager].managedObjectContext;
                     if (workerContext) {
                         [workerContext performBlock:^{
                             // get a video object in the workerContext
                             GRVVideo *workerContextVideo = [GRVVideo videoWithVideoHashKey:video.hashKey inManagedObjectContext:workerContext];
                             
                             // Now refresh video's likers
                             NSArray *likers = [GRVUser usersWithUserInfoArray:usersJSON inManagedObjectContext:workerContext];
                             workerContextVideo.likers = [NSSet setWithArray:likers];
                             
                             // No need to push changes to another context as
                             // the worker context is the main thread context
                             
                             // finally execute the callback block on main queue
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if (likersAreRefreshed) likersAreRefreshed();
                             });
                         }];
                         
                     } else {
                         // No worker context available so execute callback block
                         if (likersAreRefreshed) likersAreRefreshed();
                     }
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // do nothing but execute the callback block
                     if (likersAreRefreshed) likersAreRefreshed();
                 }];
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
