//
//  GRVAccountManager.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVAccountManager.h"
#import "GRVHTTPManager.h"
#import "GRVModelManager.h"
#import "KeychainItemWrapper.h"
#import "gRVConstants.h"
#import "NBPhoneNumberUtil+Shared.h"
#import "NBPhoneNumber.h"
#import <Crashlytics/Crashlytics.h>

@interface GRVAccountManager ()

// want all properties to be readwrite (privately)
@property (copy, nonatomic, readwrite) NSString *phoneNumber;
@property (copy, nonatomic, readwrite) NSString *password;
@property (copy, nonatomic, readwrite) NSString *authenticationToken;
@property (nonatomic, readwrite, getter=isAuthenticated) BOOL authenticated;

@property (strong, nonatomic) KeychainItemWrapper *keychain;

@end


@implementation GRVAccountManager

#pragma mark - Properties
#pragma mark Public
- (NSString *)phoneNumber
{
    return [self.keychain objectForKey:(__bridge id)(kSecAttrAccount)];
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    [self.keychain setObject:[phoneNumber copy] forKey:(__bridge id)(kSecAttrAccount)];
}

- (NSString *)regionCode
{
    NSString *regionCode = kGRVUnknownRegionCode;
    if (self.phoneNumberObj) {
        regionCode = [[NBPhoneNumberUtil sharedUtilInstance] getRegionCodeForNumber:self.phoneNumberObj];
    }
    return regionCode;
}

- (NBPhoneNumber *)phoneNumberObj
{
    NBPhoneNumberUtil *phoneUtil = [NBPhoneNumberUtil sharedUtilInstance];
    NSError *error = nil;
    NBPhoneNumber *phoneNumber = [phoneUtil parse:self.phoneNumber defaultRegion:nil error:&error];
    if (error) {
        phoneNumber = nil;
    }
    return phoneNumber;
}

- (NSString *)password
{
    return [self.keychain objectForKey:(__bridge id)kSecValueData];
}

- (void)setPassword:(NSString *)password
{
    [self.keychain setObject:[password copy] forKey:(__bridge id)(kSecValueData)];
}

- (NSString *)authenticationToken
{
    // value changes frequently so no point in lazy instantiation
    return  [self.keychain objectForKey:(__bridge id)(kSecAttrGeneric)];
}

- (void)setAuthenticationToken:(NSString *)authenticationToken
{
    [self.keychain setObject:[authenticationToken copy] forKey:(__bridge id)(kSecAttrGeneric)];
}

- (BOOL)isRegistered
{
    return ([self.authenticationToken length] > 0);
}

- (void)setRegistered:(BOOL)registered
{
    if (!registered) {
        self.authenticationToken = @"";
    }
}

#pragma mark - Class Methods
#pragma mark Public
// Declare a static variable, which is an instance of this class
// It is initialized once and only once in a thread-safe manner by using
//   Grand Central Dispatch (GCD)
+ (instancetype)sharedManager
{
    static GRVAccountManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initPrivate];
    });
    return sharedInstance;
}


#pragma mark - Initialization
// Ideally we would make the designated initializer of the superclass call
//   the new designated initializer, but that doesn't make sense in this case.
// If a programmer calls [GRVAccountManager alloc] init], let him know the error
//   of his ways.
- (instancetype)init
{
    @throw [NSException exceptionWithName:@"Singleton"
                                   reason:@"Use + [GRVAccountMananger sharedManager]"
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
        
        // setup keychain... will be accessing it a lot here.
        self.keychain = [[KeychainItemWrapper alloc] initWithIdentifier:kGRVLoginKeychainIdentifier
                                                            accessGroup:nil];
    }
    return self;
}


#pragma mark - Instance Methods
#pragma mark Public: Account Registration/Activation/Authentication
- (void)registerAccount:(NSString *)phoneNumber
                success:(void (^)())success
                failure:(void (^)())failure
{
    // Generate a random password
    NSString *password = [[NSUUID UUID] UUIDString];
    
    NSDictionary *parameters = @{kGRVRESTUserPhoneNumberKey : phoneNumber,
                                 kGRVRESTUserPasswordKey : password};
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodPOST
                  forURL:kGRVRESTUsers
              parameters:parameters
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     // Save provided credentials
                     self.phoneNumber = phoneNumber;
                     self.password = password;
                     
                     // Call callback if available
                     if (success) success();
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // Inform user of error
                     [GRVHTTPManager alertWithFailedResponse:responseObject withAlternateTitle:@"Couldn't setup account" andMessage:@"That phone number didn't seem to work."];
                     
                     // Call callback if available
                     if (failure) failure();
                 }
     ];
}


