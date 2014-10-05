//
//  MasterViewController.h
//  test-app
//
//  Created by No One on 29.09.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

#import <CoreData/CoreData.h>
#import "AddressBookContacts.h"

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, AddressBookContactsDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property (strong, nonatomic) AddressBookContacts *addressBookContacts;
@property (strong, nonatomic) DetailViewController *detailViewController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@end
