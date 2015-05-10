//
//  GRVAlertBannerView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//
//  Heavily based on ALAlertBanner, https://github.com/alobi/ALAlertBanner

#import "GRVAlertBannerView.h"
#import <QuartzCore/QuartzCore.h>
#import "GRVAlertBannerView+Private.h"
#import "GRVAlertBannerManager.h"
#import "GRVUserAvatarView.h"
#import "GRVConstants.h"

#pragma mark - Constants
/**
 * Banner Background Color is RGB #505050
 */
#define kAlertBannerBackgroundColor [UIColor colorWithRed:80.0/255.0 green:80.0/255.0 blue:80.0/255.0 alpha:1.0]

/**
 * Banner text color is white
 */
#define kAlertBannerTextColor [UIColor whiteColor]


static NSString * const kShowAlertBannerKey = @"showAlertBannerKey";
static NSString * const kHideAlertBannerKey = @"hideAlertBannerKey";
static NSString * const kMoveAlertBannerKey = @"moveAlertBannerKey";

static CGFloat const kShadowMargin = 10.f;
static CGFloat const kMessageMarginTop = 0.0f;
static CGFloat const kTitleMarginRight = 0.0f;
static CGFloat const kAvatarThumbnailMarginHorizontal = 8.0f;
static CGFloat const kAvatarThumbnailMarginVertical = 6.0f;
static CGFloat const kAvatarThumbnailHeight = 50.0f;
static CGFloat const kCloseButtonWidth = 52.0f;

static CGFloat const kNavigationBarHeightDefault = 44.f;
static CGFloat const kNavigationBarHeightiOS7Landscape = 32.f;

static CFTimeInterval const kRotationDurationIphone = 0.3;
static CFTimeInterval const kRotationDurationIPad = 0.4;

static CGFloat const kForceHideAnimationDuration = 0.1f;

#pragma mark Default Property Values
static NSTimeInterval kDefaultFadeOutDuration = 0.2f;
static NSTimeInterval kDefaultShowAnimationDuration = 0.25f;
static NSTimeInterval kDefaultHideAnimationDuration = 0.2f;
static CGFloat kDefaultBannerOpacity = 0.93f;
static CGFloat kDefaultBannerSecondsToShow = 5.0f;

#pragma mark Default Subview Property Values
static CGFloat kBannerTitleFontSize = 14.0f;
static CGFloat kBannerMessageFontSize = 13.0f;
static CGFloat kBannerTextShadowOpacity = 0.3f;
static CGFloat kBannerTextShadowRadius = 0.0f;

#pragma mark Macros
#define GRV_DEVICE_ANIMATION_DURATION UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? kRotationDurationIPad : kRotationDurationIphone;

# pragma mark - Categories for Convenience
@implementation UIApplication (GRVApplicationBarHeights)

+ (CGFloat)navigationBarHeight
{
    //if we're on iOS7 or later, return new landscape navBar height
    if (UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad)
        return kNavigationBarHeightiOS7Landscape;
    
    return kNavigationBarHeightDefault;
}

+ (CGFloat)statusBarHeight
{
    return [UIApplication sharedApplication].statusBarFrame.size.height;
}

@end


@interface GRVAlertBannerView () <UIGestureRecognizerDelegate>

#pragma mark - Properties
@property (strong, nonatomic) GRVAlertBannerManager *manager;
@property (nonatomic) GRVAlertBannerViewPosition position;
@property (nonatomic) GRVAlertBannerViewState state;
@property (nonatomic) NSTimeInterval fadeOutDuration;
@property (nonatomic, readonly) BOOL isAnimating;
@property (strong, nonatomic) GRVUserAvatarView *avatarThumbnailView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIButton *closeButton;
@property (nonatomic) CGRect parentFrameUponCreation;

@end


@implementation GRVAlertBannerView

