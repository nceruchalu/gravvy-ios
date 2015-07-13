//
//  GRVRegionStore.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVRegionStore.h"
#import "GRVRegion.h"

@implementation GRVRegionStore

#pragma mark - Properties


#pragma mark - Class Methods

// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedStore
{
    static GRVRegionStore *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}


#pragma mark - Initializers
/*
 * ideally we would make the designated initializer of the superclass call
 *   the new designated initializer, but that doesn't make sense in this case.
 * if a programmer calls [GRVRegionStore alloc] init], let them know the error
 *   of their ways.
 */
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use +[GRVRegionStore sharedStore]"
                                 userInfo:nil];
    return nil;
}


// here is the real (secret) initializer
// this is the official designated initializer so call the designated
// initializer of the superclass
- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        
        // Setup all regions being careful to only add supported regions
        NSMutableArray *privateRegions = [[NSMutableArray alloc] init];
        
        NSArray *regionCodes = [NSLocale ISOCountryCodes];
        for (NSString *regionCode in regionCodes) {
            GRVRegion *region = [[GRVRegion alloc] initWithRegionCode:regionCode];
            if (region) [privateRegions addObject:region];
        }
        
        // Now sort all supported regions
        NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"regionName" ascending:YES];
        _allRegions = [privateRegions sortedArrayUsingDescriptors:@[sd]];
        
        
        // Setup region groups
        NSMutableDictionary *privateRegionGroups = [[NSMutableDictionary alloc] init];
        for (GRVRegion *region in _allRegions) {
            NSString *regionGroupTitle = [region.regionName substringToIndex:1];
            NSMutableArray *regionGroup = [privateRegionGroups objectForKey:regionGroupTitle];
            if (!regionGroup) {
                regionGroup = [[NSMutableArray alloc] initWithArray:@[region]];
            } else {
                [regionGroup addObject:region];
            }
            [privateRegionGroups setObject:regionGroup forKey:regionGroupTitle];
        }
        _allRegionsGrouped = privateRegionGroups;
    }
    return self;
}


@end
