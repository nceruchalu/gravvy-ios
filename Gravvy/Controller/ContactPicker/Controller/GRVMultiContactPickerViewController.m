//
//  GRVMultiContactPickerViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVMultiContactPickerViewController.h"
#import "GRVModelManager.h"
#import "GRVConstants.h"
#import "GRVUser.h"
#import "GRVMultiContactPickerTableViewCell.h"
#import "GRVUserViewHelper.h"

#pragma mark - Constants
/**
 * TableViewCell Identifier and nib name for multi contact picker cell
 */
static NSString *const kMultiContactCellIdentifier  = @"Multi Contact Cell";
static NSString *const kMultiContactCellNibName     = @"GRVMultiContactPickerTableViewCell";

/**
 * Title of Multi-Contact Picker's navigationItem
 */
static NSString *const kMultiContactPickerTitle = @"Contacts";

@interface GRVMultiContactPickerViewController ()

#pragma mark - Properties

#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

#pragma mark - Properties
/**
 * Internally managed copy of the selected contacts
 */
@property (strong, nonatomic) NSMutableArray *privateSelectedContacts;

/**
 * need this property to get a handle to the database
 */
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end


@implementation GRVMultiContactPickerViewController

#pragma mark - Properties
- (NSArray *)selectedContacts
{
    return [self.privateSelectedContacts copy];
}

- (void)setSelectedContacts:(NSArray *)selectedContacts
{
    self.privateSelectedContacts = [NSMutableArray arrayWithArray:selectedContacts];
    [self updateDoneButton];
}

- (NSMutableArray *)privateSelectedContacts
{
    // lazy instantiation
    if (!_privateSelectedContacts) _privateSelectedContacts = [NSMutableArray array];
    return _privateSelectedContacts;
}

- (NSArray *)excludedContactPhoneNumbers
{
    // lazy instantiation
    if (!_excludedContactPhoneNumbers) _excludedContactPhoneNumbers = [NSArray array];
    return _excludedContactPhoneNumbers;
}

/**
 * This view controller cannot function until the managed object context is set
 */
- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    [self setupFetchedResultsController];
}


#pragma mark - Class Methods
+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([GRVMultiContactPickerViewController class])
                          bundle:[NSBundle mainBundle]];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    // Load all subviews and setup outlets before calling superclass' viewDidLoad
    [[[self class] nib] instantiateWithOwner:self options:nil];
    [super viewDidLoad];
    
    self.title = kMultiContactPickerTitle;
    
    // load the cell nib files and register.
    UINib *multiContactCellNib = [UINib nibWithNibName:kMultiContactCellNibName bundle:nil];
    [self.tableView registerNib:multiContactCellNib forCellReuseIdentifier:kMultiContactCellIdentifier];
    
    // Repeat any outlet actions performed in property setters as outlets might
    // not have been available when the setters were called
    [self updateDoneButton];
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
#pragma mark Private

/**
 * Hook up fetchedResultsController property to a users request
 *
 * Creates an NSFetchRequest for GRVUsers sorted by full name.
 *
 * This NSFetchRequest is used to build  our NSFetchedResultsController @property
 * inherited from ExtendedCoreDataTableViewController.
 */
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVUser"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[@"contact"];
        
        // Don't forget that we are in a View Controller where we only show users
        // that have an associated address book contact and haven't been excluded
        request.predicate = [NSPredicate predicateWithFormat:@"(contact != nil) AND (NOT (phoneNumber IN[c] %@))", self.excludedContactPhoneNumbers];
        
        NSSortDescriptor *firstNameSort = [NSSortDescriptor sortDescriptorWithKey:@"contact.firstName" ascending:YES];
        NSSortDescriptor *lastNameSort = [NSSortDescriptor sortDescriptorWithKey:@"contact.lastName" ascending:YES];
        request.sortDescriptors = @[firstNameSort, lastNameSort];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"contact.sectionIdentifier" cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
    
}


/**
 * Get user's index in array of selected users
 *
 * @param user  GRVUser of interest
 *
 * @return user's index in array or NSNotFound
 */
