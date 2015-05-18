//
//  GRVPanGestureInteractiveTransition.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 11/5/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVPanGestureInteractiveTransition.h"

#pragma mark - Constants
/**
 * Minimum percentage complete before finishing the transition.
 * During a pan gesture, if the user doesn't make it this far the transition
 * is canceled. This aids aborting a transition after it has been started.
 *
 * This number ranges from 0.0 to 0.4 so keep it <= 0.2f
 */
static CGFloat const kMinimumPercentComplete = 0.15f;

@interface GRVPanGestureInteractiveTransition ()

// Make readonly properties, readwrite internally
@property (strong, nonatomic, readwrite) UIPanGestureRecognizer *recognizer;

@property (nonatomic) BOOL goingRight;

@end

@implementation GRVPanGestureInteractiveTransition

#pragma mark - Initialization
- (instancetype)initWithGestureRecognizerInView:(UIView *)view recognizedBlock:(void (^)(UIPanGestureRecognizer *))gestureRecognizedBlock
{
    if (self = [super init]) {
        self.gestureRecognizedBlock = [gestureRecognizedBlock copy];
        self.recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [view addGestureRecognizer:self.recognizer];
    }
    return self;
}

#pragma mark - Instance Methods
- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    [super startInteractiveTransition:transitionContext];
    // Going right means panning left
    self.goingRight = !([self.recognizer velocityInView:self.recognizer.view].x > 0);
}


#pragma mark - Target/Action Methods
- (void)pan:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.gestureRecognizedBlock(recognizer);
        
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:recognizer.view];
        CGFloat travelDistance = translation.x / CGRectGetWidth(recognizer.view.bounds);
        travelDistance = self.goingRight ? -travelDistance : travelDistance;
        [self updateInteractiveTransition:travelDistance*0.5];
    
    } else if (recognizer.state >= UIGestureRecognizerStateEnded) {
        if (self.percentComplete > kMinimumPercentComplete) {
            [self finishInteractiveTransition];
        } else {
            [self cancelInteractiveTransition];
        }
    }
}

@end
