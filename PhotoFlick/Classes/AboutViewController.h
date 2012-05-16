//
//  AboutViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 11/14/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MMViewController.h"

@interface AboutViewController : MMViewController <UIWebViewDelegate>
{
    UIWebView *_webView;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (void)backClicked:(id)sender;

@end
