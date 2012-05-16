//
//  ImageBytes.h
//  PhotoFrame
//
//  Created by John Sheets on 1/9/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Photo;

@interface ImageBytes :  NSManagedObject  
{
}

@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) Photo * photo;

@end
