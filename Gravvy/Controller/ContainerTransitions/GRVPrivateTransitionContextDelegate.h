//
//  GRVPrivateTransitionContextDelegate.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/31/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GRVPrivateTransitionContext;

/**
 * GRVPrivateTransitionContextDelegate provides the protocol needed by
 * GRVPrivateTransitionContext's delegates. Its delegates respond to transition
 * context changes such as animating the buttons as user interactively pans
 * across view controllers.
 */
@protocol GRVPrivateTransitionContextDelegate <NSObject>

@optional
/**
 * Informs the delegate that the transition context has updating position
 * while going right.
 */
- (void)transitionContext:(GRVPrivateTransitionContext *)transitionContext didUpdateInteractiveTransition:(CGFloat)percentComplete goingRight:(BOOL)goingRight;

/**
 * Informs the delegate that the transition context has finished updating its
 * position.
 */
- (void)transitionContext:(GRVPrivateTransitionContext *)transitionContext didFinishInteractiveTransitionGoingRight:(BOOL)goingRight;


/**
 * Informs the delegate that the transition context has canceled updating its
 * position.
 */
- (void)transitionContext:(GRVPrivateTransitionContext *)transitionContext didCancelInteractiveTransitionGoingRight:(BOOL)goingRight;

@end
