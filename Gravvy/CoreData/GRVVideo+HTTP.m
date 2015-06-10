//
//  GRVVideo+HTTP.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideo+HTTP.h"
#import "GRVUser+HTTP.h"
#import "GRVClip+HTTP.h"
#import "GRVMember.h"
#import "GRVCoreDataImport.h"
#import "GRVFormatterUtils.h"
#import "GRVRestUtils.h"
#import "GRVConstants.h"
#import "GRVHTTPManager.h"
#import "GRVModelManager.h"
#import "GRVAccountManager.h"

@implementation GRVVideo (HTTP)

#pragma mark - Class Methods
#pragma mark Private
/**
 * Create a new video
 *
 * @param videoDictionary   Video object with all attributes from server
 * @param context           handle to database
 */
+ (instancetype)newVideoWithVideoInfo:(NSDictionary *)videoDictionary
               inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVVideo *newVideo = [NSEntityDescription insertNewObjectForEntityForName:@"GRVVideo" inManagedObjectContext:context];
    
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // Setup all the dates
    NSString *rfc3339CreatedAt = [[videoDictionary objectForKey:kGRVRESTVideoCreatedAtKey] description];
    NSDate *createdAt = [rfc3339DateFormatter dateFromString:rfc3339CreatedAt];
    
    NSString *rfc3339UpdatedAt = [[videoDictionary objectForKey:kGRVRESTVideoUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // Get and save dictionary attributes being sure call the description method
    // incase dictionary values are NULL
    newVideo.createdAt = createdAt;
    newVideo.hashKey = [[videoDictionary objectForKey:kGRVRESTVideoHashKeyKey] description];
    newVideo.liked = @([[videoDictionary objectForKey:kGRVRESTVideoLikedKey] boolValue]);
    newVideo.likesCount = [videoDictionary objectForKey:kGRVRESTVideoLikesCountKey];
    newVideo.photoThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoThumbnailKey] description];
    newVideo.playsCount = [videoDictionary objectForKey:kGRVRESTVideoPlaysCountKey];
    newVideo.title = [[videoDictionary objectForKey:kGRVRESTVideoTitleKey] description];
    newVideo.updatedAt = updatedAt;
    
    // Setup the relationships
    
    // Set the owner
    newVideo.owner = [GRVUser userWithUserInfo:[videoDictionary objectForKey:kGRVRESTVideoOwnerKey]
                        inManagedObjectContext:context];
    
    // Setup the clips
    NSArray *clipDicts = [videoDictionary objectForKey:kGRVRESTVideoClipsKey];
    [GRVClip clipsWithClipInfoArray:clipDicts associatedVideo:newVideo inManagedObjectContext:context];
    
    return newVideo;
}

/**
 * Update an existing video with a given video object from server
 * Note that we get our NSManagedObjectContext by asking the GRVVideo for it
 *
 * @param existingVideo     Existing GRVVideo object to be updated
 * @param videoDictionary   Video object with all attributes from server
 */
+ (void)syncVideo:(GRVVideo *)existingVideo
    withVideoInfo:(NSDictionary *)videoDictionary
{
    NSManagedObjectContext *context = existingVideo.managedObjectContext;
    NSDateFormatter *rfc3339DateFormatter = [GRVFormatterUtils generateRFC3339DateFormatter];
    
    // get updatedAt date which is used for sync
    NSString *rfc3339UpdatedAt = [[videoDictionary objectForKey:kGRVRESTVideoUpdatedAtKey] description];
    NSDate *updatedAt = [rfc3339DateFormatter dateFromString:rfc3339UpdatedAt];
    
    // Sync related objects regardless of whether parent video has changed.
    // If we implemented the related object syncs properly then this won't result
    // in unnecessary writes.
    NSArray *clipDicts = [videoDictionary objectForKey:kGRVRESTVideoClipsKey];
    [GRVClip clipsWithClipInfoArray:clipDicts associatedVideo:existingVideo inManagedObjectContext:context];
    
    // only perform a sync if there are any changes
    if (![updatedAt isEqualToDate:existingVideo.updatedAt]) {
        
        // Update properties that will be sync'd
        existingVideo.liked = @([[videoDictionary objectForKey:kGRVRESTVideoLikedKey] boolValue]);
        existingVideo.likesCount = [videoDictionary objectForKey:kGRVRESTVideoLikesCountKey];
        existingVideo.photoThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoThumbnailKey] description];
        existingVideo.photoSmallThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoSmallThumbnailKey] description];
        existingVideo.playsCount = [videoDictionary objectForKey:kGRVRESTVideoPlaysCountKey];
        existingVideo.title = [[videoDictionary objectForKey:kGRVRESTVideoTitleKey] description];
        // finally sync updatedAt
        existingVideo.updatedAt = updatedAt;
    }
    
    // video might not have changed but video owner might have been updated
    [GRVUser userWithUserInfo:[videoDictionary objectForKey:kGRVRESTVideoOwnerKey]
       inManagedObjectContext:context];
}


