//
//  GRVHTTPSessionManager.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVHTTPSessionManager.h"

@implementation GRVHTTPSessionManager

#pragma mark - Class methods
#pragma mark Public
/**
 * convert a GRVHTTPMethod to a standard HTTP method String
 * @param httpMethod    GRVHTTPMethod value to be converted to a HTTP method string
 *
 * @return a standard HTTP Method string: GET, POST, PUT, PATCH, DELETE.
 */
+ (NSString *)httpMethodToString:(GRVHTTPMethod)httpMethod
{
    NSString *requestMethod = nil;
    switch (httpMethod) {
        case GRVHTTPMethodGET:
            requestMethod = @"GET";
            break;
            
        case GRVHTTPMethodPOST:
            requestMethod = @"POST";
            break;
            
        case GRVHTTPMethodPUT:
            requestMethod = @"PUT";
            break;
            
        case GRVHTTPMethodPATCH:
            requestMethod = @"PATCH";
            break;
            
        case GRVHTTPMethodDELETE:
            requestMethod = @"DELETE";
            break;
            
        default:
            requestMethod = @"GET";
            break;
    }
    return requestMethod;
}

#pragma mark - Instance methods
#pragma mark Public
- (NSURLSessionDataTask *)request:(GRVHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
{
    // get the appropriate HTTP Request method String
    NSString *httpRequestMethod = [GRVHTTPSessionManager httpMethodToString:httpMethod];
    
    // now perform HTTP request
    // This block of code was common to a lot of functions in AFTTPSessionManager
    // so it made for easy re-use.
    NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:httpRequestMethod URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters error:nil];
    
    __block NSURLSessionDataTask *task = [self dataTaskWithRequest:request completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(task, error, responseObject);
            }
        } else {
            if (success) {
                success(task, responseObject);
            }
        }
    }];
    
    [task resume];
    
    return task;
}

// See Github issue for explanation of this solution
// https://github.com/AFNetworking/AFNetworking/issues/1398
// Probably easier & cleaner to just use a HTTPRequestOperation...
- (NSURLSessionDataTask *)request:(GRVHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
        constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
{
    // only POST, PUT, PATCH allowed
    if (!((httpMethod == GRVHTTPMethodPOST) ||
          (httpMethod == GRVHTTPMethodPUT) || (httpMethod == GRVHTTPMethodPATCH))) {
        return nil;
    }
    
    // get the appropriate HTTP Request method String
    NSString *httpRequestMethod = [GRVHTTPSessionManager httpMethodToString:httpMethod];
    
    NSMutableURLRequest *request = [self.requestSerializer multipartFormRequestWithMethod:httpRequestMethod URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];
    
    // Prepare a temporary file to store the multipart request prior to sending
    // it to the server due to an alleged bug in NSURLSessionTask.
    NSString* tmpFilename = [NSString stringWithFormat:@"%f", [NSDate timeIntervalSinceReferenceDate]];
    NSURL* tmpFileUrl = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:tmpFilename]];
    
    // Dump multipart request into the temporary file.
    [self.requestSerializer requestWithMultipartFormRequest:request
                                writingStreamContentsToFile:tmpFileUrl
                                          completionHandler:^(NSError *error)
     {
         // Once the multipart form is serialized into a temporary file, we can initialize
         // the actual HTTP request using the session manager.
         
         // Here note that we are submitting the initial multipart request.
         // We are, however, forcing the body stream to be read from the temporary
         // file.
         __block NSURLSessionUploadTask *task = [self  uploadTaskWithRequest:request fromFile:tmpFileUrl progress:nil completionHandler:^(NSURLResponse * __unused response, id responseObject, NSError *error) {
             // Cleanup: remove temporary file.
             [[NSFileManager defaultManager] removeItemAtURL:tmpFileUrl error:nil];
             
             // Do something with the result.
             if (error) {
                 if (failure) {
                     failure(task, error, responseObject);
                 }
             } else {
                 if (success) {
                     success(task, responseObject);
                 }
             }
         }];
         
         // Start the file upload.
         [task resume];
     }];
    
    // this function should return void
    return nil;
}

@end
