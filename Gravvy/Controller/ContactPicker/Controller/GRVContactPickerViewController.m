//
//  GRVContactPickerViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContactPickerViewController.h"
#import "GRVModelManager.h"
#import <CoreData/CoreData.h>
#import "GRVUser.h"
#import "GRVContactPickerTableViewCell.h"
#import "GRVSelectedContactPickerTableViewCell.h"
#import "GRVContact+AddressBook.h"
#import "GRVAddressBookManager.h"
#import "GRVUserViewHelper.h"
#import "GRVUserAvatarView.h"
#import "GRVMultiContactPickerViewController.h"
#import "GRVConstants.h"

#pragma mark - Constants

/**
 * TableViewCell Identifier and nib name for contact cell when user has been selected
 */
static NSString *const kSelectedContactCellIdentifier = @"Selected Contact Cell";
static NSString *const kSelectedContactCellNibName    = @"GRVSelectedContactPickerTableViewCell";

/**
 * TableViewCell Identifier and nib name for contact cell when user is presented in search
 * results
 */
static NSString *const kFilteredContactCellIdentifier = @"Filtered Contact Cell";
static NSString *const kFilteredContactCellNibName    = @"GRVFilteredContactPickerTableViewCell";

@interface GRVContactPickerViewController () <GRVMultiContactPickerDelegate,
                                                UITextFieldDelegate>

#pragma mark - Properties
/**
 * Internally managed copy of the selected contacts
 */
@property (strong, nonatomic) NSMutableArray *privateSelectedContacts;

/**
 * Filtered contacts derived by filtering contacts based on user full names.
 */
@property (strong, nonatomic) NSArray *filteredContacts;

/**
 * Flag indicating if we are currently showing filtered contacts or not
 */
@property (nonatomic) BOOL showFilteredContacts;


#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIView *topBorderView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
// Search Results Table View is the tableView @property
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;

@end

@implementation GRVContactPickerViewController

#pragma mark - Properties
- (NSArray *)selectedContacts
{
    return [self.privateSelectedContacts copy];
}

- (NSMutableArray *)privateSelectedContacts
{
    // lazy instantiation
    if (!_privateSelectedContacts) _privateSelectedContacts = [NSMutableArray array];
    return _privateSelectedContacts;
}

- (NSArray *)filteredContacts
{
    // lazy instantiation
    if (!_filteredContacts) _filteredContacts = [NSArray array];
    return _filteredContacts;
}

- (NSArray *)excludedContactPhoneNumbers
{
    // lazy instantiation
    if (!_excludedContactPhoneNumbers) _excludedContactPhoneNumbers = [NSArray array];
    return _excludedContactPhoneNumbers;
}

#pragma mark - Class Methods
+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([GRVContactPickerViewController class])
                          bundle:[NSBundle mainBundle]];
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    // Load all subviews and setup outlets before calling superclass' viewDidLoad
    [[[self class] nib] instantiateWithOwner:self options:nil];
    [super viewDidLoad];
    
    // load the cell nib files and register.
    UINib *selectedCellNib = [UINib nibWithNibName:kSelectedContactCellNibName bundle:nil];
    [self.tableView registerNib:selectedCellNib forCellReuseIdentifier:kSelectedContactCellIdentifier];
    
    UINib *filteredCellNib = [UINib nibWithNibName:kFilteredContactCellNibName bundle:nil];
    [self.tableView registerNib:filteredCellNib forCellReuseIdentifier:kFilteredContactCellIdentifier];
    
    // Setup table view to dismiss keyboard when it is scrolled.
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    
    [self refreshTableView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateTopConstraints];
}

#pragma mark - Instance Methods
#pragma mark Private

/**
 * Update constraints so that content starts below top layout guide
 */
- (void)updateTopConstraints
{
    // Adjust view insets so it isnt blocked by navigation bar
    //self.edgesForExtendedLayout = UIRectEdgeNone;
    UIView *topView = self.topBorderView;
    [topView setTranslatesAutoresizingMaskIntoConstraints:NO];
    id topGuide = self.topLayoutGuide;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(topView, topGuide);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topGuide]-0-[topView]" options:0 metrics:nil views:viewsDictionary]];
    
    [self.view layoutSubviews];
}

/**
 * Refresh table view with the following logic
 * - hide the table view if no filtered nor selected contacts
 * - only show filtered contacts if there are any and only then can you select tableview rows
 * - reloadData
 */
