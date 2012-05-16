//
//  MMSlideshowView.h
//  PhotoFrame
//
//  Created by john sheets on 11/29/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMScrollView.h"

@class Photo;
@class MMTray;
@class DataManager;

@protocol MMSlideshowViewDelegate;

@interface MMSlideshowView : MMScrollView
{
    id <MMSlideshowViewDelegate> _slideshowDelegate;  // Send events here
    MMTray *_tray;
}

@property (nonatomic, assign) IBOutlet id <MMSlideshowViewDelegate> slideshowDelegate;
@property (nonatomic, retain) MMTray *tray;
@property (nonatomic, readonly) DataManager *dataManager;

- (Photo*)currentPhoto;
- (void)scrollToTrayIndex:(NSInteger)slideIndex animated:(BOOL)isAnimated;
- (void)scrollToNextSlide;
- (void)reorientTo:(UIInterfaceOrientation)orientation;

- (void)handleScrolled;
- (void)handleNeedMorePhotos;

@end


/*
 Protocol for handling slideshow scrolling.
 */
@protocol MMSlideshowViewDelegate <NSObject>

@optional
- (void)slideshowView:(MMSlideshowView *)view scrolledFromSlide:(NSInteger)fromTrayIndex toSlide:(NSInteger)toTrayIndex;
- (void)needMorePhotosForSlideshowView:(MMSlideshowView *)view;
@end

