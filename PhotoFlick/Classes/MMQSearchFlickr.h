//
//  MMQSearchFlickr.h
//  PhotoFrame
//
//  Created by John Sheets on 12/6/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "ObjectiveFlickr.h"

#import "MMQBase.h"

@class PhotoSource;

@interface MMQSearchFlickr : MMQBase <OFFlickrAPIRequestDelegate>
{
    OFFlickrAPIContext *_context;
    OFFlickrAPIRequest *_request;
    PhotoSource *_photoSource;
    NSString *_username;
    NSString *_keyword;
    NSString *_searchText;
    NSArray *_searchWords;
}

@property (nonatomic, retain) OFFlickrAPIContext *context;
@property (nonatomic, retain) OFFlickrAPIRequest *request;
@property (nonatomic, retain) PhotoSource *photoSource;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *keyword;
@property (nonatomic, retain) NSString *searchText;
@property (nonatomic, retain) NSArray *searchWords;

- (id)initWithPhotoSource:(PhotoSource*)photoSource
                 username:(NSString*)username
                 keyword:(NSString*)keyword;

@end