- (void)refreshTableView
{
    self.tableView.hidden = ![self.filteredContacts count] && ![self.privateSelectedContacts count];
    
    self.showFilteredContacts = [self.filteredContacts count] > 0;
    self.tableView.allowsSelection = self.showFilteredContacts;
    [self.tableView reloadData];
}

/**
 * Check if a given user is already selected
 *
 * @param user GRVUser of interest
 *
 * @return boolean indicating if user is already selected
 */
- (BOOL)userIsSelected:(GRVUser *)user
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"phoneNumber == %@", user.phoneNumber];
    NSArray *selectedContactsMatchingUser = [self.privateSelectedContacts filteredArrayUsingPredicate:predicate];
    return ([selectedContactsMatchingUser count] > 0);
}


/**
 * Done selecting contacts either from the search results, multi-contact picker 
 * or group picker.
 *
 * So undo any search in progress, hide search results table view and show the
 * selected contacts data. Show selected contacts by clearing out filtered data 
 * and refreshing the table view.
 */
- (void)contactsHaveBeenSelected
{
    self.searchTextField.text = nil;
    self.filteredContacts = nil;
    [self refreshTableView];
    [self selectedContactsChanged];
}


#pragma mark Search Content Filtering
/**
 * Update the filteredContacts after performing a search limiting results
 * to the specified search query
 *
 * @param searchString  search query string (user fullName)
 */
- (void)updateFilteredContentForSearchString:(NSString *)searchString
{
    // strip out all the leading and trailing spaces
    NSString *strippedSearchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // skip the searching and reload tableview now if there isn't a search string
    if (![strippedSearchString length]) {
        self.filteredContacts = nil;
        [self refreshTableView];
        return;
    }
    
    // break up the search terms (separated by spaces)
    NSArray *searchItems = [strippedSearchString componentsSeparatedByString:@" "];
    
    // build all the expressions for each value in the searchString
    NSPredicate *firstNameStartsWithQuery = [NSPredicate predicateWithFormat:@"contact.firstName BEGINSWITH[c] %@", strippedSearchString];
    NSPredicate *firstNameAndLastNameInQuery =[ NSPredicate predicateWithFormat:@"(contact.firstName BEGINSWITH[c] %@) && (contact.lastName BEGINSWITH[c] %@)", [searchItems firstObject], [searchItems lastObject]];
    NSPredicate *lastNameStartsWithQuery = [NSPredicate predicateWithFormat:@"contact.lastName BEGINSWITH[c] %@", strippedSearchString];
    
    NSArray *fullNamePredicates = @[firstNameStartsWithQuery, firstNameAndLastNameInQuery, lastNameStartsWithQuery];
    
    // combine all the match predicates by "OR"s
    NSCompoundPredicate *fullNameMatchPredicate = (NSCompoundPredicate *)[NSCompoundPredicate orPredicateWithSubpredicates:fullNamePredicates];
    
    // Don't forget that we are in a View Controller where we only show results
    // that meet the following conditions:
    // - users have an associated Address book contact.
    // - user is not already in list of selected numbers
    // - user is not excluded
    NSMutableArray *selectedPhoneNumbers = [NSMutableArray array];
    for (GRVUser *selectedUser in self.privateSelectedContacts) {
        [selectedPhoneNumbers addObject:selectedUser.phoneNumber];
    }
    NSPredicate *inAddressBookAndUnselectedAndNotExcludedPredicate = [NSPredicate predicateWithFormat:@"(contact != nil) AND (NOT (phoneNumber IN[c] %@)) AND (NOT (phoneNumber IN[c] %@))", selectedPhoneNumbers, self.excludedContactPhoneNumbers];
    
    NSCompoundPredicate *finalCompoundPredicate = (NSCompoundPredicate *)[NSCompoundPredicate andPredicateWithSubpredicates:@[fullNameMatchPredicate, inAddressBookAndUnselectedAndNotExcludedPredicate]];
    
    // Finally make fetch request
    NSManagedObjectContext *managedObjectContext = [GRVModelManager sharedManager].managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVUser"];
    request.relationshipKeyPathsForPrefetching = @[@"contact"];
    
    request.sortDescriptors = [GRVUserViewHelper userNameSortDescriptors];
    request.predicate = finalCompoundPredicate;
    
    NSError *error;
    self.filteredContacts = [managedObjectContext executeFetchRequest:request error:&error];
    [self refreshTableView];
}


