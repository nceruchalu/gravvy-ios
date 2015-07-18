//
//  GRVBadgeView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/17/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVBadgeView.h"
#import "GRVConstants.h"

#pragma mark - Constants
static CGFloat const kBadgeViewMinimumSize = 25.0;
static CGFloat const kBadgeViewPadding = 12.0;
static CGFloat const kBadgeViewDefaultFontSize = 12.0;

static NSTimeInterval const kBadgeAnimationDuration = 0.2;

@interface GRVBadgeView ()

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) NSNumberFormatter *formatter;

@end

@implementation GRVBadgeView

#pragma mark - Properties
- (void)setBadgeValue:(NSInteger)badgeValue
{
    // No-op if we're given zero or less and our current badge value is zero,
    // meaning we're hidden anyway.
    //
    if (badgeValue <= 0 && self.badgeValue == 0) {
        return;
    }
    
    // If we're given a negative number and our badge value is a positive number,
    // treat this like we're setting it to zero.
    //
    if (badgeValue < 0 && self.badgeValue > 0) {
        badgeValue = 0;
    }
    
    _badgeValue = badgeValue;
    
    self.valueLabel.text = [self.formatter stringFromNumber:@(badgeValue)];
    
    [self layoutBadgeSubviews];
    [self updateStateIfNeeded];
}

- (void)setTextColor:(UIColor *)textColor
{
    _textColor = textColor;
    self.valueLabel.textColor = textColor;
}

- (void)setFont:(UIFont *)font
{
    _font = font;
    self.valueLabel.font = font;
}

#pragma mark - Initialization
- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self commonInit];
    }
    
    return self;
}

- (void)commonInit
{
    self.formatter = [[NSNumberFormatter alloc] init];
    self.formatter.groupingSeparator = @",";
    self.formatter.usesGroupingSeparator = YES;
    
    [self setupDefaultAppearance];
}


#pragma mark - Instance Methods
#pragma mark Appearance
- (void)setupDefaultAppearance
{
    // Defaults for the view.
    //
    self.clipsToBounds = YES;
    self.hidden = YES;
    self.transform = CGAffineTransformMakeScale(0.001, 0.001);
    self.backgroundColor = kGRVThemeColor;
    
    // Defaults for the label.
    //
    self.valueLabel = [UILabel new];
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.valueLabel];
    
    self.textColor = [UIColor whiteColor];
    self.font = [UIFont boldSystemFontOfSize:kBadgeViewDefaultFontSize];
}

#pragma mark Laying out Subviews
- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutBadgeSubviews];
}

- (void)layoutBadgeSubviews
{
    // Size our label to fit.
    //
    [self.valueLabel sizeToFit];
    
    // Get the height of the label - which was determined by sizeToFit.
    //
    CGFloat badgeLabelWidth = CGRectGetWidth(self.valueLabel.frame);
    CGFloat badgeLabelHeight = CGRectGetHeight(self.valueLabel.frame);
    
    // Calculate the height we will be based on the label.
    //
    CGFloat height = MAX(kBadgeViewMinimumSize, badgeLabelHeight + kBadgeViewPadding);
    CGFloat width = MAX(height, badgeLabelWidth + kBadgeViewPadding);
    
    // Set our frame and corner radius based on those calculations.
    //
    self.frame = CGRectMake(CGRectGetWidth(self.superview.frame) - (width / 2.0), -(height / 2.0), width, height);
    self.layer.cornerRadius = height / 2.0;
    
    // Center the badge label.
    //
    self.valueLabel.frame = CGRectMake((width / 2.0) - (badgeLabelWidth / 2.0), (height / 2.0) - (badgeLabelHeight / 2.0), badgeLabelWidth, badgeLabelHeight);
}


#pragma mark Updating the badge value
- (void)increment
{
    self.badgeValue++;
}

- (void)decrement
{
    self.badgeValue--;
}


#pragma mark Visibility
- (void)updateStateIfNeeded
{
    // If we're currently hidden and we should be visible, show ourself.
    //
    if (self.isHidden && self.badgeValue > 0) {
        [self show];
    }
    
    // Otherwise if we're visible and we shouldn't be, hide ourself.
    //
    else if (!self.isHidden && self.badgeValue <= 0) {
        [self hide];
    }
}

- (void)show
{
    self.hidden = NO;
    
    [UIView animateWithDuration:kBadgeAnimationDuration animations:^{
        self.transform = CGAffineTransformIdentity;
    }];
}

- (void)hide
{
    [UIView animateWithDuration:kBadgeAnimationDuration animations:^{
        self.transform = CGAffineTransformMakeScale(0.001, 0.001);
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

@end
