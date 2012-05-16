//
//  MMViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 5/4/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMViewController.h"


@implementation MMViewController


- (PhotoFlickAppDelegate*)appDelegate
{
    return (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (NSDictionary*)appState
{
    return nil;
}

- (BOOL)loadAppState
{
    return NO;
}

- (BOOL)saveAppState
{
    return NO;
}

- (void)logDetailedError:(NSError*)error
{
    FFTDebug(@"============================================================");
    NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
    if(detailedErrors != nil && [detailedErrors count] > 0)
    {
        for(NSError* detailedError in detailedErrors)
        {
            FFTDebug(@"  DetailedError: %@", [detailedError userInfo]);
        }
    }
    else
    {
        FFTDebug(@"  %@", [error userInfo]);
    }
    FFTDebug(@"============================================================");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Allow rotation if this is the iPad.
    return self.appDelegate.isIPad ? YES :
        (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
}


@end
