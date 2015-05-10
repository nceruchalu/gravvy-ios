//
//  GRVCoreDataImport.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVCoreDataImport.h"

@implementation GRVCoreDataImport

#pragma mark - Create

+ (id)objectWithObjectInfo:(NSDictionary *)objectDictionary
    inManagedObjectContext:(NSManagedObjectContext *)context
                  forClass:(Class)objectClass
             withPredicate:(NSPredicate *(^)())predicate
         usingCreateObject:(NSManagedObject *(^)(NSDictionary *objectDictionary,
                                                 NSManagedObjectContext *context))newObjectWithObjectInfo
                syncObject:(void (^)(NSManagedObject *existingObject,
                                     NSDictionary *objectDictionary))syncObjectWithObjectInfo
{
    // If this is an empty dictionary then there's no matching NSManagedObject
    if (objectDictionary == (id)[NSNull null]) return nil;
    
    NSManagedObject *managedObject = nil;
    
    // first perform a query to determine if object needs to be retrieved or created
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = [NSEntityDescription entityForName:NSStringFromClass(objectClass)
                                      inManagedObjectContext:context];
    fetchRequest.predicate = predicate();
    // don't need sort descriptors since we expect just 1 matching object
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:fetchRequest error:&error];
    
    if (!matches) {
        // handle error
        
    } else if ([matches count] > 1) {
        // handle duplicates by taing one object and deleting the others
        managedObject = [matches firstObject];
        if (syncObjectWithObjectInfo) syncObjectWithObjectInfo(managedObject, objectDictionary);
        
        for (NSInteger i=1; i < [matches count]; i++) {
            [context deleteObject:matches[i]];
        }
        
    } else if ([matches count] == 0) {
        // couldn't find option object in database so create one.
        if (newObjectWithObjectInfo) managedObject = newObjectWithObjectInfo(objectDictionary, context);
        
    } else {
        // only 1 match in DB... so just retrieve it
        managedObject = [matches lastObject];
        if (syncObjectWithObjectInfo) syncObjectWithObjectInfo(managedObject, objectDictionary);
    }
    
    return managedObject;
}