# pragma mark - Properties
- (void)setShowShadow:(BOOL)showShadow
{
    _showShadow = showShadow;
    
    CGFloat oldShadowRadius = self.layer.shadowRadius;
    CGFloat newShadowRadius;
    
    if (showShadow) {
        newShadowRadius = 3.f;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0.f, self.position == GRVAlertBannerViewPositionBottom ? -1.f : 1.f);
        CGRect shadowPath = CGRectMake(self.bounds.origin.x - kShadowMargin, self.bounds.origin.y, self.bounds.size.width + kShadowMargin*2.f, self.bounds.size.height);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:shadowPath].CGPath;
        
        self.fadeInDuration = 0.15f;
    }
    
    else {
        newShadowRadius = 0.f;
        self.layer.shadowRadius = 0.f;
        self.layer.shadowOffset = CGSizeZero;
        
        //if on iOS7, keep fade in duration at a value greater than 0 so it doesn't instantly appear behind the translucent nav bar
        self.fadeInDuration = (self.position == GRVAlertBannerViewPositionTop) ? 0.15f : 0.f;
    }
    
    self.layer.shouldRasterize = YES;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shadowRadius = newShadowRadius;
    
    CABasicAnimation *fadeShadow = [CABasicAnimation animationWithKeyPath:@"shadowRadius"];
    fadeShadow.fromValue = [NSNumber numberWithFloat:oldShadowRadius];
    fadeShadow.toValue = [NSNumber numberWithFloat:newShadowRadius];
    fadeShadow.duration = self.fadeOutDuration;
    [self.layer addAnimation:fadeShadow forKey:@"shadowRadius"];
}

- (BOOL)isAnimating
{
    return (self.state == GRVAlertBannerViewStateShowing ||
            self.state == GRVAlertBannerViewStateHiding ||
            self.state == GRVAlertBannerViewStateMovingForward ||
            self.state == GRVAlertBannerViewStateMovingBackward);
}


# pragma mark - Class Methods
# pragma mark Public

+ (NSArray *)alertBannersInView:(UIView *)view
{
    return [[GRVAlertBannerManager sharedManager] alertBannersInView:view];
}

+ (void)hideAllAlertBanners {
    [[GRVAlertBannerManager sharedManager] hideAllAlertBanners];
}

+ (void)hideAlertBannersInView:(UIView *)view {
    [[GRVAlertBannerManager sharedManager] hideAlertBannersInView:view];
}

+ (void)forceHideAllAlertBannersInView:(UIView *)view {
    [[GRVAlertBannerManager sharedManager] forceHideAllAlertBannersInView:view];
}

+ (GRVAlertBannerView *)alertBannerForView:(UIView *)view
                                     title:(NSString *)title
                                   message:(NSString *)message
                           avatarThumbnail:(UIImage *)avatarThumbnail
                              withInitials:(NSString *)userInitials
                               tappedBlock:(void (^)(GRVAlertBannerView *alertBanner))tappedBlock
                 andCloseButtonTappedBlock:(void (^)(GRVAlertBannerView *alertBanner))closeButtonTappedBlock
{
    
    GRVAlertBannerView *alertBanner = [[GRVAlertBannerView alloc] init];
    
    alertBanner.avatarThumbnailView.userInitials = userInitials;
    alertBanner.avatarThumbnailView.thumbnail = avatarThumbnail;
    alertBanner.titleLabel.text = title;
    alertBanner.messageLabel.text = message;
    alertBanner.position = GRVAlertBannerViewPositionTop;
    alertBanner.state = GRVAlertBannerViewStateHidden;
    alertBanner.tappedBlock = tappedBlock;
    alertBanner.closeButtonTappedBlock = closeButtonTappedBlock;
    
    [view addSubview:alertBanner];
    
    [alertBanner setInitialLayout];
    [alertBanner updateSizeAndSubviewsAnimated:NO];
    
    return alertBanner;
}

#pragma mark - Private
/**
 * Determine view height for a single line string possibly in a UILabel
 *
 * @param text String of interest
 * @param font String's font
 *
 * @return string height
 */
+ (CGFloat)singleLineTextHeight:(NSString *)text withFont:(UIFont *)font
{
    return [text sizeWithAttributes:@{NSFontAttributeName : font}].height;
}


#pragma mark - Initialization
- (id)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

# pragma mark Helpers
- (void)commonInit
{
    self.userInteractionEnabled = YES;
    self.backgroundColor = kAlertBannerBackgroundColor;
    self.alpha = 0.f;
    self.layer.shadowOpacity = 0.5f;
    self.tag = arc4random_uniform(SHRT_MAX);
    
    // Setup tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedAlertBannerView:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
    
    [self setupSubviews];
    [self setupInitialValues];
}

