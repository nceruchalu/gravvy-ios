//
//  GRVRestUtils.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * This helper class provides helper utility methods useful for the REST API
 * communication
 */
@interface GRVRestUtils : NSObject

/**
 * Generate the relative URL for a REST API's Video Detail
 *
 * @param videoHashKey      hashKey of video of interest
 *
 * @return relative URL
 */
+ (NSString *)videoDetailURL:(NSString *)videoHashKey;

/**
 * Generate the relative URL for a REST API's Video Member List
 *
 * @param videoHashKey      hashKey of video of interest
 *
 * @return relative URL
 */
+ (NSString *)videoMemberListURL:(NSString *)videoHashKey;

/**
 * Generate the relative URL for a REST API's Video Member Detail
 *
 * @param videoHashKey  hashKey of video of interest
 * @param phoneNumber   phone number of member of interest
 *
 * @return relative URL
 */
+ (NSString *)videoMemberDetailURL:(NSString *)videoHashKey member:(NSString *)phoneNumber;



@end
