//
//  FrameViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 8/15/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "FrameViewController.h"

#import "PhotoFlickAppDelegate.h"
#import "IPhoneSearchViewController.h"
#import "SettingsViewController.h"
#import "Photo.h"
#import "MMTray.h"
#import "MMTrayLogic.h"
#import "MMQBase.h"
#import "FlickrCustomSearchViewController.h"
#import "HttpSearchViewController.h"
#import "SearchRunner.h"

@implementation FrameViewController

@synthesize photoSource = _photoSource;
@synthesize timer = _timer;
@synthesize mgr = _mgr;

@synthesize slideshowView = _slideshowView;
@synthesize label = _label;
@synthesize overlayView = _overlayView;
@synthesize titleLabel = _titleLabel;
@synthesize serviceLabel = _serviceLabel;
@synthesize mainMenuButton = _mainMenuButton;
@synthesize autocycleButton = _autocycleButton;
@synthesize resumeButton = _resumeButton;
@synthesize favoriteButton = _favoriteButton;

@synthesize flickrPopoverController = _flickrPopoverController;
@synthesize httpPopoverController = _httpPopoverController;


#pragma mark Lifecycle

- (void)dealloc
{
    [_photoSource release], _photoSource = nil;
    [_mgr release], _mgr = nil;
    [_timer release], _timer = nil;
    
    [_slideshowView release], _slideshowView = nil;
    [_label release], _label = nil;
    [_overlayView release], _overlayView = nil;
    [_titleLabel release], _titleLabel = nil;
    [_serviceLabel release], _serviceLabel = nil;
    
    [_iphoneSearchController release], _iphoneSearchController = nil;
    [_searchRunner release], _searchRunner = nil;
    [_flickrPopoverController release], _flickrPopoverController = nil;
    [_httpPopoverController release], _httpPopoverController = nil;
    
    [super dealloc];
}


#pragma mark -
#pragma mark Private Methods
#pragma mark -

- (void)timerFireMethod:(NSTimer*)theTimer
{
    FFTCritical(@"Timer fired.");
    [self.slideshowView scrollToNextSlide];
}

// Start or restart the timer.  Called once for every timer iteration, from
// startSlideshow, resumeClicked, and when scrolling halts.
- (void)startTimer
{
    // Only start timer if autocycle is on.
    BOOL autoCycle = [[NSUserDefaults standardUserDefaults] boolForKey:kAutoCycle];
    if (autoCycle)
    {
        float time = [[NSUserDefaults standardUserDefaults] floatForKey:kDisplayTimeKey];

#ifdef MM_DEBUG
        // Shorter slide time in debug mode.
        time = 2.0;
#endif

        if (self.timer && [self.timer isValid])
        {
            // Make sure timer is stopped.
            FFTDebug(@"Invalidating old timer");
            [self.timer invalidate];
        }
        FFTCritical(@"Starting new timer with %.4f seconds (%@ main thread)", time, [NSThread isMainThread] ? @"on " : @"not on");
        self.timer = [NSTimer scheduledTimerWithTimeInterval:time
                                                      target:self
                                                    selector:@selector(timerFireMethod:)
                                                    userInfo:nil
                                                     repeats:NO];
    }
}

- (void)startTimerOnMainThread
{
    [self performSelectorOnMainThread:@selector(startTimer) withObject:nil waitUntilDone:NO];
}

- (void)stopTimer
{
    FFTDebug(@"Stopping timer");
    [self.timer invalidate];
    self.timer = nil;
}

// Call this when we get our first download.
- (void) startSlideshow
{
    FFTInfo(@"Starting slideshow");
    self.label.text = nil;
    
    // Flash overlay.
    [self.mgr showOverlay:self.overlayView withDuration:0.1];
    [self.mgr hideOverlay:self.overlayView withDuration:3];

    [self startTimerOnMainThread];
}

