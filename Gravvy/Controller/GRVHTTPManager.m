//
//  GRVHTTPManager.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVHTTPManager.h"
#import "GRVHTTPSessionManager.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFNetworkActivityIndicatorManager.h"
#import "GRVAccountManager.h"
#import "GRVConstants.h"
#import "SDWebImageManager.h"

@interface GRVHTTPManager ()

// private properties
@property (strong, nonatomic) GRVHTTPSessionManager *httpSessionManager;
@property (strong, nonatomic) AFHTTPRequestOperationManager *httpOperationManager;

// user's credentials
@property (strong, nonatomic, readonly) NSString *phoneNumber;
@property (strong, nonatomic, readonly) NSString *password;
@property (nonatomic, readonly, getter=isAuthenticated) BOOL authenticated;
@property (strong, nonatomic, readonly) NSString *authenticationToken;

@end

@implementation GRVHTTPManager

#pragma mark - Properties
#pragma mark Private
- (NSString *)phoneNumber
{
    return [GRVAccountManager sharedManager].phoneNumber;
}

- (NSString *)password
{
    return [GRVAccountManager sharedManager].password;
}

- (NSString *)authenticationToken
{
    return [GRVAccountManager sharedManager].authenticationToken;
}

- (BOOL)isAuthenticated
{
    return [GRVAccountManager sharedManager].isAuthenticated;
}


#pragma mark - Class Methods
#pragma mark Public
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static GRVHTTPManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}

+ (void)alertWithFailedResponse:(id)responseObject withAlternateTitle:(NSString *)title andMessage:(NSString *)message
{
    // alert user of any error and include any responseObject data
    if (responseObject && ([[responseObject allKeys] count] > 0)) {
        // if there are error messages in the response object get any field with
        // issues and its corresponding error(s)
        NSString *composedErrorFieldKey = @"";
        id errorFieldValue = responseObject;
        
        // Since a response object could be composed of nested dictionaries and
        // arrays, loop through till you hit leaf nodes
        while ([errorFieldValue isKindOfClass:[NSDictionary class]] ||
               [errorFieldValue isKindOfClass:[NSArray class]]) {
            
            if ([errorFieldValue isKindOfClass:[NSDictionary class]]) {
                NSString *errorFieldKey = [[errorFieldValue allKeys] firstObject];
                errorFieldValue = [errorFieldValue objectForKey:errorFieldKey];
                
                composedErrorFieldKey = [NSString stringWithFormat:@"%@ %@", composedErrorFieldKey, errorFieldKey];
                
            } else {
                errorFieldValue = [((NSArray *)errorFieldValue) firstObject];
            }
            
        }
        
        if ([errorFieldValue isKindOfClass:[NSString class]]) {
            // finally show the UIAlertView
            [GRVHTTPManager alertWithTitle:[NSString stringWithFormat:@"Problem with%@",composedErrorFieldKey]
                                   message:errorFieldValue];
        } else {
            // We are faced with an invalid response object so use alternate strings.
            [GRVHTTPManager alertWithTitle:title message:message];
        }
        
    } else {
        // We are faced with an empty response object so use alternate strings.
        [GRVHTTPManager alertWithTitle:title message:message];
    }
}

#pragma mark HTTP Errors
+ (NSUInteger)statusCodeFromRequestFailure:(NSError *)error
{
    NSUInteger statusCode = GRVHTTPStatusCodeUnknown;
    
    id errorResponseObj = [[error userInfo] objectForKey:AFNetworkingOperationFailingURLResponseErrorKey];
    if (errorResponseObj && [errorResponseObj isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *errorResponse = (NSHTTPURLResponse *)errorResponseObj;
        statusCode = [errorResponse statusCode];
    }
    
    return statusCode;
}

+ (BOOL)statusCodeIs400ClientError:(NSUInteger)statusCode
{
    return (statusCode >= GRVHTTPStatusCode400BadRequest) && (statusCode <= GRVHTTPStatusCode431RequestHeaderFieldsTooLarge);
}


#pragma mark Private
/**
 * Show an alert with given title and message.
 * The alert has only a cancel button with fixed text "OK".
 *
 * @param title     alert view title
 * @param message   alert view message
 */
+ (void)alertWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil, nil];
    [alert show];
}


#pragma mark - Initialization
// Ideally we would make the designated initializer of the superclass call
//   the new designated initializer, but that doesn't make sense in this case.
// If a programmer calls [GRVHTTPManager alloc] init], let him know the error
//   of his ways.
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [GRVHTTPMananger sharedManager]"
                                 userInfo:nil];
    return nil;
}

// Here is the real (secret) initializer.
// This is the official designated initializer so it will call the designated
//   initializer of the superclass
- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        // custom initialization here...
        
        // setup httpSessionManager
        NSURL *baseURL = [NSURL URLWithString:kGRVHTTPBaseURL];
        self.httpSessionManager = [[GRVHTTPSessionManager alloc] initWithBaseURL:baseURL];
        
        self.httpSessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.httpSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [self.httpSessionManager.requestSerializer setValue:@"application/json"
                                         forHTTPHeaderField:@"Accept"];
        [self.httpSessionManager.requestSerializer setValue:@"application/json"
                                         forHTTPHeaderField:@"Content-Type"];
        
        // setup httpOperationManager with same configs
        self.httpOperationManager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:baseURL];
        self.httpOperationManager.responseSerializer = [AFJSONResponseSerializer serializer];
        self.httpOperationManager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        [self.httpOperationManager.requestSerializer setValue:@"application/json"
                                           forHTTPHeaderField:@"Accept"];
        [self.httpOperationManager.requestSerializer setValue:@"application/json"
                                           forHTTPHeaderField:@"Content-Type"];
        
        // easy management of the network activity indicator
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    }
    return self;
}

