//
//  UIImage+GRVUtilities.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/31/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "UIImage+GRVUtilities.h"

@implementation UIImage (GRVUtilities)

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