+ (NSArray *)objectsWithObjectInfoArray:(NSArray *)objectDicts
                 inManagedObjectContext:(NSManagedObjectContext *)context
                               forClass:(Class)objectClass
               usingAdditionalPredicate:(NSPredicate *(^)())additionalPredicate
                withObjectIdentifierKey:(NSString *)objectIdentifierKey
                   andDictIdentifierKey:(NSString *)dictIdentifierKey
                      usingCreateObject:(NSManagedObject *(^)(NSDictionary *objectDictionary,
                                                              NSManagedObjectContext *context))newObjectWithObjectInfo
                             syncObject:(void (^)(NSManagedObject *existingObject,
                                                  NSDictionary *objectDictionary))syncObjectWithObjectInfo
{
    // NSManagedObjects of class objectClass (new and existing) based on objectDicts
    NSMutableArray *matchedObjects = [NSMutableArray array];
    
    // The strategy here will be to create managed objects for the entire set and
    // weed out (delete) any duplicates using a single large IN predicate.
    //
    // The goal is to optimize how I find existing data by reducing, to a minimum,
    // the number of fetches I execute.
    
    // Note the use of localizedCompare: in both sort descriptors in this
    // method. This is important as without it we get outputs like
    //      sort("nce", "nce2")         -> ["nce",     "nce2"]
    //      sort("nce@lo", "nce2@lo"]   -> ["nce2@lo", "nce@lo"]
    // AND
    //      sort("nce.l", "nce2.l")     -> ["nce.l",    "nce2.l"]
    //      sort("ncE.l", "nCE2.l"]     -> ["nCE2.l",   "ncE.l"]
    //
    // In this example, both sort pairs are mismatched.
    // This of course breaks the basic rule of the algorithm below that both arrays
    // have same sort. This is why it's important to specify localizedCompare:
    // when sorting the passed in list of JSON dictionary objects.
    
    // Before starting, let's ensure all object dictionary identifier values meet
    // the two requirements:
    //     - They are strings when corresponding managed object identifiers are
    //       strings. So this covers when the dictionary object identifier values
    //       come in as integers.
    //     - They are at the top level of the object. So if dictionary keys are
    //       really key paths (such as user.phoneNumber), copy this to a
    //       key with value equal to keypath, so future calls can just access
    //       the value using objectForKey: as opposed to valueForKeyPath:
    
    // Determine if the managed object identifier data type is string
    BOOL objectIdentifierIsString = [GRVCoreDataImport objectIdentifierIsString:objectClass withObjectIdentifierKey:objectIdentifierKey inManagedObjectContext:context];
    
    
    NSMutableArray *modifiedObjectDicts = [NSMutableArray array];
    for (NSDictionary *objectDictionary in objectDicts) {
        NSMutableDictionary *modifiedObjectDictionary = [objectDictionary mutableCopy];
        
        id objectIdentifier = [modifiedObjectDictionary valueForKeyPath:dictIdentifierKey];
        if (objectIdentifierIsString) objectIdentifier = [objectIdentifier description];
        
        [modifiedObjectDictionary setObject:objectIdentifier forKey:dictIdentifierKey];
        [modifiedObjectDicts addObject:modifiedObjectDictionary];
    }
    objectDicts = [modifiedObjectDicts copy];
    
    // First, get the object dictionaries to parse in sorted order (by unique
    // identifier, dictIdentifierKey)
    if (objectIdentifierIsString) {
        objectDicts = [objectDicts sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:dictIdentifierKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    } else {
        objectDicts = [objectDicts sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:dictIdentifierKey ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 integerValue] > [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedDescending;
            }
            if ([obj1 integerValue] < [obj2 integerValue]) {
                return (NSComparisonResult)NSOrderedAscending;
            }
            return (NSComparisonResult)NSOrderedSame;
        }]]];
    }
    
    NSMutableArray *objectDictionaries = [NSMutableArray arrayWithArray:objectDicts];
    
    // also get the sorted object dictionaries unique identifiers values
    NSMutableArray *objectIdentifiers = [[NSMutableArray alloc] init];
    for (NSDictionary *objectDictionary in objectDictionaries) {
        id objectIdentifier = [objectDictionary objectForKey:dictIdentifierKey];
        [objectIdentifiers addObject:objectIdentifier];
    }
    
    // Next, create a predicate using IN with the array of objectIdentifier strings,
    // and a sort descriptor which ensures the results are returned with the same
    // sorting as the array of objectDictionaries.
    
    // Create the fetch request to get all NSManagedObjects, of class objectClass,
    // matching the objectIdentifiers.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass(objectClass) inManagedObjectContext:context]];
    
    // Create the base predicate first
    NSPredicate *basePredicate = nil;
    if (objectIdentifierIsString) {
        basePredicate = [NSPredicate predicateWithFormat:@"%K IN[c] %@", objectIdentifierKey, objectIdentifiers];
    } else {
        basePredicate = [NSPredicate predicateWithFormat:@"%K IN %@", objectIdentifierKey, objectIdentifiers];
    }
    
    if (additionalPredicate) {
        NSPredicate *addedPredicate = additionalPredicate();
        basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[addedPredicate, basePredicate]];
    }
    [fetchRequest setPredicate:basePredicate];
    
    
    // make sure the fetch request results are sorted as well with the same sort
    // algo as the object dictionaries
    NSSortDescriptor *fetchSortDescriptor = nil;
    if (objectIdentifierIsString) {
        fetchSortDescriptor = [[NSSortDescriptor alloc] initWithKey:objectIdentifierKey ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    } else {
        fetchSortDescriptor = [[NSSortDescriptor alloc] initWithKey:objectIdentifierKey ascending:YES];
    }
    
    [fetchRequest setSortDescriptors:@[fetchSortDescriptor]];
    
    // finally, execute the fetch
    NSError *error;
    NSArray *objectsMatchingObjectIdentifiers = [context executeFetchRequest:fetchRequest error:&error];
    
    // At this point the assumption is that the matching objects are all unique.
    // The followup algorithm heavily depends on this algorithm, so enforce it.
    NSMutableArray *dedupedObjectsMatchingObjectIdentifiers = [NSMutableArray array];
    NSManagedObject *prevManagedObject = nil;
    for (NSManagedObject *currManagedObject in objectsMatchingObjectIdentifiers) {
        BOOL duplicateObject = [GRVCoreDataImport compareObject:currManagedObject isEqualTo:prevManagedObject withObjectIdentifierKey:objectIdentifierKey];
        
        if (duplicateObject) {
            // delete duplicate objects
            [currManagedObject.managedObjectContext deleteObject:currManagedObject];
            
        } else {
            // Save unique objects
            [dedupedObjectsMatchingObjectIdentifiers addObject:currManagedObject];
            // and this will be the previous object on the next run
            prevManagedObject = currManagedObject;
        }
    }
    objectsMatchingObjectIdentifiers = [dedupedObjectsMatchingObjectIdentifiers copy];
    
    [matchedObjects addObjectsFromArray:objectsMatchingObjectIdentifiers];
    
    // Now we have 2 sorted arrays - one with the Object Dictionaries whose
    // identifiers were passed into the fetch request, and one with the
    // NSManagedObjects that matched them.
    // To process them, you walk through the sorted lists following these steps:
    //   1. Get the next object dictionary and NSManagedObject. If the dictionary
    //      object's identifier doesn't match the NSManagedObject's identifier,
    //      create a new NSManagedObject for that dictionary object.
    //   2. Get the next NSManagedObject: if the NSManagedObject's identifier
    //      matches the current dictionary object's identifier, do a data sync
    //      then move to the next dictionary object and NSManagedObject.
    
    // Create a list of items to be discarded because I'd rather not do
    // book-keeping involved in deleting items while iterating
    NSMutableArray *discardedObjectDictionaries = [NSMutableArray array];
    
    // [objectsMatchingObjectIdentifiers count] <= [objectDictionaries count] so have
    // outerloop go through NSManagedObjects.
    for (NSManagedObject *managedObject in objectsMatchingObjectIdentifiers) {
        
        // then get object identifers from the dictionary objects till there is
        // a match between a dictionary object's identifer and the current
        // NSManagedObject's identifier.
        for (NSDictionary *objectDictionary in objectDictionaries) {
            // discard of this item now that we are about to analyze it
            [discardedObjectDictionaries addObject:objectDictionary];
            
            // grab object identifier from object dictionary and NSManagedObject
            id dictObjectIdentifier = [objectDictionary objectForKey:dictIdentifierKey];
            id managedObjectIdentifier = [managedObject valueForKeyPath:objectIdentifierKey];
            
            // do we create new or update current NSManagedObject?
            BOOL updateCurrentManagedObject = NO;
            
            if ([managedObjectIdentifier isKindOfClass:[NSNumber class]]) {
                updateCurrentManagedObject = [((NSNumber *)managedObjectIdentifier) integerValue] == [dictObjectIdentifier integerValue];
                
            } else if ([managedObjectIdentifier isKindOfClass:[NSString class]]) {
                updateCurrentManagedObject = [((NSString *)managedObjectIdentifier) caseInsensitiveCompare:dictObjectIdentifier] == NSOrderedSame;
            }
            
            if (updateCurrentManagedObject) {
                // The current NSManagedObject matches this object dictionary so
                // sync then proceed to getting next NSManagedObject and dictionary
                // object.
                if (syncObjectWithObjectInfo) syncObjectWithObjectInfo(managedObject, objectDictionary);
                break;
                
            } else {
                // This dictionary object doesnt already exist in our database
                // so create a new NSManagedObject based off this dictionary object.
                if (newObjectWithObjectInfo) {
                    NSManagedObject *newObject = newObjectWithObjectInfo(objectDictionary, context);
                    [matchedObjects addObject:newObject];
                }
            }
        }
        
        // now remove object dictionaries that have already been processed while
        // analyzing the current NSManagedObject.
        [objectDictionaries removeObjectsInArray:discardedObjectDictionaries];
    }
    
    // at this point we are done updating NSManagedObjects already in the database
    // but there could still be unmatched event dictionary objects so process
    // those here and simply create corresponding new NSManagedObjects
    if (newObjectWithObjectInfo) {
        for (NSDictionary *objectDictionary in objectDictionaries) {
            NSManagedObject *newObject = newObjectWithObjectInfo(objectDictionary, context);
            [matchedObjects addObject:newObject];
        }
    }
    
    // return the matched NSManagedObjects
    return matchedObjects;
}


