//
//  GRVMember.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class GRVUser, GRVVideo;

@interface GRVMember : NSManagedObject

@property (nonatomic, retain) NSNumber * status;
@property (nonatomic, retain) NSDate * updatedAt;
@property (nonatomic, retain) GRVUser *user;
@property (nonatomic, retain) GRVVideo *video;

@end
