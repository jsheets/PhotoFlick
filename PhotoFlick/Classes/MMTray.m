//
//  MMTray.m
//  PhotoFrame
//
//  Created by John Sheets on 12/27/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMTray.h"

#import "DataManager.h"
#import "MMSlideView.h"
#import "MMSlideshowView.h"
#import "Photo.h"
#import "ImageBytes.h"
#import "MMQDownloadPhoto.h"
#import "PhotoFlickAppDelegate.h"
#import "MMTrayLogic.h"

@implementation MMTray

@synthesize logic = _logic;
@synthesize trayViews = _trayViews;
@synthesize slideshowView = _slideshowView;
@synthesize loadedFirstImage = _loadedFirstImage;
@synthesize photoSource = _photoSource;

- (id)initWithSlideshow:(MMSlideshowView*)slideshow
{	
    if ((self = [super init]))
    {
        // Initialization.
        self.logic = [[MMTrayLogic alloc] init];
        self.slideshowView = slideshow;
        self.trayViews = [NSMutableArray array];  // Visible images only (the tray)
        self.loadedFirstImage = NO;

        // Preload and lay out blank slides.
        for (NSInteger i = 0; i < self.logic.trayWidth; i++)
        {
            // Create an image view as a placeholder for the downloading image.
            CGRect slideFrame = [self.logic rectForSlide:i];
            
            // Inject slide into scroll view.
            MMSlideView *slideView = [[MMSlideView alloc] initWithFrame:slideFrame];
            [self.slideshowView addSubview:slideView];
            [self.trayViews addObject:slideView];
            [slideView release];
        }
    }
    
    return self;
}

- (void)dealloc
{
    [_logic release], _logic = nil;
    [_trayViews release], _trayViews = nil;
    [_slideshowView release], _slideshowView = nil;
    [_photoSource release], _photoSource = nil;

    [super dealloc];
}

- (void)resetTray
{
    FFTCritical(@"Resetting tray");
    self.logic.trayPosition = 0;
    self.loadedFirstImage = NO;
    [self.slideshowView setContentOffset:CGPointMake(0, 0)];
    [self clearImageData:NO];
}

- (void)clearImageData:(BOOL)keepAdjacentImages
{
    // Force clearing transient imageData property.
    // Discard all Photo objects.
    for (NSInteger i = 0; i < [self.trayViews count]; i++)
    {
        // Skip if keepAdjacentImages and we're within one of the current.
        if (!keepAdjacentImages || ![self.logic isAdjacent:i])
        {
            MMSlideView *slideView = [self.trayViews objectAtIndex:i];
            FFTDebug(@"Clearing image data for tray index %i", i);
            [slideView setPhoto:nil];
        }
    }
}

// Empty out tray; called when each slideshow is cancelled.
- (void)clearTray
{
    for (MMSlideView *view in self.trayViews)
    {
        [view removeFromSuperview];
    }
    
    [self clearImageData:NO];
    [self.trayViews removeAllObjects];
    [self resetTray];
}

- (void)uncacheImages
{
    // Force clearing transient imageData property.
    // Discard all Photo objects.
    for (NSInteger i = 0; i < [self.trayViews count]; i++)
    {
        // Skip if keepAdjacentImages and we're within one of the current.
        if (![self.logic isAdjacent:i])
        {
            MMSlideView *slideView = [self.trayViews objectAtIndex:i];
            FFTDebug(@"Uncaching image data for tray index %i", i);
            [slideView unloadDisplayImage];
            
            // Re-fault (uncache) related ImageBytes object.
            [self.dataManager.managedObjectContext refreshObject:slideView.photo
                                                    mergeChanges:YES];
        }
    }
}

- (void)releaseMemory
{
    // Cycle through tray and drop all non-adjacent images.
    [self uncacheImages];
    [self debugTray];
}