#pragma mark - Delete

+ (void)deleteObjectsNotInObjectInfoArray:(NSArray *)objectDicts
                   inManagedObjectContext:(NSManagedObjectContext *)context
                                 forClass:(Class)objectClass
                 usingAdditionalPredicate:(NSPredicate *(^)())additionalPredicate
                  withObjectIdentifierKey:(NSString *)objectIdentifierKey
                     andDictIdentifierKey:(NSString *)dictIdentifierKey
{
    // Determine if the object identifier is a string
    BOOL objectIdentifierIsString = [GRVCoreDataImport objectIdentifierIsString:objectClass withObjectIdentifierKey:objectIdentifierKey inManagedObjectContext:context];
    
    // Get all unique identifier values from the object dictionaries.
    NSMutableArray *objectIdentifiers = [[NSMutableArray alloc] init];
    for (NSDictionary *objectDictionary in objectDicts) {
        
        id objectIdentifier = [objectDictionary valueForKeyPath:dictIdentifierKey];
        if (objectIdentifierIsString) objectIdentifier = [objectIdentifier description];
        
        [objectIdentifiers addObject:objectIdentifier];
    }
    
    // Create the fetch request to get all nsmanagedobjects of class objectClass not matching the objectIdentifiers
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass(objectClass) inManagedObjectContext:context]];
    
    // Create the base predicate first
    NSPredicate *basePredicate = nil;
    if (objectIdentifierIsString) {
        basePredicate = [NSPredicate predicateWithFormat:@"NOT (%K IN[c] %@)", objectIdentifierKey, objectIdentifiers];
    } else {
        basePredicate = [NSPredicate predicateWithFormat:@"NOT (%K IN %@)", objectIdentifierKey, objectIdentifiers];
    }
    
    if (additionalPredicate) {
        NSPredicate *addedPredicate = additionalPredicate();
        basePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[addedPredicate, basePredicate]];
    }
    [fetchRequest setPredicate:basePredicate];
    
    // finally, execute the fetch
    NSError *error;
    NSArray *objectsNotMatchingObjectIdentifiers = [context executeFetchRequest:fetchRequest error:&error];
    
    // now remove all events that should no longer exist
    for (NSManagedObject *managedObject in objectsNotMatchingObjectIdentifiers) {
        [context deleteObject:managedObject];
    }
}

