//
//  GRVClip.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GRVActivity, GRVUser, GRVVideo;

@interface GRVClip : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * mp4URL;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) GRVUser *owner;
@property (nonatomic, retain) GRVVideo *video;
@property (nonatomic, retain) NSSet *activitiesUsingAsObject;
@end

@interface GRVClip (CoreDataGeneratedAccessors)

- (void)addActivitiesUsingAsObjectObject:(GRVActivity *)value;
- (void)removeActivitiesUsingAsObjectObject:(GRVActivity *)value;
- (void)addActivitiesUsingAsObject:(NSSet *)values;
- (void)removeActivitiesUsingAsObject:(NSSet *)values;

@end
