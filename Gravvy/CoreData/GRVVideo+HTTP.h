//
//  GRVVideo+HTTP.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideo.h"

/**
 * Using this file as a location to document the GRVVideo model which is what
 * represents a video.
 *
 * Property                 Purpose
 * createdAt                Video creation date
 * hashKey                  Video's unique identifier
 * likesCount               Number of likes
 * membership               Is user a member/invited to this video.
 * order                    Fixed ordering of videos based on descending updatedAt
 *                          as recorded during last refresh operation.
 *                          This ensures the UI doesn't go re-ordering videos
 *                          on each update.
 * photoSmallThumbnailURL   URL location of video's activity feed thumbnail image
 * photoThumbnailURL        URL location of video's cover image
 * playsCount               Number of video plays
 * title                    Video title/caption
 * updatedAt                this attribute will automatically be updated with the
 *                            current date and time by the server whenever anything
 *                            changes on a Video record. It is used for sync purposes
 *
 * @see http://stackoverflow.com/a/5052208 for more on updatedAt
 *
 * Relationship             Purpose
 * activitiesUsingAsObject  Activity objects where this video is the object
 * activitiesUsingAsTarget  Activity objects where this video is the target
 * clips                    Video's associated clips
 * members                  Video's invited members
 * owner                    Video's owner
 */
@interface GRVVideo (HTTP)

#pragma mark - Class Methods
/**
 * Find-or-Create a video object
 *
 * @param videoDictionary   Video object with all attributes from server
 * @param context           handle to database
 *
 * @return Initialized GRVVideo instance
 */
+ (instancetype)videoWithVideoInfo:(NSDictionary *)videoDictionary
            inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of video objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param videoDicts        Array of videoDictionary objects, where each
 *                          contains JSON data as expected from server.
 * @param context           handle to database
 *
 * @return Initialized GRVVideo instances (of course based on passed in videoDicts)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)videosWithVideoInfoArray:(NSArray *)videoDicts
               inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find a video by hash key in the local database.
 *
 * @param videoHashKey  hashKey of GRVVideo object.
 * @param context       handle to database
 *
 * @return Initialized GRVVideo instance or nil if video doesnt exist
 */
+ (instancetype)videoWithVideoHashKey:(NSString *)videoHashKey
               inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find/Fetch a video with a specific identifier. If the video doesn't exist
 * in local storage, attempt getting it from the server.
 *
 * @param videoHashKey      hashKey of GRVVideo object
 * @param context           handle to database
 * @param videoIsFetched    block to be called after fetching video. This is run
 *      on the main queue. This block has no return value and takes one argument:
 *      the fetched GRVVideo instance or nil if video couldn't be found/fetched.
 */
+ (void)fetchVideoWithVideoHashKey:(NSString *)videoHashKey
            inManagedObjectContext:(NSManagedObjectContext *)context
                    withCompletion:(void (^)(GRVVideo *video))videoIsFetched;

/**
 * Refresh the videos which the authenticated user is a member of.
 * Get this data from the server and sync this with what's in the local
 * Core Data storage.
 * This refresh is done on a background thread context so as to not block the
 * main thread.
 *
 * @warning Only call this method when the managedObjectContext is setup
 *
 * @param videosAreRefreshed    block to be called after refreshing videos. This
 *      is run on the main queue.
 */
+ (void)refreshVideos:(void (^)())videosAreRefreshed;


#pragma mark - Instance Methods
/**
 * Record play of this video on the server and locally
 */
- (void)play;

/**
 * Record like/unlike of this video on the server and locally
 *
 * @param likeIsToggled   block to be called after toggling the like of a video
 */
- (void)toggleLike:(void (^)())likeIsToggled;

/**
 * Revoke app user's membership from this video locally and on server.
 *
 * @param membershipIsRevoked   block to be called after revoking membership
 *
 * @note The owner of a group can't revoke their membership so this will result
 *      in a request for video deletion
 */
- (void)revokeMembershipWithCompletion:(void (^)())membershipIsRevoked;

/**
 * Revoke given user's membership from this video locally and on server.
 *
 * @param member                Membership object to be revoked
 * @param membershipIsRevoked   block to be called after revoking membership
 */
- (void)revokeMembership:(GRVMember *)member withCompletion:(void (^)())membershipIsRevoked;

/**
 * Refresh this video.
 * Get this data from the server and sync this with what's in the local
 * Core Data storage.
 * This refresh is done on the same thread that the video currently exists on.
 *
 * @warning Only call this method when the managedObjectContext is setup
 *
 * @param videoIsRefreshed    block to be called after refreshing video. This
 *      is run on the main queue.
 */
- (void)refreshVideo:(void (^)())videoIsRefreshed;

@end
