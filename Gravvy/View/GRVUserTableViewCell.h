//
//  GRVUserTableViewCell.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/29/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRVUserAvatarView.h"

/**
 * GRVUserTableViewCell represents a row in a table view controller used
 * to display a collection of users.
 */
@interface GRVUserTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet GRVUserAvatarView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@end
