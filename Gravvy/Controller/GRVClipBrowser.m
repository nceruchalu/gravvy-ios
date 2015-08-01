//
//  GRVClipBrowser.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVClipBrowser.h"
#import "MWPhotoBrowserPrivate.h"
#import "MWPhoto.h"
#import "MWGridViewController.h"
#import "GRVVideo+HTTP.h"
#import "GRVClip.h"
#import "GRVUserViewHelper.h"
#import "UIImage+GRVUtilities.h"
#import "GRVConstants.h"
#import "GRVHTTPManager.h"
#import "NSManagedObject+GRVUtilities.h"
#import "MBProgressHUD.h"

#pragma mark - Constants
/**
 * Titles for delete clip button
 */
static NSString *const kDeleteClipsButtonTitleMultipleSelection = @"Delete Selected Clips";
static NSString *const kDeleteClipsButtonTitleSingleSelection = @"Delete Selected Clip";
static NSString *const kDeleteClipsButtonTitleDeleting = @"Deleting... Please Wait";


@interface GRVClipBrowser () <MWPhotoBrowserDelegate>

#pragma mark - Properties
#pragma mark Private
/**
 * Array of GRVClip objects
 */
@property (copy, nonatomic) NSMutableArray *clips;

/**
 * Array tracking selection state for all clips
 */
@property (strong, nonatomic) NSMutableArray *clipSelections;

/**
 * Arrays of id <MWPhoto> object tracking clip videos and thumbnails
 */
@property (strong, nonatomic) NSMutableArray *clipVideos;
@property (strong, nonatomic) NSMutableArray *clipThumbnails;

/**
 * Grid view toolbar and buttons
 */
@property (strong, nonatomic) UIToolbar *gridToolbar;
@property (strong, nonatomic) UIBarButtonItem *deleteClipsButton;

@property (strong, nonatomic) MBProgressHUD *successProgressHUD;

@end

@implementation GRVClipBrowser

#pragma mark - Properties
#pragma mark Private
- (NSMutableArray *)clips
{
    // Lazy instantiation
    if (!_clips) _clips = [NSMutableArray array];
    return _clips;
}
- (NSMutableArray *)clipSelections
{
    // Lazy instantiation
    if (!_clipSelections) _clipSelections = [NSMutableArray array];
    return _clipSelections;
}

- (NSMutableArray *)clipVideos
{
    // Lazy instantiation
    if (!_clipVideos) _clipVideos = [NSMutableArray array];
    return _clipVideos;
}

- (NSMutableArray *)clipThumbnails
{
    // Lazy instantiation
    if (!_clipThumbnails) _clipThumbnails = [NSMutableArray array];
    return _clipThumbnails;
}

