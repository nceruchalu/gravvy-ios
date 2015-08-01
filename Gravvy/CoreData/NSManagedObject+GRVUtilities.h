//
//  NSManagedObject+GRVUtilities.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/31/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 * Helpful utility methods to be used on NSManagedObjects
 */
@interface NSManagedObject (GRVUtilities)

/**
 * Has the managed object been deleted?
 *
 * @ref http://stackoverflow.com/a/7896369
 */
- (BOOL)hasBeenDeleted;

@end
