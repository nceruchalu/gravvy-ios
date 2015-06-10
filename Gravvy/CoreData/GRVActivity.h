//
//  GRVActivity.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 6/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GRVClip, GRVUser, GRVVideo;

@interface GRVActivity : NSManagedObject

@property (nonatomic, retain) NSNumber * identifier;
@property (nonatomic, retain) NSString * verb;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) GRVUser *actor;
@property (nonatomic, retain) GRVVideo *targetVideo;
@property (nonatomic, retain) GRVVideo *objectVideo;
@property (nonatomic, retain) GRVUser *objectUser;
@property (nonatomic, retain) GRVClip *objectClip;

@end