- (MBProgressHUD *)successProgressHUD
{
    if (!_successProgressHUD) {
        // Lazy instantiation
        _successProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:_successProgressHUD];
        
        _successProgressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmark"]];
        // Set custom view mode
        _successProgressHUD.mode = MBProgressHUDModeCustomView;
        
        _successProgressHUD.minSize = CGSizeMake(120, 120);
        _successProgressHUD.minShowTime = 1;
    }
    return _successProgressHUD;
}


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    // Set options before calling superclass' method
    // Show action button to allow sharing, copying, etc
    self.displayActionButton = NO;
    // Whether to display left and right nav arrows on toolbar when viewing a
    // single clip
    self.displayNavArrows = YES;
    // Whether selection buttons are shown on each image both in grid view and
    // single photo view.
    // This must be YES
    self.displaySelectionButtons = YES;
    // Images that almost fill the screen will be initially zoomed to fill
    self.zoomPhotosToFill = YES;
    // Allows to control whether the bars and controls are always visible or
    // whether they fade away to show the photo full
    self.alwaysShowControls = YES;
    // Whether to allow the viewing of all the photo thumbnails on a grid.
    // This must be YES
    self.enableGrid = YES;
    // Whether to start on the grid of thumbnails instead of the first photo
    // This MUST be YES!
    self.startOnGrid = YES;
    // Swipe full screen video (up/down) to dismiss and return to grid
    self.enableSwipeToDismiss = YES;
    // Auto-play first video
    self.autoPlayOnAppear = NO;
    // Custom image selected icons
    self.customImageSelectedIconName = @"clipSelectedOn";
    self.customImageSelectedSmallIconName = @"clipSelectedSmallOn";
    
    // Finally call superclass' method which depends on the configured options
    [super viewDidLoad];
    
    self.delegate = self;
    
    // Setup a Cancel button
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(cancelButtonPressed:)];
    // Set appearance
    if ([UIBarButtonItem respondsToSelector:@selector(appearance)]) {
        [cancelButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [cancelButton setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
        [cancelButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
        [cancelButton setBackgroundImage:nil forState:UIControlStateHighlighted barMetrics:UIBarMetricsLandscapePhone];
        [cancelButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateNormal];
        [cancelButton setTitleTextAttributes:[NSDictionary dictionary] forState:UIControlStateHighlighted];
    }
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    // Setup toolbar
    self.gridToolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:self.interfaceOrientation]];
    self.gridToolbar.tintColor = [UIColor whiteColor];
    self.gridToolbar.barTintColor = nil;
    [self.gridToolbar setBackgroundImage:[UIImage imageWithColor:kGRVRedColor] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self.gridToolbar setBackgroundImage:[UIImage imageWithColor:kGRVRedColor] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    self.gridToolbar.barStyle = UIBarStyleBlackTranslucent;
    self.gridToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    // Configure delete clips button
    self.deleteClipsButton = [[UIBarButtonItem alloc] initWithTitle:kDeleteClipsButtonTitleMultipleSelection style:UIBarButtonItemStyleBordered target:self action:@selector(deleteSelectedClips:)];
    
    // configure toolbar items
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    self.gridToolbar.items = @[flexSpace, self.deleteClipsButton, flexSpace];
    
    [self configureUsingVideo];
}

#pragma mark - Layout
- (void)performLayout
{
    [super performLayout];
    // Hide done button
    self.navigationItem.rightBarButtonItem = nil;
}


#pragma mark - Navigation
- (void)updateNavigation
{
    [super updateNavigation];
    self.title = [self.title stringByReplacingOccurrencesOfString:@"Photo" withString:@"Clip"];
    self.title = [self.title stringByReplacingOccurrencesOfString:@"photo" withString:@"clip"];
}

#pragma mark - Instance methods
#pragma mark Private

/**
 * Setup browser properties from GRVVideo model and reset VC so it returns to the
 * grid view.
 */
- (void)configureUsingVideo
{
    // Reset arrays
    [self.clipSelections removeAllObjects];
    [self.clipVideos removeAllObjects];
    [self.clipThumbnails removeAllObjects];
    [self.clips removeAllObjects];
    
    // Configure deleteClipsButton
    self.deleteClipsButton.enabled = NO;
    
    NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    NSArray *clips = [self.video.clips sortedArrayUsingDescriptors:@[orderSd]];
    
    for (GRVClip *clip in clips) {
        
        // Confirm that clip hasn't been deleted
        if ([clip hasBeenDeleted]) {
            // clip has been deleted so skip
            continue;
        }
        
        [self.clips addObject:clip];
        
        // Setup clip Videos
        MWPhoto *clipVideo = [MWPhoto photoWithURL:[[NSURL alloc] initWithString:clip.photoThumbnailURL]];
        clipVideo.videoURL = [[NSURL alloc] initWithString:clip.mp4URL];
        NSString *clipOwner = [GRVUserViewHelper userFullNameOrPhoneNumber:clip.owner];
        clipVideo.caption = [NSString stringWithFormat:@"Uploader: %@", clipOwner];
        [self.clipVideos addObject:clipVideo];
        
        // Setup clip thumbnails
        MWPhoto *clipThumbnail = [MWPhoto photoWithURL:[[NSURL alloc] initWithString:clip.photoThumbnailURL]];
        clipThumbnail.isVideo = YES;
        [self.clipThumbnails addObject:clipThumbnail];
        
        // All clips start out unselected.
        [self.clipSelections addObject:@(NO)];
    }
    
    // Finally have all data so re-enable grid and reload data
    [self resetAndReloadGrid];
}

/**
 * Configure delete clips button based on selection state
 */
- (void)configureDeleteClipsButton
{
    NSUInteger clipsToDelete = [[self.clipSelections filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == YES"]] count];
    self.deleteClipsButton.title = clipsToDelete == 1 ? kDeleteClipsButtonTitleSingleSelection : kDeleteClipsButtonTitleMultipleSelection;
    self.deleteClipsButton.enabled = clipsToDelete > 0;
}

/**
 * Re-enable grid and reload its data
 */
- (void)resetAndReloadGrid
{
    self.startOnGrid = YES;
    self.enableGrid = YES;
    [self reloadData];
    [self showGrid:YES];
    
    MWGridViewController *gridVC = [self gridViewController];
    [gridVC.collectionView reloadData];
}

/**
 * Get the grid VC
 */
- (MWGridViewController *)gridViewController
{
    MWGridViewController *gridVC = nil;
    for (UIViewController *vc in self.childViewControllers) {
        if ([vc isKindOfClass:[MWGridViewController class]]) {
            gridVC = (MWGridViewController *)vc;
            break;
        }
    }
    return gridVC;
}


#pragma mark Grid Toolbar
- (void)showGrid:(BOOL)animated
{
    [super showGrid:animated];
    [self.view addSubview:self.gridToolbar];
}

- (void)hideGrid
{
    [super hideGrid];
    [self.gridToolbar removeFromSuperview];
}

- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
    [super setControlsHidden:hidden animated:animated permanent:permanent];
    if (!hidden) {
        [self.gridToolbar removeFromSuperview];
    }
}

#pragma mark Action Progress
- (void)showProgressHUDSuccessMessage:(NSString *)message
{
    self.successProgressHUD.labelText = message;
    [self.successProgressHUD show:YES];
    [self.successProgressHUD hide:YES afterDelay:1.5];
}


#pragma mark - Target/Action Methods
- (void)cancelButtonPressed:(id)sender
{
    // Dismiss view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)deleteSelectedClips:(id)sender
{
    NSMutableArray *clipsToDelete = [NSMutableArray array];
    for (NSUInteger i=0; i<[self.clipSelections count]; i++) {
        if ([self.clipSelections[i] boolValue]) {
            [clipsToDelete addObject:self.clips[i]];
        }
    }
    
    if ([clipsToDelete count]) {
        self.deleteClipsButton.enabled = NO;
        self.deleteClipsButton.title = kDeleteClipsButtonTitleDeleting;
        self.view.userInteractionEnabled = NO;
        
        [self.video deleteClips:clipsToDelete withCompletion:^(NSError *error, id responseObject) {
            self.view.userInteractionEnabled = YES;
            if (error) {
                [GRVHTTPManager alertWithFailedResponse:responseObject withAlternateTitle:@"Something went wrong" andMessage:@"Please try that again."];
            } else {
                [self showProgressHUDSuccessMessage:@"Deleted clips"];
            }
            [self.video refreshVideo:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self configureUsingVideo];
                [self configureDeleteClipsButton];
            });
        }];
    } else {
        [self configureUsingVideo];
    }
}


#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return [self.clipVideos count];
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    id <MWPhoto> clipVideo = nil;
    if (index < [self.clipVideos count]) {
        clipVideo = [self.clipVideos objectAtIndex:index];
    }
    return clipVideo;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index
{
    id <MWPhoto> clipThumbnail = nil;
    if (index < [self.clipThumbnails count]) {
        clipThumbnail = [self.clipThumbnails objectAtIndex:index];
    }
    return clipThumbnail;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index
{
    //  Did start viewing clip at index;
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index
{
    BOOL selection = NO;
    if (index < [self.clipSelections count]) {
        selection = [[self.clipSelections objectAtIndex:index] boolValue];
    }
    return selection;
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected
{
    if (index == 0) {
        // Can't select the very first clip so force an unselection
        if (self.gridToolbar.superview) {
            // If showing gridToolBar then simply reload grid so as not to force
            // a redownload of cached images
            MWGridViewController *gridVC = [self gridViewController];
            [gridVC.collectionView reloadData];
        } else {
            // If showing details page, then reload all data
            [self reloadData];
        }
        
    } else if (index < [self.clipSelections count]) {
        // Change the selection state of the given clip
        [self.clipSelections replaceObjectAtIndex:index withObject:@(selected)];
    }
    
    // Configure the delete section button based on the selection state
    [self configureDeleteClipsButton];
}

@end
