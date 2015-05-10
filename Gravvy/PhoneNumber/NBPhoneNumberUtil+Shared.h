//
//  NBPhoneNumberUtil+Shared.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "NBPhoneNumberUtil.h"

/**
 * The Shared category on NBPhoneNumberUtil is for creating a shared instance
 * of NBPhoneNumberUtil. So we don't have to allocate and initialize it multiple
 * times
 */
@interface NBPhoneNumberUtil (Shared)

/**
 * Single NBPhoneNumberUtil instance
 * It creates the instance if this hasn't been done or simply returns it.
 *
 * @return An initialized NBPhoneNumberUtil object.
 */
+ (instancetype)sharedUtilInstance;

@end
