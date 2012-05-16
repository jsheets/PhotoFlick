//
//  PhotoFlickAppDelegate.m
//  PhotoFlick
//
//  Created by John Sheets on 10/5/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "PhotoFlickAppDelegate.h"
#import "PhotoFlickViewController.h"
#import "FrameViewController.h"
#import "DataManager.h"

#include <libkern/OSAtomic.h>
#include <execinfo.h>

// Forward declarations
void SignalHandler(int signal);
void uncaughtExceptionHandler(NSException *exception);


#ifdef USE_DEBUG_REMOTE_CONFIG
#define REMOTE_CONFIG_URL @"http://mobilemethod.net/photoframe/RemoteConfig-debug.plist"
#warning Using Debug RemoteConfig file
#else
#define REMOTE_CONFIG_URL @"http://mobilemethod.net/photoframe/RemoteConfig.plist"
#warning Using Production RemoteConfig file
#endif


@implementation PhotoFlickAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize dataManager = _dataManager;
@synthesize remoteConfig = _remoteConfig;
@synthesize operationQueue = _operationQueue;


#pragma mark -
#pragma mark Lifecycle


- (void)dealloc
{
    [_remoteConfig release], _remoteConfig = nil;
    [_operationQueue release], _operationQueue = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Configuration


- (NSDictionary*)remoteConfig
{
    if (_remoteConfig == nil)
    {
#ifdef USE_REMOTE_CONFIG
        FFTCritical(@"Starting download of %@", REMOTE_CONFIG_URL);
        NSDictionary *props = [[NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:REMOTE_CONFIG_URL]] retain];
        _remoteConfig = props ? props : [NSDictionary init];
        FFTInfo(@"REMOTE CONFIG: %@", self.remoteConfig);
#else
        FFTCritical(@"Skipping Remote Config");
        _remoteConfig = [[NSDictionary alloc] init];
#endif
    }
    return _remoteConfig;
}

// Set up default values for user settings.
- (void)registerDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObject:
                                 [NSNumber numberWithFloat:7.0] forKey: kDisplayTimeKey];
    
    [defaults registerDefaults:appDefaults];
}


#pragma mark -
#pragma mark UI


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
    
    START_ANALYTICS;
    
    [self registerDefaults];
    
    application.statusBarHidden = YES;
    
    FFTInfo(@"Starting %@ (%@ screen) PhotoFlick application",
            self.isIPad ? @"iPad" : @"iPhone",
            self.isRetinaDisplay ? @"Retina" : @"non-Retina");
    FFTDebug(@"Device frame size: %@", NSStringFromCGSize(self.devicePixelSize));
    
    // Override point for customization after app launch. 
    [self.window addSubview:self.viewController.view];
    [self.window makeKeyAndVisible];
    
    if (!self.isIPad)
    {
        FFTInfo(@"iPhone Startup: Jump to search screen");
        [self.viewController searchClicked:nil];
    }

	return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
    END_ANALYTICS;
}


#pragma mark -
#pragma mark Memory management


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


#pragma mark -
#pragma mark Crash handling


+ (NSArray *)backtrace
{
    void* callstack[128];
    int frame_count = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frame_count);
    
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frame_count];
    for (int i = 0; i < frame_count; i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}


void SignalHandler(int signal)
{
	NSMutableDictionary *userInfo =
    [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal]
                                       forKey:@"signum"];
    
	NSArray *callStack = [PhotoFlickAppDelegate backtrace];
	[userInfo setObject:callStack forKey:@"stackdump"];
    
    NSException *exception = [NSException exceptionWithName:@"SignalError"
                                                     reason:@"Received fatal uncaught SIGNAL"
                                                   userInfo:userInfo];
    NSString *msg = [NSString stringWithFormat:@"Fatal SIGNAL (%i) crash: %@",
                     signal, userInfo];
    FFTCritical(@"%@", msg);
    REPORT_ERROR_TO_ANALYTICS(@"Fatal SIGNAL Exception", msg, exception);
}


// Catch fatal exceptions and forward to analytics (only works in Flurry Analytics).
void uncaughtExceptionHandler(NSException *exception)
{
    //REPORT_ERROR_TO_ANALYTICS(@"Fatal Exception", @"Application Crash!", exception);
}

- (NSOperationQueue*)operationQueue
{
    if (_operationQueue == nil)
    {
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return _operationQueue;
}

@end
