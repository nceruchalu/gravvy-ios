//
//  GRVMember+HTTP.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVMember+HTTP.h"
#import "GRVUser+HTTP.h"
#import "GRVVideo+HTTP.h"
#import "GRVCoreDataImport.h"
#import "GRVFormatterUtils.h"
#import "GRVConstants.h"
#import "GRVModelManager.h"
#import "GRVAccountManager.h"
#import "GRVHTTPManager.h"
#import "GRVRestUtils.h"

@implementation GRVMember (HTTP)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new member
 *
 * @param memberDictionary  Member object with all attributes from server
 * @param video             GRVVideo object that member belongs to
 * @param context           handle to database
 */
+ (instancetype)newMemberWithMemberInfo:(NSDictionary *)memberDictionary
                        associatedVideo:(GRVVideo *)video
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVMember *newMember = [NSEntityDescription insertNewObjectForEntityForName:@"GRVMember" inManagedObjectContext:context];
    
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // Setup all the dates
    NSString *rfc3339UpdatedAt = [[memberDictionary objectForKey:kGRVRESTMemberUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    NSString *rfc3339CreatedAt = [[memberDictionary objectForKey:kGRVRESTMemberCreatedAtKey] description];
    NSDate *createdAt = [rfc3339DateFormatter dateFromString:rfc3339CreatedAt];
    
    // Get and save dictionary attributes being sure call the description method
    // incase dictionary values are NULL
    newMember.createdAt = createdAt;
    newMember.status = [memberDictionary objectForKey:kGRVRESTMemberStatusKey];
    newMember.updatedAt = updatedAt;
    
    // Setup required relationships
    newMember.user = [GRVUser userWithUserInfo:[memberDictionary objectForKey:kGRVRESTMemberUserKey]
                        inManagedObjectContext:context];
    newMember.video = video;
    
    return newMember;
}

/**
 * Update an existing member with a given member object from server
 *
 * @param existingMember    Existing GRVMember object to be updated
 * @param memberDictionary  Member object with all attributes from server
 */
+ (void)syncMember:(GRVMember *)existingMember
    withMemberInfo:(NSDictionary *)memberDictionary
{
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // get updatedAt date which is used for sync
    NSString *rfc3339UpdatedAt = [[memberDictionary objectForKey:kGRVRESTMemberUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // only perform a sync on member object if there are any changes
    if (![updatedAt isEqualToDate:existingMember.updatedAt]) {
        
        // get and set properties that will be sync'd
        existingMember.status = [memberDictionary objectForKey:kGRVRESTMemberStatusKey];
        
        // finally sync updatedAt
        existingMember.updatedAt = updatedAt;
    }
    
    // Member might not have changed but its linked user might have changed so
    // account for that
    [GRVUser userWithUserInfo:[memberDictionary objectForKey:kGRVRESTMemberUserKey]
       inManagedObjectContext:existingMember.managedObjectContext];
}

/**
 * Delete GRVMember objects not in a provided array of member JSON objects.
 *
 * @param memberDicts       Array of memberDictionary objects, where each
 *                          contains JSON data as expected from server.
 * @param video             GRVVideo object that members belong to
 * @param context           handle to database
 */
+ (void)deleteMembersNotInMemberInfoArray:(NSArray *)memberDicts
                          associatedVideo:(GRVVideo *)video
                   inManagedObjectContext:(NSManagedObjectContext *)context
{
    [GRVCoreDataImport deleteObjectsNotInObjectInfoArray:memberDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVMember class]
                                usingAdditionalPredicate:^NSPredicate *{
                                    return [NSPredicate predicateWithFormat:@"video == %@", video];
                                }
                                 withObjectIdentifierKey:@"user.phoneNumber"
                                    andDictIdentifierKey:kGRVRESTMemberIdentifierKey];
}


#pragma mark Public
+ (instancetype)memberWithMemberInfo:(NSDictionary *)memberDictionary
                     associatedVideo:(GRVVideo *)video
              inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectWithObjectInfo:memberDictionary
                            inManagedObjectContext:context
                                          forClass:[GRVMember class]
                                     withPredicate:^NSPredicate *{
                                         // get the member object's unique identifier
                                         // call description incase dictionary value is NULL
                                         NSString *identifier = [[memberDictionary valueForKeyPath:kGRVRESTMemberIdentifierKey] description];
                                         return [NSPredicate predicateWithFormat:@"(video == %@) AND (user.phoneNumber == %@)", video, identifier];
                                         
                                     } usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                         return [GRVMember newMemberWithMemberInfo:objectDictionary associatedVideo:video inManagedObjectContext:context];
                                         
                                     } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                         [GRVMember syncMember:(GRVMember *)existingObject withMemberInfo:objectDictionary];
                                     }];
}

+ (NSArray *)membersWithMemberInfoArray:(NSArray *)memberDicts
                        associatedVideo:(GRVVideo *)video
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectsWithObjectInfoArray:memberDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVMember class]
                                usingAdditionalPredicate:^NSPredicate *{
                                    return [NSPredicate predicateWithFormat:@"video == %@", video];
                                }
                                 withObjectIdentifierKey:@"user.phoneNumber"
                                    andDictIdentifierKey:kGRVRESTMemberIdentifierKey
                                       usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                           return [GRVMember newMemberWithMemberInfo:objectDictionary associatedVideo:video inManagedObjectContext:context];
                                           
                                       } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                           [GRVMember syncMember:(GRVMember *)existingObject withMemberInfo:objectDictionary];
                                       }];
}

+ (void)refreshMembersOfVideo:(GRVVideo *)video withCompletion:(void (^)())membersAreRefreshed
{
    // don't proceed if there's no video, managedObjectContext isn't setup or
    // user isn't authenticated
    if (!video || ![GRVModelManager sharedManager].managedObjectContext ||
        ![GRVAccountManager sharedManager].isAuthenticated) {
        // execute the callback block
        if (membersAreRefreshed) membersAreRefreshed();
        return;
    }
    
    NSString *videoMemberListURL = [GRVRestUtils videoMemberListURL:video.hashKey];
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodGET
                  forURL:videoMemberListURL
              parameters:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     
                     // get array of member dictionaries in response
                     NSArray *membersJSON = [responseObject objectForKey:kGRVRESTListResultsKey];
                     
                     // Use main thread context as this won't be too many objects
                     NSManagedObjectContext *workerContext = [GRVModelManager sharedManager].managedObjectContext;
                     if (workerContext) {
                         [workerContext performBlock:^{
                             // get a video object in the workerContext
                             GRVVideo *workerContextVideo = [GRVVideo videoWithVideoHashKey:video.hashKey inManagedObjectContext:workerContext];
                             
                             // Delete members that aren't still valid
                             [GRVMember deleteMembersNotInMemberInfoArray:membersJSON associatedVideo:workerContextVideo inManagedObjectContext:workerContext];
                             
                             // Now refresh video's members
                             [GRVMember membersWithMemberInfoArray:membersJSON associatedVideo:workerContextVideo inManagedObjectContext:workerContext];
                             
                             // No need to push changes to another context as
                             // the worker context is the main thread context
                             
                             // finally execute the callback block on main queue
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if (membersAreRefreshed) membersAreRefreshed();
                             });
                         }];
                         
                     } else {
                         // No worker context available so execute callback block
                         if (membersAreRefreshed) membersAreRefreshed();
                     }
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // do nothing but execute the callback block
                     if (membersAreRefreshed) membersAreRefreshed();
                 }];
}

@end
