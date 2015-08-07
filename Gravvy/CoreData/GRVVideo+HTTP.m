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
    newVideo.hashKey = [[videoDictionary objectForKey:kGRVRESTVideoHashKeyKey] description];
    newVideo.title = [[videoDictionary objectForKey:kGRVRESTVideoTitleKey] description];
    newVideo.photoSmallThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoSmallThumbnailKey] description];
    newVideo.currentClipIndex = @(0);
    
    newVideo.order = @(kGRVVideoOrderNew);
    
    // Optional fields not present in the minimal JSON retrieved by the activity
    // stream might not be present so don't setup those fields or set an updatedAt
    // timestamp. The sync method works properly when we get the full JSON object.
    if ([videoDictionary objectForKey:kGRVRESTVideoPhotoThumbnailKey]) {
        // Working with a full JSON representation
        newVideo.createdAt = createdAt;
        newVideo.liked = @([[videoDictionary objectForKey:kGRVRESTVideoLikedKey] boolValue]);
        newVideo.likesCount = [videoDictionary objectForKey:kGRVRESTVideoLikesCountKey];
        newVideo.membership = [videoDictionary objectForKey:kGRVRESTVideoMembershipKey];
        newVideo.unseenClipsCount = [videoDictionary objectForKey:kGRVRESTVideoUnseenClipsCountKey];
        newVideo.unseenLikesCount = [videoDictionary objectForKey:kGRVRESTVideoUnseenLikesCountKey];
        newVideo.photoThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoThumbnailKey] description];
        newVideo.playsCount = [videoDictionary objectForKey:kGRVRESTVideoPlaysCountKey];
        newVideo.score = [videoDictionary objectForKey:kGRVRESTVideoScoreKey];
        newVideo.updatedAt = updatedAt;
        
        [newVideo updateParticipation];
        
        // Setup the relationships
        // Setup the clips
        NSArray *clipDicts = [videoDictionary objectForKey:kGRVRESTVideoClipsKey];
        [GRVClip clipsWithClipInfoArray:clipDicts associatedVideo:newVideo inManagedObjectContext:context];
    }
    
    // Setup the relationships
    // Set the owner
    newVideo.owner = [GRVUser userWithUserInfo:[videoDictionary objectForKey:kGRVRESTVideoOwnerKey]
                        inManagedObjectContext:context];
    
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
    if (clipDicts) {
        // Clip dictionaries only available if we have the full JSON representation
        [GRVClip deleteClipsNotInClipInfoArray:clipDicts associatedVideo:existingVideo inManagedObjectContext:context];
        [GRVClip clipsWithClipInfoArray:clipDicts associatedVideo:existingVideo inManagedObjectContext:context];
    }
    
    // video might not have changed but video owner might have been updated
    GRVUser *owner = [GRVUser userWithUserInfo:[videoDictionary objectForKey:kGRVRESTVideoOwnerKey]
                        inManagedObjectContext:context];
    
    // only perform a sync if there are any changes
    if (![updatedAt isEqualToDate:existingVideo.updatedAt]) {
        
        // If this isn't a minimal JSON object, update all fields including the
        // owner which was set to a dummy value by the Activity Stream.
        if ([videoDictionary objectForKey:kGRVRESTVideoPhotoThumbnailKey]) {
            // Working with a full JSON representation
            
            NSString *rfc3339CreatedAt = [[videoDictionary objectForKey:kGRVRESTVideoCreatedAtKey] description];
            NSDate *createdAt = [rfc3339DateFormatter dateFromString:rfc3339CreatedAt];
            
            // Update properties that will be sync'd
            existingVideo.createdAt = createdAt;
            existingVideo.liked = @([[videoDictionary objectForKey:kGRVRESTVideoLikedKey] boolValue]);
            existingVideo.likesCount = [videoDictionary objectForKey:kGRVRESTVideoLikesCountKey];
            existingVideo.unseenClipsCount = [videoDictionary objectForKey:kGRVRESTVideoUnseenClipsCountKey];
            existingVideo.unseenLikesCount = [videoDictionary objectForKey:kGRVRESTVideoUnseenLikesCountKey];
            existingVideo.photoSmallThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoSmallThumbnailKey] description];
            existingVideo.photoThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoThumbnailKey] description];
            existingVideo.playsCount = [videoDictionary objectForKey:kGRVRESTVideoPlaysCountKey];
            existingVideo.title = [[videoDictionary objectForKey:kGRVRESTVideoTitleKey] description];
            existingVideo.updatedAt = updatedAt;
            existingVideo.owner = owner;
            
        } else {
            // Working with minimal JSON representation
            NSString *title = [[videoDictionary objectForKey:kGRVRESTVideoTitleKey] description];
            NSString *photoSmallThumbnailURL = [[videoDictionary objectForKey:kGRVRESTVideoPhotoSmallThumbnailKey] description];
            
            // Only update fields if they've changed
            if (![title isEqualToString:existingVideo.title] || ![photoSmallThumbnailURL isEqualToString:existingVideo.photoSmallThumbnailURL]) {
                existingVideo.title = title;
                existingVideo.photoSmallThumbnailURL = photoSmallThumbnailURL;
            }
        }
    }
    
    // Some changes happen independent of the updated_at time on the full JSON
    // representation
    if ([videoDictionary objectForKey:kGRVRESTVideoPhotoThumbnailKey]) {
        existingVideo.membership = [videoDictionary objectForKey:kGRVRESTVideoMembershipKey];
        existingVideo.score = [videoDictionary objectForKey:kGRVRESTVideoScoreKey];
        
        [existingVideo updateParticipation];
    }
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
        // still go ahead and refresh the video silentlty
        [localVideo refreshVideo:nil];
        
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