- (void)debugTray
{
#ifdef MM_DEBUG
    FFTDebug(@"TRAY PHOTO TITLES:");
    FFTDebug(@"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    NSInteger currentTrayIndex = [self.logic atTrayIndex:self.slideshowView];
    FFTDebug(@"CURRENT POSITION: photo=%i tray=%i",
               self.logic.trayPosition + currentTrayIndex, currentTrayIndex);
    
    Photo *currentPhoto = [self.slideshowView currentPhoto];
    for (MMSlideView *slideView in self.trayViews)
    {
        FFTDebug(@"[%@] Photo (pos=%@) %@ at %@: %@ UIImage",
                [slideView.photo isEqual:currentPhoto] ? @"*" : @" ",
                slideView.photo.position, slideView.photo.title,
                NSStringFromCGRect(slideView.frame),
                slideView.imageView.image == nil ? @"does not have" : @"has");
    }
    FFTDebug(@"===================================================");
#endif
}

- (DataManager*)dataManager
{
    return ((PhotoFlickAppDelegate*)[[UIApplication sharedApplication]
                                     delegate]).dataManager;
}

// Assign the Photo to the next empty slot, if any.
- (void)appendPhotoToSlideshow:(Photo *)photo
{
    FFTInfo(@"Appending Photo to slideshow: %@", photo.remoteUrl);
    NSInteger slideIndex = self.logic.trayPosition;
    for (MMSlideView *view in self.trayViews)
    {
        FFTTrace(@"Checking slide for pre-existing photo: %@", view.photo.remoteUrl);
        if (view.photo == nil)
        {
            FFTInfo(@"Adding photo %@ to blank slide %i", photo.remoteUrl, slideIndex);
            view.photo = photo;
            [self updateScrollArea];
#ifdef MM_TRACE
            [self debugTray];
#endif
            break;
        }
        slideIndex++;
    }
}

- (Photo *)localPhoto:(Photo *)threadPhoto
{
    NSManagedObjectID *photoId = [threadPhoto objectID];
    Photo *localPhoto = (Photo*)[self.dataManager.managedObjectContext objectWithID:photoId];
    [self.dataManager.managedObjectContext refreshObject:localPhoto mergeChanges:YES];

    return localPhoto;
}

- (NSString *)titleForCurrentSlide
{
    NSInteger labelIndex = [self.logic atPhotoIndex:self.slideshowView] + 1;
    Photo *currentPhoto = [self.slideshowView currentPhoto];
    return [NSString stringWithFormat:@"%i) %@", labelIndex, currentPhoto.title];
}

// Grab a fresh UrlPath and start downloading the image into a new Photo object.
// Return YES to continue more downloads, or NO to stop all further downloads.
- (BOOL)startNextDownload
{
    if (!self.logic.activeSearch)
    {
        FFTCritical(@"No more Photo URLs available for this search.");
        return NO;
    }

    DataManager *dataManager = self.dataManager;
    UrlPath *urlPath = [dataManager popNextUrlPath];
    FFTInfo(@"***** STARTING NEW DOWNLOAD: %@ *****", urlPath.remoteUrl);
    if (urlPath && ![urlPath isDeleted])
    {
        FFTDebug(@"Kicking off new photo download for URL: %@", urlPath.remoteUrl);
        MMQDownloadPhoto *op = [[MMQDownloadPhoto alloc] init];
        op.slideshowView = self.slideshowView;
        op.photoSource = self.photoSource;
        op.urlPath = urlPath;
        
        [op addObserver:self forKeyPath:@"isFinished" options:0 context:NULL];
        
        PhotoFlickAppDelegate *appDelegate =
            (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
        [appDelegate.operationQueue addOperation:op];
//        [op release];

        return YES;
    }
    else
    {
        FFTCritical(@"No more Photo URLs found; running another search to find more Photo URLs.");
        [self.slideshowView handleNeedMorePhotos];
        return NO;
    }
}

// Called every time a download op completes; only care about the first one so
// we can kick off the slideshow.
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:@"isFinished"] &&
        [[object valueForKeyPath:keyPath] isEqualToNumber:[NSNumber numberWithBool:YES]] &&
        [object isKindOfClass:[MMQDownloadPhoto class]])
    {
        // Called for all attempted download ops, including failed downloads and
        // too-small image files.  If download succeeds, op.photo will be set.
        MMQDownloadPhoto *op = (MMQDownloadPhoto*)object;
        [op removeObserver:self forKeyPath:@"isFinished"];
        if ([op isCancelled])
        {
            FFTDebug(@"Skipping next download; op has been cancelled");
        }
        else if (op.photo)
        {
            // Another image has successfully downloaded.
            FFTDebug(@"Download complete for %@", op.photo.remoteUrl);
            
            // Append Photo to next open slot in slideshow.
            [self appendPhotoToSlideshow:op.photo];
            
            // If this is the first, move to it (away from zero-slide spinner).
            if (!self.loadedFirstImage)
            {
                FFTCritical(@"FIRST PHOTO: Scroll to first image: %@ (%@)", op.photo.remoteUrl, op.photo.title);
                [self.slideshowView scrollToTrayIndex:0 animated:NO];
                [self.slideshowView handleScrolled];
                self.loadedFirstImage = YES;
            }
        }
        else
        {
            // Failed download.  Kick off another, but only once per search.
            FFTDebug(@"Download attempt failed (not found or too small).");
            [self startNextDownload];
        }
        [op release], op = nil;
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)layoutSlides
{
    FFTInfo(@"Layout");
    
    // Preload and lay out blank slides.
    for (NSInteger i = 0; i < [self.trayViews count]; i++)
    {
        // Create an image view as a placeholder for the downloading image.
        MMSlideView *slideView = [self.trayViews objectAtIndex:i];
        
        slideView.frame = [self.logic rectForSlide:i];
        slideView.imageView.frame =
            CGRectMake(0, 0, slideView.frame.size.width, slideView.frame.size.height);
        [slideView resizeSpinner];
        FFTInfo(@"Slide %i: %@ (%@)", i, NSStringFromCGRect(slideView.frame), NSStringFromCGRect(slideView.imageView.frame));
    }
}

