//
//  GRVActivity+HTTP.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVActivity.h"

/**
 * Using this file as a location to document the GRVActivity model which is what
 * represents an activity stream record.
 *
 * Property             Purpose
 * createdAt            Activity creation date/time
 * identifier           Activity identifier
 * verb                 Activity verb
 *
 * Relationship         Purpose
 * actor                Activity's actor
 * objectClip           Activity's object which is a clip
 * objectUser           Activity's object which is a user
 * objectVideo          Activity's object which is a video
 * targetVideo          Activity's target which is a video
 */
@interface GRVActivity (HTTP)

#pragma mark - Class Methods
/**
 * Find-or-Create an activity object
 *
 * @param activityDictionary    Activity object with all attributes from server
 * @param context               handle to database
 *
 * @return Initialized GRVActivity instance
 */
+ (instancetype)activityWithActivityInfo:(NSDictionary *)activityDictionary
                  inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of activity objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param activityDicts     Array of activityDictionary objects, where each
 *                          contains JSON data as expected from server.
 * @param context           handle to database
 *
 * @return Initialized GRVActivity instances (of course based on passed in 
 *      activityDicts)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)activitiesWithActivityInfoArray:(NSArray *)activityDicts
                      inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Refresh the activity feed of the videos the authenticated user is associated
 * with.
 * Get this data from the server and sync this with what's in the local
 * Core Data storage.
 * This refresh is done on a background thread context so as to not block the
 * main thread.
 *
 * @warning Only call this method when the managedObjectContext is setup
 *
 * @param activitiesAreRefreshed    block to be called after refreshing activies.
 *      This is run on the main queue.
 */
+ (void)refreshActivities:(void (^)())activitiesAreRefreshed;

@end
