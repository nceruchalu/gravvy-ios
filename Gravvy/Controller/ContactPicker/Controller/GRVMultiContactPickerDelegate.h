//
//  GRVMultiContactPickerDelegate.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/25/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * GRVMultiContactPickerDelegate protocol defines methods that allow you to
 * receive updates from an GRVMultiContactPickerViewController object.
 */
@protocol GRVMultiContactPickerDelegate <NSObject>

@required
/**
 * Multi contact picker is done selecting contacts
 *
 * @param selectedContacts  the selected contacts from the VC
 */
- (void)multiContactPickerDoneSelectingContacts:(NSArray *)selectedContacts;

@end
