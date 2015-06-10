//
//  GRVActivity+HTTP.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVActivity+HTTP.h"
#import "GRVVideo+HTTP.h"
#import "GRVUser+HTTP.h"
#import "GRVClip+HTTP.h"
#import "GRVMember.h"
#import "GRVCoreDataImport.h"
#import "GRVFormatterUtils.h"
#import "GRVConstants.h"
#import "GRVAccountManager.h"
#import "GRVHTTPManager.h"
#import "GRVModelManager.h"

@implementation GRVActivity (HTTP)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new activity
 *
 * @param activityDictionary    Activity object with all attributes from server
 * @param context               handle to database
 */
+ (instancetype)newActivityWithActivityInfo:(NSDictionary *)activityDictionary
                     inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVActivity *newActivity = [NSEntityDescription insertNewObjectForEntityForName:@"GRVActivity" inManagedObjectContext:context];
    
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // Setup all the dates
    NSString *rfc3339CreatedAt = [[activityDictionary objectForKey:kGRVRESTActivityCreatedAtKey] description];
    NSDate *createdAt = [rfc3339DateFormatter dateFromString:rfc3339CreatedAt];
    
    // Get and save dictionary attributes being sure call the description method
    // incase dictionary values are NULL
    newActivity.createdAt = createdAt;
    newActivity.identifier = [activityDictionary objectForKey:kGRVRESTActivityIdentifierKey];
    newActivity.verb = [[activityDictionary objectForKey:kGRVRESTActivityVerbKey] description];
    
    // Setup the relationships
    // Set the actor
    NSDictionary *actorDictionary = [activityDictionary objectForKey:kGRVRESTActivityActorKey];
    newActivity.actor = [GRVUser userWithUserInfo:actorDictionary inManagedObjectContext:context];
    
    // Set the target
    id target = [activityDictionary objectForKey:kGRVRESTActivityTargetKey];
    if ([target isKindOfClass:[NSDictionary class]] && [target objectForKey:kGRVRESTVideoHashKeyKey]) {
        newActivity.targetVideo = [GRVVideo videoWithVideoInfo:target inManagedObjectContext:context];
    } else { // if (target == [NSNull null])
        // Nothing to do but ignore
    }
    
    // Set the object
    NSDictionary *object = [activityDictionary objectForKey:kGRVRESTActivityObjectKey];
    if ([object objectForKey:kGRVRESTVideoHashKeyKey]) {
        // object is a video
        newActivity.objectVideo = [GRVVideo videoWithVideoInfo:object inManagedObjectContext:context];

    } else if ([object objectForKey:kGRVRESTClipDurationKey]) {
        // object is a clip, but only valid if we have a target video
        if (newActivity.targetVideo) {
            // Augment clip to have an owner
            NSMutableDictionary *clipObject = [object mutableCopy];
            clipObject[kGRVRESTClipOwnerKey] = actorDictionary;
            newActivity.objectClip = [GRVClip clipWithClipInfo:clipObject associatedVideo:newActivity.targetVideo inManagedObjectContext:context];
        }
    
    } else if ([object objectForKey:kGRVRESTUserPhoneNumberKey]) {
        // object is a user
        newActivity.objectUser = [GRVUser userWithUserInfo:object inManagedObjectContext:context];
    }
    
    return newActivity;
}

/**
 * Update an existing activity with a given activity object from server
 * Note that we get our NSManagedObjectContext by asking the GRVActivity for it
 *
 * @param existingActivity      Existing GRVActivity object to be updated
 * @param activityDictionary    Activity object with all attributes from server
 */