- (SearchRunner*)searchRunner
{
    if (_searchRunner == nil)
    {
        _searchRunner = [[SearchRunner alloc] init];
        _searchRunner.frameViewController = self;
    }
    return _searchRunner;
}


#pragma mark UIView Implementation

- (void)resetStatusLabel
{
    if (self.appDelegate.isIPad)
    {
        // Hits this on opening screen for iPad.
        self.label.text = @"Please choose a photo slideshow search above.";
        self.label.textColor = [UIColor whiteColor];
        self.label.font = [UIFont systemFontOfSize:24.0];
    }
    else
    {
        // Hits this only after a search starts on iPhone.
        self.label.text = @"Searching for images...";
        self.label.textColor = [UIColor whiteColor];
        self.label.font = [UIFont systemFontOfSize:17.0];
    }
}

- (void)errorStatusLabel
{
    if (self.appDelegate.isIPad)
    {
        self.label.textColor = [UIColor redColor];
        self.label.font = [UIFont boldSystemFontOfSize:24.0];
    }
    else
    {
        self.label.textColor = [UIColor redColor];
        self.label.font = [UIFont boldSystemFontOfSize:17.0];
    }
}

- (void)cancelSlideshow
{
    // Make note of how far we went and send to analytics.
    NSInteger scrolledTo = [self.slideshowView.tray.logic atPhotoIndex:self.slideshowView];
    if (scrolledTo > 0)
    {
        EVENT_SLIDE_TO(scrolledTo);
    }
    [self resetStatusLabel];
    self.slideshowView.tray.logic.activeSearch = YES;
}

- (void)cancel
{
    FFTCritical(@"Cancelling slideshow.");

    [self cancelSlideshow];
    [self dismissModalViewControllerAnimated:YES];
    [self.slideshowView.tray resetTray];
    [self.appDelegate.operationQueue cancelAllOperations];
    [self.mgr showOverlay:self.overlayView];
}

- (void)resetSearch
{
    FFTCritical(@"Cancelling slideshow.");
    
    [self cancelSlideshow];
    
    // Make note of how far we went and send to analytics.
    NSInteger scrolledTo = [self.slideshowView.tray.logic atPhotoIndex:self.slideshowView];
    if (scrolledTo > 0)
    {
        EVENT_SLIDE_TO(scrolledTo);
    }
    
    NSOperationQueue *queue = self.appDelegate.operationQueue;
    FFTDebug(@"Cancelling all pending download operations (%@ on main thread)",
            [NSThread isMainThread] ? @"is" : @"is not");
    [queue cancelAllOperations];

    FFTInfo(@"Forcing all operations to 'finished': %@", queue.operations);
    for (MMQBase *op in queue.operations)
    {
        [op completeOperation];
    }
}

