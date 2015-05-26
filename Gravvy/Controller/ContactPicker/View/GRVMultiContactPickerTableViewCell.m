//
//  GRVMultiContactPickerTableViewCell.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVMultiContactPickerTableViewCell.h"

@implementation GRVMultiContactPickerTableViewCell

#pragma mark - Initialization
- (void)setup
{
    [self.selectionButton setImage:[UIImage imageNamed:@"selectionUnchecked"] forState:UIControlStateNormal];
    [self.selectionButton setImage:[UIImage imageNamed:@"selectionChecked"] forState:UIControlStateSelected];
}

- (void)awakeFromNib
{
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}


@end