- (void)setupInitialValues
{
    _fadeOutDuration = kDefaultFadeOutDuration;
    _showAnimationDuration = kDefaultShowAnimationDuration;
    _hideAnimationDuration = kDefaultHideAnimationDuration;
    _scheduledToHide = NO;
    _bannerOpacity = kDefaultBannerOpacity;
    _secondsToShow = kDefaultBannerSecondsToShow;
    _shouldForceHide = NO;
    
    _manager = [GRVAlertBannerManager sharedManager];
    self.delegate = (GRVAlertBannerManager <GRVAlertBannerViewDelegate> *)_manager;
}

- (void)setupSubviews
{
    _avatarThumbnailView = [[GRVUserAvatarView alloc] init];
    [self addSubview:_avatarThumbnailView];
    
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:kBannerTitleFontSize];
    _titleLabel.textColor = kAlertBannerTextColor;
    _titleLabel.textAlignment = NSTextAlignmentLeft;
    _titleLabel.numberOfLines = 1;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _titleLabel.layer.shadowOffset = CGSizeMake(0.f, -1.f);
    _titleLabel.layer.shadowOpacity = kBannerTextShadowOpacity;
    _titleLabel.layer.shadowRadius = kBannerTextShadowRadius;
    [self addSubview:_titleLabel];
    
    _messageLabel = [[UILabel alloc] init];
    _messageLabel.backgroundColor = [UIColor clearColor];
    _messageLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:kBannerMessageFontSize];
    _messageLabel.textColor = kAlertBannerTextColor;
    _messageLabel.textAlignment = NSTextAlignmentLeft;
    _messageLabel.numberOfLines = 2;
    _messageLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _messageLabel.layer.shadowColor = [UIColor blackColor].CGColor;
    _messageLabel.layer.shadowOffset = CGSizeMake(0.f, -1.f);
    _messageLabel.layer.shadowOpacity = kBannerTextShadowOpacity;
    _messageLabel.layer.shadowRadius = kBannerTextShadowRadius;
    [self addSubview:_messageLabel];
    
    _closeButton = [[UIButton alloc] init];
    [_closeButton setImage:[UIImage imageNamed:@"pushClose"] forState:UIControlStateNormal];
    _closeButton.imageView.contentMode = UIViewContentModeCenter;
    [_closeButton addTarget:self action:@selector(tappedCloseButton:) forControlEvents:UIControlEventTouchUpInside];
    
    [self addSubview:_closeButton];
}


# pragma mark - Instance Methods
# pragma mark Public

- (void)show
{
    [self.delegate showAlertBanner:self hideAfter:self.secondsToShow];
}

- (void)hide
{
    [self.delegate hideAlertBanner:self forced:NO];
}


# pragma mark Protected
- (void)showAlertBanner
{
    if (!CGRectEqualToRect(self.parentFrameUponCreation, self.superview.bounds)) {
        //if view size changed since this banner was created, reset layout
        [self setInitialLayout];
        [self updateSizeAndSubviewsAnimated:NO];
    }
    
    [self.delegate alertBannerWillShow:self inView:self.superview];
    
    self.state = GRVAlertBannerViewStateShowing;
    
    double delayInSeconds = self.fadeInDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.position == GRVAlertBannerViewPositionUnderNavBar) {
            //animate mask
            CGPoint currentPoint = self.layer.mask.position;
            CGPoint newPoint = CGPointMake(0.f, -self.frame.size.height);
            
            self.layer.mask.position = newPoint;
            
            CABasicAnimation *moveMaskUp = [CABasicAnimation animationWithKeyPath:@"position"];
            moveMaskUp.fromValue = [NSValue valueWithCGPoint:currentPoint];
            moveMaskUp.toValue = [NSValue valueWithCGPoint:newPoint];
            moveMaskUp.duration = self.showAnimationDuration;
            moveMaskUp.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            
            [self.layer.mask addAnimation:moveMaskUp forKey:@"position"];
        }
        
        CGPoint oldPoint = self.layer.position;
        CGFloat yCoord = oldPoint.y;
        switch (self.position) {
            case GRVAlertBannerViewPositionTop:
            case GRVAlertBannerViewPositionUnderNavBar:
                yCoord += self.frame.size.height;
                break;
            case GRVAlertBannerViewPositionBottom:
                yCoord -= self.frame.size.height;
                break;
        }
        CGPoint newPoint = CGPointMake(oldPoint.x, yCoord);
        
        self.layer.position = newPoint;
        
        CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
        moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
        moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
        moveLayer.duration = self.showAnimationDuration;
        moveLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        moveLayer.delegate = self;
        [moveLayer setValue:kShowAlertBannerKey forKey:@"anim"];
        
        [self.layer addAnimation:moveLayer forKey:kShowAlertBannerKey];
    });
    
    [UIView animateWithDuration:self.fadeInDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.alpha = self.bannerOpacity;
    } completion:nil];
}

