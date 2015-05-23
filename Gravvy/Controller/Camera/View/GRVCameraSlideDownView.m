//
//  GRVCameraSlideDownView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/22/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraSlideDownView.h"

@implementation GRVCameraSlideDownView


#pragma mark - Class methods
+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([GRVCameraSlideDownView class])
                          bundle:[NSBundle bundleForClass:[GRVCameraSlideDownView class]]];
}


#pragma mark - GRVCameraSlideViewProtocol
- (CGFloat)initialPositionWithView:(UIView *)view
{
    return CGRectGetHeight(view.frame)/2;
}

- (CGFloat)finalPosition
{
    return CGRectGetMaxY(self.frame);
}

@end