- (NSInteger)userIndexInSelectedContacts:(GRVUser *)user
{
    return [self.privateSelectedContacts indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ([((GRVUser *)obj).phoneNumber isEqualToString:user.phoneNumber]) {
            *stop = YES;
            return YES;
        }
        return NO;
    }];
}


/**
 * Change selection state for user at a given indexPath
 *
 * @param indexPath index path of user of index
 */
- (void)changeContactSelectionAtIndexPath:(NSIndexPath *)indexPath
{
    // Get user of interest
    GRVUser *selectedUser = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Get user's index in array of selected contacts (if selected)
    NSInteger selectedUserIndex = [self userIndexInSelectedContacts:selectedUser];
    
    if (selectedUserIndex != NSNotFound) {
        // if user is already selected then unselect by removing from
        // tracking array iff user is already in there
        [self.privateSelectedContacts removeObjectAtIndex:selectedUserIndex];
        
    } else {
        // if user is unselected then select by adding to tracking array
        // iff not already in there
        [self.privateSelectedContacts addObject:selectedUser];
    }
    
    // toggle selection button state
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    
    [self updateDoneButton];
}

/**
 * Configure done button based on the selected contacts
 */
- (void)updateDoneButton
{
    // only enable done button if at least 1 selected contact
    self.doneButton.enabled = ([self.privateSelectedContacts count] > 0);
}


#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GRVMultiContactPickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMultiContactCellIdentifier forIndexPath:indexPath];
    GRVUser *user = [self.fetchedResultsController objectAtIndexPath:indexPath];
    //   configure the cell with data from the managed object
    
    // Configure the cell...
    cell.displayNameLabel.text = [GRVUserViewHelper userFullName:user];
    cell.phoneNumberLabel.text = [GRVUserViewHelper userPhoneNumber:user];
    cell.selectionButton.selected = ([self userIndexInSelectedContacts:user] != NSNotFound);
    
    [cell.selectionButton addTarget:self action:@selector(changedContactSelection:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSArray *aToZ = @[@"#", @"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H",
                      @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q",
                      @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z"];
    return aToZ;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    NSArray *sectionTitles = [self.fetchedResultsController sectionIndexTitles];
    NSInteger count = 0;
    for (NSString *character in sectionTitles) {
        if ([title length] > 0) {
            // if a match between title and an actual section index character
            // return the postiion of this section index char
            if ([character isEqualToString:[title substringToIndex:1]]) {
                return count;
            }
            
            // if the current section index character has a greater ASCII value
            // than the given title's ASCII value, then we've gone too far so
            // return last index. But dont return a negative number!
            unichar characterAscii = [character characterAtIndex:0];
            unichar titleAscii = [title characterAtIndex:0];
            if (characterAscii > titleAscii) {
                return MAX((count - 1), 0);
            }
        }
        
        // On to the next index
        count ++;
    }
    
    // Couldnt find it yet? Then return last index
    return MAX((count - 1), 0);
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self changeContactSelectionAtIndexPath:indexPath];
}


#pragma mark - Target/Action Methods
- (IBAction)cancel
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

// User tapped selection button
- (IBAction)changedContactSelection:(UIButton *)sender
{
    // Get corresponding cell
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    // to ensure the button indeed is in a cell: I know this is overkill...
    if (indexPath) {
        [self changeContactSelectionAtIndexPath:indexPath];
    }
}

- (IBAction)done:(UIBarButtonItem *)sender
{
    // We want to return selected contacts in the same order as they are presented
    // So update the private tracker here
    NSArray *sortDescriptors = self.fetchedResultsController.fetchRequest.sortDescriptors;
    NSArray *sortedSelectedContacts = [self.privateSelectedContacts sortedArrayUsingDescriptors:sortDescriptors];
    self.privateSelectedContacts = [sortedSelectedContacts mutableCopy];
    
    [self.delegate multiContactPickerDoneSelectingContacts:sortedSelectedContacts];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Notification Observer Methods
/**
 * ManagedObjectContext now available from GRVModelManager so update local copy
 */
- (void)managedObjectContextReady:(NSNotification *)aNotification
{
    self.managedObjectContext = [GRVModelManager sharedManager].managedObjectContext;
}


@end
