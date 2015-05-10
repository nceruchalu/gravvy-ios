//
//  GRVManagedDocument.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVManagedDocument.h"
#import <CoreData/CoreData.h>

@interface GRVManagedDocument ()

/**
 * Property that represents what we want the managedObjectModel property to return.
 */
@property (strong, nonatomic) NSManagedObjectModel *privateGRVManagedObjectModel;

@end

@implementation GRVManagedDocument

#pragma mark - Properties
/**
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)privateGRVManagedObjectModel
{
    // lazy instantiation
    if (!_privateGRVManagedObjectModel) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Gravvy"
                                                  withExtension:@"momd"];
        _privateGRVManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _privateGRVManagedObjectModel;
}

- (NSManagedObjectModel *)managedObjectModel
{
    return self.privateGRVManagedObjectModel;
}

@end
