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


// -----------------------------------------------------------------------------
// Video Configuration info.
// -----------------------------------------------------------------------------
const NSTimeInterval kGRVClipMaximumDuration = 5.0f;
const NSTimeInterval kGRVClipMinimumDuration = 1.0f;
const float kGRVVideoSizeWidth = 480.0f;
const float kGRVVideoSizeHeight = 480.0f;


// -----------------------------------------------------------------------------
// Model Field Settings (Max Lengths)
// -----------------------------------------------------------------------------
const NSUInteger kGRVUserFullNameMaxLength  = 25;
const NSUInteger kGRVVideoTitleMaxLength    = 100;

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
NSString *const kGRVRESTVideos                  = @"videos/";


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

// Video object
NSString *const kGRVRESTVideoHashKeyKey             = @"hash_key";
NSString *const kGRVRESTVideoLeadClipKey            = @"lead_clip";
NSString *const kGRVRESTVideoLikesCountKey          = @"likes_count";
NSString *const kGRVRESTVideoOwnerKey               = @"owner";
NSString *const kGRVRESTVideoPhotoThumbnailKey      = @"photo_thumbnail";
NSString *const kGRVRESTVideoPlaysCountKey          = @"plays_count";
NSString *const kGRVRESTVideoTitleKey               = @"title";
NSString *const kGRVRESTVideoUpdatedAtKey           = @"updated_at";
NSString *const kGRVRESTVideoUsersKey               = @"users";

// Clip object
NSString *const kGRVRESTClipDurationKey             = @"duration";
NSString *const kGRVRESTClipIdentifierKey           = @"id";
NSString *const kGRVRESTClipMp4Key                  = @"mp4";
NSString *const kGRVRESTClipOrderKey                = @"order";
NSString *const kGRVRESTClipOwnerKey                = @"owner";
NSString *const kGRVRESTClipPhotoKey                = @"photo";
NSString *const kGRVRESTClipUpdatedAtKey            = @"updated_at";

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