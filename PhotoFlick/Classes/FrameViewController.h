//
//  FrameViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 8/15/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMViewController.h"
#import "MMTransitionManager.h"
#import "MMScrollView.h"
#import "MMSlideshowView.h"

@class IPhoneSearchViewController;
@class HttpSearchViewController;
@class SearchRunner;

@interface FrameViewController : MMViewController <MMScrollViewDelegate, MMSlideshowViewDelegate, NSFetchedResultsControllerDelegate, UIPopoverControllerDelegate, UISearchDisplayDelegate>
{
    NSInteger _imagesLoaded;

    // Data objects
    PhotoSource *_photoSource;
    MMTransitionManager *_mgr;
    NSTimer *_timer;
    
    // UI objects
    MMSlideshowView *_slideshowView;
    UILabel *_label;
    UIView *_overlayView;
    UILabel *_titleLabel;
    UILabel *_serviceLabel;
    UIButton *_mainMenuButton;
    UIButton *_autocycleButton;
    UIButton *_resumeButton;
    UIButton *_favoriteButton;
    
    // iPhone-only
    IPhoneSearchViewController *_iphoneSearchController;
    
    // iPad-only
    SearchRunner *_searchRunner;
    UIPopoverController *_flickrPopoverController;
    UIPopoverController *_httpPopoverController;
}

@property (nonatomic, retain) PhotoSource *photoSource;
@property (nonatomic, retain) MMTransitionManager *mgr;
@property (nonatomic, retain) NSTimer *timer;

@property (nonatomic, retain) IBOutlet MMSlideshowView *slideshowView;
@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UIView *overlayView;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;
@property (nonatomic, retain) IBOutlet UILabel *serviceLabel;
@property (nonatomic, retain) IBOutlet UIButton *mainMenuButton;
@property (nonatomic, retain) IBOutlet UIButton *autocycleButton;
@property (nonatomic, retain) IBOutlet UIButton *resumeButton;
@property (nonatomic, retain) IBOutlet UIButton *favoriteButton;

// iPhone-only
@property (nonatomic, readonly) IPhoneSearchViewController *iphoneSearchController;

// iPad-only
@property (nonatomic, readonly) IBOutlet SearchRunner *searchRunner;
@property (nonatomic, retain) IBOutlet UIPopoverController *flickrPopoverController;
@property (nonatomic, retain) IBOutlet UIPopoverController *httpPopoverController;

- (IBAction)searchClicked:(id)sender;
- (IBAction)resumeClicked:(id)sender;
- (IBAction)favoriteClicked:(id)sender;
- (IBAction)autocycleClicked:(id)sender;
- (IBAction)flickrRecentClicked:(id)sender;
- (IBAction)flickrSearchClicked:(id)sender;
- (IBAction)ffffoundClicked:(id)sender;
- (IBAction)favoriteSearchClicked:(id)sender;
- (IBAction)httpClicked:(id)sender;
- (IBAction)settingsClicked:(id)sender;

- (void)runSearch;

@end
