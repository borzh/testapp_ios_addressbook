//
//  MasterViewController.m
//  test-app
//
//  Created by No One on 29.09.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"


#pragma mark - TableViewCellDetails

@interface TableViewCellDetails : NSObject
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *phones;
@property (strong, nonatomic) NSData *image;
@property (strong, nonatomic) NSManagedObject *dbObject;
- (BOOL)matchesSearch:(NSString*)text;
@end


@implementation TableViewCellDetails
- (BOOL)matchesSearch:(NSString*)text {
    return ([self.name rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) ||
           ([self.phones rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound);
}
@end


#pragma mark - MasterViewController

@interface MasterViewController () {
    __strong NSManagedObjectContext *_managedObjectContext;
    NSMutableArray *_filteredContacts; // array of TableViewCellDetails
    NSMutableArray *_contacts; // array of TableViewCellDetails
}
- (void)showSearch:(id)sender;
- (TableViewCellDetails*)getContactForIndexPath:(NSIndexPath*)indexPath;
- (void)populateContacts;
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
- (void) updateFilteredWithSearch:(NSString*)searchText;
@end


@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(showSearch:)];
    self.navigationItem.rightBarButtonItem = searchButton;
    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
    
    CGPoint offset = self.tableView.contentOffset;
    UISearchBar *searchBar = self.searchDisplayController.searchBar;
    self.tableView.contentOffset = CGPointMake(offset.x, offset.y + searchBar.frame.size.height);
    
    _addressBookContacts = [[AddressBookContacts alloc] initWithDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (tableView == self.tableView) ? [_contacts count] : [_filteredContacts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    TableViewCellDetails *contact = [self getContactForIndexPath:indexPath];
    self.detailViewController.detailItem = contact.dbObject;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TableViewCellDetails *contact = [self getContactForIndexPath:indexPath];
        [segue.destinationViewController setDetailItem:contact.dbObject];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil)
        return _fetchedResultsController;

    if (_managedObjectContext == nil)
        return nil;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DbPerson" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:_managedObjectContext
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:@"TestAppDbCache"];
    _fetchedResultsController.delegate = self;
    
	NSError *error = nil;
    @try {
        if (![_fetchedResultsController performFetch:&error]) {
            @throw [[NSException alloc] initWithName:@"NSFetchedResultsControllerException"
                                              reason:[error localizedDescription]
                                            userInfo:[error userInfo]];
        }
    }
    @catch (NSException *exception) {
        [NSFetchedResultsController deleteCacheWithName:@"TestAppDbCache"];
        // Try again.
        if (![_fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", [error localizedDescription], [error userInfo]);
        }
    }

    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
 // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
 {
 // In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
 }
 */

# pragma mark - Private methods

- (void)showSearch:(id)sender {
    [self.searchDisplayController.searchBar becomeFirstResponder];
}

- (TableViewCellDetails*)getContactForIndexPath:(NSIndexPath*)indexPath
{
    NSInteger index = [indexPath row];
    return (self.searchDisplayController.active) ? [_filteredContacts objectAtIndex:index] : [_contacts objectAtIndex:index];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    TableViewCellDetails *contact = [self getContactForIndexPath:indexPath];
    if (contact)
    {
        cell.textLabel.text = contact.name;
        cell.detailTextLabel.text = contact.phones;
        
        NSData* image = contact.image;
        if (image == nil)
            cell.imageView.image = [UIImage imageNamed:@"DefaultContact"];
        else
            cell.imageView.image = [UIImage imageWithData:image];
    }
}

- (void)populateContacts
{
    [_filteredContacts removeAllObjects];
    [_contacts removeAllObjects];
    
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:0];
    NSArray *all = [sectionInfo objects];
    for (int i=0; i < [all count]; ++i) {
        NSManagedObject *object = [all objectAtIndex:i];
        
        NSMutableString *phonesStr = [[NSMutableString alloc] init];
        NSArray *phones = [object valueForKey:@"phones"];
        for (int i=0; i < [phones count]; ++i) {
            [phonesStr appendFormat:@"%@; ", [phones objectAtIndex:i]];
        }

        TableViewCellDetails *contact = [[TableViewCellDetails alloc] init];
        contact.dbObject = object;
        contact.name = [object valueForKey:@"name"];
        contact.image = [object valueForKey:@"image"];
        contact.phones = phonesStr;
        [_contacts addObject:contact];
    }
}

- (void) updateFilteredWithSearch:(NSString*)searchText
{
    [_filteredContacts removeAllObjects];
    for (int i=0; i < [_contacts count]; ++i) {
        TableViewCellDetails* contact = [_contacts objectAtIndex:i];
        if ([contact matchesSearch:searchText]) {
            [_filteredContacts addObject:contact];
        }
    }
}

#pragma mark - Search bar

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self updateFilteredWithSearch:searchString];
    return YES;
}

// For search view not to change cell height.
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark - AddressBookContactsDelegate

- (void)loadedWithDb:(NSManagedObjectContext *)db withAccessGranted:(BOOL)granted withDbSaved:(BOOL)saved
{
    [_activityIndicator stopAnimating];
    
    NSString *error1 = nil, *error2 = nil;
    if (!granted) {
        error1 = @"Access to address book is rejected.";
    }
    if (!saved) {
        error2 = @"Could not save database";
    }
    if (error1 || error2) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:[NSString stringWithFormat:@"%@ %@", error1, error2]
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
    _managedObjectContext = db;

    _contacts = [[NSMutableArray alloc] init];
    _filteredContacts = [[NSMutableArray alloc] init];

    [self populateContacts];
    [self.tableView reloadData];
}

@end
