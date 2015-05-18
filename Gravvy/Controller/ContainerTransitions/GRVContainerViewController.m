//
//  GRVContainerViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContainerViewController.h"
#import "GRVConstants.h"
#import "GRVContainerViewControllerDelegate.h"
#import "GRVPrivateTransitionContext.h"
#import "GRVPrivateAnimatedTransition.h"
#import "GRVPanGestureInteractiveTransition.h"


#pragma mark - Constants
/**
 * Spacing between navigation button text and image
 */
static CGFloat const kNavigationButtonSpacing = 4.0f;

/**
 * Inactive button tint color: #757A82
 */
#define kInactiveTintColor [UIColor colorWithRed:117.0/255.0 green:122.0/255.0 blue:130.0/255.0 alpha:1.0]

static NSString *const kStoryboardName                      = @"Main";
/**
 * Child view controllers' storyboard identifiers
 */
static NSString *const kStoryboardIdentifierEventOptions    = @"EventOptions";
static NSString *const kStoryboardIdentifierEventChat       = @"EventChat";
static NSString *const kStoryboardIdentifierEventPhotos     = @"EventPhotos";
static NSString *const kStoryboardIdentifierEventInfo       = @"EventInfo";


@interface GRVContainerViewController ()

#pragma mark - Properties
#pragma mark Private
// Make readonly properties readwrite internally
@property (copy, nonatomic, readwrite) NSArray *viewControllers;

// ordering of navigation buttons matches that of view controllers
@property (copy, nonatomic) NSArray *navigationButtons;

// The default, pan gesture enabled interactive transition controller
@property (strong, nonatomic) GRVPanGestureInteractiveTransition *defaultInteractionController;

#pragma mark Outlets
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (weak, nonatomic) IBOutlet UIButton *chatButton;
@property (weak, nonatomic) IBOutlet UIButton *photosButton;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@property (weak, nonatomic) IBOutlet UIView *navigationButtonsContainerView;
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
    // First grab storyboard to grab view controllers
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:kStoryboardName bundle:nil];
    
    // Instantiate and initialize view controllers
    UIViewController *eventOptionsVC = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:kStoryboardIdentifierEventOptions];
    UIViewController *eventChatVC = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:kStoryboardIdentifierEventChat];
    UIViewController *eventPhotosVC = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:kStoryboardIdentifierEventPhotos];
    UIViewController *eventInfoVC = (UIViewController *)[storyboard instantiateViewControllerWithIdentifier:kStoryboardIdentifierEventInfo];
    
    // ordering of the view controllers must match ordering of self.navigationButtons
    self.viewControllers = @[eventOptionsVC, eventChatVC, eventPhotosVC, eventInfoVC];
    
    // Don't want to trigger any side effects
    _selectedIndex = 0;
}

/**
 * Setup the navigation buttons to:
 * - Use same ordering as viewControllers
 * - Use content from the viewControllers tabBarItems
 * - Have image tint color be same as button tint color
 * - Center navigation button images above the text without any magic numbers
 * - Show inactive tint colors
 * - Set selected index to active
 */
- (void)setupNavigationButtons
{
    // Ordering of the navigation buttons must match ordering of self.viewControllers
    self.navigationButtons = @[self.optionsButton, self.chatButton, self.photosButton, self.infoButton];
    
    NSUInteger idx = 0;
    for (idx=0; idx < [self.navigationButtons count]; idx++) {
        UIButton *navigationButton = self.navigationButtons[idx];
        
        // Track button index in the tag attribute
        navigationButton.tag = idx;
        
        // Set up button target/action method
        [navigationButton addTarget:self action:@selector(navigationButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        // Configure image tint color
        UITabBarItem *tabBarItem = ((UIViewController *)self.viewControllers[idx]).tabBarItem;
        UIImage *image = [tabBarItem.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        NSString *title = tabBarItem.title;
        
        [navigationButton setImage:image forState:UIControlStateNormal];
        [navigationButton setTitle:title forState:UIControlStateNormal];
        
        // Center image above text
        // lower the text and push it left so it appears centered below the image
        CGSize imageSize = image.size;
        navigationButton.titleEdgeInsets = UIEdgeInsetsMake(0.0f, -imageSize.width, -(imageSize.height+kNavigationButtonSpacing), 0.0f);
        
        // raise the image and push it right so it appears centered above the text
        UILabel *titleLabel = navigationButton.titleLabel;
        CGSize titleSize = [titleLabel.text sizeWithAttributes:@{NSFontAttributeName : titleLabel.font}];
        navigationButton.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + kNavigationButtonSpacing), 0.0f, 0.0f, -titleSize.width);
        
        // Set to inactive tint color
        navigationButton.tintColor = kInactiveTintColor;
    }
    
    // Make the options tab active
    self.optionsButton.tintColor = kGRVThemeColor;
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
#pragma mark Private
/**
 * Update the selected navigation button, and deselect all other navigation buttons.
 */
- (void)updateNavigationButtonSelection
{
    [self.navigationButtons enumerateObjectsUsingBlock:^(UIButton *navigationButton, NSUInteger idx, BOOL *stop) {
        navigationButton.selected = self.viewControllers[idx] == self.selectedViewController;
        
        UIColor *buttonColor = navigationButton.selected ? kGRVThemeColor : kInactiveTintColor;
        navigationButton.tintColor = buttonColor;
        [navigationButton setTitleColor:buttonColor forState:UIControlStateNormal];
    }];
}

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

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


@end