- (void)hideAlertBanner
{
    [self.delegate alertBannerWillHide:self inView:self.superview];
    
    self.state = GRVAlertBannerViewStateHiding;
    
    if (self.position == GRVAlertBannerViewPositionUnderNavBar) {
        CGPoint currentPoint = self.layer.mask.position;
        CGPoint newPoint = CGPointZero;
        
        self.layer.mask.position = newPoint;
        
        CABasicAnimation *moveMaskDown = [CABasicAnimation animationWithKeyPath:@"position"];
        moveMaskDown.fromValue = [NSValue valueWithCGPoint:currentPoint];
        moveMaskDown.toValue = [NSValue valueWithCGPoint:newPoint];
        moveMaskDown.duration = self.shouldForceHide ? kForceHideAnimationDuration : self.hideAnimationDuration;
        moveMaskDown.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        
        [self.layer.mask addAnimation:moveMaskDown forKey:@"position"];
    }
    
    CGPoint oldPoint = self.layer.position;
    CGFloat yCoord = oldPoint.y;
    switch (self.position) {
        case GRVAlertBannerViewPositionTop:
        case GRVAlertBannerViewPositionUnderNavBar:
            yCoord -= self.frame.size.height;
            break;
        case GRVAlertBannerViewPositionBottom:
            yCoord += self.frame.size.height;
            break;
    }
    CGPoint newPoint = CGPointMake(oldPoint.x, yCoord);
    
    self.layer.position = newPoint;
    
    CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
    moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
    moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
    moveLayer.duration = self.shouldForceHide ? kForceHideAnimationDuration : self.hideAnimationDuration;
    moveLayer.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    moveLayer.delegate = self;
    [moveLayer setValue:kHideAlertBannerKey forKey:@"anim"];
    
    [self.layer addAnimation:moveLayer forKey:kHideAlertBannerKey];
}

- (void)pushAlertBanner:(CGFloat)distance forward:(BOOL)forward delay:(double)delay
{
    self.state = (forward ? GRVAlertBannerViewStateMovingForward : GRVAlertBannerViewStateMovingBackward);
    
    CGFloat distanceToPush = distance;
    if (self.position == GRVAlertBannerViewPositionBottom)
        distanceToPush *= -1;
    
    CALayer *activeLayer = self.isAnimating ? (CALayer *)[self.layer presentationLayer] : self.layer;
    
    CGPoint oldPoint = activeLayer.position;
    CGPoint newPoint = CGPointMake(oldPoint.x, (self.layer.position.y - oldPoint.y)+oldPoint.y+distanceToPush);
    
    double delayInSeconds = delay;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.layer.position = newPoint;
        
        CABasicAnimation *moveLayer = [CABasicAnimation animationWithKeyPath:@"position"];
        moveLayer.fromValue = [NSValue valueWithCGPoint:oldPoint];
        moveLayer.toValue = [NSValue valueWithCGPoint:newPoint];
        moveLayer.duration = forward ? self.showAnimationDuration : self.hideAnimationDuration;
        moveLayer.timingFunction = forward ? [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut] : [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        moveLayer.delegate = self;
        [moveLayer setValue:kMoveAlertBannerKey forKey:@"anim"];
        
        [self.layer addAnimation:moveLayer forKey:kMoveAlertBannerKey];
    });
}

