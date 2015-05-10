//
//  GRVUserThumbnail+Create.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUserThumbnail+Create.h"
#import "GRVUser.h"

@implementation GRVUserThumbnail (Create)

+ (instancetype)userThumbnailWithImage:(UIImage *)image
                        associatedUser:(GRVUser *)user
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    GRVUserThumbnail *newUserThumbnail = nil;
    if (user) {
        
        // Clear any prior thumbnail object
        if (user.avatarThumbnail) {
            [context deleteObject:user.avatarThumbnail];
        }
        
        // Create new thumbnail entity
        newUserThumbnail = [NSEntityDescription insertNewObjectForEntityForName:@"GRVUserThumbnail" inManagedObjectContext:context];
        
        // Setup properties
        newUserThumbnail.image = image;
        newUserThumbnail.loadingInProgress = @(NO);
        
        // Setup relationship and trigger KVO on associated user
        newUserThumbnail.user = user;
    }
    
    return newUserThumbnail;
}

@end
