//
//  AddressBookContacts.m
//  test-app
//
//  Created by No One on 30.09.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import "AddressBookContacts.h"

@interface AddressBookContacts ()
{
    ABAddressBookRef _addressBook;
}
@property (weak, nonatomic) id<AddressBookContactsDelegate> delegate;

@property (strong, nonatomic) NSManagedObjectModel* managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end


@implementation AddressBookContacts

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize delegate = _delegate;

#pragma mark - Address Book handling

- (id)initWithDelegate:(id<AddressBookContactsDelegate>)delegate
{
    self = [self init];
    if (self) {
        _delegate = delegate;
        _addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        [self checkAddressBookAccess];
    }
    return self;
}

- (void)checkAddressBookAccess
{
    typeof(self) __weak weakSelf = self;
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    if (status == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRequestAccessWithCompletion(_addressBook, ^(bool granted, CFErrorRef error) {
            [weakSelf addressBookSaveWithAccess:granted];
        }); // Will call addressBookSaveWithAccess on other thread.
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [weakSelf addressBookSaveWithAccess:(status == kABAuthorizationStatusAuthorized)];
        });
    }
}

// This method is called on background thread.
- (void)addressBookSaveWithAccess:(BOOL)granted
{
    NSAssert(![NSThread isMainThread], @"addressBookSaveWithAccess() called on main thread");
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DbPerson" inManagedObjectContext:self.managedObjectContext];
    
    NSArray *thePeople = (__bridge_transfer NSArray*)ABAddressBookCopyArrayOfAllPeople(_addressBook);
    for (int i = 0; i < [thePeople count]; i++) {
        ABRecordRef contact = (__bridge ABRecordRef)[thePeople objectAtIndex:i];
        
        CFDataRef contactImage = NULL;
        if (ABPersonHasImageData(contact))
            contactImage = ABPersonCopyImageData(contact);
        ABMultiValueRef phonesRef = ABRecordCopyValue(contact, kABPersonPhoneProperty);
        
        NSString* name = (__bridge NSString*)ABRecordCopyCompositeName(contact);
        NSData* image = (__bridge NSData*)contactImage;
        image = [self imageWithData:image scaledToSize:CGSizeMake(64, 64)];
        NSMutableArray* phones = [[NSMutableArray alloc] init];
        
        NSMutableString *phonesStr = [[NSMutableString alloc] init];
        for (int i=0; i < ABMultiValueGetCount(phonesRef); ++i)
        {
            NSString *phoneLabel = (__bridge NSString*)ABMultiValueCopyLabelAtIndex(phonesRef, i);
            NSString *phone = (__bridge NSString*)ABMultiValueCopyValueAtIndex(phonesRef, i);
            [phonesStr appendFormat:@"%@ %@,", phoneLabel, phone];
            [phones addObject:phone];
        }
        
        NSLog(@"%@ %@", name, phonesStr);
        CFRelease(phonesRef);
        
        // Add record to DB.
        NSManagedObject *record = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:_managedObjectContext];
        [record setValue:name forKey:@"name"];
        [record setValue:image forKey:@"image"];
        [record setValue:phones forKey:@"phones"];
    }
    CFRelease(_addressBook); // Will use persistent store from now on.
    
    // Save records.
    NSError *error = nil;
    BOOL saved = [self.managedObjectContext save:&error];
    if (!saved) {
        NSLog(@"Unable to save records.");
        if (error) {
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
    }
    
    // Notify delegate on main thread.
    typeof(self) __weak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate loadedWithDb:self.managedObjectContext withAccessGranted:YES withDbSaved:saved];
    });
}

#pragma mark - Core Data stack

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"test_app" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *url = [self persistentStoreURL];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
        NSLog(@"Persistent store error %@, %@", error, [error userInfo]);
        [self removePersistentStore];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]) {
            abort(); // should never happend.
        }
    }
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    [self removePersistentStore];
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

#pragma mark - Persistent store handling

// Returns the URL to persistent store.
- (NSURL *)persistentStoreURL
{
    NSURL *docsUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    return [docsUrl URLByAppendingPathComponent:@"test_app.sqlite"];
}

// Removes all objects in persistent store.
- (void)removePersistentStore
{
    [[NSFileManager defaultManager] removeItemAtPath:[self persistentStoreURL].path error:nil];
}

# pragma mark - Image handling

- (NSData *)imageWithData:(NSData *)data scaledToSize:(CGSize)newSize
{
    UIImage *image = [UIImage imageWithData:data];
    NSData *newData = nil;
    if (image) {
        UIImage *newImage = nil;
        UIGraphicsBeginImageContext(newSize);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        newData = UIImagePNGRepresentation(newImage);
    }
    return newData;
}

@end
