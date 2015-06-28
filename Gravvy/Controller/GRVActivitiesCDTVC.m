//
//  GRVActivitiesCDTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/11/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVActivitiesCDTVC.h"
#import "GRVActivity+HTTP.h"
#import "GRVVideo.h"
#import "GRVUser.h"
#import "GRVActivityTableViewCell.h"
#import "GRVUserViewHelper.h"
#import "UIImageView+WebCache.h"
#import "GRVAccountManager.h"
#import "GRVFormatterUtils.h"
#import "GRVConstants.h"

#pragma mark - Constants
/**
 * Attributed string properties of Activity Table View Cells
 */
// font name of regular text in the description attributed string
static NSString * const kDescriptionStringFontName = @"HelveticaNeue";
// font name of emphasized text in the description attributed string
static NSString * const kDescriptionEmphasizedStringFontName = @"HelveticaNeue-Bold";

// font size of description attributed string
static CGFloat const kDescriptionStringFontSize = 13.0f;
// font size of timestamp attributed string
static CGFloat const kTimestampStringFontSize = 11.0f;

// color of description attributed string: #262626
#define kDescriptionStringColor [UIColor colorWithRed:38.0/255.0 green:38.0/255.0 blue:38.0/255.0 alpha:1.0]
// color of timestamp attributed string: #959595
#define kTimestampStringColor [UIColor colorWithRed:149.0/255.0 green:149.0/255.0 blue:149.0/255.0 alpha:1.0]

// Max character count of displayed video title.
static NSUInteger const kMaxDisplayedVideoTitleLength = 30;


@interface GRVActivitiesCDTVC ()

@end

@implementation GRVActivitiesCDTVC


#pragma mark - View Lifecycle
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // register observers
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactsRefreshed:)
                                                 name:kGRVContactsRefreshedNotification
                                               object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    // remove observers
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kGRVContactsRefreshedNotification
                                                  object:nil];
}


#pragma mark - Instance Methods
#pragma mark Concrete
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVActivity"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[@"actor", @"objectClip", @"objectUser", @"objectVideo", @"targetVideo"];
        
        // fetch activies involving only users in our address book
        // actor is in address book
        NSPredicate *actorsInAddressBookPredicate = [NSPredicate predicateWithFormat:@"actor.contact != nil"];
        // object is a user and in our address book
        NSPredicate *objectUsersInAddressBookPredicate = [NSPredicate predicateWithFormat:@"(objectUser != nil) && (objectUser.contact != nil)"];
        NSCompoundPredicate *activitiesCompountPredicate = (NSCompoundPredicate *)[NSCompoundPredicate orPredicateWithSubpredicates:@[actorsInAddressBookPredicate, objectUsersInAddressBookPredicate]];
        request.predicate = activitiesCompountPredicate;
        
        // Show newer activities first (createdAt storted descending)
        NSSortDescriptor *createdAtSort = [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO];
        request.sortDescriptors = @[createdAtSort];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
    
    [self showOrHideEmptyStateView];
}

#pragma mark Private
/**
 * Reload contents of tableview, but first cancel all downloads before doing so
 * to prevent hanging
 */
- (void)refreshTableView
{
    [[SDWebImageManager sharedManager] cancelAll];
    [self.tableView reloadData];
}

