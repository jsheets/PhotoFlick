//
//  AboutViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 11/14/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "AboutViewController.h"


@implementation AboutViewController

@synthesize webView = _webView;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc
{
    [_webView release];

    [super dealloc];
}

- (void)backClicked:(id)sender
{
    FFTDebug(@"Clicked Back");
    [self dismissModalViewControllerAnimated:YES];
}

- (void)loadUrlWithRequest:(NSURL*)url
{
    self.webView.delegate = self;

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
    [request release];
}

- (void)loadUrlWithFallback:(NSURL*)url
{
    NSError *error;
    NSString *html = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
    if (html == nil)
    {
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *htmlFile = [bundle pathForResource:@"app-about" ofType:@"html"];
        html = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:&error];
    }
    [self.webView loadHTMLString:html baseURL:nil];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    NSURL *url = [NSURL URLWithString:@"http://photoframe.mobilemethod.net/app-about.html"];
//    [self loadUrlWithRequest: url];
    [self loadUrlWithFallback:url];
}

- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    FFTInfo(@"WEB LOAD ERROR: %@", error);
}


@end
