//
//  GRVContact+Section.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/10/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVContact.h"

/**
 * This `Section` category on the GRVContact object contains the logic necessary
 * for computing the sectionIdentifier transient attribute used for splitting
 * users into sections in the tableView.
 *
 * The sectionIdentifier classifies contacts by the first letter of their full name.
 * So if there isn't a first name it wil be the first letter of their last name
 *
 * The sorting of GRVContact objects are all done by the fetched results controller.
 * The section name transformations are UI level and have no effect on the order
 * of data.
 *
 * @ref https://developer.apple.com/library/ios/samplecode/datesectiontitles/introduction/intro.html
 * @ref http://davemeehan.com/technology/objective-c/core-data-transient-properties-on-nsmanagedobject
 */
@interface GRVContact (Section)

@end
