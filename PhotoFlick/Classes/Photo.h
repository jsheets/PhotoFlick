//
//  Image.h
//  PhotoFrame
//
//  Created by John Sheets on 8/30/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@class PhotoSource;
@class ImageBytes;

@interface Photo :  NSManagedObject  
{
    UIImage *_cachedImage;
}

@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSNumber * isFavorite;
@property (nonatomic, retain) NSString * ownerName;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * remoteUrl;
@property (nonatomic, retain) PhotoSource * photoSource;
@property (nonatomic, retain) ImageBytes * imageBytes;

- (UIImage*)image;
- (void)clearCachedImage;

@end
