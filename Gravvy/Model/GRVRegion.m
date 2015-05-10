//
//  GRVRegion.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVRegion.h"
#import "NBPhoneNumberUtil+Shared.h"
#import "GRVFormatterUtils.h"

@interface GRVRegion ()

// Want all properties to be read-write internally
@property (nonatomic, copy, readwrite) NSString *regionCode;
@property (nonatomic, copy, readwrite) NSString *regionName;
@property (nonatomic, strong, readwrite) NSNumber *countryCode;

@end

@implementation GRVRegion

#pragma mark - Initializers
#pragma mark Public
/*
 * ideally we would make the designated initializer of the superclass call
 *   the new designated initializer, but that doesn't make sense in this case.
 * if a programmer calls [GRVRegion alloc] init], let them know the error
 *   of their ways.
 */
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Missing properties"
                                   reason:@"Use + [GRVRegion alloc] initWithRegionCode:"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initWithRegionCode:(NSString *)regionCode
{
    
    // All we have is a region code so determine region name and country code
    NSNumber *countryCode = [[NBPhoneNumberUtil sharedUtilInstance] getCountryCodeForRegion:regionCode];
    
    // This region code is only supported if we can get a country code
    if ([countryCode integerValue]) {
        NSString *identifier = [NSLocale localeIdentifierFromComponents:@{NSLocaleCountryCode: regionCode}];
        NSString *regionName = [[GRVFormatterUtils unitedStatesLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
        
        self = [self initWithRegionCode:regionCode regionName:regionName countryCode:countryCode];
    } else {
        self = nil;
    }
    
    return self;
}

#pragma mark Private
- (instancetype)initWithRegionCode:(NSString *)regionCode regionName:(NSString *)regionName countryCode:(NSNumber *)countryCode
{
    if (self =[super init]) {
        self.regionCode = regionCode;
        self.regionName = regionName;
        self.countryCode = countryCode;
    }
    return self;
}

@end
