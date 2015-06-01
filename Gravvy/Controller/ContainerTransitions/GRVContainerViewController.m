//
//  GRVContainerViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContainerViewController.h"
#import "GRVContainerViewControllerDelegate.h"
#import "GRVPrivateTransitionContext.h"
#import "GRVPrivateAnimatedTransition.h"
#import "GRVPanGestureInteractiveTransition.h"


@interface GRVContainerViewController ()

#pragma mark - Properties
#pragma mark Private
/**
 * The default, pan gesture enabled interactive transition controller
 */
@property (strong, nonatomic) GRVPanGestureInteractiveTransition *defaultInteractionController;

#pragma mark Outlets
/**
 * Container view of navigation buttons
 */
@property (weak, nonatomic) IBOutlet UIView *navigationButtonsContainerView;

/**
 * Container view that serves as the superview of the root view of the currently
 * displayed View Controller
 */
@property (weak, nonatomic) IBOutlet UIView *containerView;

@end

@implementation GRVContainerViewController

#pragma mark - Properties
- (void)setSelectedViewController:(UIViewController *)selectedViewController
{
    NSParameterAssert(selectedViewController);
    NSParameterAssert([self.viewControllers containsObject:selectedViewController]);
    [self cycleFromViewController:_selectedViewController toViewController:selectedViewController];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    NSParameterAssert(selectedIndex < [self.viewControllers count]);
    self.selectedViewController = self.viewControllers[selectedIndex];
}

- (UIGestureRecognizer *)interactiveTransitionGestureRecognizer
{
    return self.defaultInteractionController.recognizer;
}


#pragma mark - Initialization
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

#pragma mark Helpers
/**
 * Sets up an `GRVContainerViewController` object with child controllers
 * contained in viewControllers param
 */
- (void)setup
{
    // Don't want to trigger any side effects when setting the intial child VC
    _selectedIndex = 0;
    
    [self setupViewControllers];
}

#pragma mark Abstract
- (void)setupViewControllers
{
    // abstract
}

- (void)setupNavigationButtons
{
    // abstract
}

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavigationButtons];
    [self setupPanGestureRecognizer];
    
    self.selectedViewController = self.viewControllers[self.selectedIndex];
}


#pragma mark - Instance Methods
#pragma mark Abstract

- (void)updateNavigationButtonSelection
{
    // Abstract
}

#pragma mark Private
/**
 * Add pan gesture recognizer and setup for interactive transition on the child
 * view controllers.
 */
- (void)setupPanGestureRecognizer
{
    // Add gesture recognizer and setup for interactive transition
    __weak GRVContainerViewController *weakSelf = self;
    self.defaultInteractionController = [[GRVPanGestureInteractiveTransition alloc] initWithGestureRecognizerInView:self.containerView recognizedBlock:^(UIPanGestureRecognizer *recognizer) {
        // Going right happens by panning left
        BOOL goingRight = !([recognizer velocityInView:recognizer.view].x > 0);
        
        NSUInteger selectedIndex = [self.viewControllers indexOfObject:self.selectedViewController];
        if (goingRight && (selectedIndex != (self.viewControllers.count-1))) {
            // if going left-to-right and not not on the right-most VC, then
            // transition to the right VC
            weakSelf.selectedViewController = self.viewControllers[selectedIndex+1];
            
        } else if (!goingRight && (selectedIndex > 0)){
            // if going right-to-left and not on the left-most VC, then transition
            // to the left VC
            weakSelf.selectedViewController = self.viewControllers[selectedIndex-1];
        }
    }];
}

/**
 * Add another view controller's view to the container's view hierarchy
 *
 * @param content   Child VC whose view is to be added to container's view.
 */
- (void)displayContentController:(UIViewController *)content
{
    // Add the child. Calling this method also calls the child's
    // `willMoveToParentViewController:` method automatically
    [self addChildViewController:content];
    
    // Access the child's `view` property to retrieve the view and adds it to its
    // own view hierarchy. The container sets the child's size and position before
    // adding the view.
    content.view.frame = self.containerView.bounds;
    [self.containerView addSubview:content.view];
    
    // explicitly signal that the operation is complete
    [content didMoveToParentViewController:self];
}

/**
 * Remove another view controller's view from the container's view hierarchy.
 *
 * @param content   Child VC whose view is to be removed from container's view
 */
- (void)hideContentController:(UIViewController *)content
{
    // Tell the child that it is being removed.
    [content willMoveToParentViewController:nil];
    
    // Clean up the view hierarchy
    [content.view removeFromSuperview];
    
    // Remove the child from the container. Calling this method also
    // automatically calls the child's `didMoveToParentViewController:` method.
    [content removeFromParentViewController];
}


/**
 * Transitioning between two view controllers
 *
 * @param fromViewController    old child view controller
 * @param toViewController      new child view controller
 */
