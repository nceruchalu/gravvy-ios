//
//  GRVRegion.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * GRVRegion is the representation of Phone number regions which include,
 * region code (ex: "US"), region name (ex: "United States") and country code
 * (ex: 1)
 */
@interface GRVRegion : NSObject

#pragma mark - Properties
/**
 * regionCode is the ISO 3166-1 Alpha-2 code for the name of a Country.
 * Ex: For the United States this is "US".
 */
@property (nonatomic, copy, readonly) NSString *regionCode;

/**
 * regionName is the full name of a Country.
 * Ex: "United States".
 */
@property (nonatomic, copy, readonly) NSString *regionName;

/**
 * countryCode is the international country calling code used in E.164 format
 * phone numbers.
 * Ex: For the United States this is 1.
 */
@property (nonatomic, strong, readonly) NSNumber *countryCode;


#pragma mark - Initializers

/**
 * Designated initializer.
 *
 * @param regionCode    region code used to derive the region name and country
 *      code.
 *
 * @return full instantiated object or nil if regionCode is invalid or not
 *      supported by libPhoneNumber
 */
- (instancetype)initWithRegionCode:(NSString *)regionCode;

@end
