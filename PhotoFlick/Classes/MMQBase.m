//
//  MMQBase.m
//  PhotoFrame
//
//  Created by John Sheets on 12/7/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMQBase.h"
#import "PhotoFlickAppDelegate.h"
#import "DataManager.h"

@implementation MMQBase

- (DataManager*)dataManager
{
    return ((PhotoFlickAppDelegate*)[[UIApplication sharedApplication]
                                     delegate]).dataManager;
}

- (NSOperationQueue*)queue
{
    return ((PhotoFlickAppDelegate*)[[UIApplication sharedApplication]
                                     delegate]).operationQueue;
}

@end
