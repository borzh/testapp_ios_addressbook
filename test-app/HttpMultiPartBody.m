//
//  HttpMultiPartBody.m
//  test-app
//
//  Created by No One on 06.10.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import "HttpMultiPartBody.h"


@interface HttpMultiPartBody() {
    NSData *_boundary;
    NSMutableData *_body;
}
+ (NSString *)randomStringWithLength:(int)length;
@end

@implementation HttpMultiPartBody

NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

+ (NSString *)randomStringWithLength:(int)length
{
    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    for (int i=0; i<length; i++) {
        [randomString appendFormat: @"%C", [letters characterAtIndex: arc4random_uniform([letters length]) % [letters length]]];
    }
    return randomString;
}

- (id)init
{
    self = [super init];
    if (self) {
        _boundary = [[HttpMultiPartBody randomStringWithLength:16] dataUsingEncoding:NSUTF8StringEncoding];
        _body = [[NSMutableData alloc] init];
        [_body appendBytes:"--" length:2];
    }
    return self;
}

- (NSString*)boundary
{
    return [[NSString alloc] initWithData:_boundary encoding:NSASCIIStringEncoding];
}

- (void)addContent:(NSString*)name withData:(NSString*)data
{
    [_body appendBytes:"--" length:2];
    [_body appendData:_boundary];
    [_body appendData:[[NSString stringWithFormat:@"\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n", name] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendBytes:"\r\n" length:2];
}

- (void)addContent:(NSString*)name withFileName:(NSString*)fileName withFileData:(NSData*)fileData
{
    [_body appendBytes:"--" length:2];
    [_body appendData:_boundary];
    [_body appendData:[[NSString stringWithFormat:@"\r\nContent-Disposition: form-data; name=\"%@\"; fileName=\"%@\"\r\n", name, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:[@"Content-Type: text/plain\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [_body appendData:fileData];
    [_body appendBytes:"\r\n" length:2];
}

- (NSData*)data
{
    [_body appendBytes:"--" length:2];
    [_body appendData:_boundary];
    [_body appendBytes:"--" length:2];
    NSMutableData *body = _body;
    _body = nil;
    return body;
}

@end
