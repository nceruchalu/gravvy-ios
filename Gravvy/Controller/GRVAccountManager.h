//
//  GRVAccountManager.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GRVConstants.h"

@class NBPhoneNumber;

/**
 * A singleton class that manages user credentials.
 * Having just one instance of this class throughout the application ensures all
 *   data stays synced.
 */
@interface GRVAccountManager : NSObject

#pragma mark - Properties
/**
 * User's E.164 formatted phone number string.
 */
@property (copy, nonatomic, readonly) NSString *phoneNumber;

/**
 * User's password.
 */
@property (copy, nonatomic, readonly) NSString *password;

/**
 * User's region, e.g. "US" derived from user's E.164 phone number
 */
@property (copy, nonatomic, readonly) NSString *regionCode;

/**
 * User's Phone Number object, derived from user's E.164 phone number.
 */
@property (strong, nonatomic, readonly) NBPhoneNumber *phoneNumberObj;

/**
 * User's authentication token. Will be set accordingly after each authentication
 * attempt
 */
@property (copy, nonatomic, readonly) NSString *authenticationToken;

/**
 * Indicator of the current HTTP Authentication status.
 * If YES then the user is identified by a phoneNumber/password
 * If NO then the user is operating as an anonymous user
 */
@property (nonatomic, readonly, getter=isAuthenticated) BOOL authenticated;

/**
 * Indicator of if the device is registered (i.e. gone past registration and
 * verification)
 */
@property (nonatomic, getter=isRegistered) BOOL registered;

/**
 * Indicator of if already registered for push notifications
 */
@property (nonatomic) BOOL apnsRegistered;


#pragma mark - Class Methods
/**
 * Single instance manager.
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized GRVAccountManager object.
 */
+ (instancetype)sharedManager;


#pragma mark - Instance Methods
#pragma mark Account Registration/Activation/Authentication
/**
 * Attempt registering an account with provided phone number.
 *
 * @param phoneNumber   E164 formatted phone number. (Not checked).
 * @param success   block object to be executed when the task succeeds.
 * @param failure   block object to be executed when the task fails.
 */
- (void)registerAccount:(NSString *)phoneNumber
                success:(void (^)())success
                failure:(void (^)())failure;

/**
 * Attempt activating an account with provided verification code.
 * The verification code will be submitted along with the saved phone nmber and
 * password.
 *
 * @param verificationCode  code to use for account activation.
 * @param success   block object to be executed when the task succeeds.
 * @param failure   block object to be executed when the task fails.
 */
- (void)activateWithCode:(NSNumber *)verificationCode
                 success:(void (^)())success
                 failure:(void (^)())failure;

/**
 * Attempt authenticating user with saved phone number and password. Successful
 * authentication results in the authenticated flag being set as well as persisting
 * the authentication token.
 *
 * If this fails prompt the user to register an account.
 *
 * You really want to call this whenever app starts up
 *
 * @param success   block object to be executed when the task succeeds.
 * @param failure   block object to be executed when the task fails. This block
 *      has no return value and takes one argument: the status code of the HTTP
 *      request that failed.
 */
- (void)authenticateWithSuccess:(void (^)())success failure:(void (^)(NSUInteger statusCode))failure;

#pragma mark Credentials
/**
 * Delete the saved phoneNumber and password.
 */
- (void)resetCredentials;

@end
