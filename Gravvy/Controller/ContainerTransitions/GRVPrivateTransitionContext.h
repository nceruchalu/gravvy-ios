//
//  GRVPrivateTransitionContext.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GRVPrivateTransitionContextDelegate;

/**
 * A private UIViewControllerContextTransitioning class to be passed on to our
 * transitioning delegates.
 *
 * @discussion Because we are a custom UIViewController class, with our own
 *      containment implementation, we have to provide an object conforming to
 *      the UIViewControllerContextTransitioning protocol. The system view
 *      controllers use one provided by the framework, which we cannot configure,
 *      let alone create. This class will be used even if the developer provides
 *      their own transitioning objects
 *
 * @note The only methods that will be called on objects of this class are the
 *      ones defined in the UIViewControllerContextTransitioning protocol. The
 *      rest are our own private implementation
 */
@interface GRVPrivateTransitionContext : NSObject <UIViewControllerContextTransitioning>

#pragma mark - Properties
/**
 * A block of code we can set to execute after having received the
 * completeTransition: message
 */
@property (copy, nonatomic) void (^completionBlock)(BOOL didComplete);

/**
 * Private setter for the animated property
 */
@property (nonatomic, getter=isAnimated) BOOL animated;

/**
 * Private setter for the interactive property
 */
@property (nonatomic, getter=isInteractive) BOOL interactive;

/**
 * The delegate for an interactive transition context.
 */
@property (weak, nonatomic) id<GRVPrivateTransitionContextDelegate>delegate;


#pragma mark - Initialization
/**
 * Designated initializer
 */
- (instancetype)initWithFromViewController:(UIViewController *)fromViewController
                          toViewController:(UIViewController *)toViewController
                                goingRight:(BOOL)goingRight;

@end