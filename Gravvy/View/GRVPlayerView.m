//
//  GRVPlayerView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/24/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVPlayerView.h"

@implementation GRVPlayerView

#pragma mark - Properties
- (AVPlayer *)player
{
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player
{
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}

#pragma mark - Class Methods
+ (Class)layerClass
{
    // The layer for instances of this class will be AVPlayerLayer
    return [AVPlayerLayer class];
}

@end
