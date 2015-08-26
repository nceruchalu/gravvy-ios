//
//  GRVMember+HTTP.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVMember.h"

/**
 * Using this file as a location to document the GRVMember model which is
 * what represents an video's associated user.
 *
 * Property             Purpose
 * createdAt            Member's invite date
 * status               Member's status in video
 * updatedAt            this attribute will automatically be updated with the
 *                      current date and time by the server whenever anything
 *                      changes on a Member record. It is used for sync purposes
 *
 * @see http://stackoverflow.com/a/5052208 for more on updatedAt
 *
 * Relationship         Purpose
 * user                 User that's the video member
 * video                Video that user is affiliated with.
 */
@interface GRVMember (HTTP)

/**
 * Find-or-Create a member object
 *
 * @param memberDictionary  Member object with all attributes from server
 * @param video             GRVVideo object that member belongs to
 * @param context           handle to database
 *
 * @return Initialized GRVMember instance
 */
+ (instancetype)memberWithMemberInfo:(NSDictionary *)memberDictionary
                     associatedVideo:(GRVVideo *)video
              inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of member objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param memberDicts       Array of memberDictionary objects, where each
 *                          contains JSON data as expected from server.
 * @param video             GRVVideo object that members belong to
 * @param context           handle to database
 *
 * @return Initiailized GRVMember instances (of course based on passed in memberDicts)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)membersWithMemberInfoArray:(NSArray *)memberDicts
                        associatedVideo:(GRVVideo *)video
                 inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Refresh a video's members.
 * Get this data from the server and sync this with what's in the local
 * Core Data storage.
 * This refresh is done on a background thread context so as to not block the
 * main thread.
 *
 * @warning Only call this method when the managedObjectContext is setup
 *
 * @param video                 GRVVideo object whose members are to be refreshed.
 * @param membersAreRefreshed   block to be called after refreshing members. This
 *      is run on the main queue.
 */
+ (void)refreshMembersOfVideo:(GRVVideo *)video withCompletion:(void (^)())membersAreRefreshed;

@end
