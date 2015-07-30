//
//  GRVUser.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/29/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GRVActivity, GRVClip, GRVContact, GRVMember, GRVUserThumbnail, GRVVideo;

@interface GRVUser : NSManagedObject

@property (nonatomic, retain) NSString * avatarThumbnailURL;
@property (nonatomic, retain) NSNumber * favorited;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSNumber * relationshipType;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) NSSet *activitiesUsingAsActor;
@property (nonatomic, retain) NSSet *activitiesUsingAsObject;
@property (nonatomic, retain) GRVUserThumbnail *avatarThumbnail;
@property (nonatomic, retain) GRVContact *contact;
@property (nonatomic, retain) NSSet *ownedVideos;
@property (nonatomic, retain) NSSet *uploadedClips;
@property (nonatomic, retain) NSSet *videoMemberships;
@property (nonatomic, retain) NSSet *likedVideos;
@end

@interface GRVUser (CoreDataGeneratedAccessors)

- (void)addActivitiesUsingAsActorObject:(GRVActivity *)value;
- (void)removeActivitiesUsingAsActorObject:(GRVActivity *)value;
- (void)addActivitiesUsingAsActor:(NSSet *)values;
- (void)removeActivitiesUsingAsActor:(NSSet *)values;

- (void)addActivitiesUsingAsObjectObject:(GRVActivity *)value;
- (void)removeActivitiesUsingAsObjectObject:(GRVActivity *)value;
- (void)addActivitiesUsingAsObject:(NSSet *)values;
- (void)removeActivitiesUsingAsObject:(NSSet *)values;

- (void)addOwnedVideosObject:(GRVVideo *)value;
- (void)removeOwnedVideosObject:(GRVVideo *)value;
- (void)addOwnedVideos:(NSSet *)values;
- (void)removeOwnedVideos:(NSSet *)values;

- (void)addUploadedClipsObject:(GRVClip *)value;
- (void)removeUploadedClipsObject:(GRVClip *)value;
- (void)addUploadedClips:(NSSet *)values;
- (void)removeUploadedClips:(NSSet *)values;

- (void)addVideoMembershipsObject:(GRVMember *)value;
- (void)removeVideoMembershipsObject:(GRVMember *)value;
- (void)addVideoMemberships:(NSSet *)values;
- (void)removeVideoMemberships:(NSSet *)values;

- (void)addLikedVideosObject:(GRVVideo *)value;
- (void)removeLikedVideosObject:(GRVVideo *)value;
- (void)addLikedVideos:(NSSet *)values;
- (void)removeLikedVideos:(NSSet *)values;

@end
