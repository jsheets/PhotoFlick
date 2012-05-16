// 
//  Image.m
//  PhotoFrame
//
//  Created by John Sheets on 8/30/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "Photo.h"
#import "ImageBytes.h"


@implementation Photo

// The position is the Photo's position in the slide show.
// It is only set when the image has successfully downloaded
// and is large enough.
@dynamic position;

@dynamic isFavorite;
@dynamic ownerName;
@dynamic title;
@dynamic timestamp;
@dynamic remoteUrl;
@dynamic photoSource;
@dynamic imageBytes;

- (UIImage*)image
{
    if (_cachedImage == nil && self.imageBytes != nil && self.imageBytes.imageData != nil)
    {
        FFTDebug(@"Loading and caching UIImage for photo %@", self.title);
        _cachedImage = [[UIImage imageWithData:self.imageBytes.imageData] retain];
    }
    return _cachedImage;
}

- (void)clearCachedImage
{
    // Must comment this out to avoid crash.  Threading issue?
//    self.imageData = nil;

    [_cachedImage release], _cachedImage = nil;
}

- (void) dealloc
{
    [self clearCachedImage];
    [super dealloc];
}

@end
