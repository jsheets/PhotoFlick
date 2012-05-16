//
//  MMViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 5/4/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhotoFlickAppDelegate.h"
#import "DataManager.h"

@interface MMViewController : UIViewController
{
}

@property (nonatomic, retain, readonly) PhotoFlickAppDelegate* appDelegate;

- (void)logDetailedError:(NSError*)error;

@end