// Fill as many slides as we can from the database.
- (void)fillOldPhotos
{
    for (NSInteger i = 0; i < [self.trayViews count]; i++)
    {
        // Create an image view as a placeholder for the downloading image.
        MMSlideView *slideView = [self.trayViews objectAtIndex:i];
        if (slideView.photo == nil)
        {
            // Grab Photo from database, if it exists.
            Photo *photo = [self.dataManager photoAtPosition:self.logic.trayPosition + i];
            if (photo)
            {
                FFTInfo(@"Found a photo for empty tray index %i (pos=%i): %@",
                           i, self.logic.trayPosition + i, photo.remoteUrl);
                slideView.photo = photo;
            }
        }
    }
}

- (void)startMissingDownloads
{
    FFTDebug(@"Checking for empty slides to download....");
    for (MMSlideView *slideView in self.trayViews)
    {
        // Should now have Photo, but still missing Display image.
        if (![slideView hasPhotoImage])
        {
            BOOL keepGoing = [self startNextDownload];
            if (!keepGoing)
            {
                FFTCritical(@"Bailing out early from missing download checks.");
                break;
            }
        }
    }
}

- (void)updateScrollArea
{
    // Resize scroll area to match the images we have.
    NSInteger maxPhotoIndex = [self.dataManager slideshowPhotoCount] - self.logic.trayPosition;
    NSRange range = [self activeTrayRange];
    NSInteger maxTrayIndex = range.length;
    NSInteger endSlide = (maxPhotoIndex < maxTrayIndex) ? maxPhotoIndex : maxTrayIndex;
    FFTInfo(@"maxPhotoIndex=%i maxTrayIndex=%i endSlide=%i", maxPhotoIndex, maxTrayIndex, endSlide);
    
    if (endSlide > 0)
    {
        self.slideshowView.contentSize = [self.logic contentSize:endSlide];
        FFTDebug(@"Expanding contentSize to %@ (%i slides)", NSStringFromCGSize(self.slideshowView.contentSize), endSlide);
    }
}

