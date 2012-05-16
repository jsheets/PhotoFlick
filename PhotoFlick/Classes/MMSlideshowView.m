//
//  MMSlideshowView.m
//  PhotoFrame
//
//  Created by john sheets on 11/29/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMScrollView.h"
#import "MMSlideshowView.h"
#import "PhotoFlickAppDelegate.h"
#import "MMSlideView.h"
#import "MMTray.h"
#import "MMTrayLogic.h"
#import "ImageBytes.h"

@implementation MMSlideshowView

@synthesize slideshowDelegate = _slideshowDelegate;
@synthesize tray = _tray;

- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder])
    {
        // Initialization code
        PhotoFlickAppDelegate *appDelegate = (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
        BOOL initialPortrait = appDelegate.isIPad;
        CGSize size = [appDelegate appScreenSizeForPortrait:initialPortrait scaled:NO];
        self.frame = CGRectMake(0, 0, size.width, size.height);
        self.tray = [[[MMTray alloc] initWithSlideshow:self] autorelease];
        
        // Srolling content area is always a static size.
        self.contentSize = [self.tray.logic contentSize:0];
        FFTDebug(@"SLIDESHOW VIEW: contentSize = %@", NSStringFromCGSize(self.contentSize));
    }
    return self;
}

- (void)dealloc
{
    [_slideshowDelegate release], _slideshowDelegate = nil;
    [_tray release], _tray = nil;

    [super dealloc];
}


#pragma mark -
#pragma mark Private Delegate Handler Methods
#pragma mark -

//- (void)handleScrolledToPhoto:(NSInteger)photoIndex
- (void)handleScrolled
{
    FFTTrace(@"Entered handleScrolled");
    if ([self.slideshowDelegate respondsToSelector:@selector(slideshowView:scrolledFromSlide:toSlide:)])
    {
        FFTDebug(@"Calling delegate for handleScrolledFromSlide: %i -> %i",
                self.tray.logic.prevTrayPosition, self.tray.logic.currTrayPosition);
        [self.slideshowDelegate slideshowView:self
                            scrolledFromSlide:self.tray.logic.prevTrayPosition
                                      toSlide:self.tray.logic.currTrayPosition];
    }
}

- (void)handleNeedMorePhotos
{
    FFTDebug(@"Entered handleNeedMorePhotos");
    if ([self.slideshowDelegate respondsToSelector:@selector(needMorePhotosForSlideshowView:)])
    {
        FFTDebug(@"Calling delegate for handleNeedMorePhotos");
        [self.slideshowDelegate needMorePhotosForSlideshowView:self];
    }
}


#pragma mark Core Data