- (void)cycleFromViewController:(UIViewController *)fromViewController
toViewController:(UIViewController *)toViewController
{
    if ((toViewController == fromViewController) || ![self isViewLoaded]) {
        return;
    }
    
    // if this is the initial presentation, ad the child with no animation.
    if (!fromViewController) {
        [self displayContentController:toViewController];
        [self finishCycleToViewController:toViewController];
        return;
    }
    
    // Calculates the two new frame positions used to perform the transition
    // animation.
    UIView *toView = toViewController.view;
    [toView setTranslatesAutoresizingMaskIntoConstraints:YES];
    toView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    toView.frame = self.containerView.bounds;
    
    // Start both view controller transitions
    [fromViewController willMoveToParentViewController:nil];
    [self addChildViewController:toViewController];
    
    // Animate the transition by calling the animator with our private
    // transition context. If we don't have a delegate, or if it doesn't return
    // an animated transitioning object, we will use our own, private animator.
    id <UIViewControllerAnimatedTransitioning>animator = nil;
    if ([self.delegate respondsToSelector:@selector(containerViewController:animationControllerForTransitionViewController:toViewController:)]) {
        animator = [self.delegate containerViewController:self animationControllerForTransitionViewController:fromViewController toViewController:toViewController];
    }
    
    BOOL animatorIsDefault = (animator == nil);
    if (!animator) animator = [[GRVPrivateAnimatedTransition alloc] init];
        
    // Because of the nature of our view controller, with horizontally arranged
    // buttons, we instantiate our private transition context with information
    // about whether this is a left-to-right or right-to-left transition. The
    // animator can use this information if it wants.
    NSUInteger fromIndex = [self.viewControllers indexOfObject:fromViewController];
    NSUInteger toIndex = [self.viewControllers indexOfObject:toViewController];
    GRVPrivateTransitionContext *transitionContext = [[GRVPrivateTransitionContext alloc] initWithFromViewController:fromViewController toViewController:toViewController goingRight:(toIndex > fromIndex)];
    
    transitionContext.animated = YES;
    
    // At the start of the transition, we need to figure out if we should be
    // interactive or not. We do this by trying to fetch an interaction controller.
    id <UIViewControllerInteractiveTransitioning> interactionController = [self interactionControllerForAnimator:animator animatorIsDefault:animatorIsDefault];
    transitionContext.interactive = (interactionController != nil);
    
    transitionContext.delegate = self;
        
    transitionContext.completionBlock = ^(BOOL didComplete) {
        
        if (didComplete) {
            [fromViewController.view removeFromSuperview];
            [fromViewController removeFromParentViewController];
            [toViewController didMoveToParentViewController:self];
            [self finishCycleToViewController:toViewController];
            
        } else {
            [toViewController.view removeFromSuperview];
        }
        
        
        if ([animator respondsToSelector:@selector(animationEnded:)]) {
            [animator animationEnded:didComplete];
        }
        self.navigationButtonsContainerView.userInteractionEnabled = YES;
    };
    
    // Prevent user tapping butons, mid-transition, messing up state
    self.navigationButtonsContainerView.userInteractionEnabled = NO;
    
    if (transitionContext.isInteractive) {
        [interactionController startInteractiveTransition:transitionContext];
    } else {
        [animator animateTransition:transitionContext];
        // Not interactive so no transition cancellation here. So might as
        // well finish the cycling. This isn't necessary but doesn't hurt.
        [self finishCycleToViewController:toViewController];
    }
}

- (void)finishCycleToViewController:(UIViewController *)toViewController
{
    _selectedViewController = toViewController;
    _selectedIndex = [self.viewControllers indexOfObject:toViewController];
    [self updateNavigationButtonSelection];
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForAnimator:(id<UIViewControllerAnimatedTransitioning>)animationController animatorIsDefault:(BOOL)animatorIsDefault
{
    if (self.defaultInteractionController.recognizer.state == UIGestureRecognizerStateBegan) {
        self.defaultInteractionController.animator = animationController;
        return self.defaultInteractionController;
        
    } else if (!animatorIsDefault && [self.delegate respondsToSelector:@selector(containerViewController:interactionControllerForAnimationController:)]) {
        return [self.delegate containerViewController:self interactionControllerForAnimationController:animationController];
        
    } else {
        return nil;
    }
}


#pragma mark - Target/Action Methods
/**
 * Naviation button tapped so change selected view controller
 */
- (void)navigationButtonTapped:(UIButton *)button
{
    self.selectedViewController = (UIViewController *)self.viewControllers[button.tag];
    // alternatively could set self.selectedIndex to button.tag
    //   self.selectedIndex = button.tag;
    
    if ([self.delegate respondsToSelector:@selector(containerViewController:didSelectViewController:)]) {
        [self.delegate containerViewController:self didSelectViewController:self.selectedViewController];
    }
}


@end