// Active range is at minimum (0..saveWidth).
- (NSRange)activeTrayRange
{
    NSInteger lowTrayIndex = 0;
    NSInteger highTrayIndex = self.logic.trayWidth;
    
    // Find furthest image.
    for (NSInteger i = [self.trayViews count] - 1; i >= self.logic.saveWidth; i--)
    {
        MMSlideView *slideView = [self.trayViews objectAtIndex:i];
        if (slideView.photo == nil)
        {
            highTrayIndex = i;
        }
        else
        {
            break;
        }
    }
    
    FFTInfo(@"Found active tray range from %i to %i", lowTrayIndex, highTrayIndex);
    return NSMakeRange(lowTrayIndex, highTrayIndex - lowTrayIndex);
}

- (BOOL)shouldSlideTray:(BOOL)forward
{
//    NSRange activeSlides = [self activeTrayRange];
    
    // Inside the bumper area at the end of the tray?
    NSInteger currentTrayIndex = [self.logic atTrayIndex:self.slideshowView];
    
    BOOL shouldSlide = NO;
    if (forward)
    {
        // See if we're close to the end of the tray.
//        NSInteger maxTrayIndex = NSMaxRange(activeSlides);
//        NSInteger hotIndex = maxTrayIndex - self.logic.bumperWidth;
        NSInteger hotIndex = self.logic.trayWidth - self.logic.bumperWidth;
        NSUInteger maxPhotoCount = [self.dataManager slideshowPhotoCount];

        // Lock down forward scrolling when search goes inactive.
        BOOL atEnd = (!self.logic.activeSearch && self.logic.trayPosition + self.logic.trayWidth >= maxPhotoCount);

        shouldSlide = !atEnd && (currentTrayIndex >= hotIndex);
        FFTCritical(@"SHOULD SLIDE TRAY FORWARD? (%@): photo=%i current=%i hot=%i",
                   shouldSlide ? @"YES" : @"NO", self.logic.trayPosition + currentTrayIndex,
                   currentTrayIndex, hotIndex);
    }
    else
    {
//        NSInteger minTrayIndex = activeSlides.location;
//        NSInteger hotIndex = minTrayIndex + self.logic.bumperWidth;
        NSInteger hotIndex = self.logic.bumperWidth;
        shouldSlide = (self.logic.trayPosition > 0) && (currentTrayIndex <= hotIndex);
        FFTCritical(@"SHOULD SLIDE TRAY BACKWARD? (%@): photo=%i current=%i hot=%i",
                   shouldSlide ? @"YES" : @"NO", self.logic.trayPosition + currentTrayIndex,
                   currentTrayIndex, hotIndex);
    }
    return shouldSlide;
}

// Check if we're close enough from the end to download more images.
// Skip check if on the first slide.
// TODO: Tweak preloadCount according to wifi vs 3G
- (void)checkNearEnd
{
    BOOL forward = [self.logic isForward];
    if ([self shouldSlideTray:forward])
    {
        FFTInfo(@"Need to slide the tray %@", forward ? @"forward" : @"backward");
        BOOL wereEnabled = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        [self slideTray:forward];
        [UIView setAnimationsEnabled:wereEnabled];
    }
}


// THE MAGIC!!
//
// Refresh all image views in the tray.
//
// Make sure all slides in the tray have Photo objects and that their images
// are downloaded.  Start downloads here; when downloads complete, wrap up
// the download process in the observer callback contextDidSave:.
- (void)loadTray
{
    // MMSlideshowView
    //  \--MMSlideViews (trayViews) <-- (1) Created in MMSlideshowView init
    //      |--Photo    <-- (2) Added here in loadTray
    //      |   \--UIImage  <-- (3) Added by observer when download complete
    //      |
    //      \--UIImageView  <-- (1) Created in MMSlideView init
    //
    
    FFTInfo(@"Updating tray: position=%i", self.logic.trayPosition);
    [self layoutSlides];
    [self startMissingDownloads];
    [self updateScrollArea];

//    [self.dataManager debugPhotos];
    [self debugTray];
}

