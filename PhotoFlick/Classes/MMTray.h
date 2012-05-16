//
//  MMTray.h
//  PhotoFrame
//
//  Created by John Sheets on 12/27/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

//
// Manages tray shuffling.
//

#import <Foundation/Foundation.h>

@class MMSlideshowView;
@class DataManager;
@class PhotoSource;
@class MMTrayLogic;

@interface MMTray : NSObject
{
    MMTrayLogic *_logic;
    NSMutableArray *_trayViews;
    MMSlideshowView *_slideshowView;
    BOOL _loadedFirstImage;
    PhotoSource *_photoSource;
}

@property (nonatomic, retain) MMTrayLogic *logic;
@property (nonatomic, retain) NSMutableArray *trayViews;
@property (nonatomic, retain) MMSlideshowView *slideshowView;
@property (nonatomic, assign) BOOL loadedFirstImage;
@property (nonatomic, retain) PhotoSource *photoSource;
@property (nonatomic, readonly) DataManager *dataManager;

- (id)initWithSlideshow:(MMSlideshowView*)slideshow;
- (void)layoutSlides;
- (NSString *)titleForCurrentSlide;
- (void)updateScrollArea;
- (NSRange)activeTrayRange;
- (BOOL)shouldSlideTray:(BOOL)forward;
- (void)checkNearEnd;
- (void)resetTray;
- (void)clearTray;
- (void)debugTray;
- (void)loadTray;
- (void)slideTray:(BOOL)forward;
- (void)clearImageData:(BOOL)keepTrayImages;
- (void)releaseMemory;

@end
