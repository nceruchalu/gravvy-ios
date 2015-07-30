//
//  GRVClip+HTTP.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVClip+HTTP.h"
#import "GRVUser+HTTP.h"
#import "GRVCoreDataImport.h"
#import "GRVFormatterUtils.h"
#import "GRVConstants.h"

@implementation GRVClip (HTTP)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new clip
 *
 * @param clipDictionary    Clip object with all attributes from server
 * @param video             GRVVideo object that clip belongs to
 * @param context           handle to database
 */
+ (instancetype)newClipWithClipInfo:(NSDictionary *)clipDictionary
                    associatedVideo:(GRVVideo *)video
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVClip *newClip = [NSEntityDescription insertNewObjectForEntityForName:@"GRVClip" inManagedObjectContext:context];
    
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // Setup all the dates
    NSString *rfc3339UpdatedAt = [[clipDictionary objectForKey:kGRVRESTClipUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // Get and save dictionary attributes being sure to call the description method
    // incase dictionary values are NULL
    newClip.duration = [clipDictionary objectForKey:kGRVRESTClipDurationKey];
    newClip.identifier = [clipDictionary objectForKey:kGRVRESTClipIdentifierKey];
    newClip.mp4URL = [[clipDictionary objectForKey:kGRVRESTClipMp4Key] description];
    newClip.order = [clipDictionary objectForKey:kGRVRESTClipOrderKey];
    newClip.photoThumbnailURL = [[clipDictionary objectForKey:kGRVRESTClipPhotoThumbnailKey] description];
    newClip.updatedAt = updatedAt;
    
    // Setup required relationships
    newClip.owner = [GRVUser userWithUserInfo:[clipDictionary objectForKey:kGRVRESTClipOwnerKey] inManagedObjectContext:context];
    newClip.video = video;
    
    return newClip;
}

/**
 * Update an existing clip with a given clip object from server
 *
 * @param existingClip      Existing GRVClip object to be updated
 * @param clipDictionary    Clip object with all attributes from server
 */
+ (void)syncClip:(GRVClip *)existingClip
    withClipInfo:(NSDictionary *)clipDictionary
{
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // get updatedAt date which is used for sync
    NSString *rfc3339UpdatedAt = [[clipDictionary objectForKey:kGRVRESTClipUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // Even though clip might might not have changed but video owner might have been updated
    GRVUser *owner = [GRVUser userWithUserInfo:[clipDictionary objectForKey:kGRVRESTClipOwnerKey]
       inManagedObjectContext:existingClip.managedObjectContext];
    
    // only perform a sync if there are any changes
    if (![updatedAt isEqualToDate:existingClip.updatedAt]) {
        existingClip.mp4URL = [[clipDictionary objectForKey:kGRVRESTClipMp4Key] description];
        existingClip.order = [clipDictionary objectForKey:kGRVRESTClipOrderKey];
        existingClip.photoThumbnailURL = [[clipDictionary objectForKey:kGRVRESTClipPhotoThumbnailKey] description];
        existingClip.updatedAt = updatedAt;
        existingClip.owner = owner;
    }
    
    if (!existingClip.photoThumbnailURL) {
        // Photo thumbnail wasn't always present in the model, so if it's missing
        // add that now
        existingClip.photoThumbnailURL = [[clipDictionary objectForKey:kGRVRESTClipPhotoThumbnailKey] description];
    }
}

/**
 * Delete GRVClip objects not in a provided array of clip JSON objects.
 *
 * @param clipDicts     Array of clipDictionary objects, where each contains
 *                      JSON data as expected from server.
 * @param video         GRVVideo object that clips belong to
 * @param context       handle to database
 */
+ (void)deleteClipsNotInClipInfoArray:(NSArray *)clipDicts
                      associatedVideo:(GRVVideo *)video
               inManagedObjectContext:(NSManagedObjectContext *)context
{
    [GRVCoreDataImport deleteObjectsNotInObjectInfoArray:clipDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVClip class]
                                usingAdditionalPredicate:^NSPredicate *{
                                    return [NSPredicate predicateWithFormat:@"video == %@", video];
                                }
                                 withObjectIdentifierKey:@"identifier"
                                    andDictIdentifierKey:kGRVRESTClipIdentifierKey];
}



#pragma mark Public
+ (instancetype)clipWithClipInfo:(NSDictionary *)clipDictionary
                 associatedVideo:(GRVVideo *)video
          inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectWithObjectInfo:clipDictionary
                            inManagedObjectContext:context
                                          forClass:[GRVClip class]
                                     withPredicate:^NSPredicate *{
                                         // get the clip object's unique identifier
                                         // call description incase dictionary value is NULL
                                         NSString *identifier = [[clipDictionary objectForKey:kGRVRESTClipIdentifierKey] description];
                                         return [NSPredicate predicateWithFormat:@"(video == %@) AND (identifier == %@)", video, identifier];
                                         
                                     } usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                         return [GRVClip newClipWithClipInfo:objectDictionary associatedVideo:video inManagedObjectContext:context];
                                         
                                     } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                         [GRVClip syncClip:(GRVClip *)existingObject withClipInfo:objectDictionary];
                                     }];
}

+ (NSArray *)clipsWithClipInfoArray:(NSArray *)clipDicts
                    associatedVideo:(GRVVideo *)video
             inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectsWithObjectInfoArray:clipDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVClip class]
                                usingAdditionalPredicate:^NSPredicate *{
                                    return [NSPredicate predicateWithFormat:@"video == %@", video];
                                }
                                 withObjectIdentifierKey:@"identifier"
                                    andDictIdentifierKey:kGRVRESTClipIdentifierKey
                                       usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                           return [GRVClip newClipWithClipInfo:objectDictionary associatedVideo:video inManagedObjectContext:context];
                                           
                                       } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                           [GRVClip syncClip:(GRVClip *)existingObject withClipInfo:objectDictionary];
                                       }];
}


@end
