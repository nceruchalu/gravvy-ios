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
    self.versionLabel.text = [NSString stringWithFormat:@"VERSION: %@", [self versionAndBuild]];
}

#pragma mark - Instance Methods
#pragma mark Private
/**
 * Compose app version and build number string
 */
- (NSString *)versionAndBuild
{
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString *build = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
    return [NSString stringWithFormat:@"%@ (%@)",version, build];
}


@end
