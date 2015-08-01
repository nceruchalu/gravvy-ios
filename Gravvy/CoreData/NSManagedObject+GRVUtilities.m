//
//  NSManagedObject+GRVUtilities.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/31/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "NSManagedObject+GRVUtilities.h"

@implementation NSManagedObject (GRVUtilities)

- (BOOL)hasBeenDeleted
{
    /*
     Returns YES if |managedObject| has been deleted from the Persistent Store,
     or NO if it has not.
     
     NO will be returned for NSManagedObject's who have been marked for deletion
     (e.g. their -isDeleted method returns YES), but have not yet been commited
     to the Persistent Store. YES will be returned only after a deleted
     NSManagedObject has been committed to the Persistent Store.
     
     Rarely, an exception will be thrown if Mac OS X 10.5 is used AND
     |managedObject| has zero properties defined. If all your NSManagedObject's
     in the data model have at least one property, this will not be an issue.
     
     Property == Attributes and Relationships
     
     Mac OS X 10.4 and earlier are not supported, and will throw an exception.
     */
    NSManagedObject *managedObject = self;
    NSManagedObjectContext *moc = self.managedObjectContext;
    
    // Check for Mac OS X 10.6+
    if ([moc respondsToSelector:@selector(existingObjectWithID:error:)])
    {
        NSManagedObjectID   *objectID           = [managedObject objectID];
        NSManagedObject     *managedObjectClone = [moc existingObjectWithID:objectID error:NULL];
        
        if (!managedObjectClone)
            return YES;                 // Deleted.
        else
            return NO;                  // Not deleted.
    }
    
    // Check for Mac OS X 10.5
    else if ([moc respondsToSelector:@selector(countForFetchRequest:error:)])
    {
        // 1) Per Apple, "may" be nil if |managedObject| deleted but not always.
        if (![managedObject managedObjectContext])
            return YES;                 // Deleted.
        
        
        // 2) Clone |managedObject|. All Properties will be un-faulted if
        //    deleted. -objectWithID: always returns an object. Assumed to exist
        //    in the Persistent Store. If it does not exist in the Persistent
        //    Store, firing a fault on any of its Properties will throw an
        //    exception (#3).
        NSManagedObjectID *objectID             = [managedObject objectID];
        NSManagedObject   *managedObjectClone   = [moc objectWithID:objectID];
        
        
        // 3) Fire fault for a single Property.
        NSEntityDescription *entityDescription  = [managedObjectClone entity];
        NSDictionary        *propertiesByName   = [entityDescription propertiesByName];
        NSArray             *propertyNames      = [propertiesByName allKeys];
        
        NSAssert1([propertyNames count] != 0, @"Method cannot detect if |managedObject| has been deleted because it has zero Properties defined: %@", managedObject);
        
        @try
        {
            // If the property throws an exception, |managedObject| was deleted.
            (void)[managedObjectClone valueForKey:[propertyNames objectAtIndex:0]];
            return NO;                  // Not deleted.
        }
        @catch (NSException *exception)
        {
            if ([[exception name] isEqualToString:NSObjectInaccessibleException])
                return YES;             // Deleted.
            else
                [exception raise];      // Unknown exception thrown.
        }
    }
    
    // Mac OS X 10.4 or earlier is not supported.
    else
    {
        NSAssert(0, @"Unsupported version of Mac OS X detected.");
    }
}

@end
