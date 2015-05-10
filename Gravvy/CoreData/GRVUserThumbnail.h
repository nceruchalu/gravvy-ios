//
//  GRVUserThumbnail.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <UIKit/UIKit.h>

@class GRVUser;

@interface GRVUserThumbnail : NSManagedObject

@property (nonatomic, retain) UIImage * image;
@property (nonatomic, retain) NSNumber * loadingInProgress;
@property (nonatomic, retain) GRVUser *user;

@end
