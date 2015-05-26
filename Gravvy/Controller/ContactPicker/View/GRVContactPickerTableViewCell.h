//
//  GRVContactPickerTableViewCell.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GRVUserAvatarView;

/**
 * GRVContactPickerTableViewCell represents a row in a table view controller used
 * to display a user in the contact picker.
 * This can be subclassed to add more specific controls like "add" or "remove"
 * user buttons.
 */
@interface GRVContactPickerTableViewCell : UITableViewCell


@property (weak, nonatomic) IBOutlet GRVUserAvatarView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;

@end
