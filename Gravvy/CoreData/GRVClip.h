//
//  GRVClip.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GRVUser, GRVVideo;

@interface GRVClip : NSManagedObject

@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSString * mp4URL;
@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) GRVUser *owner;
@property (nonatomic, retain) GRVVideo *video;

@end
