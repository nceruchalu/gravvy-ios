//
//  GRVVideoSectionHeaderView.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/1/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GRVUserAvatarView.h"

/**
 * GRVVideoSectionHeaderView is a custom view for section headers in a Table
 * View of Videos.
 *
 * This loads the contents from a XIB file using some trickery.
 * @ref http://sebastiancelis.com/2014/06/12/using-xibs-layout-custom-views/
 */
@interface GRVVideoSectionHeaderView : UIView

@property (weak, nonatomic) IBOutlet GRVUserAvatarView *ownerAvatarView;
@property (weak, nonatomic) IBOutlet UILabel *ownerNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *createdAtLabel;
@property (weak, nonatomic) IBOutlet UILabel *playsCountLabel;
@property (weak, nonatomic) IBOutlet UIButton *addClipButton;

@end
