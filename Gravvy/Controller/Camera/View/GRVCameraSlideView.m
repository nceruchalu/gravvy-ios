//
//  GRVCameraSlideView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/22/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCameraSlideView.h"

#pragma mark - Constants
// Slide view removal duration
static NSTimeInterval const kSlideViewRemovalDuration  = 0.30f;
// Slide view presentation duration
static NSTimeInterval const kSlideViewPresentationDuration = 0.15f;

@interface GRVCameraSlideView ()


@end

@implementation GRVCameraSlideView

#pragma mark - Class Methods
#pragma mark Public
+ (void)showSlideUpView:(GRVCameraSlideView *)slideUpView
          slideDownView:(GRVCameraSlideView *)slideDownView
                 atView:(UIView *)view
             completion:(void (^)(void))completion
{
    [slideUpView addSlideToView:view
                    withOriginY:[slideUpView finalPosition]
                    usingHeight:[slideUpView heightWithView:view]];
    [slideDownView addSlideToView:view
                      withOriginY:[slideDownView finalPosition]
                      usingHeight:[slideDownView heightWithView:view]];
    
    [slideUpView removeSlideFromSuperview:NO withDuration:kSlideViewPresentationDuration originY:[slideUpView initialPositionWithView:view] completion:nil];
    [slideDownView removeSlideFromSuperview:NO withDuration:kSlideViewPresentationDuration originY:[slideDownView initialPositionWithView:view] completion:completion];
}

+ (void)hideSlideUpView:(GRVCameraSlideView *)slideUpView
          slideDownView:(GRVCameraSlideView *)slideDownView
                 atView:(UIView *)view
             completion:(void (^)(void))completion
{
    [slideUpView hideWithAnimationAtView:view withTimeInterval:kSlideViewRemovalDuration completion:nil];
    [slideDownView hideWithAnimationAtView:view withTimeInterval:kSlideViewRemovalDuration completion:completion];
}


#pragma mark - Instance Methods
#pragma mark Private
- (void)showWithAnimationAtView:(UIView *)view completion:(void (^)(void))completion
{
    [self addSlideToView:view
             withOriginY:[self finalPosition]
             usingHeight:[self heightWithView:view]];
    
    [self removeSlideFromSuperview:NO
                      withDuration:kSlideViewPresentationDuration
                           originY:[self initialPositionWithView:view]
                        completion:completion];
}

- (void)hideWithAnimationAtView:(UIView *)view completion:(void (^)(void))completion
{
    [self hideWithAnimationAtView:view
                 withTimeInterval:kSlideViewRemovalDuration
                       completion:completion];
}

- (void)hideWithAnimationAtView:(UIView *)view withTimeInterval:(CGFloat)timeInterval completion:(void (^)(void))completion
{
    [self addSlideToView:view
             withOriginY:[self initialPositionWithView:view]
             usingHeight:[self heightWithView:view]];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self removeSlideFromSuperview:YES
                              withDuration:timeInterval
                                   originY:[self finalPosition]
                                completion:completion];
        });
    });
}

/**
 * Use slide view to cover half the height of another view (capture view).
 * Ideally this is setup for eventual removal by calling
 * hideSlideUpView:slideDownView:atView:completion:
 *
 * @param view      View that will be covered
 * @param originY   y positiion of the slide view's frame
 * @param height    height of the slide view's frame
 */
- (void)addSlideToView:(UIView *)view withOriginY:(CGFloat)originY usingHeight:(CGFloat)height
{
    CGFloat width = CGRectGetWidth(view.frame);
    
    CGRect frame = self.frame;
    frame.size.width = width;
    frame.size.height = height;
    frame.origin.y = originY;
    self.frame = frame;
    
    [view addSubview:self];
}


- (void)removeSlideFromSuperview:(BOOL)remove withDuration:(CGFloat)duration originY:(CGFloat)originY completion:(void (^)(void))completion
{
    CGRect frame = self.frame;
    frame.origin.y = originY;
    
    [UIView animateWithDuration:duration animations:^{
        self.frame = frame;
    } completion:^(BOOL finished) {
        if (finished) {
            if (remove) {
                [self removeFromSuperview];
            }
            
            if (completion) {
                completion();
            }
        }
    }];
}


#pragma mark - GRVCameraSlideViewProtocol
- (CGFloat)initialPositionWithView:(UIView *)view
{
    // Abstract
    return 0.;
}

- (CGFloat)finalPosition
{
    // Abstract
    return 0.;
}

- (CGFloat)heightWithView:(UIView *)view
{
    // Abstract;
    return CGRectGetHeight(view.frame)/2;
}


@end
