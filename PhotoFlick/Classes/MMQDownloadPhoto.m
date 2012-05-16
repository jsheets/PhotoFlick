//
//  MMQDownloadImage.m
//  PhotoFrame
//
//  Created by John Sheets on 12/6/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMQDownloadPhoto.h"

#import "MMQBase.h"
#import "DataManager.h"
#import "Photo.h"
#import "PhotoSource.h"
#import "ImageBytes.h"
#import "MMSlideshowView.h"

@implementation MMQDownloadPhoto

#if ALLOW_SMALL_IMAGES
//const NSInteger kDefaultMinimumImageSize = 0;
const NSInteger kDefaultMinimumImageSize = 2048;
//const NSInteger kDefaultMinimumImageSize = 8196;
#else
//const NSInteger kDefaultMinimumImageSize = 16384;
//const NSInteger kDefaultMinimumImageSize = 24576;
//const NSInteger kDefaultMinimumImageSize = 32768;
const NSInteger kDefaultMinimumImageSize = 36864;
#endif

@synthesize slideshowView = _slideshowView;
@synthesize urlPath = _urlPath;
@synthesize threadContext = _threadContext;
@synthesize responseData = _responseData;
@synthesize minimumImageSize = _minimumImageSize;
@synthesize maximumImageSize = _maximumImageSize;
@synthesize photoSource = _photoSource;
@synthesize photo = _photo;

- (id)init
{	
    if ((self = [super init]))
    {
        // Initialization.
        self.responseData = [NSMutableData dataWithLength:0];
        self.minimumImageSize = kDefaultMinimumImageSize;  //  24kb bytes
        self.maximumImageSize = 262144; // 250kb bytes
    }

    return self;
}

- (void) dealloc
{
    [_slideshowView release], _slideshowView = nil;
//    FFTCritical(@"Deallocing UrlPath: %@", _urlPath);
    [_urlPath release], _urlPath = nil;
    [_responseData release], _responseData = nil;
    [_threadContext release], _threadContext = nil;
    [_photoSource release], _photoSource = nil;
    [_photo release], _photo = nil;

    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<MMQDownloadPhoto executing=%i finished=%i cancelled=%i URL=%@",
            [self isExecuting], [self isFinished], [self isCancelled], self.urlPath.remoteUrl];
}

- (NSManagedObject *)localObjectFor:(NSManagedObject *)remoteObject
{
    NSManagedObject *localObject = nil;
    if (remoteObject)
    {
        localObject = [self.dataManager.managedObjectContext objectWithID:[remoteObject objectID]];
        [self.threadContext refreshObject:localObject mergeChanges:YES];
    }
    
    return localObject;
}

- (void)startOperation
{
    // Main Loop.

    // Look up a fresh, thread-local Photo object from its Core Data objectID.
    self.threadContext = [[self.dataManager newManagedObjectContext] autorelease];
    [self.threadContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];

#ifdef MM_TRACE
    [self.dataManager debugPhotos];
#endif

    // Set up callback to merge changes back into main thread.  After we
    // save the context below, the DNC calls contextDidSave: then the op
    // removes itself as an observer.
    //
    // NOTE: The slideshow view is also watching the same event.  We can't
    // be sure which order each gets called in, but we need to merge first
    // or the changes made here will fail to make it to the main thread
    // in time.  Hmmm....
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(contextDidSave:)
                   name:NSManagedObjectContextDidSaveNotification
                 object:self.threadContext];

    // Kick off image download.
    NSURL* url = [NSURL URLWithString:self.urlPath.remoteUrl];
    FFTInfo(@"Starting image download: %@", url);
    
    NSURLRequest *request = [[[NSURLRequest alloc] initWithURL: url] autorelease];
    [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];    
}

// Save the current Photo to the local context (not the app context).
- (BOOL)saveContext
{
    FFTDebug(@"THREAD: Saving Photo %@", self.urlPath.remoteUrl);
    BOOL succeeded = YES;
    NSError *error;
    if ([self.threadContext hasChanges] && ![self.threadContext save:&error])
    {
		// Handle the error...
        succeeded = NO;
        [self.dataManager logError:error];
    }
    
    return succeeded;
}

- (void)contextDidSave:(NSNotification*)notification
{
    FFTDebug(@"EVENT: Merging changes for Photo %@ back to main thread: %@", self.urlPath.remoteUrl, [NSThread isMainThread] ? @"main thread" : @"worker thread");
    [self.threadContext processPendingChanges];
    [self.threadContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:) withObject:notification waitUntilDone:YES];
    FFTDebug(@"Completed merge!");

    // Trigger the main-thread photo loading.
    [self.slideshowView.tray performSelectorOnMainThread:@selector(contextDidSave:) withObject:notification waitUntilDone:YES];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -
#pragma mark URL Delegates

// Catch for cancelled operation and bail out of download if so.
- (BOOL)checkCancel:(NSURLConnection *)connection
{
    if ([self isCancelled])
    {
        FFTInfo(@"Bailing out of cancelled download operation");
        [connection cancel];
        [self completeOperation];
        return YES;
    }
    return NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if ([self checkCancel:connection]) { return; }

    if ([response expectedContentLength] < self.minimumImageSize ||
        [response expectedContentLength] > self.maximumImageSize)
    {
        FFTDebug(@"Rejecting Photo, size out of bounds: (%i bytes)", [response expectedContentLength]);
//        FFTDebug(@"Rejecting Photo, size out of bounds: (%i bytes) %@ - %@", [response expectedContentLength], self.urlPath.remoteUrl, self);
        [connection cancel];

        // Not valid, too small.  Should delete entirely.
        self.urlPath = nil;
        self.responseData = nil;
        [self completeOperation];
    }
    else
    {
        // Proceed with download.
        [self.responseData setLength:0];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if ([self checkCancel:connection]) { return; }

    FFTTrace(@"LOADING %i bytes for image", [data length]);
    [self.responseData appendData:data];
    FFTTrace(@" --> Cached %i bytes so far", [self.responseData length]);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([self checkCancel:connection]) { return; }
    
    FFTError(@"CACHE: FATAL ERROR loading photo: %@", self.urlPath);
    self.urlPath = nil;
    self.responseData = nil;
    [self completeOperation];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if ([self checkCancel:connection]) { return; }

    @try
    {
        FFTInfo(@"FAULTED? %i", [self.urlPath isFault]);
        FFTInfo(@"COMPLETED loading %i-byte image at '%@'",
               [self.responseData length], self.urlPath.remoteUrl);
        
        self.photo = [self.dataManager createPhotoNamed:self.urlPath.title fromUrl:self.urlPath.remoteUrl forPhotoSource:self.photoSource];
        self.photo.imageBytes = [NSEntityDescription insertNewObjectForEntityForName:@"ImageBytes"
                                                              inManagedObjectContext:self.dataManager.managedObjectContext];
        self.photo.imageBytes.imageData = self.responseData;
        self.photo.position = [NSNumber numberWithInteger:[self.dataManager nextPhotoPosition]];
        
        self.responseData = nil;
        
        [self saveContext];
    }
    @catch (NSException * e)
    {
        FFTError(@"Attempted to load a dead UrlPath object: %@", e);
    }
    @finally
    {
        [self completeOperation];
    }
}

@end
