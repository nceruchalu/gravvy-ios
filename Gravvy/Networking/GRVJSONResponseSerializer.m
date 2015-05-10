//
//  GRVJSONResponseSerializer.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVJSONResponseSerializer.h"

NSString * const GRVJSONResponseSerializerKey = @"GRVJSONResponseSerializerKey";

@implementation GRVJSONResponseSerializer

#pragma mark - Instance methods
#pragma mark Public (overrides)
- (id)responseObjectForResponse:(NSURLResponse *)response
                           data:(NSData *)data
                          error:(NSError *__autoreleasing *)error
{
    // get super's JSON Object
    id JSONObject = [super responseObjectForResponse:response data:data error:error];
    
    // modify JSON object if there is an error
    if (*error) {
        NSMutableDictionary *userInfo = [(*error).userInfo mutableCopy];
        // insert JSON response object if it exists
        if (data == nil) {
            // don't insert response object entry
            
        } else {
            // convert data to JSON response object and save it
            id JSONResponseObject = [self JSONObjectFromResponseData:data];
            if (JSONResponseObject) {
                [userInfo setObject:JSONResponseObject forKey:GRVJSONResponseSerializerKey];
            }
        }
        
        NSError *newError = [NSError errorWithDomain:(*error).domain code:(*error).code userInfo:userInfo];
        (*error) = newError;
    }
    return JSONObject;
}


#pragma mark Private
/**
 * Generate JSON object from response data
 */
- (id)JSONObjectFromResponseData:(NSData *)data
{
    id responseObject = nil;
    NSString *responseString = [[NSString alloc] initWithData:data encoding:self.stringEncoding];
    if (responseString && ![responseString isEqualToString:@" "]) {
        // Workaround for a bug in NSJSONSerialization when Unicode character escape codes are used instead of the actual character
        // See http://stackoverflow.com/a/12843465/157142
        data = [responseString dataUsingEncoding:NSUTF8StringEncoding];
        
        if (data) {
            if ([data length] > 0) {
                NSError *error;
                responseObject = [NSJSONSerialization JSONObjectWithData:data options:self.readingOptions error:&error];
            } else {
                responseObject = nil;
            }
        }
    }
    
    return responseObject;
}

@end
