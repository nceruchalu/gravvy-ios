//
//  GRVRestUtils.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/30/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVRestUtils.h"
#import "GRVConstants.h"

@implementation GRVRestUtils

+ (NSString *)videoDetailURL:(NSString *)videoHashKey
{
    return [NSString stringWithFormat:@"%@%@/",kGRVRESTVideos, videoHashKey];
}

+ (NSString *)videoDetailPlayURL:(NSString *)videoHashKey
{
    NSString *videoDetailURL = [GRVRestUtils videoDetailURL:videoHashKey];
    return [NSString stringWithFormat:@"%@%@", videoDetailURL, kGRVRESTVideoPlay];
}

+ (NSString *)videoDetailLikeURL:(NSString *)videoHashKey
{
    NSString *videoDetailURL = [GRVRestUtils videoDetailURL:videoHashKey];
    return [NSString stringWithFormat:@"%@%@", videoDetailURL, kGRVRESTVideoLike];
}

+ (NSString *)videoMemberListURL:(NSString *)videoHashKey
{
    NSString *videoDetailURL = [GRVRestUtils videoDetailURL:videoHashKey];
    return [NSString stringWithFormat:@"%@%@", videoDetailURL, kGRVRESTVideoMembers];
}

+ (NSString *)videoMemberDetailURL:(NSString *)videoHashKey member:(NSString *)phoneNumber
{
    NSString *videoMemberListURL = [GRVRestUtils videoMemberListURL:videoHashKey];
    return [NSString stringWithFormat:@"%@%@/", videoMemberListURL, phoneNumber];
}

@end