- (void)updateSizeAndSubviewsAnimated:(BOOL)animated
{
    CGSize superviewSize = self.superview.bounds.size;
    
    // If on iOS7, the rotation events are off so adjust for that by swapping
    // the superview's bound size's width and height accordingly for portrait
    // and/or landscape modes
    if (GRV_SYSTEM_VERSION_LESS_THAN(@"8.0")) {
        // This is an iOS7 device, so let's check and swap width/size if
        // necessary
        CGFloat longerSide = MAX(superviewSize.width, superviewSize.height);
        CGFloat shorterSide = MIN(superviewSize.width, superviewSize.height);
        
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            // In portrait mode, the height is longer than the width
            superviewSize.height = longerSide;
            superviewSize.width = shorterSide;
            
        } else {
            // In landscape mode, the height is shorter than the width
            superviewSize.height = shorterSide;
            superviewSize.width = longerSide;
        }
    }
    
    // All elements in the banner have a fixed width except the title and message
    // labels. so determine the max size these labels can take up
    // by taking out the space required for other elements
    CGFloat avatarWidthAndMargins = kAvatarThumbnailMarginHorizontal*2.0f + kAvatarThumbnailHeight;
    CGFloat maxLabelWidth = (superviewSize.width - avatarWidthAndMargins - kTitleMarginRight - kCloseButtonWidth);
    CGSize maxLabelSize = CGSizeMake(maxLabelWidth, CGFLOAT_MAX);
    
    // Title label is a single line field
    CGFloat titleLabelHeight =  [GRVAlertBannerView singleLineTextHeight:self.titleLabel.text withFont:self.titleLabel.font];
    
    // Message label is a 2-line field so its height is simply 2*title label height
    CGFloat messageLabelHeight = titleLabelHeight * 2.0f;
    
    // Height of banner is determined by avatar thumbnail
    CGFloat heightForSelf = kAvatarThumbnailHeight + kAvatarThumbnailMarginVertical *2.0f;
    
    CFTimeInterval boundsAnimationDuration = GRV_DEVICE_ANIMATION_DURATION;
    
    CGRect oldBounds = self.layer.bounds;
    CGRect newBounds = oldBounds;
    newBounds.size = CGSizeMake(superviewSize.width, heightForSelf);
    self.layer.bounds = newBounds;
    
    if (animated) {
        CABasicAnimation *boundsAnimation = [CABasicAnimation animationWithKeyPath:@"bounds"];
        boundsAnimation.fromValue = [NSValue valueWithCGRect:oldBounds];
        boundsAnimation.toValue = [NSValue valueWithCGRect:newBounds];
        boundsAnimation.duration = boundsAnimationDuration;
        [self.layer addAnimation:boundsAnimation forKey:@"bounds"];
    }
    
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:boundsAnimationDuration];
    }
    
    // Avatar thumbnail is offset horizontally and vertically by
    // kAvatarThumbnailMarginHorizontal and kAvatarThumbnailMarginVertical
    // with both width and height of kAvatarThumbnailHeight
    self.avatarThumbnailView.frame = CGRectMake(kAvatarThumbnailMarginHorizontal,
                                                (self.frame.size.height/2.f) - (kAvatarThumbnailHeight/2.f),
                                                kAvatarThumbnailHeight,
                                                kAvatarThumbnailHeight);
    
    // Title label is offset from avatar thumbnail by kAvatarThumbnailMarginHorizontal
    // and its top is aligned with avatar thumbnail's top
    self.titleLabel.frame = CGRectMake(self.avatarThumbnailView.frame.origin.x + kAvatarThumbnailHeight + kAvatarThumbnailMarginHorizontal,
                                       kAvatarThumbnailMarginVertical,
                                       maxLabelSize.width,
                                       titleLabelHeight);
    
    // Message label is offset from title label vertically by kMessageMarginTop
    // and its left and right are aligned with title label.
    self.messageLabel.frame = CGRectMake(self.titleLabel.frame.origin.x,
                                         self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height + kMessageMarginTop,
                                         maxLabelSize.width,
                                         messageLabelHeight);
    
    // Close button is centered vertically in container and to the right of the
    // title label. It also takes the full height of the banner
    self.closeButton.frame = CGRectMake(self.titleLabel.frame.origin.x + maxLabelSize.width + kTitleMarginRight,
                                        0,
                                        kCloseButtonWidth,
                                        heightForSelf);
    
    if (animated) {
        [UIView commitAnimations];
    }
    
    if (self.showShadow) {
        CGRect oldShadowPath = CGPathGetPathBoundingBox(self.layer.shadowPath);
        CGRect newShadowPath = CGRectMake(self.bounds.origin.x - kShadowMargin, self.bounds.origin.y, self.bounds.size.width + kShadowMargin*2.f, self.bounds.size.height);
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:newShadowPath].CGPath;
        
        if (animated) {
            CABasicAnimation *shadowAnimation = [CABasicAnimation animationWithKeyPath:@"shadowPath"];
            shadowAnimation.fromValue = (id)[UIBezierPath bezierPathWithRect:oldShadowPath].CGPath;
            shadowAnimation.toValue = (id)[UIBezierPath bezierPathWithRect:newShadowPath].CGPath;
            shadowAnimation.duration = boundsAnimationDuration;
            [self.layer addAnimation:shadowAnimation forKey:@"shadowPath"];
        }
    }
}