- (void)noPhotosFound
{
    FFTDebug(@"Catching no photos found condition.");
    self.label.text = @"Sorry, web scan failed to find any slideshow images here.";
    
    // FIXME: CA animation not working here; font not animatable?
    [UIView beginAnimations:@"fadeRed" context:NULL];
    [UIView setAnimationDuration:2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    [self errorStatusLabel];
    
    [UIView commitAnimations];
    
    [self performSelector:@selector(cancel) withObject:nil afterDelay:2.5];
}


#pragma mark -
#pragma mark iPhone Button Overlay Actions


- (void)reorientOverlayTo:(UIInterfaceOrientation)newOrientation
{
    BOOL isPortrait = newOrientation == UIDeviceOrientationPortrait ||
        newOrientation == UIDeviceOrientationPortraitUpsideDown;
    
    [UIView beginAnimations:@"fadeIn" context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    [UIView setAnimationBeginsFromCurrentState:YES];
    
    if (isPortrait)
    {
        // Move overlay buttons to vertical layout.
        self.mainMenuButton.frame =  CGRectMake(112,  35, 95, 95);
        self.autocycleButton.frame = CGRectMake(112, 155, 95, 95);
        self.resumeButton.frame =    CGRectMake(112, 275, 95, 95);
    }
    else
    {
        // Move overlay buttons to horizontal layout.
        self.mainMenuButton.frame =  CGRectMake(55,  79, 95, 95);
        self.autocycleButton.frame = CGRectMake(193, 79, 95, 95);
        self.resumeButton.frame =    CGRectMake(330, 79, 95, 95);
    }
    
    [UIView commitAnimations];
}

- (IBAction)searchClicked:(id)sender
{
    // IPHONE: Bring up search view!
    [self presentModalViewController:self.iphoneSearchController animated:YES];
    
    EVENT_ANALYTICS_END(@"Search");
    [self cancel];
}

- (IBAction)resumeClicked:(id)sender
{
    // Skip if we have no images loaded.
    if ([self.slideshowView currentPhoto] == nil)
    {
        FFTDebug(@"Ignoring Resume click when no active search");
        return;
    }

    [self.mgr hideOverlay:self.overlayView];
    [self startTimerOnMainThread];
}

- (IBAction)favoriteClicked:(id)sender
{
    // Skip if we have no images loaded.
    if ([self.slideshowView currentPhoto] == nil)
    {
        FFTDebug(@"Ignoring Favorite click when no active search");
        return;
    }

    // Toggle favorite.
    self.favoriteButton.selected = !self.favoriteButton.selected;

    Photo *photo = [self.slideshowView currentPhoto];
    FFTDebug(@"Setting favorite to %i for image %@", self.favoriteButton.selected, photo);
    photo.isFavorite = [NSNumber numberWithBool:self.favoriteButton.selected];
    
    // Copy favorite over to special Favorite source.
    [self.appDelegate.dataManager mirrorFavorite:photo];
    [self.appDelegate.dataManager saveContext];
}

- (IBAction)autocycleClicked:(id)sender
{
    // Toggle autocycle.
    self.autocycleButton.selected = !self.autocycleButton.selected;
    [[NSUserDefaults standardUserDefaults] setBool:self.autocycleButton.selected
                                            forKey:kAutoCycle];
}


#pragma mark -
#pragma mark iPad Actions


- (BOOL)hidePopup:(UIPopoverController*)controller
{
    if (controller && controller.popoverVisible)
    {
        FFTDebug(@"Popover already displayed, hiding.");
        [controller dismissPopoverAnimated:YES];
        return YES;
    }

    return NO;
}

// Flickr All
- (IBAction)flickrRecentClicked:(id)sender
{
    if ([self hidePopup:self.httpPopoverController]) return;
    [self hidePopup:self.flickrPopoverController];
    
    FFTInfo(@"Clicked Flickr Recent");
    self.label.text = @"";
    [self resetSearch];
    
    [self.searchRunner setSearchKeyword:nil];
    [self.searchRunner setSearchUsername:nil];

    EVENT_SEARCH_FLICKR;
    [self.searchRunner searchFlickr:nil];
}

- (IBAction)flickrSearchClicked:(id)sender
{
    if ([self hidePopup:self.flickrPopoverController]) return;
    [self hidePopup:self.httpPopoverController];
    
    FFTInfo(@"Clicked Flickr Search");
    if (self.flickrPopoverController == nil)
    {
        FFTDebug(@"Instantiating Flickr search box");
        NSString *nibName = self.appDelegate.isIPad ? @"FlickrView-ipad" : @"FlickrView-iphone";
        FlickrCustomSearchViewController* searchController = [[FlickrCustomSearchViewController alloc] initWithNibName:nibName bundle:nil];
        searchController.frameViewController = self;
        searchController.searchRunner = self.searchRunner;

//        searchController.searchBar = [[[UISearchBar alloc] init] autorelease];
//        searchController.searchBar.delegate = searchController;
//        searchController.searchBar.placeholder = @"Search Flickr by username or keyword";
//        [searchController.searchBar sizeToFit];
//        searchController.tableView.tableHeaderView = searchController.searchBar;
        
        UIPopoverController* aPopover = [[UIPopoverController alloc] initWithContentViewController:searchController];
        aPopover.delegate = self;
        aPopover.popoverContentSize = CGSizeMake(480, 180);
        [searchController release];
        
        // Store the popover in a custom property for later use.
        self.flickrPopoverController = aPopover;
        [aPopover release];
    }
    
    [self.flickrPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)ffffoundClicked:(id)sender
{
    if ([self hidePopup:self.httpPopoverController]) return;
    [self hidePopup:self.flickrPopoverController];
    
    EVENT_SEARCH_FFFFOUND;
    
    FFTInfo(@"Clicked Ffffound");
    [self resetSearch];
    [self.searchRunner searchHttp:@"http://ffffound.com"];
}

- (IBAction)favoriteSearchClicked:(id)sender
{
    FFTInfo(@"Clicked Favorites");
    [self.appDelegate.dataManager debugFavorites];
    self.slideshowView.tray.photoSource = [self.appDelegate.dataManager favoritesPhotoSource];
    [self resetSearch];
    [self.searchRunner searchFavorites];

    [self.slideshowView.tray loadTray];
    FFTInfo(@"Tray finished loading: %@", self.slideshowView);
    
    if (!self.slideshowView.tray.loadedFirstImage)
    {
        FFTInfo(@"FIRST PHOTO: Initializing labels and starting slideshow.");
        self.label.text = @"Loading first image...";
        self.titleLabel.text = @"";
        [self startSlideshow];
    }
}

// Show http:// popup list.
- (IBAction)httpClicked:(id)sender
{
    if ([self hidePopup:self.httpPopoverController]) return;
    [self hidePopup:self.flickrPopoverController];
    
    FFTInfo(@"Clicked http:// Search");
    if (self.httpPopoverController == nil)
    {
        [self resetSearch];

        FFTDebug(@"Instantiating HTTP search box");
        HttpSearchViewController* searchController = [[HttpSearchViewController alloc] init];
        searchController.frameViewController = self;
        searchController.searchRunner = self.searchRunner;
        
        searchController.searchBar = [[[UISearchBar alloc] init] autorelease];
        searchController.searchBar.delegate = searchController;
        searchController.searchBar.placeholder = @"Search for pictures on any web site";
        [searchController.searchBar sizeToFit];
        searchController.tableView.tableHeaderView = searchController.searchBar;
        
        UIPopoverController* aPopover = [[UIPopoverController alloc] initWithContentViewController:searchController];
        aPopover.delegate = self;
        aPopover.popoverContentSize = CGSizeMake(350, 600);
        [searchController release];
        
        // Store the popover in a custom property for later use.
        self.httpPopoverController = aPopover;
        [aPopover release];
    }
    
    FFTDebug(@"Showing Http popover: %@", self.httpPopoverController);
    [self.httpPopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)settingsClicked:(id)sender
{
    FFTInfo(@"Clicked Settings");
}

/*
#pragma mark -
#pragma mark UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    FFTDebug(@"POPOVER SHOULD DISMISS");
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    // Don't really do anything here. Don't want to trigger a new search when they
    // click away from the popover.
    FFTDebug(@"POPOVER DID DISMISS");
}
*/


#pragma mark -
#pragma mark UI View Handling

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

// Stretch view frame to full window when orientation changes.
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    FFTInfo(@"Rotating from %i to %i", fromInterfaceOrientation, self.interfaceOrientation);
    [self.slideshowView reorientTo:self.interfaceOrientation];
    if (!self.appDelegate.isIPad)
    {
        [self reorientOverlayTo:self.interfaceOrientation];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    
    FFTError(@"===== FRAME MEMORY WARNING =====");
    self.flickrPopoverController = nil;
    self.httpPopoverController = nil;
    
//    [self.slideshowView.tray releaseMemory];
}

- (void)viewDidLoad
{
    FFTDebug(@"View initialization");
    _imagesLoaded = 0;
}

- (void)viewDidUnload
{
    [self.slideshowView.tray clearImageData:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (!self.mgr)
    {
        self.mgr = [[[MMTransitionManager alloc] init] autorelease];
    }
    [super viewWillAppear:animated];
    
    BOOL autoCycle = [[NSUserDefaults standardUserDefaults] boolForKey:kAutoCycle];
    FFTCritical(@"SETTING AUTOCYCLE: %i (button=%i)", autoCycle, self.autocycleButton.selected);
    self.autocycleButton.selected = autoCycle;
    self.serviceLabel.text = self.photoSource.title;

    [self resetStatusLabel];
    self.overlayView.alpha = self.appDelegate.isIPad ? 1 : 0;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [self.slideshowView reorientTo:self.interfaceOrientation];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.label.text = nil;
    
    [self stopTimer];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

/*

#pragma mark -
#pragma mark UISearchDisplayDelegate

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    FFTInfo(@"WILL SHOW");
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didShowSearchResultsTableView:(UITableView *)tableView
{
    FFTInfo(@"DID SHOW");
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willHideSearchResultsTableView:(UITableView *)tableView
{
    FFTInfo(@"WILL HIDE");
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    FFTInfo(@"DID HIDE");
}


- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    FFTInfo(@"DID LOAD (hidden=%i)", tableView.hidden);
    [tableView reloadData];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView
{
    FFTInfo(@"WILL UNLOAD");
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    FFTInfo(@"SHOULD RELOAD SCOPE(%i)", searchOption);
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    FFTInfo(@"SHOULD RELOAD STRING (%@)", searchString);
    return YES;
}


- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    FFTInfo(@"WILL BEGIN SEARCH");
}

- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    FFTInfo(@"DID BEGIN SEARCH");
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    FFTInfo(@"WILL END SEARCH");
}

- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    FFTInfo(@"DID END SEARCH");
}


#pragma mark -
#pragma mark Search bar table view


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    FFTInfo(@"TABLE SECTIONS: 1");
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    FFTInfo(@"TABLE ROWS: 3");
    return 3;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    FFTInfo(@"Getting cell for roe %i", indexPath.row);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    //    NSArray *results = [[NSArray alloc] initWithObjects:@"Flickr", @"Ffffound", @"Other Results...", nil];
    //    cell.textLabel.text = [results objectAtIndex:indexPath.row];
    cell.textLabel.text = @"Random Woot!";
    
    return cell;
}

*/


#pragma mark MMScrollViewDelegate implementation

- (void)imageScrollView:(MMScrollView *)view gotSingleTapAtPoint:(CGPoint)tapPoint
{
    FFTInfo(@"Single tap at %@", NSStringFromCGPoint(tapPoint));
    if (self.overlayView.alpha == 0)
    {
        [self.mgr showOverlay:self.overlayView];
        [self stopTimer];

        // Set the favorite status for this image.
        Photo *photo = [self.slideshowView currentPhoto];
        self.favoriteButton.selected = [photo.isFavorite boolValue];
    }
    else
    {
        [self.mgr hideOverlay:self.overlayView];
        [self startTimerOnMainThread];
    }
}

- (void)imageScrollView:(MMScrollView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint
{
    FFTInfo(@"Double tap at %@", NSStringFromCGPoint(tapPoint));
}

- (void)imageScrollView:(MMScrollView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint
{
    FFTInfo(@"Two-finger tap at %@", NSStringFromCGPoint(tapPoint));
}


#pragma mark MMSlideshowViewDelegate implementation

- (void)slideshowView:(MMSlideshowView *)view scrolledFromSlide:(NSInteger)fromTrayIndex toSlide:(NSInteger)toTrayIndex
{
    // Update info layer text and reset timer if autocycle is on.

    self.titleLabel.text = [self.slideshowView.tray titleForCurrentSlide];
    FFTCritical(@"FRAME: Scrolled %i -> %i (title: '%@')", fromTrayIndex, toTrayIndex, self.titleLabel.text);

    [self startTimerOnMainThread];
}

- (void)needMorePhotosForSlideshowView:(MMSlideshowView *)view
{
    FFTCritical(@"Running another search for new Photos");
    [self runSearch];
}

// Kick off a new search operation for the current PhotoSource.
- (void)runSearch
{
    if (self.slideshowView.tray.logic.searchRunning)
    {
        FFTCritical(@"Search already running; refusing to run concurrent searches");
        return;
    }

    MMQBase *op = [self.photoSource searchOp];
    if (op)
    {
        FFTCritical(@"Before URL Search");
        [((PhotoFlickAppDelegate*)[[UIApplication sharedApplication]
                                   delegate]).dataManager debugUrlPaths];
        // Add frame view controller as observer of search op.
        [op addObserver:self forKeyPath:@"isFinished" options:0 context:NULL];
        
        FFTInfo(@"Queueing op: %@", op);
        self.slideshowView.tray.logic.searchRunning = YES;
        [self.appDelegate.operationQueue addOperation:op];
        
        // Continue downloading photos in the background....  Then
        // call back into observe method below when download is complete.
    }
    else if ([self.photoSource.title isEqualToString:@"Favorites"])
    {
        FFTCritical(@"Manually starting local Favorites slideshow.");
//        [self startSlideshow];
    }
}

// Called every time a search completes; only care about the first one so
// we can kick off the slideshow.
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:@"isFinished"] &&
        [[object valueForKeyPath:keyPath] isEqualToNumber:[NSNumber numberWithBool:YES]])
    {
        // A search op has completed.
        DataManager *dataManager = ((PhotoFlickAppDelegate*)[[UIApplication sharedApplication]
                                                             delegate]).dataManager;
        if ([dataManager hasAvailableUrlPaths])
        {
            // We now have Photo objects in the database.  We want to load the
            // first tray now.
            FFTCritical(@"Slideshow search completed");
            [dataManager debugUrlPaths];
            
            [self.slideshowView.tray loadTray];
            FFTInfo(@"Tray finished loading: %@", self.slideshowView);
            
            if (!self.slideshowView.tray.loadedFirstImage)
            {
                FFTInfo(@"FIRST PHOTO: Initializing labels and starting slideshow.");
                self.label.text = @"Loading first image...";
                self.titleLabel.text = @"";
                [self startSlideshow];
            }
        }
        else
        {
            // Search returned no new results.
            FFTCritical(@"EMPTY SEARCH: Disabling further searching on this source.");
            self.slideshowView.tray.logic.activeSearch = NO;
            
            if (self.photoSource && ![self.photoSource.builtin boolValue])
            {
                [dataManager.managedObjectContext deleteObject:self.photoSource];
                self.photoSource = nil;
                [dataManager saveContext];
            }
            
            if (!self.slideshowView.tray.loadedFirstImage && ![dataManager hasAvailableUrlPaths])
            {
                FFTCritical(@"No URLs found for this entire site!");
                [self noPhotosFound];
            }
        }

        MMQBase *op = (MMQBase*)object;
        [op removeObserver:self forKeyPath:@"isFinished"];
        self.slideshowView.tray.logic.searchRunning = NO;
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark Controller Property Initializers.


- (IPhoneSearchViewController*)iphoneSearchController
{
    if (_iphoneSearchController == nil)
    {
        NSString *nibName = self.appDelegate.isIPad ? @"SearchView-ipad" : @"SearchView-iphone";
        _iphoneSearchController = [[IPhoneSearchViewController alloc] initWithNibName:nibName bundle:nil];
        _iphoneSearchController.frameViewController = self;
    }
    return _iphoneSearchController;
}


@end
