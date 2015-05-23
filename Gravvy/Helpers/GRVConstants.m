//
//  GRVConstants.m
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVConstants.h"

// -----------------------------------------------------------------------------
// Fonts
// -----------------------------------------------------------------------------
NSString *const kGRVThemeFontRegular    = @"HelveticaNeue-Light";
NSString *const kGRVThemeFontBold       = @"HelveticaNeue-Bold";

// -----------------------------------------------------------------------------
// Styling
// -----------------------------------------------------------------------------
const float kGRVButtonCornerRadius      = 5.0f;

// -----------------------------------------------------------------------------
// App Configuration info.
// -----------------------------------------------------------------------------
#if DEBUG
const BOOL kGRVReachabilityRequired     = NO;
#else
const BOOL kGRVReachabilityRequired     = YES;
#endif

const NSTimeInterval kGRVClipMaximumDuration = 5.0f;
const NSTimeInterval kGRVClipMinimumDuration = 1.0f;

// -----------------------------------------------------------------------------
// HTTP Connection info.
// -----------------------------------------------------------------------------
#if DEBUG
    // An IP address won't work on the simulator.
    #if TARGET_IPHONE_SIMULATOR
    NSString *const kGRVHTTPBaseURL     = @"http://localhost:8000/api/v1/";
    #else
    NSString *const kGRVHTTPBaseURL     = @"http://10.0.0.4:8000/api/v1/";
    #endif

#else
NSString *const kGRVHTTPBaseURL         = @"http://gravvy.nnoduka.com/api/v1/";
#endif

NSString *const kGRVRESTListResultsKey  = @"results";


// -----------------------------------------------------------------------------
// REST API HTTP relative paths (observe no leading slash)
// -----------------------------------------------------------------------------
NSString *const kGRVRESTUsers                   = @"users/";
NSString *const kGRVRESTAccountActivateAccount  = @"account/activate/";
NSString *const kGRVRESTAccountObtainAuthToken  = @"account/auth/";
NSString *const kGRVRESTUser                    = @"user/";
NSString *const kGRVRESTPushRegister            = @"push/apns/";
NSString *const kGRVRESTFeedbacks               = @"feedbacks/";


// -----------------------------------------------------------------------------
// REST API Object Keys
// -----------------------------------------------------------------------------
// Account object
NSString *const kGRVRESTAccountVerificationCodeKey  = @"verification_code";
NSString *const kGRVRESTAccountTokenKey             = @"token";

// User object
NSString *const kGRVRESTUserAvatarKey               = @"avatar";
NSString *const kGRVRESTUserAvatarThumbnailKey      = @"avatar_thumbnail";
NSString *const kGRVRESTUserFullNameKey             = @"full_name";
NSString *const kGRVRESTUserUpdatedAtKey            = @"updated_at";
NSString *const kGRVRESTUserPasswordKey             = @"password";
NSString *const kGRVRESTUserPhoneNumberKey          = @"phone_number";

// Push registration object
NSString *const kGRVRESTPushRegistrationIdKey       = @"registration_id";

// Feedback object
NSString *const kGRVRESTFeedbackBodyKey             = @"body";


// -----------------------------------------------------------------------------
// User Credentials
// -----------------------------------------------------------------------------
NSString *const kGRVLoginKeychainIdentifier     = @"GravvyLoginData";
NSString *const kGRVUnknownRegionCode           = @"ZZ";


// -----------------------------------------------------------------------------
// Application Settings
// -----------------------------------------------------------------------------
NSString *const kGRVSettingsSounds          = @"kGRVSettingsSounds";


// -----------------------------------------------------------------------------
// Notifications
// -----------------------------------------------------------------------------
NSString *const kGRVMOCAvailableNotification        = @"kGRVMOCAvailableNotification";
NSString *const kGRVMOCDeletedNotification          = @"kGRVMOCDeletedNotification";
NSString *const kGRVHTTPAuthenticationNotification  = @"kGRVHTTPAuthenticationNotification";


// EOF