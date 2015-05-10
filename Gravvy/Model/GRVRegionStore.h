//
//  GRVRegionStore.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * GRVRegionStore is a singleton class that ensures we have just one instance
 * of the RegionStore throughout this application.
 */
@interface GRVRegionStore : NSObject

#pragma mark - Properties
/**
 * All regions supported by this application.
 * Regions sorted in ascending order of regionName @property
 */
@property (copy, nonatomic, readonly) NSArray *allRegions;

/**
 * Region groupings, where regions are grouped by the first character of
 * regionName @property
 * Each region group entry is a key-value pair where the key is the group title
 * (first character of all regions in group) and the value is the list of regions.
 * This is handy if trying to populate an indexed list UITableView.
 */
@property (copy, nonatomic, readonly) NSDictionary *allRegionsGrouped;


#pragma mark - Class Methods
/**
 * Single instance.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized GRVRegionStore object.
 */
+ (instancetype)sharedStore;


#pragma mark - Initalizers


#pragma mark - Instance Methods


@end
