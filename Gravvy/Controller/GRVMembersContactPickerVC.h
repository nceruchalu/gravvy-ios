//
//  GRVMembersContactPickerVC.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/7/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContactPickerViewController.h"

@class GRVVideo;

/**
 * GRVMembersContactPickerVC is a contact picker fori nviting at least 1
 * contact to an already video event.
 *
 * Upon unwinding, this VC will invite the selected contacts to the video.
 */
@interface GRVMembersContactPickerVC : GRVContactPickerViewController

/**
 * The View Controller's model.
 */
@property (strong, nonatomic) GRVVideo *video;

@end
