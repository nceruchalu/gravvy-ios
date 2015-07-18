//
//  GRVBadgeView.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/17/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
// Heavily based on Sheriff, https://github.com/gemr/sheriff

#import <UIKit/UIKit.h>

/**
 * GRVBadgeView provides an interface for custom badges
 */
@interface GRVBadgeView : UIView

#pragma mark - Properties
/**
 * The number currently set as the badge value for the view.
 * @note The badge will be visible if this number is greater than zero. Setting the `badgeValue` to a negative number will set it to zero and hide the label.
 */
@property (nonatomic) NSInteger badgeValue;

/**
 * The color of the badge value text.
 */
@property (nonatomic, strong) UIColor *textColor;

/**
 * The font used for the badge value text.
 */
@property (nonatomic, strong) UIFont *font;

#pragma mark - Instance Methods
/**
 * Increment the badge value, which will result in the badge being displayed if the current value is zero.
 */
- (void)increment;

/**
 * Decrement the badge value, which will result in the badge being hidden if the new value is zero.
 * @note Calling `decrement` when the value is currently zero will have no effect.
 */
- (void)decrement;

@end
