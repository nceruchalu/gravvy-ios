//
//  GRVVideoTableViewCell.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRVPlayerView.h"

/**
 * GRVVideoTableViewCell represents a row in a table view controller used
 * to display a video's detailed info and play associated clips.
 */
@interface GRVVideoTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet GRVPlayerView *playerView;
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *likesCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentClipIndexLabel;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;

@end