- (void)updatePositionAfterRotationWithY:(CGFloat)yPos animated:(BOOL)animated
{
    CFTimeInterval positionAnimationDuration = kRotationDurationIphone;
    
    BOOL isAnimating = self.isAnimating;
    CALayer *activeLayer = isAnimating ? (CALayer *)self.layer.presentationLayer : self.layer;
    NSString *currentAnimationKey = nil;
    CAMediaTimingFunction *timingFunction = nil;
    
    if (isAnimating) {
        CABasicAnimation *currentAnimation;
        if (self.state == GRVAlertBannerViewStateShowing) {
            currentAnimation = (CABasicAnimation *)[self.layer animationForKey:kShowAlertBannerKey];
            currentAnimationKey = kShowAlertBannerKey;
        } else if (self.state == GRVAlertBannerViewStateHiding) {
            currentAnimation = (CABasicAnimation *)[self.layer animationForKey:kHideAlertBannerKey];
            currentAnimationKey = kHideAlertBannerKey;
        } else if (self.state == GRVAlertBannerViewStateMovingBackward || self.state == GRVAlertBannerViewStateMovingForward) {
            currentAnimation = (CABasicAnimation *)[self.layer animationForKey:kMoveAlertBannerKey];
            currentAnimationKey = kMoveAlertBannerKey;
        } else
            return;
        
        CFTimeInterval remainingAnimationDuration = currentAnimation.duration - (CACurrentMediaTime() - currentAnimation.beginTime);
        timingFunction = currentAnimation.timingFunction;
        positionAnimationDuration = remainingAnimationDuration;
        
        [self.layer removeAnimationForKey:currentAnimationKey];
    }
    
    if (self.state == GRVAlertBannerViewStateHiding || self.state == GRVAlertBannerViewStateMovingBackward) {
        switch (self.position) {
            case GRVAlertBannerViewPositionTop:
            case GRVAlertBannerViewPositionUnderNavBar:
                yPos -= self.layer.bounds.size.height;
                break;
                
            case GRVAlertBannerViewPositionBottom:
                yPos += self.layer.bounds.size.height;
                break;
        }
    }
    CGPoint oldPos = activeLayer.position;
    CGPoint newPos = CGPointMake(oldPos.x, yPos);
    self.layer.position = newPos;
    
    if (animated) {
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        positionAnimation.fromValue = [NSValue valueWithCGPoint:oldPos];
        positionAnimation.toValue = [NSValue valueWithCGPoint:newPos];
        
        //because the banner's location is relative to the height of the screen when in the bottom position, we should just immediately set it's position upon rotation events. this will prevent any ill-timed animations due to the presentation layer's position at the time of rotation
        if (self.position == GRVAlertBannerViewPositionBottom) {
            positionAnimationDuration = GRV_DEVICE_ANIMATION_DURATION;
        }
        
        positionAnimation.duration = positionAnimationDuration;
        positionAnimation.timingFunction = timingFunction == nil ? [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear] : timingFunction;
        
        if (currentAnimationKey != nil) {
            //hijack the old animation's key value
            positionAnimation.delegate = self;
            [positionAnimation setValue:currentAnimationKey forKey:@"anim"];
        }
        
        [self.layer addAnimation:positionAnimation forKey:currentAnimationKey];
    }
}

