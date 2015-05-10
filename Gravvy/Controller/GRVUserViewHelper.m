//
//  GRVUserViewHelper.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUserViewHelper.h"
#import "GRVUser+HTTP.h"
#import "GRVUserThumbnail.h"
#import "GRVUserAvatarView.h"
#import "GRVContact+AddressBook.h"
#import "GRVFormatterUtils.h"

@implementation GRVUserViewHelper

#pragma mark - Class Methods
#pragma mark Public
+ (GRVUserAvatarView *)userAvatarView:(GRVUser *)user
{
    GRVUserAvatarView *userView = [[GRVUserAvatarView alloc] init];
    
    if (user.avatarThumbnail.image) {
        // User has a thumbnail so that's what avatar will be based on.
        userView.thumbnail = user.avatarThumbnail.image;
        
    } else if (user.contact.avatarThumbnail) {
        // If user has an associated contact object, check for an avatar there
        userView.thumbnail = user.contact.avatarThumbnail;
        
    } else {
        // We still need to generate an avatar so let's check for a  full name,
        // first in user then in user's related contact
        // If there's a full name compose an initial string of first characters
        // of first 2 words.
        
        NSString *fullName = [GRVUserViewHelper userFullName:user];
        
        if ([fullName length] > 0) {
            // We still need to generate an avatar so let's check for full name.
            // If there's a full name compose a initials string of first characters
            // of first 2 words
            NSMutableString *userInitials = [NSMutableString string];
            NSArray *fullNameWords = [fullName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            for (NSString *word in fullNameWords) {
                if ([word length] > 0) {
                    NSString *firstLetter = [word substringToIndex:1];
                    [userInitials appendString:[firstLetter uppercaseString]];
                    if ([userInitials length] == 2) break;
                }
            }
            
            // User view will be using intials
            userView.userInitials = [userInitials copy];
            
        } else {
            // User doesnt have a full name so we will just use a default avatar
            userView.thumbnail = [UIImage imageNamed:@"defaultAvatar"];
        }
    }
    
    // if there isnt a thumbnail but there is a thumbnail URL, try getting
    // that URL
    if (!user.avatarThumbnail.image && user.avatarThumbnailURL) [user updateThumbnailImage];
    
    return userView;
}

+ (NSString *)userFullName:(GRVUser *)user
{
    NSString *fullName = [user.contact fullName];
    if ([fullName length] == 0) {
        fullName = user.fullName;
    }
    return fullName;
}

+ (NSString *)userFirstName:(GRVUser *)user
{
    NSString *firstName = nil;
    
    NSString *fullName = [GRVUserViewHelper userFullName:user];
    NSArray *fullNameWords = [fullName componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([fullNameWords count] > 0) {
        firstName = [fullNameWords objectAtIndex:0];
    }
    
    return firstName;
}

+ (NSString *)userPhoneNumber:(GRVUser *)user
{
    return [GRVFormatterUtils formatPhoneNumber:user.phoneNumber
                                   numberFormat:NBEPhoneNumberFormatNATIONAL
                                  defaultRegion:nil error:NULL];
}

+ (NSString *)userFullNameOrPhoneNumber:(GRVUser *)user
{
    NSString *displayName = [GRVUserViewHelper userFullName:user];
    if (![displayName length]) displayName = [GRVUserViewHelper userPhoneNumber:user];
    return displayName;
}

+ (NSString *)userFirstNameOrPhoneNumber:(GRVUser *)user
{
    NSString *displayName = [GRVUserViewHelper userFirstName:user];
    if (![displayName length]) displayName = [GRVUserViewHelper userPhoneNumber:user];
    return displayName;
}


#pragma mark Sort Descriptors
+ (NSArray *)userNameSortDescriptors
{
    return [GRVUserViewHelper userNameSortDescriptorsWithRelationshipKey:nil];
}

+ (NSArray *)userNameSortDescriptorsWithRelationshipKey:(NSString *)relationship
{
    NSString *relationshipTypeKey = @"relationshipType";
    NSString *contactFirstNameKey = @"contact.firstName";
    NSString *contactLastNameKey = @"contact.lastName";
    NSString *fullNameKey = @"fullName";
    
    if (relationship) {
        relationshipTypeKey = [NSString stringWithFormat:@"%@.%@", relationship, relationshipTypeKey];
        contactFirstNameKey = [NSString stringWithFormat:@"%@.%@", relationship, contactFirstNameKey];
        contactLastNameKey = [NSString stringWithFormat:@"%@.%@", relationship, contactLastNameKey];
        fullNameKey = [NSString stringWithFormat:@"%@.%@", relationship, fullNameKey];
    }
    
    NSSortDescriptor *relationshipTypeSort = [NSSortDescriptor sortDescriptorWithKey:relationshipTypeKey ascending:NO];
    NSSortDescriptor *contactFirstNameSort = [NSSortDescriptor sortDescriptorWithKey:contactFirstNameKey ascending:YES];
    NSSortDescriptor *contactLastNameSort = [NSSortDescriptor sortDescriptorWithKey:contactLastNameKey ascending:YES];
    NSSortDescriptor *fullNameSort = [NSSortDescriptor sortDescriptorWithKey:fullNameKey ascending:YES];
    
    return @[relationshipTypeSort, contactFirstNameSort, contactLastNameSort, fullNameSort];
}

@end
