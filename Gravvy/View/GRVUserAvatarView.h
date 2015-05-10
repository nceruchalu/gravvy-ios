//
//  GRVUserAvatarView.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * GRVUserAvatarView is a circular avatar representation of a given user.
 * If the user has a thumbnail image then that will be used, else the provided
 * user initials will be presented on a circular background.
 *
 * @warning This view's bounds really should be a square rectangle otherwise
 *  things get very odd.
 */
@interface GRVUserAvatarView : UIView

/**
 * Providing a thumbnail means the avatar view will be this image cropped to a
 * circle of the view's diameter.
 */
@property (strong, nonatomic) UIImage *thumbnail;

/**
 * If there's no thumbnail image then the user initials are required to generate
 * an avatar image of initials on a circular background.
 * This has to be 2 characters or fewer.
 */
@property (copy, nonatomic) NSString *userInitials;

@end