#pragma mark Public (Concrete)
- (void)startSpinner
{
    [self.spinner startAnimating];
}

- (void)stopSpinner
{
    [self.spinner stopAnimating];
}

- (void)selectedContactsChanged
{
    // Nothing to do here
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    // The model depends on whether we are showing filtered contacts. If there
    // aren't then the model is simply the selected contacts
    return (self.showFilteredContacts) ? [self.filteredContacts count] : [self.privateSelectedContacts count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GRVContactPickerTableViewCell *cell = nil;
    GRVUser *user = nil;
    
    // The model depends on whether we are showing filtered contacts. If there
    // aren't then the model is simply the selected contacts
    if (self.showFilteredContacts) {
        cell = [tableView dequeueReusableCellWithIdentifier:kFilteredContactCellIdentifier forIndexPath:indexPath];
        user = [self.filteredContacts objectAtIndex:indexPath.row];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:kSelectedContactCellIdentifier forIndexPath:indexPath];
        user = [self.privateSelectedContacts objectAtIndex:indexPath.row];
        // Add target/action method for deselect/remove button
        [self configureSelectedCellRemoveButton:(GRVSelectedContactPickerTableViewCell *)cell forIndexPath:indexPath];
    }
    
    // Configure the cell...
    // Avatar first
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:user];
    cell.avatarView.thumbnail = avatarView.thumbnail;
    cell.avatarView.userInitials = avatarView.userInitials;
    
    // Display name
    cell.displayNameLabel.text = [GRVUserViewHelper userFullName:user];
    
    // Finally phone number
    cell.phoneNumberLabel.text = [GRVUserViewHelper userPhoneNumber:user];
    
    return cell;
}

#pragma mark - Helper
- (void)configureSelectedCellRemoveButton:(GRVSelectedContactPickerTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath
{
    cell.removeButton.tag = indexPath.row;
    [cell.removeButton addTarget:self action:@selector(deselectContact:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    GRVUser *selectedUser = [self.filteredContacts objectAtIndex:indexPath.row];

    // Add selectedUser if it doesnt already exist in private Selected Contacts
    if (![self userIsSelected:selectedUser]) {
        [self.privateSelectedContacts addObject:selectedUser];
    }
    
    [self contactsHaveBeenSelected];
}


#pragma mark - Target/Action Methods
- (IBAction)textFieldDidChange:(UITextField *)textField
{
    if (textField == self.searchTextField) {
        [self updateFilteredContentForSearchString:textField.text];
    }
}

/**
 * Remove contact from array of selected contacts
 * Be sure to do this with some animation by calling tableView's beginUpdates
 * and endUpdates
 */
- (IBAction)deselectContact:(UIButton *)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero
                                           toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    
    // to ensure the button indeed is in a cell: I know this is overkill...
    if (indexPath) {
        // Get appropriate contact and remove it being sure to not exceed
        // bounds of array
        if (indexPath.row < [self.privateSelectedContacts count]) {
            [self.tableView beginUpdates];
            [self.privateSelectedContacts removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView endUpdates];
            
            // hide table view if there's nothing left in selected contacts
            self.tableView.hidden = ([self.privateSelectedContacts count] == 0);
            [self selectedContactsChanged];
        }
    }
}

- (IBAction)presentMultiContactPicker:(UIButton *)sender
{
    GRVMultiContactPickerViewController *multiContactPickerVC = [[GRVMultiContactPickerViewController alloc] initWithNibName:nil bundle:nil];
    multiContactPickerVC.selectedContacts = [self.privateSelectedContacts copy];
    multiContactPickerVC.excludedContactPhoneNumbers = self.excludedContactPhoneNumbers;
    multiContactPickerVC.delegate = self;
    
    // Wrap the multi-contact picker VC is a Navigation View Controller
    UINavigationController *wrapperNVC = [[UINavigationController alloc] initWithRootViewController:multiContactPickerVC];
    [self presentViewController:wrapperNVC animated:YES completion:nil];
}


#pragma mark GRVMultiContactPickerDelegate
/**
 * Selected multiple contacts from Multi-contact picker so use those in this
 * contact picker
 */
- (void)multiContactPickerDoneSelectingContacts:(NSArray *)selectedContacts
{
    // overwrite our private tracker of selected contacts with the output of
    // the multi-contact picker
    self.privateSelectedContacts = [selectedContacts mutableCopy];
    
    [self contactsHaveBeenSelected];
}


@end
