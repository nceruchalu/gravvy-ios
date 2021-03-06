//
//  GRVAddClipCameraReviewVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/7/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVAddClipCameraReviewVC.h"
#import "SCRecordSession.h"
#import "GRVConstants.h"
#import "GRVHTTPManager.h"
#import "GRVRestUtils.h"
#import "GRVVideo.h"
#import "GRVClip+HTTP.h"
#import "GRVModelManager.h"
#import "GRVUserViewHelper.h"

#pragma mark - Constants
/**
 * Unwind Segue Identifier
 */
static NSString *const kUnwindSegueIdentifier = @"addedClip";


@interface GRVAddClipCameraReviewVC ()

#pragma mark - Properties
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;

#pragma mark Private
@property (strong, nonatomic, readwrite) GRVClip *addedClip;

@end

@implementation GRVAddClipCameraReviewVC

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    // Disable add button till recording is validated
    self.addButton.enabled = NO;
    
    [super viewDidLoad];
    
    [self configureVideoTitle];
}

#pragma mark - Instance Methods
#pragma mark Concrete
- (void)recordingValidated
{
    self.addButton.enabled = YES;
}

#pragma mark Private
- (void)configureVideoTitle
{
    if ([self.video.title length]) {
        self.videoTitleLabel.text = [NSString stringWithFormat:@"Video: %@", self.video.title];
    } else {
        self.videoTitleLabel.text = [NSString stringWithFormat:@"Video by: %@", [GRVUserViewHelper userFullName:self.video.owner]];
    }
}

#pragma mark - Target/Action Methods
- (IBAction)addClip:(UIBarButtonItem *)sender
{
    // Generate complete video details parameters
    NSTimeInterval duration = CMTimeGetSeconds(self.recordSession.duration);
    NSDictionary *parameters = @{kGRVRESTClipDurationKey: @(duration)};
    
    // temporarily disable add buttons
    self.addButton.enabled = NO;
    
    // inform user of server activity.
    [self.spinner startAnimating];
    self.videoTitleLabel.hidden = YES;
    
    // Upload video to the server
    NSString *videoClipListURL = [GRVRestUtils videoClipListURL:self.video.hashKey];
    [[GRVHTTPManager sharedManager] operationRequest:GRVHTTPMethodPOST
                                              forURL:videoClipListURL
                                          parameters:[parameters copy]
                           constructingBodyWithBlock:^(id<AFMultipartFormData> formData)
    {
        // Come up with a random file name. Doesn't have
        // to be unique as the server will handle that
        NSString *baseFileName = [[[NSUUID UUID] UUIDString] substringToIndex:8];
        NSString *mp4FileName = [NSString stringWithFormat:@"%@.mp4", baseFileName];
        NSString *photoFileName = [NSString stringWithFormat:@"%@.jpg", baseFileName];
        
        [formData appendPartWithFileData:self.mp4
                                    name:kGRVRESTClipMp4Key
                                fileName:mp4FileName
                                mimeType:@"video/mp4"];
        [formData appendPartWithFileData:UIImageJPEGRepresentation(self.previewImage,
                                                                   kGRVVideoPhotoCompressionQuality)
                                    name:kGRVRESTClipPhotoKey
                                fileName:photoFileName
                                mimeType:@"image/jpeg"];
    }
                                             success:^(AFHTTPRequestOperation *operation, id responseObject)
    {
        // Sync new clip
        self.addedClip = [GRVClip clipWithClipInfo:responseObject
                                   associatedVideo:self.video
                            inManagedObjectContext:[GRVModelManager sharedManager].managedObjectContext];
        
        // No need to enable buttons or stop spinner as we unwind VC
        [self performSegueWithIdentifier:kUnwindSegueIdentifier sender:self];
        
    }
                                             failure:^(AFHTTPRequestOperation *operation, NSError *error)
    {
        [GRVHTTPManager alertWithFailedResponse:nil
                             withAlternateTitle:@"Can't add clip to video."
                                     andMessage:@"Something went wrong. Please try again."];
        // enable button
        self.addButton.enabled = YES;
        
        // inform user server activity is done
        [self.spinner stopAnimating];
        self.videoTitleLabel.hidden = NO;
    }
                                 operationDependency:nil];
}

@end
