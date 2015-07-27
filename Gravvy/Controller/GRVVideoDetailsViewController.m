//
//  GRVVideoDetailsViewController.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/27/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideoDetailsViewController.h"
#import "GRVVideo.h"

@interface GRVVideoDetailsViewController ()

@end

@implementation GRVVideoDetailsViewController

#pragma mark Instance Methods
#pragma mark Public
- (void)setupFetchedResultsController
{
    if (self.managedObjectContext && self.video) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"GRVVideo"];
        
        // prefetch to avoid faulting relationships individually
        request.relationshipKeyPathsForPrefetching = @[@"owner", @"clips"];
        
        // fetch specific video
        request.predicate = [NSPredicate predicateWithFormat:@"hashKey == %@", self.video.hashKey];
        
        // An instance of NSFetchedResultsController requires a fetch request
        // with sort descriptors so even though we have just one video, sort
        // by the order
        NSSortDescriptor *orderSort = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES];
        request.sortDescriptors = @[orderSort];
        request.fetchBatchSize = 20;
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"order" cacheName:nil];
        
    } else {
        self.fetchedResultsController = nil;
    }
    
    [self showOrHideEmptyStateView];
}

- (CGFloat)tableViewFooterHeight
{
    return 0.0f;
}

@end
