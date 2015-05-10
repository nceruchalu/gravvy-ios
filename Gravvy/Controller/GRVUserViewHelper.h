//
//  GRVUserViewHelper.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GRVUserAvatarView;
@class GRVUser;

/**
 * GRVUserViewHelper has shared methods used by multiple View Controllers
 * that render GRVUser-based views.
 */
@interface GRVUserViewHelper : NSObject

#pragma mark - Class Methods
/**
 * Generate an appropriate avatar view for a given user.
 *
 * This attempts the following approaches for determining an avatar image in order:
 * - If the user has a thumbnail then use that for the avatar
 * - If user has an address book contact with a thumbnail, use that for the avatar
 * - If user doesn't have a thumbnail but has a fullName, create an avatar
 *   using initials of first two words. If there's just one word then take first
 *   initial only.
 *   The fullName here is that of the address book contact (if one exists).
 * - If user has neither a thumbnail nor a fullName, use a default avatar image
 *
 * If the user has a thumbnail URL but the avatar hasnt been downloaded yet,
 * this method starts the asynchronous download for this to be used when that
 * data is available.
 *
 * @param user  GRVUser to generate an avatar view for
 *
 * @return GRVUserAvatar view instance with a zero frame.
 */
+ (GRVUserAvatarView *)userAvatarView:(GRVUser *)user;


/**
 * Get the appropriate full name for a given user.
 *
 * This will use the following approaches for determining the appropriate name:
 * - If the user has an address book contact use that to generate the full name
 * - If there is not an address book contact lacks a name, or there isnt an
 *   associated address book contact, get take the name from the user object.
 *
 * @param user  GRVUser to generate a full name for
 *
 * @return full name string.
 */
+ (NSString *)userFullName:(GRVUser *)user;

/**
 * Get the appropriate first name of a given user. This will simply be the
 * first word of the full name.
 */
+ (NSString *)userFirstName:(GRVUser *)user;

/**
 * Get the well formated phone number for a given user
 *
 * @param user  GRVUser to generate a phone number for
 *
 * @return phone number string.
 */
+ (NSString *)userPhoneNumber:(GRVUser *)user;

/**
 * Get the appropriate full name for a given user and if that isn't available
 * get the well formateted phone number for the user. This is handy when you
 * have just one row/label to display information about a user.
 *
 * @retun display name string
 */
+ (NSString *)userFullNameOrPhoneNumber:(GRVUser *)user;

/**
 * Get the appropriate first name for a given user and if that isn't available
 * get the well formated phone number of the user. This effectively makes for
 * a shorter display name than fullName or phone number
 *
 * @retun display name string
 */
+ (NSString *)userFirstNameOrPhoneNumber:(GRVUser *)user;


#pragma mark Sort Descriptors
/**
 * An array of sort descriptors to sort GRVUser objects by the following:
 * - associated contact's firstName (Ascending Order)
 * - associated contact's lastName (Ascending Order)
 * - user object's fullName (Ascending Order)
 *
 * @return Array of sort descriptors
 */
+ (NSArray *)userNameSortDescriptors;

/**
 * An array of sort descriptor to sort objects with a to-one GRVUser object
 * relationship by the following:
 * - Phone's associated user object first. Association determined by phoneNumber
 * - Users in address book appear next. That is have an associated GRVContact object
 * - Other users appear last.
 *
 * The above 3 groups of users are sorted by the following
 * - associated contact's firstName (Ascending Order)
 * - associated contact's lastName (Ascending Order)
 * - user object's fullName (Ascending Order)
 *
 * @param relationship  GRVUser relationship string
 *
 * @return Array of sort descriptors
 */
+ (NSArray *)userNameSortDescriptorsWithRelationshipKey:(NSString *)relationship;

@end
