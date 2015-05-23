//
//  GRVConstants.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

// -----------------------------------------------------------------------------
// System Version Macros
//
//
// Usage:
//  - GRV_SYSTEM_VERSION_LESS_THAN(@"4.0")
//  - GRV_SYSTEM-VERSION_LESS_THAN_OR_EQUAL_TO(@"3.1.1")
// -----------------------------------------------------------------------------
#define GRV_SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define GRV_SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define GRV_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define GRV_SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define GRV_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


// -----------------------------------------------------------------------------
// Colors
// -----------------------------------------------------------------------------
/**
 * Theme Color is RGB #00BF8F
 */
#define kGRVThemeColor [UIColor colorWithRed:0.0/255.0 green:191.0/255.0 blue:143.0/255.0 alpha:1.0]

/**
 * Avatar view background color
 */
#define kGRVUserAvatarBackgroundColor [UIColor colorWithRed:182.0/255.0 green:182.0/255.0 blue:182.0/255.0 alpha:1.0]

/**
 * Avatar view user initials text color
 */
#define kGRVUserAvatarTextColor [UIColor whiteColor]


// -----------------------------------------------------------------------------
// Fonts
// -----------------------------------------------------------------------------
/**
 * Theme Font
 */
extern NSString *const kGRVThemeFontRegular;
extern NSString *const kGRVThemeFontBold;


// -----------------------------------------------------------------------------
// Styling
// -----------------------------------------------------------------------------
/**
 * kGRVButtonCornerRadius is the default corner radius of rounded custom buttons
 */
extern const float kGRVButtonCornerRadius;


// -----------------------------------------------------------------------------
// App Configuration info.
// -----------------------------------------------------------------------------
/**
 * kGRVReachabilityRequired indicates if app needs to check for internet
 * reachability before attempting to connect to the server.
 * This might seem odd to have configurable, but in development mode it might
 * be necessary to this setting off when there's no wifi available.
 */
extern const BOOL kGRVReachabilityRequired;

/**
 * kGRVClipMaximumDuration is the maximum duration, in seconds, of a video clip
 */
extern const NSTimeInterval kGRVClipMaximumDuration;

/**
 * kGRVClipMinimumDuration is the minimum duration, in seconds, of a video clip
 */
extern const NSTimeInterval kGRVClipMinimumDuration;


// -----------------------------------------------------------------------------
// HTTP Connection info.
// -----------------------------------------------------------------------------
/**
 * kGRVHTTPBaseURL is the base URL of the server's REST API.
 */
extern NSString *const kGRVHTTPBaseURL;

/**
 * key for results when REST API returns a list
 */
extern NSString *const kGRVRESTListResultsKey;


// -----------------------------------------------------------------------------
// REST API HTTP relative paths
// -----------------------------------------------------------------------------
/**
 * kGRVRESTUsers: URL for Registering a new user.
 */
extern NSString *const kGRVRESTUsers;

/**
 * kGRVRESTAccountActivateAccount: URL to active a (re)registered account.
 */
extern NSString *const kGRVRESTAccountActivateAccount;

/**
 * kGRVRESTAccountObtainAuthToken: URL to retrieve authentication path for a given
 * phoneNumber and password.
 */
extern NSString *const kGRVRESTAccountObtainAuthToken;

/**
 * kGRVRESTUser: URL for Details of authenticated user
 */
extern NSString *const kGRVRESTUser;

/**
 * kGRVRESTPushRegister: URL for registering APNS device token with the server
 */
extern NSString *const kGRVRESTPushRegister;

/**
 * kGRVRESTFeedbacks: URL for submitting feedback
 */
extern NSString *const kGRVRESTFeedbacks;


// -----------------------------------------------------------------------------
// REST API Object Keys
// -----------------------------------------------------------------------------
// Account object
extern NSString *const kGRVRESTAccountVerificationCodeKey;
extern NSString *const kGRVRESTAccountTokenKey;

// User object
extern NSString *const kGRVRESTUserAvatarKey;
extern NSString *const kGRVRESTUserAvatarThumbnailKey;
extern NSString *const kGRVRESTUserFullNameKey;
extern NSString *const kGRVRESTUserUpdatedAtKey;
extern NSString *const kGRVRESTUserPasswordKey;
extern NSString *const kGRVRESTUserPhoneNumberKey;

// Push registration object
extern NSString *const kGRVRESTPushRegistrationIdKey;

// Feedback object
extern NSString *const kGRVRESTFeedbackBodyKey;


// -----------------------------------------------------------------------------
// User Credentials
// -----------------------------------------------------------------------------
/**
 * kGRVLoginKeychainIdentifier is the KeychainItemWrapper identifier
 */
extern NSString *const kGRVLoginKeychainIdentifier;

/**
 * A definition hidden in NBPhoneNumberUtil.m as "UNKNOWN_REGION_"
 */
extern NSString *const kGRVUnknownRegionCode;


// -----------------------------------------------------------------------------
// Application Settings
// -----------------------------------------------------------------------------
/**
 * kGRVSettingsSounds is the key for NSUserDefaults setting on whether app makes
 * sounds or not
 */
extern NSString *const kGRVSettingsSounds;


// -----------------------------------------------------------------------------
// Notifications
// -----------------------------------------------------------------------------
/**
 * kGRVMOCAvailableNotification is the NSNotification identifier for
 managedObjectContext availability
 */
