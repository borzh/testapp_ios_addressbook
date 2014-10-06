//
//  HttpMultiPartBody.h
//  test-app
//
//  Created by No One on 06.10.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import <Foundation/Foundation.h>

// TODO: This class is just a fast draft.
@interface HttpMultiPartBody : NSObject

- (NSString*)boundary;
- (void)addContent:(NSString*)name withData:(NSString*)data;
- (void)addContent:(NSString*)name withFileName:(NSString*)fileName withFileData:(NSData*)fileData;

// After calling this method, no more adding content is allowed.
- (NSData*)data;

@end
