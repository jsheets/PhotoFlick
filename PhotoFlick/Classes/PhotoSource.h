//
//  ImageSource.h
//  PhotoFrame
//
//  Created by John Sheets on 8/30/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@class MMQBase;
@class UrlPath;

@interface PhotoSource :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * builtin;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) NSString * photoTitleXpath;
@property (nonatomic, retain) NSString * photoBaseXpath;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * photoFileXpath;
@property (nonatomic, retain) NSString * nextPage;
@property (nonatomic, retain) NSSet* photos;

+ (NSArray*)findPhotoSourceByUrl:(NSURL*)url inContext:(NSManagedObjectContext*)context;
- (MMQBase*)searchOp;
@end


@interface PhotoSource (CoreDataGeneratedAccessors)
- (void)addPhotoObject:(NSManagedObject *)value;
- (void)removePhotoObject:(NSManagedObject *)value;
- (void)addPhotos:(NSSet *)value;
- (void)removePhotos:(NSSet *)value;
@end