extern NSString *const kGRVMOCAvailableNotification;

/**
 * kGRVMOCDeletedNotification is the NSNotification identifier for
 * managedObjectContext removal. This happens on signout.
 */
extern NSString *const kGRVMOCDeletedNotification;

/**
 * kGRVHTTPAuthenticationNotification is the NSNotification identifier for
 * successful HTTP Authentication status.
 */
extern NSString *const kGRVHTTPAuthenticationNotification;


// -----------------------------------------------------------------------------
// Custom Type Defs
// -----------------------------------------------------------------------------
/**
 * HTTP Methods: GET/POST/PUT/DELETE
 */
typedef enum : NSUInteger {
    GRVHTTPMethodGET = 0,
    GRVHTTPMethodPOST,
    GRVHTTPMethodPUT,
    GRVHTTPMethodPATCH,
    GRVHTTPMethodDELETE
} GRVHTTPMethod;


/**
 * HTTP Status Codes as defined in RFC 2616 and RFC 6585
 */
typedef enum : NSUInteger {
    // GRVHTTPStatusCodeUnknown indicates status code. Could be due to inability
    // to reach a server.
    GRVHTTPStatusCodeUnknown = 0,
    
    GRVHTTPStatusCode100Continue            = 100,
    GRVHTTPStatusCode101SwitchingProtocols  = 101,
    
    GRVHTTPStatusCode200Ok                  = 200,
    GRVHTTPStatusCode201Created             = 201,
    GRVHTTPStatusCode202Accepted            = 202,
    GRVHTTPStatusCode203NonAuthoritativeInformation = 203,
    GRVHTTPStatusCode204NoContent           = 204,
    GRVHTTPStatusCode205ResetContent        = 205,
    GRVHTTPStatusCode206PartialContent      = 206,
    
    GRVHTTPStatusCode300MultipleChoices     = 300,
    GRVHTTPStatusCode301MovedPermanently    = 301,
    GRVHTTPStatusCode302Found               = 302,
    GRVHTTPStatusCode303SeeOther            = 303,
    GRVHTTPStatusCode304NotModified         = 304,
    GRVHTTPStatusCode305UseProxy            = 305,
    GRVHTTPStatusCode306Reserved            = 306,
    GRVHTTPStatusCode307TemporaryRedirect   = 307,
    
    GRVHTTPStatusCode400BadRequest          = 400,
    GRVHTTPStatusCode401Unauthorized        = 401,
    GRVHTTPStatusCode402PaymentRequired     = 402,
    GRVHTTPStatusCode403Forbidden           = 403,
    GRVHTTPStatusCode404NotFound            = 404,
    GRVHTTPStatusCode405MethodNotAllowed    = 405,
    GRVHTTPStatusCode406NotAcceptable       = 406,
    GRVHTTPStatusCode407ProxyAuthenticationRequired = 407,
    GRVHTTPStatusCode408RequestTimeout      = 408,
    GRVHTTPStatusCode409Conflict            = 409,
    GRVHTTPStatusCode410Gone                = 410,
    GRVHTTPStatusCode411LenghRequired       = 411,
    GRVHTTPStatusCode412PreconditionFailed  = 412,
    GRVHTTPStatusCode413RequestEntityTooLarge= 413,
    GRVHTTPStatusCode414RequestURITooLong   = 414,
    GRVHTTPStatusCode415UnsupportedMediaType= 415,
    GRVHTTPStatusCode416RequestedRangeNotSatisfiable= 416,
    GRVHTTPStatusCode417ExpectationFailed   = 417,
    GRVHTTPStatusCode428PreconditionRequired= 428,
    GRVHTTPStatusCode429TooManyRequests     = 429,
    GRVHTTPStatusCode431RequestHeaderFieldsTooLarge = 431,
    
    GRVHTTPStatusCode500InternalServerError = 500,
    GRVHTTPStatusCode501NotImplemented      = 501,
    GRVHTTPStatusCode502BadGateway          = 502,
    GRVHTTPStatusCode503ServiceUnavailable  = 503,
    GRVHTTPStatusCode504GatewayTimeout      = 504,
    GRVHTTPStatusCode505HTTPVersionNotSupported     = 505,
    GRVHTTPStatusCode511NetworkAuthenticationRequired = 511
} GRVHTTPStatusCode;


/**
 * User relationship type code
 */
typedef enum : NSUInteger {
    // This user is unknown to app user (neither me nor in address book)
    GRVUserRelationshipTypeUnknown = 0,
    
    // This user is in device address book
    GRVUserRelationshipTypeContact = 100,
    
    // This user is current app user/device owner
    GRVUserRelationshipTypeMe = 200
} GRVUserRelationshipType;


/**
 * Remote notification type code
 */
typedef enum : NSUInteger {
    GRVRemoteNotificationTypeDefault = 0,
    
    GRVRemoteNotificationTypeInvitedUserToVideo = 10,
    GRVRemoteNotificationTypeAddedMember = 11,
    GRVRemoteNotificationTypeRemovedMember = 12,
    
    GRVRemoteNotificationTypeAddedClip = 20,
    GRVRemoteNotificationTypeDeletedClip = 21
} GRVRemoteNotificationType;


// EOF