#pragma mark - Instance methods
#pragma mark Public
- (NSURLSessionDataTask *)request:(GRVHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
{
    [self addAuthorizationHeader];
    
    // call corresponding GRVHTTPSessionManager method
    return [self.httpSessionManager request:httpMethod forURL:URLString parameters:parameters success:success failure:failure];
}


- (NSURLSessionDataTask *)request:(GRVHTTPMethod)httpMethod
                           forURL:(NSString *)URLString
                       parameters:(id)parameters
        constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                          success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                          failure:(void (^)(NSURLSessionDataTask *task, NSError *error, id responseObject))failure
{
    [self addAuthorizationHeader];
    
    // call corresponding GRVHTTPSessionManager method
    return [self.httpSessionManager request:httpMethod forURL:URLString parameters:parameters constructingBodyWithBlock:block success:success failure:failure];
}

- (AFHTTPRequestOperation *)operationRequest:(GRVHTTPMethod)httpMethod
                                      forURL:(NSString *)URLString
                                  parameters:(id)parameters
                   constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                                     success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                                     failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
                         operationDependency:(AFHTTPRequestOperation *)dependency
{
    [self addAuthorizationHeader];
    
    // only POST, PUT, PATCH allowed
    if (!((httpMethod == GRVHTTPMethodPOST) ||
          (httpMethod == GRVHTTPMethodPUT) || (httpMethod == GRVHTTPMethodPATCH))) {
        return nil;
    }
    
    // get the appropriate HTTP Request method String
    NSString *httpRequestMethod = [GRVHTTPSessionManager httpMethodToString:httpMethod];
    
    // Now run through the Operation
    NSMutableURLRequest *request = [self.httpOperationManager.requestSerializer multipartFormRequestWithMethod:httpRequestMethod URLString:[[NSURL URLWithString:URLString relativeToURL:self.httpOperationManager.baseURL] absoluteString] parameters:parameters constructingBodyWithBlock:block error:nil];
    
    AFHTTPRequestOperation *operation = [self.httpOperationManager HTTPRequestOperationWithRequest:request success:success failure:failure];
    
    if (dependency) [operation addDependency:dependency];
    [self.httpOperationManager.operationQueue addOperation:operation];
    
    return operation;
}


- (void)imageFromURL:(NSString *)URLString
             success:(void (^)(UIImage *image))success
             failure:(void (^)(NSError *error))failure
{
    SDWebImageManager *imageManager = [SDWebImageManager sharedManager];
    [imageManager downloadImageWithURL:[NSURL URLWithString:URLString]
                               options:0
                              progress:nil
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                 if (error || !image) {
                                     if (failure) failure(error);
                                 } else {
                                     if (success) success(image);
                                 }
                             }];
}

- (void)videoFromURL:(NSString *)URLString
             success:(void (^)(AFHTTPRequestOperation *operation, id video))success
             failure:(void (^)(NSError *error))failure
{
    // Would have used a shared manager object but that results in memory warnings
    // Have to use NSURLConnection to ensure caching works
    // @ref http://stackoverflow.com/a/25967174
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];

    AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
    requestSerializer.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
    manager.requestSerializer = requestSerializer;
    
    AFHTTPResponseSerializer *responseSerializer =  [AFHTTPResponseSerializer serializer];
    manager.responseSerializer = responseSerializer;
    
    [manager GET:URLString
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             if (success) success(operation, responseObject);
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             if (failure) failure(error);
         }];
}


#pragma mark - Private
/**
 * Add an authorization header to the HTTP Request if current user is authenticated
 * "Authorization" HTTP header is of the form:
 *    Authorization: Token 401f7ac837da42b97f613d789819ff93537bee6a
 *
 * Clear authorization header if the user is not authenticated.
 */
- (void)addAuthorizationHeader
{
    if (self.isAuthenticated) {
        NSString *authorizationHeader = [NSString stringWithFormat:@"Token %@", self.authenticationToken];
        [self.httpSessionManager.requestSerializer setValue:authorizationHeader
                                         forHTTPHeaderField:@"Authorization"];
        [self.httpOperationManager.requestSerializer setValue:authorizationHeader
                                           forHTTPHeaderField:@"Authorization"];
    } else {
        [self clearAuthorizationHeader];
    }
}

/**
 * Remove authorization header used for HTTP Requests.
 *
 * It's a good idea to call this when clearing credentials, i.e. resetting keychain.
 */
- (void)clearAuthorizationHeader
{
    [self.httpSessionManager.requestSerializer clearAuthorizationHeader];
    [self.httpOperationManager.requestSerializer clearAuthorizationHeader];
}

@end
