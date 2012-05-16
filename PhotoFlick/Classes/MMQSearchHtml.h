//
//  MMQSearchHtml.h
//  PhotoFrame
//
//  Created by John Sheets on 12/6/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMQBase.h"

#import <libxml/HTMLParser.h>
#import <libxml/xpath.h>

@class PhotoSource;
@class UrlPath;

@interface MMQSearchHtml : MMQBase
{
    PhotoSource *_photoSource;
    NSString *_currentPage;
    NSString *_nextPage;

    NSURL *_pageUrl;
    
    // The URL currently downloading; refers to responseData.
    NSString *_currentLoadingUrl;
    
    // Image data for a single download at a time.
    NSMutableData *_responseData;
}

@property (nonatomic, retain) PhotoSource *photoSource;
@property (nonatomic, retain) NSString *currentPage;
@property (nonatomic, retain) NSString *nextPage;
@property (nonatomic, retain) NSURL *pageUrl;
@property (nonatomic, retain) NSString *currentLoadingUrl;
@property (nonatomic, retain) NSMutableData *responseData;

- (id)initWithPhotoSource:(PhotoSource*)photoSource;
- (NSURL*)xmlFindNextPage:(htmlDocPtr)doc;
- (NSMutableArray*)xmlLoadPhotoUrls:(NSURL*)page;

@end
