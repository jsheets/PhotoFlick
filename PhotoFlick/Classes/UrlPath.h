//
//  UrlPath.h
//  PhotoFrame
//
//  Created by John Sheets on 2/10/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@class PhotoSource;

@interface UrlPath :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * isDownloaded;
@property (nonatomic, retain) NSNumber * position;
@property (nonatomic, retain) NSString * remoteUrl;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) PhotoSource * photoSource;

@end