- (void)activateWithCode:(NSNumber *)verificationCode
                 success:(void (^)())success
                 failure:(void (^)())failure
{
    NSDictionary *parameters = @{kGRVRESTUserPhoneNumberKey : self.phoneNumber,
                                 kGRVRESTUserPasswordKey : self.password,
                                 kGRVRESTAccountVerificationCodeKey : verificationCode};
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodPOST
                  forURL:kGRVRESTAccountActivateAccount
              parameters:parameters
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     // Call callback if available
                     if (success) success();
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     // Inform user of error. I don't pass a response object because
                     // I rather use the more informative alternate messages
                     [GRVHTTPManager alertWithFailedResponse:nil withAlternateTitle:@"Couldn't verify account" andMessage:@"That activation code didn't seem to work."];
                     
                     // Call callback if available
                     if (failure) failure();
                 }
     ];
}


- (void)authenticateWithSuccess:(void (^)())success failure:(void (^)(NSUInteger statusCode))failure
{
    // only bother an authentication attempt if there's a saved phone number and password
    if ([self.phoneNumber length] && [self.password length]) {
        [self authenticatePhoneNumber:self.phoneNumber
                             password:self.password
                              success:^{
                                  if (success) success();
                              }
                              failure:^(NSUInteger statusCode) {
                                  // failed to authentiate with current credentials
                                  // so maybe prompt user to register
                                  if (failure) failure(statusCode);
                              }
         ];
        
    } else {
        // unable to authenticate so this would have been a bad request.
        // so maybe prompt user to register
        if (failure) failure(GRVHTTPStatusCode400BadRequest);
    }
}

#pragma mark Public: Credentials
- (void)resetCredentials
{
    [self.keychain resetKeychainItem];
}


#pragma mark Private
/**
 * Authenticate a given phone number and password.
 * Successful authentication results in the authenticated flag being set
 *   as well as authentication token being persisted.
 *
 * @param phoneNumber   phoneNumber to authenticate
 * @param password      password to authenticate phoneNUmber against
 * @param success       block object to be executed when the task succeeds.
 * @param failure       block object to be executed when the task fails.
 * @param failure       block object to be executed when the task fails. This
 *      block has no return value and takes one argument: the status code of the
 *      HTTP request that failed.
 */
- (void)authenticatePhoneNumber:(NSString *)phoneNumber
                       password:(NSString *)password
                        success:(void (^)())success
                        failure:(void (^)(NSUInteger statusCode))failure
{
    NSDictionary *parameters = @{kGRVRESTUserPhoneNumberKey : phoneNumber,
                                 kGRVRESTUserPasswordKey : password};
    
    GRVHTTPManager *httpManager = [GRVHTTPManager sharedManager];
    [httpManager request:GRVHTTPMethodPOST
                  forURL:kGRVRESTAccountObtainAuthToken
              parameters:parameters
                 success:^(NSURLSessionDataTask *task, id responseObject) {
                     self.authenticated = YES;
                     
                     // Inform listeners that HTTP authentication is completed
                     [[NSNotificationCenter defaultCenter] postNotificationName:kGRVHTTPAuthenticationNotification
                                                                         object:self
                                                                       userInfo:nil];
                     
                     // Set Crashlytics user information which is now available
                     [[Crashlytics sharedInstance] setUserName:phoneNumber];
                     
                     // extract token and save it
                     self.authenticationToken = [responseObject objectForKey:@"token"];;
                     
                     // If you haven't already done so, register for push notifications
                     if (!self.apnsRegistered) {
                         
                         UIApplication *application = [UIApplication sharedApplication];
                         if ([application respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
                             // iOS 8 Notifications
                             [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
                             
                             // will finish registration for remote notifications
                             // when the application did register  user notification
                             // settings.
                             
                         } else {
                             // iOS < 8 Notifications
                             [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge)];
                         }
                     }
                     
                     [[GRVModelManager sharedManager] setupDocumentForUser:phoneNumber completionHandler:^{
                        
                         
                         // Now that we have a context and are authenticated
                         // we can sync the top level objects, contacts and videos
                         //[GRVContact refreshContacts:nil];
                         //[GRVVideo refreshVideos:nil];
                     }];
                     
                     // finally execute callback;
                     if (success) success();
                 }
                 failure:^(NSURLSessionDataTask *task, NSError *error, id responseObject) {
                     self.authenticated = NO;
                     // execute callback
                     if (failure) {
                         NSUInteger statusCode = [GRVHTTPManager statusCodeFromRequestFailure:error];
                         failure(statusCode);
                     }
                 }
     ];
}

@end
