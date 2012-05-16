//
//  MMQDownloadImage.h
//  PhotoFrame
//
//  Created by John Sheets on 12/6/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMQBase.h"

@class UrlPath;
@class MMSlideshowView;
@class PhotoSource;
@class Photo;

@interface MMQDownloadPhoto : MMQBase
{
    MMSlideshowView *_slideshowView;
    UrlPath *_urlPath;
    NSManagedObjectContext *_threadContext;
    NSMutableData *_responseData;
    NSInteger _minimumImageSize;
    NSInteger _maximumImageSize;
    PhotoSource *_photoSource;
    Photo *_photo;
}

@property (nonatomic, retain) MMSlideshowView *slideshowView;
@property (nonatomic, retain) UrlPath *urlPath;
@property (nonatomic, retain) NSManagedObjectContext *threadContext;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, assign) NSInteger minimumImageSize;
@property (nonatomic, assign) NSInteger maximumImageSize;
@property (nonatomic, retain) PhotoSource *photoSource;
@property (nonatomic, retain) Photo *photo;

@end
