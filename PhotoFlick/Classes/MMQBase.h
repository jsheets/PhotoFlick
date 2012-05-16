//
//  MMQBase.h
//  PhotoFrame
//
//  Created by John Sheets on 12/7/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <FringeTools/FFTThreadedOperation.h>

@class DataManager;

@interface MMQBase : FFTThreadedOperation
{
}

@property (nonatomic, retain, readonly) DataManager *dataManager;
@property (nonatomic, retain, readonly) NSOperationQueue *queue;

@end
