//
//  GRVUserAvatarView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVUserAvatarView.h"
#import "GRVConstants.h"

#pragma mark - Constants
// max # of characters in initials.
static NSUInteger const kMaxUserInitialsLength  = 3;

/**
 * Avatar view user initials text font size and corresponding diameter, as this
 * font must scale with size
 */
static CGFloat const kUserAvatarFontSize = 12.0f;
static CGFloat const kUserAvatarMaxFontSize = 13.0f;
static CGFloat const kUserAvatarFontScale = 1.0f/28.0;


@implementation GRVUserAvatarView

#pragma mark - Properties
// Whenever a property is set, the view needs to be redrawn;
- (void)setThumbnail:(UIImage *)thumbnail
{
    _thumbnail = thumbnail;
    [self setNeedsDisplay];
}

- (void)setUserInitials:(NSString *)userInitials
{
    _userInitials = [userInitials copy];
    [self setNeedsDisplay];
}


#pragma mark - Initialization
- (void)setup
{
    // make transparent (no background color)
    self.backgroundColor = nil;
    self.opaque = NO;
    // want to redraw whenever bound change
    self.contentMode = UIViewContentModeRedraw;
}

- (void)awakeFromNib
{
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setup];
    }
    return self;
}


#pragma mark - Drawing
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    // Define the avatar's boundary
    UIBezierPath *circleBorder = [UIBezierPath bezierPathWithOvalInRect:self.bounds];
    
    // Restrict all avatar drawing to this circle
    [circleBorder addClip];
    
    // Set Avatar background color
    [kGRVUserAvatarBackgroundColor setFill];
    
    UIImage *avatarImage = nil;
    if (self.thumbnail) {
        // Convert thumbnail to a circular image
        avatarImage = [self circularImage:self.thumbnail withDiameter:self.bounds.size.width];
        
    } else if ([self.userInitials length]) {
        NSString *initials = self.userInitials;
        if ([initials length] > kMaxUserInitialsLength) {
            initials = @"...";
        }
        CGFloat diameter = self.bounds.size.width;
        CGFloat fontSize = kUserAvatarFontSize * diameter *kUserAvatarFontScale;
        fontSize = MIN(fontSize, kUserAvatarMaxFontSize);
        UIFont *font = [UIFont boldSystemFontOfSize:fontSize];
        avatarImage = [self imageWithInitials:initials
                              backgroundColor:kGRVUserAvatarBackgroundColor
                                    textColor:kGRVUserAvatarTextColor
                                         font:font
                                     diameter:diameter];
    } else {
        // No thumbnailor initials?, use a default avatar image
        avatarImage = [self circularImage:[UIImage imageNamed:@"defaultAvatar"]
                             withDiameter:self.bounds.size.width];
    }
    [avatarImage drawInRect:self.bounds];
}


#pragma mark - Instance Methods
#pragma mark Private
/**
 * Generate a circular image from provided initials
 *
 * Derived from JSQMessagesViewController's
 * jsq_imageWitInitials:backgroundColor:textColor:font:diameter:
 *
 * @param initials          intials to be used to generate an avatar image
 * @param backgroundColor   background color of avatar image.
 * @param textColor         color of initials in avatar image
 * @param font              font of initials in avatar image
 * @param diameter          diameter of avatar image circle.
 *
 * @return a composed UIImage.
 */
- (UIImage *)imageWithInitials:(NSString *)initials
               backgroundColor:(UIColor *)backgroundColor
                     textColor:(UIColor *)textColor
                          font:(UIFont *)font
                      diameter:(NSUInteger)diameter
{
    NSParameterAssert(initials != nil);
    NSParameterAssert(backgroundColor != nil);
    NSParameterAssert(textColor != nil);
    NSParameterAssert(font != nil);
    NSParameterAssert(diameter > 0);
    
    CGRect frame = CGRectMake(0.0f, 0.0f, diameter, diameter);
    
    NSString *text = [initials uppercaseStringWithLocale:[NSLocale currentLocale]];
    
    NSDictionary *attributes = @{ NSFontAttributeName : font,
                                  NSForegroundColorAttributeName : textColor };
    
    CGRect textFrame = [text boundingRectWithSize:frame.size
                                          options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                       attributes:attributes
                                          context:nil];
    
    CGPoint frameMidPoint = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    CGPoint textFrameMidPoint = CGPointMake(CGRectGetMidX(textFrame), CGRectGetMidY(textFrame));
    
    CGFloat dx = frameMidPoint.x - textFrameMidPoint.x;
    CGFloat dy = frameMidPoint.y - textFrameMidPoint.y;
    CGPoint drawPoint = CGPointMake(dx, dy);
    UIImage *image = nil;
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, [UIScreen mainScreen].scale);
    {
        [self pushContext];
        
        [backgroundColor setFill];
        UIRectFill(frame);
        [text drawAtPoint:drawPoint withAttributes:attributes];
        
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        [self pushContext];
    }
    UIGraphicsEndImageContext();
    
    return [self circularImage:image withDiameter:diameter];
}


/**
 * Generate a circular image from provided rectangular image
 *
 * Derived from JSQMessagesViewController's
 * jsq_circularImage:withDiamter:highlightedColor:
 *
 * @param image             Image to be cropped to a circular view.
 * @param diameter          diameter of avatar image circle. Must be > 0.
 *
 * @return a composed UIImage.
 */
- (UIImage *)circularImage:(UIImage *)image
              withDiameter:(NSUInteger)diameter
{
    NSParameterAssert(image != nil);
    NSParameterAssert(diameter > 0);
    
    CGRect frame = CGRectMake(0.0f, 0.0f, diameter, diameter);
    UIImage *newImage = nil;
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, [UIScreen mainScreen].scale);
    {
        [self pushContext];
        
        UIBezierPath *imgPath = [UIBezierPath bezierPathWithOvalInRect:frame];
        [imgPath addClip];
        [image drawInRect:frame];
        
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        [self popContext];
    }
    UIGraphicsEndImageContext();
    
    return newImage;
}


/**
 * Push current CGContext. This is used in conjunction with `popContext`
 */
- (void)pushContext
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
}

/**
 * Pop most recent CGContext. This is unded in conjunction with `pushContext`
 */
- (void)popContext
{
    CGContextRestoreGState(UIGraphicsGetCurrentContext());
}



@end
