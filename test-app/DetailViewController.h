//
//  DetailViewController.h
//  test-app
//
//  Created by No One on 29.09.14.
//  Copyright (c) 2014 Boris Godin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController <UISplitViewControllerDelegate>

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;
@end