#pragma mark - Private
#pragma mark Helpers
/**
 * Determine if the managed object's identifier is a string or number.
 *
 * @param objectClass
 *      SubClass of NSManagedObject to be inspected
 * @param objectIdentifierKey
 *      String representation of property of an objectClass instance that serves
 *      as its unique object identifier.
 * @param context
 *      Handle to database
 *
 * @return BOOL indicator of identifier type, YES means string and NO means number.
 *
 * @ref http://oleb.net/blog/2011/05/inspecting-core-data-attributes/
 */
+ (BOOL)objectIdentifierIsString:(Class)objectClass
         withObjectIdentifierKey:(NSString *)objectIdentifierKey
          inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *managedObjectEntity = [NSEntityDescription entityForName:NSStringFromClass(objectClass)
                                                           inManagedObjectContext:context];
    
    NSAttributeDescription *identifierAttribute;
    
    NSMutableArray *keyPaths = [[objectIdentifierKey componentsSeparatedByString:@"."] mutableCopy];
    
    // Work through keypaths and top level objects
    while ([keyPaths count] > 1) {
        NSString *key = [keyPaths firstObject];
        NSDictionary *relationships = [managedObjectEntity relationshipsByName];
        NSRelationshipDescription *relationshipDescription = [relationships objectForKey:key];
        managedObjectEntity = relationshipDescription.destinationEntity;
        
        [keyPaths removeObject:key];
    }
    
    NSDictionary *attributes = [managedObjectEntity attributesByName];
    identifierAttribute = [attributes objectForKey:[keyPaths firstObject]];
    
    return ([identifierAttribute attributeType] == NSStringAttributeType);
}


/**
 * Determine if two managed object's are equal by comparing their object
 * identifiers
 *
 * @param object1
 *      Managed Object to compare
 * @param object2
 *      Other managed object to be compared against
 * @param objectIdentifierKey
 *      String representation of property of an objectClass instance that serves
 *      as its unique object identifier.
 */
+ (BOOL)compareObject:(NSManagedObject *)object1 isEqualTo:(NSManagedObject *)object2 withObjectIdentifierKey:(NSString *)objectIdentifierKey
{
    BOOL isEqual = NO;
    
    id object1Identifier = [object1 valueForKeyPath:objectIdentifierKey];
    id object2Identifier = [object2 valueForKeyPath:objectIdentifierKey];
    
    if ([object1Identifier isKindOfClass:[NSNumber class]]) {
        isEqual = [((NSNumber *)object1Identifier) integerValue] == [((NSNumber *)object2Identifier) integerValue];
        
    } else if ([object1Identifier isKindOfClass:[NSString class]]) {
        isEqual = [((NSString *)object1Identifier) caseInsensitiveCompare:((NSString *)object2Identifier)] == NSOrderedSame;
    }
    
    return isEqual;
}

@end
