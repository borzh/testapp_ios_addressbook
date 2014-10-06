//
//  DetailViewController.m
//  test-app
//
//  Created by No One on 29.09.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import "HttpMultiPartBody.h"
#import "DetailViewController.h"

@interface DetailViewController () <NSURLConnectionDelegate> {
    NSMutableData *_responseData;
}
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
- (void)configureView;
@end


@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (newDetailItem != _detailItem)
    {
        _detailItem = newDetailItem;
        if (self.masterPopoverController) {
            [self.masterPopoverController dismissPopoverAnimated:YES];
        }
        [self configureView];
    }
}

- (void)configureView
{
    NSArray *phones = [self.detailItem valueForKey:@"phones"];
    if ([phones count])
    {
        NSString *phone = phones[0]; // TODO: other posts for other phones?
        
        NSURL* url = [NSURL URLWithString:@"http://libphonenumber.appspot.com/phonenumberparser"];
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request setHTTPMethod:@"POST"];
        
        HttpMultiPartBody *multiPart = [[HttpMultiPartBody alloc] init];
        [multiPart addContent:@"phoneNumber" withData:phone];
        [multiPart addContent:@"defaultCountry" withData:nil];
        [multiPart addContent:@"languageCode" withData:nil];
        [multiPart addContent:@"regionCode" withData:nil];
        [multiPart addContent:@"numberFile" withFileName:@"empty.txt" withFileData:nil];
        
        NSData *body = [multiPart data];
        NSString *bodyLength = [NSString stringWithFormat:@"%d", [body length]];
        
        NSString *boundary = [multiPart boundary];
        
        [request setValue:bodyLength forHTTPHeaderField:@"Content-Length"];
        [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=\"%@\"", boundary] forHTTPHeaderField:@"Content-Type"];
        [request setTimeoutInterval:20.0];
        [request setHTTPBody:body];
        
        NSLog(@"%@", [request allHTTPHeaderFields]);
        NSLog(@"%s", [[request HTTPBody] bytes]);
        
        //NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        [_webView loadRequest:request];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"TestApp", @"TestApp");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}



/*
#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    NSString* test = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
}*/

@end
