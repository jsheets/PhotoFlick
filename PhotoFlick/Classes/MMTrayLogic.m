//
//  MMTrayLogic.m
//  PhotoFrame
//
//  Created by John Sheets on 2/20/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "MMTrayLogic.h"
#import "PhotoFlickAppDelegate.h"


@implementation MMTrayLogic

@synthesize activeSearch = _activeSearch;
@synthesize searchRunning = _searchRunning;
@synthesize trayPosition = _trayPosition;
@synthesize trayWidth = _trayWidth;
@synthesize bumperWidth = _bumperWidth;
@synthesize saveWidth = _saveWidth;
@synthesize imageSize = _imageSize;
@synthesize prevTrayPosition = _prevTrayPosition;
@synthesize currTrayPosition = _currTrayPosition;

- (id)init
{	
    if ((self = [super init]))
    {
        // Initialization.
        self.activeSearch = YES;
        self.searchRunning = NO;

        // Should remain constant if no reorient.
        PhotoFlickAppDelegate *appDelegate = (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
        self.imageSize = [appDelegate appScreenSizeForPortrait:YES scaled:NO];

        self.trayPosition = 0; // Anchor point for the "tray".
        self.prevTrayPosition = 0;
        self.currTrayPosition = 0;

        // NOTE: bumperWidth should be less than half of saveWidth or weird
        // image swapping will occur across the bumper threshold.
#ifdef WIDE_TRAY
        self.trayWidth = 30;   // How many slides are loaded at a time.
        self.bumperWidth = 5;  // Give ourselves a five-image headstart.
        self.saveWidth = 15;   // How many slides we hang on to when bumping.
#elif MEDIUM_TRAY
        self.trayWidth = 20;   // How many slides are loaded at a time.
        self.bumperWidth = 4;  // Give ourselves a five-image headstart.
        self.saveWidth = self.bumperWidth * 3;
#else
        self.trayWidth = 15;   // How many slides are loaded at a time.
        self.bumperWidth = 2;  // Give ourselves a five-image headstart.
        self.saveWidth = 5;
#endif

        // Testing overrides.
//        self.trayWidth = 10;
//        self.bumperWidth = 3;
//        self.saveWidth = 5;

//        self.trayWidth = 20;
    }

    return self;
}

- (BOOL)scrollVector
{
    return self.currTrayPosition - self.prevTrayPosition;
}

- (CGSize)contentSize:(NSInteger)maxSlideCount
{
    NSInteger slideCount = self.trayPosition + self.trayWidth;
    if (slideCount > maxSlideCount)
    {
        slideCount = maxSlideCount;
    }
    
    return CGSizeMake(self.imageSize.width * slideCount,
                      self.imageSize.height);
}

- (CGRect)rectForSlide:(NSInteger)slideIndex
{
    return CGRectMake(self.imageSize.width * slideIndex, 0,
                      self.imageSize.width, self.imageSize.height);
}

- (NSInteger)jumpWidth
{
    return (self.trayWidth - self.saveWidth);  // e.g. 20
}

- (NSInteger)nextTrayIndex:(BOOL)forward
{
    return forward ? self.saveWidth - self.bumperWidth : self.jumpWidth + self.bumperWidth;
}

- (BOOL)isForward
{
    FFTDebug(@"FORWARD? curr %i - prev %i = %i >= 0?", self.currTrayPosition, self.prevTrayPosition, self.scrollVector);
    return (self.scrollVector >= 0);
}

- (BOOL)isAdjacent:(NSInteger)trayIndex
{
    return abs(trayIndex - self.currTrayPosition) <= 2;
}

- (void)jumpTray:(BOOL)forward
{
#ifdef FFT_LOG_CRITICAL
    NSInteger oldPrev = self.prevTrayPosition;
    NSInteger oldCurr = self.currTrayPosition;
#endif

    NSInteger vector = self.scrollVector;
    self.currTrayPosition = [self nextTrayIndex:forward];
    self.prevTrayPosition = self.currTrayPosition - vector;

    if (forward)
    {
        self.trayPosition += self.jumpWidth;
    }
    else
    {
        self.trayPosition -= self.jumpWidth;
    }
    FFTCritical(@"Jumped to trayPosition=%i, (%i -> %i) ==> (%i -> %i)", self.trayPosition,
               oldPrev, oldCurr, self.prevTrayPosition, self.currTrayPosition);
}

- (BOOL)isBlankForDirection:(BOOL)forward atIndex:(NSInteger)trayIndex
{
    return forward ? (trayIndex < self.jumpWidth) : (trayIndex >= self.saveWidth);
}

- (NSInteger)oldTrayIndex:(BOOL)forward forNewIndex:(NSInteger)trayIndex
{
    if ([self isBlankForDirection:forward atIndex:trayIndex])
    {
        return NSNotFound;
    }
    return forward ? (trayIndex - self.jumpWidth) : (trayIndex + self.jumpWidth);
}

- (NSInteger)atTrayIndex:(UIScrollView*)scrollView
{
    return (scrollView.contentOffset.x / self.imageSize.width);
}

- (NSInteger)atPhotoIndex:(UIView*)scrollView
{
    return [self atTrayIndex:scrollView] + self.trayPosition;
}

- (BOOL)isTooWide:(CGFloat)contentWidth
{
    return self.currTrayPosition * self.imageSize.width >= contentWidth;
}

@end
