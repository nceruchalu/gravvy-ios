//
//  GRVExtendedCoreDataTableViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/16/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVExtendedCoreDataTableViewController.h"
#import "GRVConstants.h"
#import "GRVModelManager.h"

@interface GRVExtendedCoreDataTableViewController ()

#pragma mark - Properties
#pragma mark Outlets
/**
 * Empty-state view to be displayed when there is no data,
 * @ref http://emptystat.es
 */
@property (weak, nonatomic) IBOutlet UIView *emptyStateView;

@end

@implementation GRVExtendedCoreDataTableViewController

#pragma mark - Properties
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    [self setupFetchedResultsController];
}

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupRefreshControl];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // setup the managedObjectContext @property
    self.managedObjectContext = [GRVModelManager sharedManager].managedObjectContext;
    
    // register observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedObjectContextReady:)
                                                 name:kGRVMOCAvailableNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kGRVMOCAvailableNotification
                                                  object:nil];
}

#pragma mark - Instance Methods
#pragma mark Abstract
- (void)setupFetchedResultsController
{
    // abstract
    [self showOrHideEmptyStateView];
}

#pragma mark Private
/**
 * Setup Refresh Control so it is similar to what is expected from a
 * UITableViewController.
 *
 * @ref: http://stackoverflow.com/a/12502450
 */
- (void)setupRefreshControl
{
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
    
    self.refreshControl.tintColor = kGRVThemeColor;
}


#pragma mark Empty State View
- (void)showOrHideEmptyStateView
{
    if ([self.fetchedResultsController.fetchedObjects count] > 0 ) {
        // if there are contents to display then hide empty state view
        self.emptyStateView.hidden = YES;
    } else {
        // Nothing to dispaly, so show user something informative
        self.emptyStateView.hidden = NO;
    }
}


#pragma mark - Target/Action Methods
- (IBAction)refresh
{
    [self.refreshControl endRefreshing];
}


#pragma mark - NSFetchedResultsControllerDelegate
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [super controllerDidChangeContent:controller];
    [self showOrHideEmptyStateView];
}


#pragma mark - Notification Observer Methods
/**
 * ManagedObjectContext now available from EVTModelManager so update local copy
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    self.managedObjectContext = [GRVModelManager sharedManager].managedObjectContext;
}


@end
