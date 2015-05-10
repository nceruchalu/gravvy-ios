//
//  GRVJSONResponseSerializer.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "AFURLResponseSerialization.h"

extern NSString *const GRVJSONResponseSerializerKey;

/**
 * `GRVJSONResponseSerializer` is a subclass of `AFJSONResponseSerializer` that
 * validates and decodes JSON responses.
 * It's added functionality is embedding the error body (response object) in the
 * NSError passed in failure object of AFHTTPSessionManager request methods.
 *
 * You use this class by setting an instance of AFHTTPSessionManager, httpSessionManager:
 *      httpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
 *
 * The response object can be found in the failure block's NSError:
 *      [error.userInfo objectForKey:GRVJSONResponseSerializerKey]
 *
 * This class can be used as an alternative to using GRVHTTPSessionManager which
 *      creates wrapper functions that provide the response Object even on failed
 *      responses.
 * @see GRVHTTPSessionManager
 *
 * @ref http://blog.gregfiumara.com/archives/239
 */
@interface GRVJSONResponseSerializer : AFJSONResponseSerializer

@end
