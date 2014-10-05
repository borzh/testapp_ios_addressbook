//
//  AddressBookContacts.h
//  test-app
//
//  Created by No One on 30.09.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <AddressBook/AddressBook.h>
#include <CoreData/CoreData.h>

@protocol AddressBookContactsDelegate <NSObject>
- (void)loadedWithDb:(NSManagedObjectContext*)db withAccessGranted:(BOOL)granted withDbSaved:(BOOL)saved;
@end


@interface AddressBookContacts : NSObject
- (id)initWithDelegate:(id<AddressBookContactsDelegate>)delegate;
@end
