//
//  GRVScrollViewContainer.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * GRVScrollViewContainer is a helper class that makes it possible to setup
 * a scrollView with auto layout.
 * It stretches the  content of the scrollview in portrait and landscape
 * It also uses the UIScrollView to move input fields out of the way of the keyboard
 *
 * @see http://spin.atomicobject.com/2014/03/05/uiscrollview-autolayout-ios/
 *
 * @warning this class is not very useful if not subclassed
 */
@interface GRVScrollViewContainer : UIViewController <UITextFieldDelegate>

@end
