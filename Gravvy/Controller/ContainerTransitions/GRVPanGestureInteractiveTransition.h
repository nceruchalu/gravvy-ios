//
//  GRVPanGestureInteractiveTransition.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AWPercentDrivenInteractiveTransition.h"

/**
 * Minimum percentage complete before finishing the transition.
 * During a pan gesture, if the user doesn't make it this far the transition
 * is canceled. This aids aborting a transition after it has been started.
 *
 * This number ranges from 0.0 to 0.4 so keep it <= 0.2f
 */
extern const CGFloat kGRVPanGestureInteractiveMinimumPercentComplete;

/**
 * GRVPanGestureInteractiveTransition is a gesture recognizer to be used by the
 * GRVContainerViewController for swiping through the child view controllers.
 *
 * Instances of this class perform the interactive transition by using a
 * UIPanGestureRecognizer to control the animation.
 */
@interface GRVPanGestureInteractiveTransition : AWPercentDrivenInteractiveTransition

#pragma mark - Properties
@property (strong, nonatomic, readonly) UIPanGestureRecognizer *recognizer;

/**
 * This block gets run when the gesture recognizer starts recognizing a pan. Inside,
 * the start of a transition can be triggered.
 */
@property (copy, nonatomic) void (^gestureRecognizedBlock)(UIPanGestureRecognizer *recognizer);

#pragma mark - Initializers
- (instancetype)initWithGestureRecognizerInView:(UIView *)view recognizedBlock:(void (^)(UIPanGestureRecognizer *recognizer))gestureRecognizedBlock;

@end
