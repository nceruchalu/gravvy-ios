//
//  GRVContact.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class GRVUser;

@interface GRVContact : NSManagedObject

@property (nonatomic, retain) UIImage * avatarThumbnail;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSNumber * recordId;
@property (nonatomic, retain) NSString * sectionIdentifier;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSSet *phoneNumbers;
@end

@interface GRVContact (CoreDataGeneratedAccessors)

- (void)addPhoneNumbersObject:(GRVUser *)value;
- (void)removePhoneNumbersObject:(GRVUser *)value;
- (void)addPhoneNumbers:(NSSet *)values;
- (void)removePhoneNumbers:(NSSet *)values;

@end
