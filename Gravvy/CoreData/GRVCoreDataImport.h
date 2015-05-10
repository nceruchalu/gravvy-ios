//
//  GRVCoreDataImport.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/**
 * This class provides shared methods used when importing JSON data from
 * the HTTP web server into Core Data.
 * It provides implementations for Find-or-Create of NSManagedObjects.
 * It also provides an implementation for deletion of collections of NSManagedObjects.
 *
 * This follows apple's guidelines found here:
 * https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 *
 */
@interface GRVCoreDataImport : NSObject

#pragma mark - Create
/**
 * Find-or-Create an NSManagedObject
 *
 * @param objectDictionary
 *      JSON data with all object attributes from server
 * @param context
 *      Handle to database
 * @param objectClass
 *      SubClass of NSManagedObject to be returned.
 * @param predicate
 *      A block object to be executed when its been confirmed that this is a valid
 *      objectDictionary and a search predicate can be constructed based off of
 *      it. This block takes no arguments.
 * @param newObjectWithObjectInfo
 *      A block object to be executed when the a new instance of objectClass needs
 *      to be created given an JSON object dictionary. This block returns an
 *      NSManagedObject (an instance of objectClass ideally) and takes two
 *      argument:
 *          - the object Dictionary to create a new managed object from.
 *          - the database handle (it's not quite appropriate to assume what context
 *            this should be created on).
 * @param syncObjectWithObjectInfo
 *      A block object to be executed when the an instance of objectClass has been
 *      found in the database but needs to be synced with its corresponding
 *      JSON object dictionary. This block has no return value and takes two
 *      arguments:
 *          - the managed object to be synced and possibly updated
 *          - the object Dictionary to sync the managed object with.
 *      The database handle, if needed, can be obtained from the managed object.
 *
 * @return Initialized NSManagedObject instance
 */
+ (id)objectWithObjectInfo:(NSDictionary *)objectDictionary
    inManagedObjectContext:(NSManagedObjectContext *)context
                  forClass:(Class)objectClass
             withPredicate:(NSPredicate *(^)())predicate
         usingCreateObject:(NSManagedObject *(^)(NSDictionary *objectDictionary,
                                                 NSManagedObjectContext *context))newObjectWithObjectInfo
                syncObject:(void (^)(NSManagedObject *existingObject,
                                     NSDictionary *objectDictionary))syncObjectWithObjectInfo;


/**
 * Find-or-Create a batch of NSManagedObjects.
 * This follows apple's guidelines for implementing Find-Or-Create Efficiently.
 *
 * @param objectDicts
 *      Array of object Dictionaries, where each contains JSON data as expected
 *      from server.
 * @param context
 *      Handle to database
 * @param objectClass
 *      SubClass of NSManagedObject to be returned.
 * @param additionalPredicate
 *      A block object to be that returns a predicate to be ANDed with the basic
 *      predicate that searches for objects whose identifiers are in the array of
 *      JSON objects. This block takes no arguments.
 * @param objectIdentifierKey
 *      String representation of property of an objectClass instance that serves
 *      as its unique object identifier.
 *      This serves same purpose as `dictIdentiferKey` for each object dictionary.
 * @param dictIdentifierKey
 *     Key of JSON dictionary object with a corresponding value that serves as
 *      unique identifier of JSON object.
 *      This is serves same purpose as `objectIdentifer` on the NSManagedObject,
 *      an objectClass instance.
 * @param newObjectWithObjectInfo
 *      A block object to be executed when the a new instance of objectClass needs
 *      to be created given an JSON object dictionary. This block returns an
 *      NSManagedObject (an instance of objectClass ideally) and takes two
 *      argument:
 *          - the object Dictionary to create a new managed object from.
 *          - the database handle (it's not quite appropriate to assume what context
 *            this should be created on).
 * @param syncObjectWithObjectInfo
 *      A block object to be executed when the an instance of objectClass has been
 *      found in the database but needs to be synced with its corresponding
 *      JSON object dictionary. This block has no return value and takes two
 *      arguments:
 *          - the managed object to be synced and possibly updated
 *          - the object Dictionary to sync the managed object with.
 *      The database handle, if needed, can be obtained from the managed object.
 *
 * @return Initiailized NSManagedObject instances (of course based on passed in
 *  objectDicts) of class `objectClass`.
 *
 * @see https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/CoreData/Articles/cdImporting.html
 */
+ (NSArray *)objectsWithObjectInfoArray:(NSArray *)objectDicts
                 inManagedObjectContext:(NSManagedObjectContext *)context
                               forClass:(Class)objectClass
               usingAdditionalPredicate:(NSPredicate *(^)())additionalPredicate
                withObjectIdentifierKey:(NSString *)objectIdentifierKey
                   andDictIdentifierKey:(NSString *)dictIdentifierKey
                      usingCreateObject:(NSManagedObject *(^)(NSDictionary *objectDictionary,
                                                              NSManagedObjectContext *context))newObjectWithObjectInfo
                             syncObject:(void (^)(NSManagedObject *existingObject,
                                                  NSDictionary *objectDictionary))syncObjectWithObjectInfo;


#pragma mark - Delete
/**
 * Delete NSManagedObjects not in a provided array of JSON data objects.
 *
 * @param objectDicts
 *      Array of object Dictionaries, where each contains JSON data as expected
 *      from server.
 * @param context
 *      Handle to database
 * @param objectClass
 *      SubClass of NSManagedObject to be used in deletion.
 * @param additionalPredicate
 *      A block object to be that returns a predicate to be ANDed with the basic
 *      predicate that searches for objects whose identifiers are not in the array
 *      of provided JSON objects. This block takes no arguments.
 * @param objectIdentifierKey
 *      String representation of property of an objectClass instance that serves
 *      as its unique object identifier.
 *      This serves same purpose as `dictIdentiferKey` for each object dictionary.
 * @param dictIdentifierKey
 *     Key of JSON dictionary object with a corresponding value that serves as
 *      unique identifier of JSON object.
 *      This is serves same purpose as `objectIdentifer` on the NSManagedObject,
 *      an objectClass instance.
 */
+ (void)deleteObjectsNotInObjectInfoArray:(NSArray *)objectDicts
                   inManagedObjectContext:(NSManagedObjectContext *)context
                                 forClass:(Class)objectClass
                 usingAdditionalPredicate:(NSPredicate *(^)())additionalPredicate
                  withObjectIdentifierKey:(NSString *)objectIdentifierKey
                     andDictIdentifierKey:(NSString *)dictIdentifierKey;

@end
