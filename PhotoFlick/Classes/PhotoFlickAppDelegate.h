//
//  PhotoFlickAppDelegate.h
//  PhotoFlick
//
//  Created by John Sheets on 10/5/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import <FringeTools/FFTAppDelegate.h>

#define kDisplayTimeKey @"displayTime"
#define kAutoCycle @"autoCycle"

@class FrameViewController;
@class PhotoFlickViewController;
@class DataManager;

@interface PhotoFlickAppDelegate : FFTAppDelegate <UIApplicationDelegate>
{
    UIWindow *_window;
    FrameViewController *_viewController;
    DataManager *_dataManager;
    NSDictionary *_remoteConfig;
    NSOperationQueue *_operationQueue;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet FrameViewController *viewController;
@property (nonatomic, retain) IBOutlet DataManager *dataManager;
@property (nonatomic, copy) NSDictionary *remoteConfig;
@property (nonatomic, retain) NSOperationQueue *operationQueue;

@end
