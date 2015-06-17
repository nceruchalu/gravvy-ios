//
//  GRVVideosCDTVC.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/14/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideosCDTVC.h"
#import "GRVVideo+HTTP.h"

@interface GRVVideosCDTVC ()

@end

@implementation GRVVideosCDTVC


#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


#pragma mark - Instance Methods
#pragma mark Private



#pragma mark - Refresh
- (IBAction)refresh
{
    // Refresh videos from server
    [GRVVideo refreshVideos:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // run in main queue UIKit only runs there
            [self.refreshControl endRefreshing];
        });
    }];
}

@end
