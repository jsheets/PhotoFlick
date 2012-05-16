//
//  MMSearchController.h
//  PhotoFlick
//
//  Created by John Sheets on 10/9/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "MMViewController.h"

#import "FrameViewController.h"
#import "SearchRunner.h"

@interface MMSearchController : MMViewController
{
    FrameViewController *_frameViewController;
    SearchRunner *_searchRunner;
}

@property (nonatomic, retain) FrameViewController *frameViewController;
@property (nonatomic, retain) SearchRunner *searchRunner;

- (PhotoSource *)flickrPhotoSource;
- (PhotoSource *)ffffoundPhotoSource;
- (PhotoSource *)photoSourceForPath:(NSString *)urlPath;

- (BOOL)isValidURL:(NSString*)urlString;
- (void)runFlickrSearchWithKeyword:(NSString *)keyword username:(NSString *)username;
- (void)runSearchForPhotoSource:(PhotoSource *)photoSource;

@end
