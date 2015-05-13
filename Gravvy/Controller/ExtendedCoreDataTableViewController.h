//
//  ExtendedCoreDataTableViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 10/28/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "ExtendedTableViewController.h"
#import <CoreData/CoreData.h>

/**
 * This class mostly just copies the code from NSFetchedResultController's
 *   documentation page into a subclass of ExtendedTableViewController
 *
 * Just subclass this and set the fetchedResultsController
 * The only UITableViewDataSource method you have to implement is
 *   tableView:cellForRowAtIndexPath: and you can use NSFetchedResultsController's
 *   method objectAtIndexPath: to do it.
 *
 * @note Remember that once you create an NSFetchedResultsController you CANNOT modify
 *   its properties.
 * If you want to create new fetch parameters (predicate, sorting, etc),
 *   create a NEW NSFetchedResultsController and set this class's
 *   fetchedResultsController again.
 *
 *  @warning This class is intended to be subclassed. You should not use it directly.
 */
@interface ExtendedCoreDataTableViewController : ExtendedTableViewController <NSFetchedResultsControllerDelegate>

#pragma mark - Properties

/**
 * The controller (this class) fetches nothing if this is not set
 */
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

/**
 * Turn this on before making any changes in the managed object context that
 *   are a one-to-one result of user manipulating rows in the table view.
 * Such changes cause the context to report them after a brief delay
 *   and normally our fetchedResultsController will try to update the table,
 *   but that is unnecessary because the changes were made in the table already
 *   (by the user) so the fetchedResultsController has nothing to do but ignore
 *   these notifications.
 * Turn this back on after the user has finished the change.
 * NOTE that the effect of setting this to NO actually gets delayed slighty
 *   so as to ignore previously-posted, but not yet processed context-changed
 *   notifications. therefore it is fine to set this to YES at the beginning of,
 *   e.g. tableView:moveRowAtIndexPath:toIndexPath:, and then set it back to NO
 *   at the end of your implementation of that method.
 * It is not necessary (in fact, not desirable) to set this during row deletion
 *   or insertion (but definitely for row moves).
 * This is called `changeIsUserDriven` in documentation of delegate
 *
 * Default is NO
 */
@property (nonatomic) BOOL suspendAutomaticTrackingOfChangesInManagedObjectContext;

/**
 * Set to YES to get some debugging output in the console. Default is NO.
 */
@property BOOL debug;


#pragma mark - Instance Methods

/**
 * Causes the fetchedResultsController to refetch the data.
 * You almost certainly never need to call this.
 * The fetchedResultsController observes the context
 *   (so if objects in the context change, you do not need to call performFetch
 *   since the fetchedResultsController will notice and update the table automatically).
 * This will also be automatically called if you change the fetchedResultsController
 *   property.
 */
- (void)performFetch;


/**
 * Map FRC's indexPaths to and from the FRC's default section(s) to new
 * tableView sections.
 * The default implementation returns the argument as-is.
 *
 * @warning If using these utility, be sure to call mapIndexPathToFetchedResultsController: 
 *      in tableView:cellForRowAtIndexPath: before calling FRC's objectAtIndexPath:
 *
 * @discussion  Use these utility methods if you want to place the results
 *      of the fetched results controller in sections other than the defaults 
 *      (starting at section 0). This comes in handy when trying to prepend
 *      rows/section or mixing dynamic and static UITableViewCells.
 *
 * @param indexPath indexPath to be mapped
 *
 * @return mapped indexPath.
 *
 * @ref http://stackoverflow.com/a/11878827
 */
// Map indexPath from value given by FRC
- (NSIndexPath *)mapIndexPathFromFetchedResultsController:(NSIndexPath *)indexPath;
// Map indexPath to a value to be consumed by FRC
- (NSIndexPath *)mapIndexPathToFetchedResultsController:(NSIndexPath *)indexPath;

/**
 * Similar mapping as for indexPaths but specific to just sections
 */
- (NSInteger)mapSectionFromFetchedResultsController:(NSInteger)section;
- (NSInteger)mapSectionToFetchedResultsController:(NSInteger)section;


@end