+ (void)refreshVideos:(BOOL)reorder withCompletion:(void (^)())videosAreRefreshed
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
                     NSManagedObjectContext *workerContext = [GRVModelManager sharedManager].workerContextVideo;
                     if (workerContext) {
                         [workerContext performBlock:^{
                             // Delete videos that you aren't still a member of
                             [GRVVideo deleteVideosNotInVideoInfoArray:videosJSON inManagedObjectContext:workerContext];
                             
                             // Now refresh the videos
                             NSArray *refreshedVideos = [GRVVideo videosWithVideoInfoArray:videosJSON inManagedObjectContext:workerContext];
                             
                             if (reorder) {
                                 [GRVVideo reorderVideos:refreshedVideos];
                             }
                             
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

+ (void)reorderVideos:(NSArray *)videos
{
    NSSortDescriptor *participationSort = [NSSortDescriptor sortDescriptorWithKey:@"participation" ascending:NO];
    NSSortDescriptor *unseenClipsCountSort = [NSSortDescriptor sortDescriptorWithKey:@"unseenClipsCount" ascending:NO];
    NSSortDescriptor *unseenLikesCountSort = [NSSortDescriptor sortDescriptorWithKey:@"unseenLikesCount" ascending:NO];
    NSSortDescriptor *scoreSort = [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO];
    NSSortDescriptor *updatedAtSort = [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:NO];
    
    videos = [videos sortedArrayUsingDescriptors:@[participationSort, unseenClipsCountSort, unseenLikesCountSort, scoreSort, updatedAtSort]];
    NSUInteger idx = 0;
    for (GRVVideo *video in videos) {
        video.order = @(idx);
        idx++;
    }
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Set the participation on a video
 */
- (void)updateParticipation
{
    
    if ([self isVideoOwner] && [self.playsCount integerValue] == 0) {
        // Check if video is just created by the user
        // TODO: add a time limit
        self.participation = @(GRVVideoParticipationCreated);

    } else if ([self.membership integerValue] <= GRVVideoMembershipInvited) {
        // Have you been invited to the video and haven't viewed it yet?
        self.participation = @(GRVVideoParticipationInvited);
    
    } else {
        self.participation = @(GRVVideoParticipationDefault);
    }
}

#pragma mark Public
- (BOOL)isVideoOwner
{
    return [self.owner.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber];
}

- (BOOL)hasPendingNotifications
{
    return (([self.unseenLikesCount integerValue] > 0) ||
            ([self.unseenClipsCount integerValue] > 0) ||
            ([self.membership integerValue] <= GRVVideoMembershipInvited));
}

- (void)play:(void (^)())videoIsPlayed
{
    NSString *videoDetailPlayURL = [GRVRestUtils videoDetailPlayURL:self.hashKey];
    
    // Start by assume a successful operation for immediate user feedback
    self.playsCount = @([self.playsCount integerValue]);
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodPUT forURL:videoDetailPlayURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        // refresh video
        self.playsCount = [responseObject objectForKey:kGRVRESTVideoPlaysCountKey];
        if ([self.membership integerValue] <= GRVVideoMembershipInvited) {
            self.membership = @(GRVVideoMembershipViewed);
        }
        if (videoIsPlayed) videoIsPlayed();
    } failure:nil];
}

- (void)toggleLike:(void (^)())likeIsToggled
{
    NSString *videoDetailLikeURL = [GRVRestUtils videoDetailLikeURL:self.hashKey];
    
    // Start by assume a successful operation for immediate user feedback
    BOOL originalLiked = [self.liked boolValue];
    NSUInteger originalLikesCount = [self.likesCount integerValue];
    
    // if already liked, then unlike and vice-versa
    self.liked = @(!originalLiked);
    GRVHTTPMethod method;
    if (originalLiked) {
        method = GRVHTTPMethodDELETE;
        self.likesCount = @(originalLikesCount - 1);
    } else {
        method = GRVHTTPMethodPUT;
        self.likesCount = @(originalLikesCount + 1);
    }
    
    [[GRVHTTPManager sharedManager] request:method forURL:videoDetailLikeURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        // refresh video
        [self refreshVideo:nil];
        if (likeIsToggled) likeIsToggled();
        
    } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        // revert like action
        self.liked = @(originalLiked);
        self.likesCount = @(originalLikesCount);
        if (likeIsToggled) likeIsToggled();
    }];
}

