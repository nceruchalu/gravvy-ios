//
//  GRVManagedDocument.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 5/9/15.
//  Copyright (c) 2015 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * GRVManagedDocument is a concrete subclass of UIManagedDocument that customizes
 * the creation of the managed object model to only use the Gravvy model.
 *
 * This is important because the default UIManagedDocument model is the union of
 * all models in the main bundle. This causes a problem given that some third
 * party libraries throw in a number of Core Data models. We don't want them 
 * merged in here so the managedObjectModel property is overriden.
 */
@interface GRVManagedDocument : UIManagedDocument

@end
