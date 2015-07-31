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
#import "GRVVideo.h"
#import "GRVClip.h"
#import "GRVUserViewHelper.h"

@interface GRVClipBrowser () <MWPhotoBrowserDelegate>

#pragma mark - Properties
#pragma mark Private
/**
 * Array of GRVClip objects
 */
@property (copy, nonatomic) NSArray *clips;

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
 * Grid view toolbar
 */
@property (strong, nonatomic) UIToolbar *gridToolbar;

@end

@implementation GRVClipBrowser

#pragma mark - Properties
#pragma mark Private
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
    [self.gridToolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self.gridToolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    self.gridToolbar.barStyle = UIBarStyleBlackTranslucent;
    self.gridToolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
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
    
    NSSortDescriptor *orderSd = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
    self.clips = [self.video.clips sortedArrayUsingDescriptors:@[orderSd]];
    
    for (GRVClip *clip in self.clips) {
        
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
 * Re-enable grid and reload its data
 */
- (void)resetAndReloadGrid
{
    self.startOnGrid = YES;
    self.enableGrid = YES;
    [self reloadData];
    [self showGrid:YES];
}


#pragma mark - Target/Action Methods
- (void)cancelButtonPressed:(id)sender
{
    // Dismiss view controller
    [self dismissViewControllerAnimated:YES completion:nil];
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
    if (index < [self.clipSelections count]) {
        // Change the selection state of the given clip
        [self.clipSelections replaceObjectAtIndex:index withObject:@(selected)];
    }
}

@end