/**
 * Delete GRVVideo objects not in a provided array of video JSON objects.
 *
 * @param videoDicts    Array of videoDictionary objects, where each contains
 *                      JSON data as expected from server.
 * @param context       handle to database
 */
+ (void)deleteVideosNotInVideoInfoArray:(NSArray *)videoDicts
                 inManagedObjectContext:(NSManagedObjectContext *)context
{
    [GRVCoreDataImport deleteObjectsNotInObjectInfoArray:videoDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVVideo class]
                                usingAdditionalPredicate:nil
                                 withObjectIdentifierKey:@"hashKey"
                                    andDictIdentifierKey:kGRVRESTVideoHashKeyKey];
}


#pragma mark Public
+ (instancetype)videoWithVideoInfo:(NSDictionary *)videoDictionary
            inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectWithObjectInfo:videoDictionary
                            inManagedObjectContext:context
                                          forClass:[GRVVideo class]
                                     withPredicate:^NSPredicate *{
                                         // get the video object's unique identifier
                                         // call description incase dictionary value is NULL
                                         NSString *hashKey = [[videoDictionary objectForKey:kGRVRESTVideoHashKeyKey] description];
                                         return [NSPredicate predicateWithFormat:@"hashKey ==[c] %@", hashKey];
                                         
                                     } usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                         return [GRVVideo newVideoWithVideoInfo:objectDictionary inManagedObjectContext:context];
                                         
                                     } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                         [GRVVideo syncVideo:(GRVVideo *)existingObject withVideoInfo:objectDictionary];
                                     }];
}

+ (NSArray *)videosWithVideoInfoArray:(NSArray *)videoDicts
               inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectsWithObjectInfoArray:videoDicts
                                  inManagedObjectContext:context
                                                forClass:[GRVVideo class]
                                usingAdditionalPredicate:nil
                                 withObjectIdentifierKey:@"hashKey"
                                    andDictIdentifierKey:kGRVRESTVideoHashKeyKey
                                       usingCreateObject:^NSManagedObject *(NSDictionary *objectDictionary, NSManagedObjectContext *context) {
                                           return [GRVVideo newVideoWithVideoInfo:objectDictionary inManagedObjectContext:context];
                                           
                                       } syncObject:^(NSManagedObject *existingObject, NSDictionary *objectDictionary) {
                                           [GRVVideo syncVideo:(GRVVideo *)existingObject withVideoInfo:objectDictionary];
                                       }];
}

+ (instancetype)videoWithVideoHashKey:(NSString *)videoHashKey
               inManagedObjectContext:(NSManagedObjectContext *)context
{
    return [GRVCoreDataImport objectWithObjectInfo:nil
                            inManagedObjectContext:context
                                          forClass:[GRVVideo class]
                                     withPredicate:^NSPredicate *{
                                         return [NSPredicate predicateWithFormat:@"hashKey ==[c] %@", videoHashKey];
                                         
                                     }
                                 usingCreateObject:nil
                                        syncObject:nil];
}

+ (void)fetchVideoWithVideoHashKey:(NSString *)videoHashKey
            inManagedObjectContext:(NSManagedObjectContext *)context
                    withCompletion:(void (^)(GRVVideo *video))videoIsFetched
{
    // Without a context there's nothing to be done here
    if (!context) {
        if (videoIsFetched) videoIsFetched(nil);
        return;
    }
    
    // Attempt getting this from local storage
    GRVVideo *localVideo = [GRVVideo videoWithVideoHashKey:videoHashKey inManagedObjectContext:context];
    if (localVideo) {
        // If video is found in local storage, we are done
        if (videoIsFetched) videoIsFetched(localVideo);
        
    } else {
        // Time for a server request
        NSString *videoDetailURL = [GRVRestUtils videoDetailURL:videoHashKey];
        [[GRVHTTPManager sharedManager] request:GRVHTTPMethodGET forURL:videoDetailURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            
            // sync video
            [context performBlock:^{
                // Import fetched video JSON data
                GRVVideo *fetchedVideo = [GRVVideo videoWithVideoInfo:responseObject
                                               inManagedObjectContext:context];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Video was fetched so we are done
                    if (videoIsFetched) videoIsFetched(fetchedVideo);
                });
            }];
            
        } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
            if (videoIsFetched) videoIsFetched(nil);
        }];
    }
}