- (DataManager*)dataManager
{
    PhotoFlickAppDelegate *appDelegate =
        (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
    return appDelegate.dataManager;
}

// Get the Photo for the slide we are currently viewing.
- (Photo*)currentPhoto
{
    NSInteger trayIndex = [self.tray.logic atTrayIndex:self];
    if (trayIndex >= [self.tray.trayViews count])
    {
        return nil;
    }
    
    MMSlideView *slide = [self.tray.trayViews objectAtIndex:trayIndex];
    return slide.photo;
//    return (photoIndex < [self.tray.photos count]) ? [self.tray.photos objectAtIndex:photoIndex] : nil;
}


#pragma mark -
#pragma mark UI Methods

// Timer scroll
//
// Scroll this view to the given image index (imageWidth * imageIndex).
// Clip to zero or greatest loaded image + 1.  When scrolling to
// a blank image, should display a spinner.
- (void)scrollToTrayIndex:(NSInteger)trayIndex animated:(BOOL)isAnimated
{
    self.tray.logic.prevTrayPosition = [self.tray.logic atTrayIndex:self];
    self.tray.logic.currTrayPosition = trayIndex;

    FFTInfo(@"SCROLLER at photo %i (tray index %i -> %i; contentOffset %@)",
               [self.tray.logic atPhotoIndex:self], self.tray.logic.prevTrayPosition,
               self.tray.logic.currTrayPosition, NSStringFromCGPoint(self.contentOffset));
    if ([self.tray.logic isTooWide:self.contentSize.width])
    {
        FFTInfo(@"Attempted to scroll past the scroll region; slow down there Tex!!");
        return;
    }
    
    if (isAnimated)
    {
        [UIView beginAnimations:@"scrollTo" context:NULL];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }
    
    CGPoint scrollTo = CGPointMake(self.tray.logic.imageSize.width * self.tray.logic.currTrayPosition, 0);
    FFTInfo(@"Scrolling from %i (%@) to %i (%@)", self.tray.logic.prevTrayPosition,
               NSStringFromCGPoint(self.contentOffset), self.tray.logic.currTrayPosition,
               NSStringFromCGPoint(scrollTo));
    [self setContentOffset:scrollTo];
    
    if (isAnimated)
    {
        [UIView commitAnimations];

        [self handleScrolled];  // Alert slideshow delegate.
        [self.tray checkNearEnd];
    }
}

- (void)scrollToNextSlide
{
    [self scrollToTrayIndex:[self.tray.logic atTrayIndex:self] + 1 animated:YES];
}

- (void)scrollRotate:(BOOL)isAnimated
{
    FFTInfo(@"SCROLLER at photo %i (contentOffset %@)",
           [self.tray.logic atPhotoIndex:self], NSStringFromCGPoint(self.contentOffset));
    
    if (isAnimated)
    {
        [UIView beginAnimations:@"scrollTo" context:NULL];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }
    
    CGPoint scrollTo = CGPointMake(self.tray.logic.imageSize.width * self.tray.logic.currTrayPosition, 0);
    FFTInfo(@"Rotate scroll from %@ to %@", NSStringFromCGPoint([self contentOffset]), NSStringFromCGPoint(scrollTo));
    [self setContentOffset:scrollTo];
    
    if (isAnimated)
    {
        [UIView commitAnimations];
    }
}


#pragma mark -
#pragma mark UISlideshowViewDelegate Implementation

// Start manual scroll.
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.tray.logic.prevTrayPosition = [self.tray.logic atTrayIndex:self];
    FFTDebug(@"Starting slide scroll from %i", self.tray.logic.prevTrayPosition);
}

// End manual scroll.
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.tray.logic.currTrayPosition = [self.tray.logic atTrayIndex:self];
    FFTDebug(@"Finished slide scroll at %i", self.tray.logic.currTrayPosition);

    [self handleScrolled];  // Alert slideshow delegate.
    [self.tray checkNearEnd];
}


- (void)reorientTo:(UIInterfaceOrientation)newOrientation
{
    // Portrait screen size.
    BOOL isPortrait = newOrientation == UIDeviceOrientationPortrait ||
        newOrientation == UIDeviceOrientationPortraitUpsideDown;

    CGSize screenSize = [(PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate] appScreenSizeForPortrait:isPortrait scaled:NO];
    if (screenSize.width > screenSize.height)
    {
        // Oops, landscape bounds. Swap.
        screenSize = CGSizeMake(screenSize.height, screenSize.width);
    }
    
    // Smoothly rotate to new orientation.
    [UIView beginAnimations:@"fadeIn" context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    if (newOrientation == UIDeviceOrientationPortrait ||
        newOrientation == UIDeviceOrientationPortraitUpsideDown)
    {
        FFTDebug(@"Rotate to PORTRAIT (%@) at %@", NSStringFromCGSize(screenSize), NSStringFromCGPoint(self.contentOffset));
        self.tray.logic.imageSize = screenSize;
    }
    else if (newOrientation == UIDeviceOrientationLandscapeLeft ||
             newOrientation == UIDeviceOrientationLandscapeRight)
    {
        FFTDebug(@"Rotate to LANDSCAPE (%@) at %@", NSStringFromCGSize(screenSize), NSStringFromCGPoint(self.contentOffset));
        self.tray.logic.imageSize = CGSizeMake(screenSize.height, screenSize.width);
    }
    [self.tray layoutSlides];

    FFTDebug(@"Content size before orient: %@", NSStringFromCGSize(self.contentSize));
    FFTDebug(@"Content size wanted by tray: %@", NSStringFromCGSize([self.tray.logic contentSize:0]));
    self.contentSize = CGSizeMake(self.contentSize.width, [self.tray.logic contentSize:0].height);
    FFTDebug(@"Content size after orient: %@", NSStringFromCGSize(self.contentSize));

    [UIView commitAnimations];

    [self.tray debugTray];
    
    // Current image has now scrolled off screen; scroll back to it.
    if (!CGPointEqualToPoint(self.contentOffset, CGPointZero))
    {
        [self scrollRotate:YES];
    }
    
}

@end
