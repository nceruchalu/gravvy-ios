//
//  GRVCountrySelectTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCountrySelectTVC.h"
#import "GRVRegionStore.h"
#import "GRVRegion.h"

/**
 * Constants
 */
static NSString *const kUnwindSegueIdentifier = @"SelectedCountry";

@interface GRVCountrySelectTVC ()

// View's model: Collections of GRVRegion objects and their groups
@property (strong, nonatomic, readonly) NSArray *regions;
@property (strong, nonatomic, readonly) NSDictionary *regionGroups;
@property (strong, nonatomic, readonly) NSArray *regionGroupTitles;

// VC output is readwrite internally
@property (strong, nonatomic, readwrite) GRVRegion *selectedRegion;

@end

@implementation GRVCountrySelectTVC

#pragma mark - Properties
@synthesize regions = _regions;
@synthesize regionGroups = _regionGroups;
@synthesize regionGroupTitles = _regionGroupTitles;

- (NSArray *)regions
{
    // lazy instantiation
    if (!_regions) _regions = [GRVRegionStore sharedStore].allRegions;
    return _regions;
}

- (NSDictionary *)regionGroups
{
    // lazy instantiation
    if (!_regionGroups)_regionGroups = [GRVRegionStore sharedStore].allRegionsGrouped;
    return _regionGroups;
}

- (NSArray *)regionGroupTitles
{
    // lazy instantiation
    if (!_regionGroupTitles) _regionGroupTitles = [[self.regionGroups allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    return _regionGroupTitles;
}

#pragma mark - View LifeCycle
- (void)viewDidLoad {
    [super viewDidLoad];
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Get the region given an index path of the table view.
 *
 * @param indexPath     UiTableView index path
 *
 * @return an GRVRegion instance
 */
- (GRVRegion *)regionForIndexPath:(NSIndexPath *)indexPath
{
    NSString *regionGroupTitle = [self.regionGroupTitles objectAtIndex:indexPath.section];
    NSArray *regionGroup = [self.regionGroups objectForKey:regionGroupTitle];
    GRVRegion *region = [regionGroup objectAtIndex:indexPath.row];
    return region;
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return [self.regionGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    NSString *regionGroupTitle = [self.regionGroupTitles objectAtIndex:section];
    return [[self.regionGroups objectForKey:regionGroupTitle] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Country Select Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier
                                                            forIndexPath:indexPath];
    
    // Get the assocated region
    
    // Configure the cell...
    GRVRegion *region = [self regionForIndexPath:indexPath];
    cell.textLabel.text = region.regionName;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"+%@", region.countryCode];
    
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.regionGroupTitles objectAtIndex:section];
}

// Show section index Titles
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return self.regionGroupTitles;
}


#pragma mark - Navigation
- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifier
                fromIndexPath:(NSIndexPath *)indexPath
{
    GRVRegion *region = [self regionForIndexPath:indexPath];
    if (![segueIdentifier length] || [segueIdentifier isEqualToString:kUnwindSegueIdentifier]) {
        // prepare source vc
        self.selectedRegion = region;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    
    [self prepareViewController:segue.destinationViewController
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailVC = [self.splitViewController.viewControllers lastObject];
    if ([detailVC isKindOfClass:[UINavigationController class]]) {
        detailVC = [((UINavigationController *)detailVC).viewControllers firstObject];
        [self prepareViewController:detailVC
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}


@end