#pragma mark - Refresh
- (IBAction)refresh
{
    // Refresh activities from server
    [GRVActivity refreshActivities:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
            // Reload table to reflect changes in the activities' related objects
            [self refreshTableView];
        });
    }];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Activity Cell"; // get the cell
    GRVActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    GRVActivity *activity = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    // Configure the cell with data from the managed object
    
    // Setup avatar first
    GRVUserAvatarView *avatarView = [GRVUserViewHelper userAvatarView:activity.actor];
    cell.actorAvatarView.thumbnail = avatarView.thumbnail;
    cell.actorAvatarView.userInitials = avatarView.userInitials;
    
    // Setup Video Image which is either the target or the object
    GRVVideo *video = activity.targetVideo ? activity.targetVideo : activity.objectVideo;
    cell.videoImageView.image = nil;
    [cell.videoImageView sd_setImageWithURL:[NSURL URLWithString:video.photoSmallThumbnailURL]];
    
    // Setup description complete with a timestamp
    UIFont *descriptionFont = [UIFont fontWithName:kDescriptionStringFontName size:kDescriptionStringFontSize];
    UIFont *descriptionEmphasizedFont = [UIFont fontWithName:kDescriptionEmphasizedStringFontName size:kDescriptionStringFontSize];
    UIFont *timestampFont = [UIFont fontWithName:kDescriptionStringFontName size:kTimestampStringFontSize];
    
    NSDictionary *textAttrsDictionary = @{NSFontAttributeName : descriptionFont,
                                          NSForegroundColorAttributeName: kDescriptionStringColor};
    NSDictionary *emphasizedTextAttrsDictionary = @{NSFontAttributeName : descriptionEmphasizedFont,
                                                   NSForegroundColorAttributeName: kDescriptionStringColor};
    NSDictionary *timestampAttrsDictionary = @{NSFontAttributeName : timestampFont,
                                               NSForegroundColorAttributeName: kTimestampStringColor};
    // Generate description string
    NSString *actorDisplayName;
    BOOL emphasizeActor = YES;
    if ([activity.actor.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber]) {
        actorDisplayName = @"You";
    } else {
        actorDisplayName = [GRVUserViewHelper userFullNameOrPhoneNumber:activity.actor];
        emphasizeActor = (activity.actor.contact != nil);
    }
    NSDictionary *actorAttrsDictionary = emphasizeActor ? emphasizedTextAttrsDictionary : textAttrsDictionary;
    NSAttributedString *actorString = [[NSAttributedString alloc] initWithString:actorDisplayName attributes:actorAttrsDictionary];
    
    NSAttributedString *verbString = [[NSAttributedString alloc] initWithString:[self pastTenseOfVerb:activity.verb] attributes:textAttrsDictionary];
    
    // Generate object string
    NSAttributedString *objectString = [self objectStringForActivity:activity usingAttrsDictionary:textAttrsDictionary andEmphasizedAttrsDictionary:emphasizedTextAttrsDictionary];
    
    // Combine all these strings
    NSMutableAttributedString *description = [actorString mutableCopy];
    [description appendAttributedString:verbString];
    [description appendAttributedString:objectString];
    
    if (activity.targetVideo) {
        // if there's a target then append this also
        NSString *augmentedTargetString =  [NSString stringWithFormat:@" to %@", [self videoRepresentation:activity.targetVideo]];
        NSAttributedString *targetString = [[NSAttributedString alloc] initWithString:augmentedTargetString attributes:textAttrsDictionary];
        [description appendAttributedString:targetString];
    }
    
    // Append a timestamp to the description.
    NSTimeInterval timeSinceActivity = [[NSDate date] timeIntervalSinceDate:activity.createdAt];
    NSAttributedString *timestampString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@". %@", [GRVFormatterUtils timeStringForInterval:timeSinceActivity]] attributes:timestampAttrsDictionary];
    [description appendAttributedString:timestampString];
    
    cell.descriptionLabel.attributedText = description;
    
    return cell;
}

#pragma mark Helpers
/**
 * Generate past tense of a given verb
 */
- (NSString *)pastTenseOfVerb:(NSString *)verb
{
    NSString *pastTense = verb;
    if ([verb isEqualToString:@"like"]) {
        pastTense = @" liked ";
    } else if ([verb isEqualToString:@"invite"]) {
        pastTense = @" invited ";
    } else if ([verb isEqualToString:@"add"]) {
        pastTense = @" added ";
    }
    return pastTense;
}

/**
 * Generate object string for a given activity
 */
- (NSAttributedString *)objectStringForActivity:(GRVActivity *)activity
                           usingAttrsDictionary:(NSDictionary *)attrsDictionary
                   andEmphasizedAttrsDictionary:(NSDictionary *)emphasizedAttrsDictionary;
{
    NSString *object = @"an object";
    BOOL emphasized = NO;
    
    if (activity.objectUser) {
        if ([activity.objectUser.phoneNumber isEqualToString:[GRVAccountManager sharedManager].phoneNumber]) {
            object = @"you";
            emphasized = YES;
        } else {
            object = [GRVUserViewHelper userFullNameOrPhoneNumber:activity.objectUser];
            // Emphasize this object if activity's actor is not in address book
            emphasized = (activity.actor.contact == nil);
        }
        
    } else if (activity.objectClip) {
        object = @"a clip";
        
    } else if (activity.objectVideo) {
        object =  [self videoRepresentation:activity.objectVideo];
    }
    NSDictionary *attrs = emphasized ? emphasizedAttrsDictionary : attrsDictionary;
    return [[NSAttributedString alloc] initWithString:object attributes:attrs];
}

/**
 * Generate video string for a given video
 */
- (NSString *)videoRepresentation:(GRVVideo *)video
{
    NSString *representation = nil;
    if ([video.title length] > 0) {
        NSString *videoTitle = video.title;
        // Clip video title if longer than max allowed display length, but don't
        // clip final 3 characters just to show 3 ellipsis. That's just odd
        // so when comparing length, account for an additional 3 characters to
        // the max allowed length
        if ([videoTitle length] > (kMaxDisplayedVideoTitleLength + 3)) {
            videoTitle =[NSString stringWithFormat:@"%@...", [videoTitle substringToIndex:kMaxDisplayedVideoTitleLength]];
        }
        representation = [NSString stringWithFormat:@"\"%@\"", videoTitle];
    } else {
        representation = @"a video";
    }
    return representation;
}


#pragma mark - Notification Observer Methods
/**
 * Core Data contacts are now synced with address book.
 */
- (void)contactsRefreshed:(NSNotification *)aNotification
{
    // Reload tableview
    [self setupFetchedResultsController];
}


@end
