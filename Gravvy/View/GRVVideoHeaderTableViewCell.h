//
//  GRVVideoHeaderTableViewCell.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/27/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRVUserAvatarView.h"

/**
 * GRVVideoTableViewCell represents a section header in a table view controller 
 * and is used to display a video's summary info as the header cell.
 */
@interface GRVVideoHeaderTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet GRVUserAvatarView *ownerAvatarView;
@property (weak, nonatomic) IBOutlet UILabel *ownerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *playsCountLabel;

@end
