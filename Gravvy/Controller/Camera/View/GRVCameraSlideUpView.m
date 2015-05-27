//
//  GRVCameraSlideUpView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/22/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraSlideUpView.h"

@implementation GRVCameraSlideUpView


#pragma mark - Class methods
+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([GRVCameraSlideUpView class])
                          bundle:[NSBundle bundleForClass:[GRVCameraSlideUpView class]]];
}


#pragma mark - GRVCameraSlideViewProtocol
- (CGFloat)initialPositionWithView:(UIView *)view
{
    return 0;
}

- (CGFloat)finalPosition
{
    return -CGRectGetHeight(self.frame);
}

- (CGFloat)heightWithView:(UIView *)view
{
    return CGRectGetHeight(view.frame)/2;
}

@end
