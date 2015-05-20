//
//  GRVAboutViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/19/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVAboutViewController.h"

@interface GRVAboutViewController ()

#pragma mark - Properties
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

@end

@implementation GRVAboutViewController

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    self.versionLabel.text = [NSString stringWithFormat:@"VERSION: %@", version];
}

@end
