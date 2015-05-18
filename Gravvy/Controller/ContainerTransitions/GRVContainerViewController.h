//
//  GRVContainerViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GRVContainerViewControllerDelegate;

/**
 * GRVContainerViewController is a custom container view controller
 * that allows for child view controllers that can be swiped easily.
 *
 * @discussion the initial selected child view controllers will not get the very
 *      first `viewWillAppear:` appearance message.
 *
 * @ref http://www.objc.io/issue-12/custom-container-view-controller-transitions.html
 * @ref http://www.iosnomad.com/blog/2014/5/12/interactive-custom-container-view-controller-transitions
 */

@interface GRVContainerViewController : UIViewController

#pragma mark - Properties
/**
 * An array of the child view controllers managed by the container view controller
 */
@property (copy, nonatomic, readonly) NSArray *viewControllers;

/**
 * The container view controller delegate receiving the protocol callbacks.
 */
@property (nonatomic, weak) id<GRVContainerViewControllerDelegate>delegate;

/**
 * The currently selected and visible child view controller.
 *
 * @discussion
 *      This VC is the one whose custom view is currently displayed by the
 *      interface. The specified view controller must be in the viewControllers
 *      array. Assigning a new view controller to thisproperty changes the
 *      displayed view and also selects an appropriate tab. Changing this view
 *      controller also updates the selectedIndex property accordingly.
 *
 *      The default value of this property is the first element in viewControllers
 *      property.
 *
 * @see selectedIndex
 */
@property (strong, nonatomic) UIViewController *selectedViewController;

/**
 * The index of the currently selected and visible child view controller.
 *
 * @discussion
 *      This property nominally represents an index into the array of the
 *      viewControllers property.
 *
 *      The default value of this property is 0.
 *
 * @see selectedViewController
 */
@property (nonatomic) NSUInteger selectedIndex;


/**
 * The gesture recognizer that triggers the default interaction transition.
 *
 * @discussion  When someone uses this Container VC and wants to vend their own
 *      interactive transitions, they probably want to disable the interaction
 *      controller already built in. This exposed UIGestureRecognizer has
 *      an enabled property, so anyone using the class can just disable the
 *      recognizer to disable the default interactive transition.
 *
 *      This approach is similar to what's done in UINavigationController
 */
@property (strong, nonatomic, readonly) UIGestureRecognizer *interactiveTransitionGestureRecognizer;

@end