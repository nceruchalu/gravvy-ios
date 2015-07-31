//
//  GRVClipBrowser.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "MWPhotoBrowser.h"

@class GRVVideo;

/**
 * GRVClipBrowser provides an interface for deleting owned clips from a video.
 */
@interface GRVClipBrowser : MWPhotoBrowser

#pragma mark - Properties
/**
 * Video that will serve as the source of all the displayed clips.
 */
@property (strong, nonatomic) GRVVideo *video;

@end
