//
//  GRVHTTPManager.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AFURLRequestSerialization.h"
#import "GRVConstants.h"

@class AFHTTPSessionManager;
@class AFHTTPRequestOperation;

/**
 * A singleton class that manages all HTTP interactions (including user authentication)
 * Having just one instance of this class throughout the application ensures all
 *   data stays synced.
 */
@interface GRVHTTPManager : NSObject

#pragma mark -  Properties


#pragma mark - Class Methods
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized GRVHTTPManager object.
 */
+ (instancetype)sharedManager;

/**
 * Show an alert for a given response object following a failed HTTP Request.
 * Provide alternate messaging in the event the responseObject is empty or cannot
 * be parsed
 *
 * @param responseObject    HTTP response object from failed response
 * @param title             Alternate title to be used if response object can't be used.
 * @param message           Alternate message to be used if response object can't be used.
 */
+ (void)alertWithFailedResponse:(id)responseObject withAlternateTitle:(NSString *)title andMessage:(NSString *)message;


#pragma mark HTTP Status Codes
/**
 * Return the HTTP status code from a failed HTTP response's error object.
 *
 * @param error     the description of the network or parsing error that occurred
 *
 * @return integer value of HTTP Error Code embedded in the error object. If there
 *      isnt one then
 */
+ (NSUInteger)statusCodeFromRequestFailure:(NSError *)error;

/**
 * Check if HTTP status code is a Client error (status code: 4xx)
 *
 * @param statusCode    HTTP status code to be checked
 *
 * @return BOOLean indicating if status code is a client error.
 *
 */
+ (BOOL)statusCodeIs400ClientError:(NSUInteger)statusCode;


#pragma mark - Instance Methods
#pragma mark HTTP Operations
/**
 Creates and runs an `NSURLSessionDataTask` with a <HTTP Method> request.
 This is just a wrapper to GRVHTTPSessionManager's HTTP Method requests.
 The value-add here is setting the request headers appropriately on each call
 
 @param httpMethod
 HTTP request method (GET, POST, PUT, DELETE, etc)
 @param URLString
 The relative (to REST API's base URL) URL string used to create the request
 URL.
 @param parameters
 The parameters to be encoded according to the client request serializer.
 @param success
 A block object to be executed when the task finishes successfully.
 This block has no return value and takes two arguments: the data task, and
 the response object created by the client response serializer.
 @param failure
 A block object to be executed when the task finishes unsuccessfully,
 or that finishes successfully, but encountered an error while parsing the
 response data. This block has no return value and takes three arguments: the
 data task, the error describing the network or parsing error that occurred, and
 the response object created by the client response serializer.
 
 @see -dataTaskWithRequest:completionHandler:
 */
- (NSURLSessionDataTask *)request:(GRVHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;



/**
 * Creates and runs an `NSURLSessionDataTask` with a multipart `POST`/`PUT`/`PATCH`
 * request.
 * This is just a wrapper to GRVHTTPSessionManager's HTTP Method requests.
 * The value-add here is setting the request headers appropriately on each call
 *
 * @param httpMethod
 *      HTTP request method (POST, PUT, PATCH)
 * @param URLString
 *      The URL string used to create the request URL.
 * @param parameters
 *      The parameters to be encoded according to the client request serializer.
 * @param block
 *      A block that takes a single argument and appends data to the HTTP body.
 *      The block argument is an object adopting the `AFMultipartFormData` protocol.
 * @param success
 *      A block object to be executed when the task finishes successfully. This
 *      block has no return value and takes two arguments: the data task, and the
 *      response object created by the client response serializer.
 * @param failure
 *      A block object to be executed when the task finishes unsuccessfully, or
 *      that finishes successfully, but encountered an error while parsing the
 *      response data. This block has no return value and takes three arguments:
 *      the data task, the error describing the network or parsing error that
 *      occurred, and the response object created by the client response serializer.
 *
 * @see -dataTaskWithRequest:completionHandler:
 *
 * @warning you probably want to use the `AFHTTPRequestOperation` counterpart.
 *      This has been modified to work around the issues as documented here:
 *      https://github.com/AFNetworking/AFNetworking/issues/1398
 *      I'm not a fan of having to create a temporary file as is done in this
 *      implementation...
 */
- (NSURLSessionDataTask *)request:(GRVHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
        constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure;


/**
 * Creates and runs an `AFHTTPRequestOperation` with a multipart `POST`/`PUT`/`PATCH`
 * request.
 *
 * This is just a wrapper to AFHTTPRequestOperationManager's HTTP Method requests.
 * The value-add here is setting the request headers appropriately on each call
 *   and this is more efficient than the HTTPSessionManager equivalent in that
 *   it doesn't create a temporary file.
 *
 * @param httpMethod
 *      HTTP request method (POST, PUT, PATCH)
 * @param URLString
 *      The URL string used to create the request URL.
 * @param parameters
 *      The parameters to be encoded according to the client request serializer.
 * @param block
 *      A block that takes a single argument and appends data to the HTTP body.
 *      The block argument is an object adopting the `AFMultipartFormData` protocol.
 * @param success
 *      A block object to be executed when the request operation finishes successfully.
 *      This block has no return value and takes two arguments: the request
 *      operation, and the response object created by the client response serializer.
 * @param failure
 *      A block object to be executed when the request operation finishes
 *      unsuccessfully, or that finishes successfully, but encountered an error
 *      while parsing the response data. This block has no return value and takes
 *      two arguments: the request operation and the error describing the network
 *      or parsing error that occurred.
 * @param dependency
 *      Another Request operation that must complete before this request can
 *      start This is tremendously useful when uploding multiple images.
 *      Uploading them all concurrently will cause errors and crash the app.
 *
 * @see -HTTPRequestOperationWithRequest:success:failure:
 */
- (AFHTTPRequestOperation *)operationRequest:(GRVHTTPMethod)httpMethod
                                      forURL:(NSString *)URLString
                                  parameters:(id)parameters
                   constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                         operationDependency:(AFHTTPRequestOperation *)dependency;


/**
 * Asynchronously downloads an image from the specified URL request.
 * This does have caching.
 *
 * @param URLString
 *      The absolute URL location of the image.
 * @param success
 *      A block object to be executed when the task finishes successfully. This
 *      block has no return value and takes one argument: the downloaded image
 * @param failure
 *      A block object to be executed when the task finishes unsuccessfull.
 *      This block has no return value and takes one argument: the error
 *      describing the network or parsing error that occured.
 */
- (void)imageFromURL:(NSString *)URLString
             success:(void (^)(UIImage *image))success
             failure:(void (^)(NSError *error))failure;


@end
