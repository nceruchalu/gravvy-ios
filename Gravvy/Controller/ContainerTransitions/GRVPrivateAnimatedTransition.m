//
//  GRVPrivateAnimatedTransition.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVPrivateAnimatedTransition.h"

#pragma mark - Constants

/**
 * Spacing between child views which is visible during transition
 */
static CGFloat const kChildViewPadding = 16.0f;

/**
 * Transition animation dynamic parameters.
 */
static NSTimeInterval const kTransitionDuration = 0.5f;
static CGFloat const kDamping = 0.75f;
static CGFloat const kInitialSpringVelocity = 0.5f;

@implementation GRVPrivateAnimatedTransition


- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return kTransitionDuration;
}

/**
 * Slide views horizontally, with a bit of space between, while fading out and in.
 */
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    // When sliding the views horizontally in and out, figure out whether we
    // are going left or right.
    BOOL goingRight = ([transitionContext initialFrameForViewController:toViewController].origin.x < [transitionContext finalFrameForViewController:toViewController].origin.x);
    CGFloat travelDistance = [transitionContext containerView].bounds.size.width + kChildViewPadding;
    CGAffineTransform travel = CGAffineTransformMakeTranslation((goingRight ? travelDistance : -travelDistance), 0.0f);
    
    [[transitionContext containerView] addSubview:toViewController.view];
    toViewController.view.alpha = 0;
    toViewController.view.transform = CGAffineTransformInvert(travel);
    
    [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:kDamping initialSpringVelocity:kInitialSpringVelocity options:0x00 animations:^{
        
        fromViewController.view.transform = travel;
        fromViewController.view.alpha = 0;
        
        toViewController.view.transform = CGAffineTransformIdentity;
        toViewController.view.alpha = 1;
        
    } completion:^(BOOL finished) {
        fromViewController.view.transform = CGAffineTransformIdentity;
        fromViewController.view.alpha = 1;
        
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
