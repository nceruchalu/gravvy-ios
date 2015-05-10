//
//  NBPhoneNumberUtil+Shared.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "NBPhoneNumberUtil+Shared.h"

@implementation NBPhoneNumberUtil (Shared)

+ (instancetype)sharedUtilInstance
{
    static NBPhoneNumberUtil *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

@end