+ (void)syncActivity:(GRVActivity *)existingActivity
    withActivityInfo:(NSDictionary *)activityDictionary
{
    NSManagedObjectContext *context = existingActivity.managedObjectContext;
    
    // Activities don't change, but related objects might have changed
    
    // Update the actor
    [GRVUser userWithUserInfo:[activityDictionary objectForKey:kGRVRESTActivityActorKey]
       inManagedObjectContext:context];
    
    // Update the target
    id target = [activityDictionary objectForKey:kGRVRESTActivityTargetKey];
    if ([target isKindOfClass:[NSDictionary class]] && [target objectForKey:kGRVRESTVideoHashKeyKey]) {
        [GRVVideo videoWithVideoInfo:target inManagedObjectContext:context];
    } else { // if (target == [NSNull null])
        // Nothing to do but ignore
    }
    
    // Updated the object
    NSDictionary *object = [activityDictionary objectForKey:kGRVRESTActivityObjectKey];
    if ([object objectForKey:kGRVRESTVideoHashKeyKey]) {
        // object is a video
        [GRVVideo videoWithVideoInfo:object inManagedObjectContext:context];
        
    } else if ([object objectForKey:kGRVRESTClipDurationKey]) {
        // object is a clip, but only valid if we have a target video
        if (existingActivity.targetVideo) {
            [GRVClip clipWithClipInfo:object associatedVideo:existingActivity.targetVideo inManagedObjectContext:context];
        }
        
    } else if ([object objectForKey:kGRVRESTUserPhoneNumberKey]) {
        // object is a user
        [GRVUser userWithUserInfo:object inManagedObjectContext:context];
    }
}

#pragma mark Public
+ (instancetype)activityWithActivityInfo:(NSDictionary *)activityDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectWithObjectInfo:activityDictionary
                            inManagedObjectContext:context
                                          forClass:[GRVVideo class]
                                     withPredicate:^NSPredicate *{
                                         // get the activity object's unique identifier
                                         NSNumber *identifier = [activityDictionary objectForKey:kGRVRESTActivityIdentifierKey];
                                         return [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
                                         
                                     } usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                         return [GRVActivity newActivityWithActivityInfo:objectDictionary inManagedObjectContext:context];
                                         
                                     } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                         [GRVActivity syncActivity:(GRVActivity *)existingObject withActivityInfo:objectDictionary];
                                     }];
}

+ (NSArray *)activitiesWithActivityInfoArray:(NSArray *)activityDicts
                      inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectsWithObjectInfoArray:activityDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVActivity class]
                                usingAdditionalPredicate:nil
                                 withObjectIdentifierKey:@"identifier"
                                    andDictIdentifierKey:kGRVRESTActivityIdentifierKey
                                       usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                           return [GRVActivity newActivityWithActivityInfo:objectDictionary inManagedObjectContext:context];
                                           
                                       } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                           [GRVActivity syncActivity:(GRVActivity *)existingObject withActivityInfo:objectDictionary];
                                       }];
}

+ (void)refreshActivities:(void (^)())activitiesAreRefreshed
{
    // don't proceed if managedObjectContext isn't setup or user isn't authenticated
    if (![GRVModelManager sharedManager].managedObjectContext || ![GRVAccountManager sharedManager].isAuthenticated) {
        // execute the callback block
        if (activitiesAreRefreshed) activitiesAreRefreshed();
        return;
    }
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodGET
                  forURL:kGRVRESTUserActivities
              parameters:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     
                     // get array of activity dictionaries in response
                     NSArray *activitiesJSON = [responseObject objectForKey:kGRVRESTListResultsKey];
                     
                     // Use worker context for background execution
                     NSManagedObjectContext *workerContext = [GRVModelManager sharedManager].workerContext;
                     if (workerContext) {
                         [workerContext performBlock:^{
                             // Delete activities that you aren't still a member of
                             
                             // Now refresh the activities
                             [GRVActivity activitiesWithActivityInfoArray:activitiesJSON inManagedObjectContext:workerContext];
                             
                             // Push changes up to main thread context. Alternatively,
                             // could turn all objects into faults but this is easier.
                             [workerContext save:NULL];
                             
                             // ensure context is cleaned up for next use.
                             [workerContext reset];
                             
                             // finally execute the callback block on main queue
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if (activitiesAreRefreshed) activitiesAreRefreshed();
                             });
                         }];
                         
                     } else {
                         // No worker context available so execute callback block
                         if (activitiesAreRefreshed) activitiesAreRefreshed();
                     }
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // do nothing but execute the callback block
                     if (activitiesAreRefreshed) activitiesAreRefreshed();
                 }];
}

@end
