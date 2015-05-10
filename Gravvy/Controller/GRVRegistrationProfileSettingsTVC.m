//
//  GRVRegistrationProfileSettingsTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVRegistrationProfileSettingsTVC.h"
#import "GRVModelManager.h"

#pragma mark - Constants
static NSString * const kSegueIdentifierShowVideos = @"postActivationShowVideos";

@interface GRVRegistrationProfileSettingsTVC ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;

@end

@implementation GRVRegistrationProfileSettingsTVC

#pragma mark - Properties
- (void)setDisplayName:(NSString *)displayName
{
    [super setDisplayName:displayName];
    self.doneButton.enabled = ([displayName length] > 0);
}

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.hidesBackButton = YES;
    self.doneButton.enabled = NO;
}

#pragma mark - Instance Methods
#pragma mark Overrides
- (void)doneUpdatingName
{
    [GRVModelManager sharedManager].profileConfiguredPostActivation = YES;
    [self performSegueWithIdentifier:kSegueIdentifierShowVideos sender:self];
}

#pragma mark - Target/Action Methods
- (IBAction)doneConfiguringProfile:(UIBarButtonItem *)sender
{
    [self updateUserDisplayName];
}

- (IBAction)textFieldDidChange:(UITextField *)sender
{
    self.doneButton.enabled = ([sender.text length] > 0);
}

@end
