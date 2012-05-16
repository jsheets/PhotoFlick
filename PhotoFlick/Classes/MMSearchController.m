    //
//  MMSearchController.m
//  PhotoFlick
//
//  Created by John Sheets on 10/9/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "MMSearchController.h"
#import "FrameViewController.h"
#import "MMTray.h"

@implementation MMSearchController

@synthesize frameViewController = _frameViewController;
@synthesize searchRunner = _searchRunner;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
    if ((self = [super initWithNibName:nibName bundle:nibBundle]))
    {
        // Initialization.
        _searchRunner = [[SearchRunner alloc] init];
    }
    
    return self;
}

- (void)dealloc
{
    [_frameViewController release], _frameViewController = nil;
    [_searchRunner release], _searchRunner = nil;
    
    [super dealloc];
}

- (PhotoSource *)flickrPhotoSource
{
    return [self.appDelegate.dataManager loadPhotoSourceByPath:@"http://flickr.com"];
}

- (PhotoSource *)ffffoundPhotoSource
{
    return [self.appDelegate.dataManager loadPhotoSourceByPath:@"http://ffffound.com"];
}

- (PhotoSource *)photoSourceForPath:(NSString *)urlPath
{
    return [self.appDelegate.dataManager loadPhotoSourceByPath:urlPath];
}

// Simple sanity check: host with a period character in URL.
- (BOOL)isValidURL:(NSString*)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    return ([url host] != nil) && ([[url host] rangeOfString:@"."].location != NSNotFound);
}

- (void)runSearchForPhotoSource:(PhotoSource *)photoSource
{
    // Clear cached nextPage marker and all previous photo results.
    photoSource.nextPage = nil;
    [self.appDelegate.dataManager deleteAllUrlPaths];
    [self.appDelegate.dataManager deleteAllPhotos:YES];
    
    self.frameViewController.photoSource = photoSource;
    [self.frameViewController loadView];
    [self.frameViewController.slideshowView.tray resetTray];
    [self.frameViewController runSearch];
}

- (void)runFlickrSearchWithKeyword:(NSString *)keyword username:(NSString *)username
{
    // Save text fields in settings.
    self.searchRunner.searchUsername = username;
    self.searchRunner.searchKeyword = keyword;
    
    // FIXME: Use Core Data PhotoSource objects.
    PhotoSource *photoSource = [self.appDelegate.dataManager
                                loadPhotoSourceByPath:@"http://flickr.com"];
    FFTInfo(@"Found Flickr PhotoSource: %@", photoSource);
    EVENT_SEARCH_FLICKR;
    
    [self runSearchForPhotoSource:photoSource];
}

@end