- (id)nextAvailableViewController:(id)view
{
    id nextResponder = [view nextResponder];
    if ([nextResponder isKindOfClass:[UIViewController class]]) {
        return nextResponder;
    } else if ([nextResponder isKindOfClass:[UIView class]]) {
        return [self nextAvailableViewController:nextResponder];
    } else {
        return nil;
    }
}


#pragma mark - Private
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([[anim valueForKey:@"anim"] isEqualToString:kShowAlertBannerKey] && flag) {
        [self.delegate alertBannerDidShow:self inView:self.superview];
        self.state = GRVAlertBannerViewStateVisible;
    }
    
    else if ([[anim valueForKey:@"anim"] isEqualToString:kHideAlertBannerKey] && flag) {
        [UIView animateWithDuration:self.shouldForceHide ? kForceHideAnimationDuration : self.fadeOutDuration delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.state = GRVAlertBannerViewStateHidden;
            [self.delegate alertBannerDidHide:self inView:self.superview];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [self removeFromSuperview];
        }];
    }
    
    else if ([[anim valueForKey:@"anim"] isEqualToString:kMoveAlertBannerKey] && flag) {
        self.state = GRVAlertBannerViewStateVisible;
    }
}

- (void)setInitialLayout
{
    self.layer.anchorPoint = CGPointMake(0.f, 0.f);
    
    UIView *superview = self.superview;
    self.parentFrameUponCreation = superview.bounds;
    BOOL isSuperviewKindOfWindow = ([superview isKindOfClass:[UIWindow class]]);
    
    CGFloat heightForSelf = kAvatarThumbnailHeight + kAvatarThumbnailMarginVertical *2.0f;
    
    CGRect frame = CGRectMake(0.f, 0.f, superview.bounds.size.width, heightForSelf);
    CGFloat initialYCoord = 0.f;
    switch (self.position) {
        case GRVAlertBannerViewPositionTop:
        {
            initialYCoord = -heightForSelf;
            if (isSuperviewKindOfWindow) initialYCoord += [UIApplication statusBarHeight];
            
            id nextResponder = [self nextAvailableViewController:self];
            if (nextResponder) {
                UIViewController *vc = nextResponder;
                if (!(vc.automaticallyAdjustsScrollViewInsets && [vc.view isKindOfClass:[UIScrollView class]])) {
                    initialYCoord += [vc topLayoutGuide].length;
                }
            }
        }
            break;
        case GRVAlertBannerViewPositionBottom:
            initialYCoord = superview.bounds.size.height;
            break;
        case GRVAlertBannerViewPositionUnderNavBar:
            initialYCoord = -heightForSelf + [UIApplication navigationBarHeight] + [UIApplication statusBarHeight];
            break;
    }
    frame.origin.y = initialYCoord;
    self.frame = frame;
    
    //if position is under the nav bar, add a mask
    if (self.position == GRVAlertBannerViewPositionUnderNavBar) {
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        CGRect maskRect = CGRectMake(0.f, frame.size.height, frame.size.width, superview.bounds.size.height); //give the mask enough height so it doesn't clip the shadow
        CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
        maskLayer.path = path;
        CGPathRelease(path);
        
        self.layer.mask = maskLayer;
        self.layer.mask.position = CGPointZero;
    }
}



#pragma mark - Target/Action Methods
- (void)tappedCloseButton:(UIButton *)sender
{
    if (self.state != GRVAlertBannerViewStateVisible)
        return;
    
    if (self.closeButtonTappedBlock) // && !self.isScheduledToHide ...?
        self.closeButtonTappedBlock(self);
}

- (void)tappedAlertBannerView:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.state != GRVAlertBannerViewStateVisible)
        return;
    
    if (self.tappedBlock) // && !self.isScheduledToHide ...?
        self.tappedBlock(self);
    
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    // Don't acknowledge touches on the close button
    if (touch.view == self.closeButton) {
        return NO;
    }
    return YES;
}

@end
