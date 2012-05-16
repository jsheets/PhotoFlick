//
//  SearchRunner.h
//  PhotoFrame
//
//  Created by John Sheets on 3/25/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "FrameViewController.h"

@interface SearchRunner : NSObject
{
    FrameViewController *_frameViewController;
}

@property (nonatomic, retain) FrameViewController *frameViewController;

// Helpers to persisted settings.
@property (nonatomic, assign) NSString *searchUsername;
@property (nonatomic, assign) NSString *searchKeyword;
@property (nonatomic, assign) NSString *searchUrl;

- (void)searchFlickr:(NSString *)searchTerms;
- (void)searchHttp:(NSString *)httpUrl;
- (void)searchFavorites;

@end