// Pretend to move tray forward.
//
// For example, with trayWidth 30 and trayIndex 27,
// newTrayIndex becomes 20; we bump trayPosition to 20.
// We're saving 10 slides each bump (saveWidth).
//
// 0         10        20        30        40       50 slide index (abs)
// 0         10        20        30        40       50 tray index (rel)
// |---------|---------|---------|---------|---------|
// |============================|
//             (trayIndex) -->*
// 20        30        40        50        60       70 slide index (abs)
// 0         10        20        30        40       50 tray index (rel)
// |---------|---------|---------|---------|---------|
// |=========-------------------|
//     -->*
//   (trayPosition) -->|======*=====================| (virtual position)
//
- (void) slideTray:(BOOL)forward
{
//    [self debugTray];
    FFTDebug(@"Before tray bump: current photo %@, tray index %i -> %i",
            [self.slideshowView currentPhoto].title,
            self.logic.prevTrayPosition, self.logic.currTrayPosition);
    
    FFTInfo(@"Found %i total Photos in database.", [self.dataManager slideshowPhotoCount]);
    
    FFTInfo(@"Moving tray %@.", forward ? @"forward" : @"backward");
    for (NSInteger i = 0; i < [self.trayViews count]; i++)
    {
        MMSlideView *slide = [self.trayViews objectAtIndex:i];
        if ([self.logic isBlankForDirection:forward atIndex:i])
        {
            FFTInfo(@"Clearing slide %i", i);
            slide.photo = nil;
        }
        else
        {
            NSInteger oldIndex = [self.logic oldTrayIndex:forward forNewIndex:i];
            FFTInfo(@"Moving photo from slide %i to slide %i", i, oldIndex);
            // Move Photo from oldSlideIndex to i.
            MMSlideView *oldSlide = [self.trayViews objectAtIndex:oldIndex];
            
            oldSlide.photo = slide.photo;
            slide.photo = nil;
        }
    }

    [self.logic jumpTray:forward];

    FFTDebug(@"Scrolling tray from %i to %i", self.logic.prevTrayPosition,
               self.logic.currTrayPosition);
    CGPoint scrollTo = CGPointMake(self.logic.imageSize.width * self.logic.currTrayPosition, 0);

    FFTInfo(@"Snapping slideshow to %i (%@)", self.logic.currTrayPosition, NSStringFromCGPoint(scrollTo));
    [self.slideshowView setContentOffset:scrollTo];
    
    // FIXME: Distinguish between inflating UrlPaths that we already have, and running a whole new search.
    
    // The new Photos.
    // NOTE: This will only hit Photo objects when we are retracing our steps.
//    NSInteger jumpWidth = self.logic.jumpWidth;
//    FFTCritical(@"Attempting to load previous Photos from %i to  %i",
//               self.logic.trayPosition + jumpWidth, self.logic.trayPosition + jumpWidth + jumpWidth);
//    NSArray *newPhotos = [self.dataManager slideshowPhotos:self.logic.trayPosition + jumpWidth count:jumpWidth];
//    FFTDebug(@"NEW PHOTOS: %@", newPhotos);
//    if ([newPhotos count] < [self.trayViews count])
//    {
//        // NOTE: This only means we haven't rolled over these Photos before.
//        
//        FFTCritical(@"Almost ran out of photos; should hit service again for more!");
//        [self.slideshowView handleNeedMorePhotos];
//        
//        // The new Photo objects will continue loading in the background,
//        // but normally we'd want them right now, below.
//    }
    
    // Fill in the nil Photos then snap scroll area to fit what we have.
    FFTDebug(@"Finished sliding tray; checking for missing downloads.");
    [self fillOldPhotos];

    [self startMissingDownloads];
    [self updateScrollArea];
    
    [self debugTray];
}


@end
