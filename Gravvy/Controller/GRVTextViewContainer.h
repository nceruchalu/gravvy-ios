//
//  GRVTextViewContainer.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/19/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * GRVTextViewContainer is a helper class that makes it possible to setup
 * a textView with auto layout and keyboard management.
 * It stretches the  content of the textview in portrait and landscape
 * It also uses the UITextView to move input fields out of the way of the keyboard
 *
 * @see https://devforums.apple.com/message/918284
 *
 * @warning this class is not very useful if not subclassed
 */
@interface GRVTextViewContainer : UIViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

// Max length of data entered in this text view. The default is 0 which means
// no max length.
@property (nonatomic) NSUInteger maxLength;

@end