- (void)clearNotifications:(void (^)())notificationsCleared
{
    NSString *videoDetailClearNotificationsURL = [GRVRestUtils videoDetailClearNotificationsURL:self.hashKey];
    
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodPUT forURL:videoDetailClearNotificationsURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        // clear video notification stats
        self.unseenClipsCount = @(0);
        self.unseenLikesCount = @(0);
        if ([self.membership integerValue] <= GRVVideoMembershipInvited) {
            self.membership = @(GRVVideoMembershipViewed);
        }
        if (notificationsCleared) notificationsCleared();
    } failure:nil];
}

- (void)revokeMembershipWithCompletion:(void (^)())membershipIsRevoked
{
    NSString *revokeURL;
    if ([self.owner.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber]) {
        // delete video if owner
        revokeURL = [GRVRestUtils videoDetailURL:self.hashKey];
    } else {
        // delete membership if not owner
        revokeURL = [GRVRestUtils videoMemberDetailURL:self.hashKey
                                                member:[GRVAccountManager sharedManager].phoneNumber];
    }
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodDELETE forURL:revokeURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
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

- (void)deleteClip:(GRVClip *)clip withCompletion:(void (^)(NSError *error, id responseObject))clipIsDeleted
{
    // first get the URL to delete clip
    
    NSString *videoClipDetailURL = [GRVRestUtils videoClipDetailURL:self.hashKey clip:clip.identifier];
    
    [[GRVHTTPManager sharedManager] request:GRVHTTPMethodDELETE forURL:videoClipDetailURL parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        // Perform a local hard-delete as the clip is gone on the server
        [clip.managedObjectContext deleteObject:clip];
        if (clipIsDeleted) clipIsDeleted(nil, responseObject);
        
    } failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
        if (clipIsDeleted) clipIsDeleted(error, responseObject);
    }];
}

- (void)deleteClips:(NSArray *)clips withCompletion:(void (^)(NSError *error, id responseObject))clipsAreDeleted
{
    NSUInteger clipsCount = [clips count];
    if (!clipsCount) {
        if (clipsAreDeleted) clipsAreDeleted(nil, nil);
    }
    
    __block NSUInteger deletedClipsCount = 0;
    __block NSError *deleteError = nil;
    __block id deleteResponseObject = nil;
    
    for (GRVClip *clip in clips) {
        [self deleteClip:clip withCompletion:^(NSError *error, id responseObject) {
            // One more clip deleted (or at least we tried to)
            deletedClipsCount++;
            
            if (error) {
                // if there's an error log it here
                deleteError = error;
                deleteResponseObject = responseObject;
            }
            
            if (deletedClipsCount >= clipsCount) {
                // Finally done with all the clips so execute callback
                if (clipsAreDeleted) clipsAreDeleted(deleteError, deleteResponseObject);
            }
        }];
    }
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
