//
//  GRVActivityTableViewCell.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/16/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRVUserAvatarView.h"

/**
 * GRVActivityTableViewCell represents a row in a table view controller used
 * to display an activity's summary info.
 */
@interface GRVActivityTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet GRVUserAvatarView *actorAvatarView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *videoImageView;

@end
