//
//  GRVCountrySelectTVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GRVRegion;

/**
 * GRVCountrySelectTVC presents a list of Countries for a user to select.
 * This is handy for determining the appropriate country code for a phone number
 * during account registration.
 */
@interface GRVCountrySelectTVC : UITableViewController

/**
 * The selected region. This will be the output of the VC.
 */
@property (strong, nonatomic, readonly) GRVRegion *selectedRegion;

@end
