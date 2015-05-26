//
//  GRVMultiContactPickerTableViewCell.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * GRVContactPickerTableViewCell represents a row in a table view controller used
 * to display a user in the multi-contact picker.
 */
@interface GRVMultiContactPickerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *displayNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberLabel;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;

@end
