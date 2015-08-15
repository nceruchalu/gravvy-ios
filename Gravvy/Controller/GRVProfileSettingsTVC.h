//
//  GRVProfileSettingsTVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * GRVProfileSettingsTVC provides an interface for modifying display name and
 * avatar.
 */
@interface GRVProfileSettingsTVC : UITableViewController <UIActionSheetDelegate,
                                                            UITextFieldDelegate>

#pragma mark - Properties
@property (strong, nonatomic) NSString *displayName;

#pragma mark - Instance Methods
#pragma mark Abstract
/**
 * This method is called when we are have succesfully updated the user's
 * display name on the server
 */
- (void)doneUpdatingName;


#pragma mark Public
/**
 * Undo changes made to the user's display name and/or avatar
 */
- (void)undoProfileChanges;

/**
 * Update the profile's display name on the server using data in View Controller.
 * This is good to use in the done button's target/action method.
 */
- (void)updateUserDisplayName;

@end
