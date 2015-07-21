//
//  GRVNotificationIndicatorView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/20/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVNotificationIndicatorView.h"
#import "GRVConstants.h"
#import <QuartzCore/QuartzCore.h>

#pragma mark - Constants
/**
 * Pulsing Animation Key
 */
static NSString *const kPulsingAnimationKey = @"AnimateOpacity";

/**
 * Default alpha value
 */
static CGFloat const kDefaultAlpha = 1.0f;

@implementation GRVNotificationIndicatorView

#pragma mark - Initialization
- (void)setup
{
    // make transparent (no background color)
    self.backgroundColor = nil;
    self.opaque = NO;
    // want to redraw whenever bound change
    self.contentMode = UIViewContentModeRedraw;
    
    // Pulsing Animation
    // @ref http://stackoverflow.com/a/8083199
    // @ref https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreAnimation_guide/CreatingBasicAnimations/CreatingBasicAnimations.html#//apple_ref/doc/uid/TP40004514-CH3-SW17
    CABasicAnimation *pulsingAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    pulsingAnimation.repeatCount=HUGE_VALF; // repeat animation forever
    pulsingAnimation.autoreverses=YES;
    pulsingAnimation.fromValue = @(kDefaultAlpha);
    pulsingAnimation.toValue = @(0.0);
    pulsingAnimation.duration=1.0;
    [self.layer addAnimation:pulsingAnimation forKey:kPulsingAnimationKey];
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

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    [circle addClip];
    [kGRVThemeColor setFill];
    UIRectFill(self.bounds);
}


#pragma mark - Instance Methods
#pragma mark Public
- (void)stopPulsingAnimation
{
    [self.layer removeAnimationForKey:kPulsingAnimationKey];
    self.alpha = kDefaultAlpha;
}

@end
