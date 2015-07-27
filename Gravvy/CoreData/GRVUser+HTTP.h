//
//  GRVUser+HTTP.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUser.h"

/**
 * Using this file as a location to document the GRVUser model which is what
 * represents a user.
 *
 * Property             Purpose
 * avatarThumbnailURL   URL where thumbnail image can be downloaded
 * favorited            Is user a recent contact of app user?
 * fullName             User's full name
 * phoneNumber          User's unique identifier, an E.164 formatted phone number.
 * relationshipType     App user's relationship to user, self, contact or other.
 * updatedAt            this attribute will automatically be updated with the
 *                        current date and time by the server whenever anything
 *                        changes on a User record. It is used for sync purposes
 *
 * @see http://stackoverflow.com/a/5052208 for more on updatedAt
 *
 * Relationship             Purpose
 * activitiesUsingAsActor   Activity objects that have this user as an actor
 * activitiesUsingAsObject  Activity objects that have this user as an object
 * avatarThumbnail          cached thumbnail image data
 * ownedVideos              Videos owned by this user
 * uploadedClips            Clips uploaded by this user
 * videoMemberships         Video Member objects this user is associated with.
 */
@interface GRVUser (HTTP)

#pragma mark - Class Methods
/**
 * Find-or-Create a user object
 *
 * @param userDictionary    User object with all attributes from server
 * @param context           handle to database
 *
 * @return Initialized GRVUser instance
 */
+ (instancetype)userWithUserInfo:(NSDictionary *)userDictionary
          inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of user objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param userDicts         Array of userDictionary objects, where each contains
 *                          JSON data as expected from server.
 * @param context           handle to database
 *
 * @return Initiailized GRVUser instances (of course based on passed in userDicts)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)usersWithUserInfoArray:(NSArray *)userDicts
             inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find a user by phone number in local database.
 *
 * @param phoneNumber    Phone Number string as acquired from an ABPerson reference
 * @param context        handle to database
 *
 * @return Initialized GRVUser instance or nil if user doesnt exist
 */
+ (instancetype)findUserWithPhoneNumber:(NSString *)phoneNumber
                 inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Refresh the collection of favorite contacts of the app user.
 * This refresh is done on a background thread context so as to not block the
 * main thread.
 *
 * @warning Only call this method when the managedObjectContext is setup
 *
 * @param favoritesAreRefreshed    block to be called after refreshing favorite
 *      contacts. This is run on the main queue.
 */
+ (void)refreshFavorites:(void (^)())favoritesAreRefreshed;

#pragma mark - Instance Methods
/**
 * Download thumbnail image data of user if not already done and there is a
 * download URL
 */
- (void)updateThumbnailImage;

@end
