//
//  GRVVideo+Section.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 7/1/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import "GRVVideo.h"

/**
 * This `Section` category on the GRVVideo object contains the logic necessary
 * for computing the sectionIdentifier transient attribute used for splitting
 * videos into sections in the tableView.
 *
 * The sectionIdentifier classifies videos by createdAt.
 *
 * The sorting of GRVVideo objects are all done by the fetched results controller.
 * The section name transformations are UI level and have no effect on the order
 * of data.
 *
 * @ref https://developer.apple.com/library/ios/samplecode/datesectiontitles/introduction/intro.html
 * @ref http://davemeehan.com/technology/objective-c/core-data-transient-properties-on-nsmanagedobject
 */
@interface GRVVideo (Section)

@end
