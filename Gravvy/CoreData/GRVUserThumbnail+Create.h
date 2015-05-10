//
//  GRVUserThumbnail+Create.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUserThumbnail.h"

/**
 * GRVUserThumbnail represents the thumbnail image of its associated user
 *
 * The Create category is used for creation of the GRVUserThumbnail objects
 * given image data.
 *
 * Property             Purpose
 * image                Cached image used for thumbnail
 * loadingInProgress    Indicator of if thumbnail is downloading for caching
 *
 * Relationship         Purpose
 * user                 Thumbnail's associated user
 */
@interface GRVUserThumbnail (Create)

/**
 * Create a user thumbnail object and trigger a KVO notification on the
 * associated user.
 * If the user already had a thumbnail image this is sure to delete that first
 *
 * @param image         Image to be contained in the user thumbnail object
 * @param user          GRVUser object that thumbnail belongs to
 * @param context       handle to database
 *
 * @return Initialized GRVUserThumbnail instance or nil if image is invalid
 */
+ (instancetype)userThumbnailWithImage:(UIImage *)image
                        associatedUser:(GRVUser *)user
                inManagedObjectContext:(NSManagedObjectContext *)context;

@end
