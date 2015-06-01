//
//  GRVPrivateTransitionContext.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVPrivateTransitionContext.h"
#import "GRVPrivateTransitionContextDelegate.h"

@interface GRVPrivateTransitionContext ()

@property (strong, nonatomic) NSDictionary *privateViewControllers;
@property (nonatomic) CGRect privateDisappearingFromRect;
@property (nonatomic) CGRect privateAppearingFromRect;
@property (nonatomic) CGRect privateDisappearingToRect;
@property (nonatomic) CGRect privateAppearingToRect;
@property (weak, nonatomic) UIView *containerView;
@property (nonatomic) UIModalPresentationStyle presentationStyle;
@property (nonatomic) BOOL transitionWasCancelled;
@property (nonatomic) BOOL goingRight;

@end

@implementation GRVPrivateTransitionContext

#pragma mark - Initialization
- (instancetype)initWithFromViewController:(UIViewController *)fromViewController
                          toViewController:(UIViewController *)toViewController
                                goingRight:(BOOL)goingRight
{
    NSAssert([fromViewController isViewLoaded] && fromViewController.view.superview,
             @"The fromViewController must reside in the container view upon initializing the transition context.");
    
    if (self = [super init]) {
        self.presentationStyle = UIModalPresentationCustom;
        self.containerView = fromViewController.view.superview;
        self.privateViewControllers = @{UITransitionContextFromViewControllerKey : fromViewController,
                                        UITransitionContextToViewControllerKey : toViewController};
        self.goingRight = goingRight;
        
        // Set the view frame properties which make sense in our specialized
        // ContainerViewController context. Views appear from and disappear to
        // the sides, corresponding to where the icon buttons are positioned.
        // So tapping a button to the right of the currently selected, makes the
        // view disappear to the left and the new view appear from the right.
        // The animator object can choose to use this to determine whether the
        // transition should be going left to right, or right to left, for example.
        CGFloat travelDistance = (goingRight ? -self.containerView.bounds.size.width : self.containerView.bounds.size.width);
        self.privateDisappearingFromRect = self.privateAppearingToRect = self.containerView.bounds;
        self.privateDisappearingToRect = CGRectOffset(self.containerView.bounds, travelDistance, 0);
        self.privateAppearingFromRect = CGRectOffset(self.containerView.bounds, -travelDistance, 0);
    }
    
    return self;
}

#pragma mark - Instance Methods
- (CGRect)initialFrameForViewController:(UIViewController *)vc
{
    if (vc == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
        return self.privateDisappearingFromRect;
    } else {
        return self.privateAppearingFromRect;
    }
}

- (CGRect)finalFrameForViewController:(UIViewController *)vc
{
    if (vc == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
        return self.privateDisappearingToRect;
    } else {
        return self.privateAppearingToRect;
    }
}

- (UIViewController *)viewControllerForKey:(NSString *)key
{
    return self.privateViewControllers[key];
}

- (void)completeTransition:(BOOL)didComplete
{
    if (self.completionBlock) {
        self.completionBlock(didComplete);
    }
}


// Suppress warnings by implementing empty interaction methods for the remainder
// of the protocol:
- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
    if ([self.delegate respondsToSelector:@selector(transitionContext:didUpdateInteractiveTransition:goingRight:)]) {
        [self.delegate transitionContext:self didUpdateInteractiveTransition:percentComplete goingRight:self.goingRight];
    }
}

- (void)finishInteractiveTransition
{
    self.transitionWasCancelled = NO;
    
    if ([self.delegate respondsToSelector:@selector(transitionContext:didFinishInteractiveTransitionGoingRight:)]) {
        [self.delegate transitionContext:self didFinishInteractiveTransitionGoingRight:self.goingRight];
    }
}

- (void)cancelInteractiveTransition
{
    self.transitionWasCancelled = YES;
    
    if ([self.delegate respondsToSelector:@selector(transitionContext:didCancelInteractiveTransitionGoingRight:)]) {
        [self.delegate transitionContext:self didCancelInteractiveTransitionGoingRight:self.goingRight];
    }
}

@end

