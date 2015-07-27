//
//  GRVExtendedCoreDataTableViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/16/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "ExtendedCoreDataTableViewController.h"

/**
 * App-specific customizations to the ExtendedCoreDataTableViewController
 * class
 * 
 * @warning This class is intended to be subclassed by the Activities and Videos
 * VCs
 */
@interface GRVExtendedCoreDataTableViewController : ExtendedCoreDataTableViewController

#pragma mark - Properties
/**
 * Refresh Control with logic as seen here: http://stackoverflow.com/a/12502450
 */
@property (strong, nonatomic) UIRefreshControl *refreshControl;

/**
 * Handle to the database
 */
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


#pragma mark - Instance Methods
/**
 * Show/hide the empty state view by checking if there is any data from
 * the fetched results controller
 */
- (void)showOrHideEmptyStateView;

/**
 * Height of table view footer when tableview is displayed
 */
- (CGFloat)tableViewFooterHeight;

#pragma mark Abstract
/**
 * Hook up fetchedResultsController property to a Core Data request
 *
 * This NSFetchRequest is used to build  our NSFetchedResultsController @property
 * inherited from CoreDataTableViewController.
 *
 * Assumption: This method is only called when self.managedObjectContext has been
 * configured.
 *
 * @warning This method is intended to be overriden.
 */
- (void)setupFetchedResultsController;

#pragma mark - Target/Action Methods
/**
 * Refresh the objects displayed in the table view from the server.
 * When done be sure to stop the refresh control.
 *
 * @warning This method is intended to be overriden.
 */
- (IBAction)refresh;

@end
