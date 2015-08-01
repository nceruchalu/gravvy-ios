//
//  UIImage+GRVUtilities.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/31/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * This category provides a number of helpful utitlity methods on UIImage
 */
@interface UIImage (GRVUtilities)

/**
 * Generate a UIImage with a given color
 *
 * @param color image background color
 *
 * @return UIImage
 *
 * @ref http://stackoverflow.com/a/14525049
 */
+ (UIImage *)imageWithColor:(UIColor *)color;

@end
