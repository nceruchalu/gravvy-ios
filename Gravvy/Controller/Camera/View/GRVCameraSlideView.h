//
//  GRVCameraSlideView.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/22/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * GRVCameraSlideViewProtocol specifies the methods required of any slideView
 * and its subclasses
 */
@protocol GRVCameraSlideViewProtocol <NSObject>

- (CGFloat)initialPositionWithView:(UIView *)view;
- (CGFloat)finalPosition;
- (CGFloat)heightWithView:(UIView *)view;

@end

/**
 * GRVCameraSlideView represents a view that will be used to cover or reveal
 * another view, particularly a camera preview view.
 *
 * @warning This class is meant to be subclassed
 */
@interface GRVCameraSlideView : UIView <GRVCameraSlideViewProtocol>

#pragma mark - Class Methods
/**
 * Show both slide up and slide down views to cover another view
 *
 * @param slideUpView   view that slides up
 * @param slideDownView view that slides down
 * @param view          view that will be covered by the sliding views
 * @param completion    A block object to be executed when the task finishes.
 *      This block has no return value and takes no arguments.
 */
+ (void)showSlideUpView:(GRVCameraSlideView *)slideUpView
          slideDownView:(GRVCameraSlideView *)slideDownView
                 atView:(UIView *)view
             completion:(void (^)(void))completion;

/**
 * Hide both slide up and slide down views to reveal another view
 *
 * @param slideUpView   view that slides up
 * @param slideDownView view that slides down
 * @param view          view that will be revealed by the sliding views
 * @param completion    A block object to be executed when the task finishes.
 *      This block has no return value and takes no arguments.
 */
+ (void)hideSlideUpView:(GRVCameraSlideView *)slideUpView
          slideDownView:(GRVCameraSlideView *)slideDownView
                 atView:(UIView *)view
             completion:(void (^)(void))completion;

@end
