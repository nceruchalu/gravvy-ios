//
//  GRVContainerViewControllerDelegate.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GRVContainerViewController;

/**
 * GRVContainerViewControllerDelegate provides the protocol needed by
 * GRVContainerViewController's delegates. Its delegates vend alternative/custom
 * animation controllers.
 */
@protocol GRVContainerViewControllerDelegate <NSObject>

@optional
/**
 * Informs the delegate that the user selected view controller by tapping the
 * corresponding icon.
 *
 * @note The method is called regardless of whether the selected view controller
 *      changed or not and only as a result of the user tapped a button. The
 *      method is not called when the view controller is changed
 *      programmatically. This is the same pattern as UITabBarController uses.
 */
- (void)containerViewController:(GRVContainerViewController *)containerViewController
        didSelectViewController:(UIViewController *)viewController;

/**
 * Called on the delegate to obtain a UIViewControllerAnimatedTransitioning
 * object which can be used to animate a non-interactive transition.
 */
- (id <UIViewControllerAnimatedTransitioning>)containerViewController:(GRVContainerViewController *)containerViewController animationControllerForTransitionViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController;

/**
 * Called on the delegate to obtain a UIViewControllerInteractiveTransitioning
 * object which can be used to interact during a transition.
 */
- (id <UIViewControllerInteractiveTransitioning>)containerViewController:(GRVContainerViewController *)containerViewController interactionControllerForAnimationController:(id <UIViewControllerAnimatedTransitioning>)animationController;

@end
