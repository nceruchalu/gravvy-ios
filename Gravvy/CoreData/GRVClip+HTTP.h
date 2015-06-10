//
//  GRVClip+HTTP.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVClip.h"

/**
 * Using this file as a location to document the GRVClip model which is what
 * represents a video clip.
 *
 * Property             Purpose
 * duration             Clip duration, in seconds
 * identifier           Clip identifier
 * mp4URL               URL where clip's mp4 file can be downloaded
 * order                Order in video's clips, where order 0 comes first
 * updatedAt            this attribute will automatically be updated with the
 *                        current date and time by the server whenever anything
 *                        changes on a Clip record. It is used for sync purposes
 *
 * @see http://stackoverflow.com/a/5052208 for more on updatedAt
 *
 * Relationship             Purpose
 * activitiesUsingAsObject  Activity objects where this clip is the object
 * owner                    Clip's owner
 * video                    Clip's parent video
 */
@interface GRVClip (HTTP)

#pragma mark - Class Methods
/**
 * Find-or-Create a clip object
 *
 * @param clipDictionary    Clip object with all attributes from server
 * @param video             GRVVideo object that clip belongs to
 * @param context           handle to database
 *
 * @return Initialized GRVClip instance
 */
+ (instancetype)clipWithClipInfo:(NSDictionary *)clipDictionary
                 associatedVideo:(GRVVideo *)video
          inManagedObjectContext:(NSManagedObjectContext *)context;

/**
 * Find-or-Create a batch of clip objects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param clipDicts         Array of clipDictionary objects, where each
 *                          contains JSON data as expected from server.
 * @param video             GRVVideo object that clips belong to
 * @param context           handle to database
 *
 * @return Initiailized GRVClip instances (of course based on passed in clipDicts)
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)clipsWithClipInfoArray:(NSArray *)clipDicts
                    associatedVideo:(GRVVideo *)video
             inManagedObjectContext:(NSManagedObjectContext *)context;

@end
