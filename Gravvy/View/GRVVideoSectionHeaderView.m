//
//  GRVVideoSectionHeaderView.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/1/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideoSectionHeaderView.h"

@interface GRVVideoSectionHeaderView ()

/**
 * View with contents of the XIB file.
 */
@property (nonatomic, strong) UIView *containerView;

/**
 * Cached constraints used to ensure the containerView fills up this view
 */
@property (nonatomic, strong) NSMutableArray *customConstraints;

@end

@implementation GRVVideoSectionHeaderView

#pragma mark - Initialization
- (void)setup
{
    // Load top level objects from the XIB file. Iterate over this array to find
    // our view. Add this view to our hierarchy and create some constraints to
    // ensure that this view fills our custom view class
    // @ref: http://sebastiancelis.com/2014/06/12/using-xibs-layout-custom-views/
    self.customConstraints = [[NSMutableArray alloc] init];
    
    UIView *view = nil;
    NSArray *objects = [[NSBundle mainBundle] loadNibNamed:@"GRVVideoSectionHeaderView"
                                                     owner:self
                                                   options:nil];
    for (id object in objects) {
        if ([object isKindOfClass:[UIView class]]) {
            view = object;
            break;
        }
    }
    
    if (view) {
        self.containerView = view;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        [self setNeedsUpdateConstraints];
    }
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

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}


- (void)updateConstraints
{
    [self removeConstraints:self.customConstraints];
    [self.customConstraints removeAllObjects];
    
    if (self.containerView) {
        UIView *view = self.containerView;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        
        [self.customConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:views]];
        [self.customConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:views]];
        
        [self addConstraints:self.customConstraints];
    }
    
    [super updateConstraints];
}

@end
