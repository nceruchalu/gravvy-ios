//
//  GRVVideo.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GRVClip, GRVMember, GRVUser;

@interface GRVVideo : NSManagedObject

@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * hashKey;
@property (nonatomic, retain) NSNumber * likesCount;
@property (nonatomic, retain) NSNumber * membership;
@property (nonatomic, retain) NSString * photoThumbnailURL;
@property (nonatomic, retain) NSNumber * playsCount;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSSet *clips;
@property (nonatomic, retain) NSSet *members;
@property (nonatomic, retain) GRVUser *owner;
@end

@interface GRVVideo (CoreDataGeneratedAccessors)

- (void)addClipsObject:(GRVClip *)value;
- (void)removeClipsObject:(GRVClip *)value;
- (void)addClips:(NSSet *)values;
- (void)removeClips:(NSSet *)values;

- (void)addMembersObject:(GRVMember *)value;
- (void)removeMembersObject:(GRVMember *)value;
- (void)addMembers:(NSSet *)values;
- (void)removeMembers:(NSSet *)values;

@end