+ (void)refreshVideos:(void (^)())videosAreRefreshed
{
    // don't proceed if managedObjectContext isn't setup or user isn't authenticated
    if (![GRVModelManager sharedManager].managedObjectContext || ![GRVAccountManager sharedManager].isAuthenticated) {
        // execute the callback block
        if (videosAreRefreshed) videosAreRefreshed();
        return;
    }
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodGET
                  forURL:kGRVRESTUserVideos
              parameters:nil
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     
                     // get array of video dictionaries in response
                     NSArray *videosJSON = [responseObject objectForKey:kGRVRESTListResultsKey];
                     
                     // Use worker context for background execution
                     NSManagedObjectContext *workerContext = [GRVModelManager sharedManager].workerContext;
                     if (workerContext) {
                         [workerContext performBlock:^{
                             // Delete videos that you aren't still a member of
                             [GRVVideo deleteVideosNotInVideoInfoArray:videosJSON inManagedObjectContext:workerContext];
                             
                             // Now refresh the videos
                             [GRVVideo videosWithVideoInfoArray:videosJSON inManagedObjectContext:workerContext];
                             
                             // Push changes up to main thread context. Alternatively,
                             // could turn all objects into faults but this is easier.
                             [workerContext save:NULL];
                             
                             // ensure context is cleaned up for next use.
                             [workerContext reset];
                             
                             // finally execute the callback block on main queue
                             dispatch_async(dispatch_get_main_queue(), ^{
                                 if (videosAreRefreshed) videosAreRefreshed();
                             });
                         }];
                         
                     } else {
                         // No worker context available so execute callback block
                         if (videosAreRefreshed) videosAreRefreshed();
                     }
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // do nothing but execute the callback block
                     if (videosAreRefreshed) videosAreRefreshed();
                 }];
}


#pragma mark - Instance Methods
#pragma mark Public
- (void)revokeMembershipWithCompletion:(void (^)())membershipIsRevoked
{
    // TODO: delete video if owner
    
    // revoke membership locally but first get the URL to delete membership
    NSString *videoDetailMemberURL = [GRVRestUtils videoMemberDetailURL:self.hashKey member:[GRVAccountManager sharedManager].phoneNumber];
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodDELETE forURL:videoDetailMemberURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        // Perform a local hard-delete as the membership is gone on the server
        [self.managedObjectContext deleteObject:self];
        if (membershipIsRevoked) membershipIsRevoked();
        
    } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        
        // if you get a 404 error it means the video does not exist so delete it
        // from data storage
        NSUInteger statusCode = [GRVHTTPManager statusCodeFromRequestFailure:error];
        if (statusCode == GRVHTTPStatusCode404NotFound) {
            [self.managedObjectContext deleteObject:self];
        }
        
        if (membershipIsRevoked) membershipIsRevoked();
    }];
}

- (void)revokeMembership:(GRVMember *)member withCompletion:(void (^)())membershipIsRevoked
{
    // revoke membership locally but first get the URL to delete membership
    NSString *videoDetailMemberURL = [GRVRestUtils videoMemberDetailURL:self.hashKey member:member.user.phoneNumber];
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodDELETE forURL:videoDetailMemberURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        // Perform a local hard-delete as the membership is gone on the server
        [member.managedObjectContext deleteObject:member];
        if (membershipIsRevoked) membershipIsRevoked();
        
    } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (membershipIsRevoked) membershipIsRevoked();
    }];
}

- (void)refreshVideo:(void (^)())videoIsRefreshed
{
    NSString *videoDetailURL = [GRVRestUtils videoDetailURL:self.hashKey];
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodGET forURL:videoDetailURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        
        // sync video
        [self.managedObjectContext performBlockAndWait:^{
            [GRVVideo videoWithVideoInfo:responseObject inManagedObjectContext:self.managedObjectContext];
        }];
        
        if (videoIsRefreshed) videoIsRefreshed();
        
    } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (videoIsRefreshed) videoIsRefreshed();
    }];
}



@end
