//
//  ExtendedTableViewController.h
//  Gravvy
//
//  Created by Nnoduka Eruchalu on 10/27/14.
//  Copyright (c) 2014 Nnoduka Eruchalu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 * ExtendedTableViewController is a UIViewController that manages a table view
 * when the view to be managed is composed of multiple subviews, only one of
 * which is a table view.
 *
 * This means that unlike the UITableViewController the tableView @property
 * isn't the same as the view @property. So subviews can be added to the view.
 *
 * This class replicates the tableView management as seen in UITableViewController
 *
 * @ref https://developer.apple.com/library/ios/documentation/UserExperience/Conceptual/TableView_iPhone/TableViewAndDataModel/TableViewAndDataModel.html#//apple_ref/doc/uid/TP40007451-CH5-SW1
 */
@interface ExtendedTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
