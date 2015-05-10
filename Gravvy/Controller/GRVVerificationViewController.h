//
//  GRVVerificationViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVScrollViewContainer.h"

/**
 * GRVVerificationViewController is the class for account verification. After
 * successful account registration, a verification code is sent to the user.
 * This class reads in that SMS code and sends to the server for validation.
 */
@interface GRVVerificationViewController : GRVScrollViewContainer

@end
