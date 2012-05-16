//
//  SearchRunner.m
//  PhotoFrame
//
//  Created by John Sheets on 3/25/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "SearchRunner.h"
#import "PhotoSource.h"
#import "PhotoFlickAppDelegate.h"
#import "MMTray.h"
#import "SettingsViewController.h"

#define kSearchKeyword @"searchKeyword"
#define kSearchUsername @"searchUsername"
#define kSearchUrl @"searchUrl"

@implementation SearchRunner

@synthesize frameViewController = _frameViewController;

- (void)dealloc
{
    [_frameViewController release], _frameViewController = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Settings helpers


- (void)setSearchUsername:(NSString *)username
{
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:kSearchUsername];
}

- (NSString *)searchUsername
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSearchUsername];
}


- (void)setSearchKeyword:(NSString *)keyword
{
    [[NSUserDefaults standardUserDefaults] setObject:keyword forKey:kSearchKeyword];
}

- (NSString *)searchKeyword
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSearchKeyword];
}


- (void)setSearchUrl:(NSString *)customUrl
{
    [[NSUserDefaults standardUserDefaults] setObject:customUrl forKey:kSearchUrl];
}

- (NSString *)searchUrl
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kSearchUrl];
}


#pragma mark -
#pragma mark Searches


- (void)startSearchForPhotoSource:(NSString *)photoSourcePath
{
    PhotoFlickAppDelegate *appDelegate = (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
    PhotoSource *photoSource = [appDelegate.dataManager loadPhotoSourceByPath:photoSourcePath];
    FFTInfo(@"Found PhotoSource: %@\n%@", photoSource.title, photoSource);

    // Clear cached nextPage marker and all previous photo results.
    [appDelegate.dataManager deleteAllUrlPaths];
    [appDelegate.dataManager deleteAllPhotos:YES];
    
    photoSource.nextPage = nil;
    self.frameViewController.photoSource = photoSource;
//    [self.frameViewController loadView];
    self.frameViewController.serviceLabel.text = photoSource.title;
    [self.frameViewController.slideshowView.tray resetTray];
    FFTInfo(@"SERVICE TEXT: %@", self.frameViewController.serviceLabel.text);
    
    [self.frameViewController runSearch];
}

- (void)searchFlickr:(NSString *)searchTerms
{
    // Save text fields in settings.
    self.searchKeyword = searchTerms;
    
    [self startSearchForPhotoSource:@"http://flickr.com"];
}

// Simple sanity check: host with a period character in URL.
- (BOOL)isValidURL:(NSString*)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    return ([url host] != nil) && ([[url host] rangeOfString:@"."].location != NSNotFound);
}

- (void)searchHttp:(NSString *)httpUrl
{
    // Check for blank custom field.
    if (![httpUrl hasPrefix:@"http://"])
    {
        httpUrl = [@"http://" stringByAppendingString:httpUrl];
    }
    if (![self isValidURL:httpUrl])
    {
        FFTError(@"Clicked PLAY but not valid URL: %@", httpUrl);
        return;
    }
    
    // Save text fields in settings.
    self.searchUrl = httpUrl;
    
    [self startSearchForPhotoSource:httpUrl];
}

- (void)searchFavorites
{
    [self startSearchForPhotoSource:@"Favorites"];
}

@end
