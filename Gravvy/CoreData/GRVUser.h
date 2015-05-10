//
//  GRVUser.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GRVClip, GRVContact, GRVMember, GRVUserThumbnail, GRVVideo;

@interface GRVUser : NSManagedObject

@property (nonatomic, retain) NSString * avatarThumbnailURL;
@property (nonatomic, retain) NSString * fullName;
@property (nonatomic, retain) NSString * phoneNumber;
@property (nonatomic, retain) NSNumber * relationshipType;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) GRVUserThumbnail *avatarThumbnail;
@property (nonatomic, retain) GRVContact *contact;
@property (nonatomic, retain) NSSet *ownedVideos;
@property (nonatomic, retain) NSSet *videoMemberships;
@property (nonatomic, retain) NSSet *uploadedClips;
@end

@interface GRVUser (CoreDataGeneratedAccessors)

- (void)addOwnedVideosObject:(GRVVideo *)value;
- (void)removeOwnedVideosObject:(GRVVideo *)value;
- (void)addOwnedVideos:(NSSet *)values;
- (void)removeOwnedVideos:(NSSet *)values;

- (void)addVideoMembershipsObject:(GRVMember *)value;
- (void)removeVideoMembershipsObject:(GRVMember *)value;
- (void)addVideoMemberships:(NSSet *)values;
- (void)removeVideoMemberships:(NSSet *)values;

- (void)addUploadedClipsObject:(GRVClip *)value;
- (void)removeUploadedClipsObject:(GRVClip *)value;
- (void)addUploadedClips:(NSSet *)values;
- (void)removeUploadedClips:(NSSet *)values;

@end
