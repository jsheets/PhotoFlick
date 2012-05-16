//
//  SettingsViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 3/21/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "SettingsViewController.h"
#import "FavoritesViewController.h"
#import "AboutViewController.h"

@implementation SettingsViewController

@synthesize displayTimeSlider = _displayTimeSlider;
@synthesize backButton = _backButton;
@synthesize favoritesButton = _favoritesButton;
@synthesize aboutButton = _aboutButton;

- (void)dealloc
{
    [_favoritesViewController release];
    [_aboutViewController release];
    [_displayTimeSlider release];
    [_backButton release];
    [_favoritesButton release];
    [_aboutButton release];
    
    [super dealloc];
}

- (void)saveSliderSettings
{
    // Save control values to user settings.
    EVENT_SETTINGS(self.displayTimeSlider.value);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:self.displayTimeSlider.value forKey:kDisplayTimeKey];
}

- (void)loadSliderSettings
{
    // Initialize UI controls from user settings.
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    float value = [defaults floatForKey:kDisplayTimeKey];
    if (value < 2.0)
    {
        FFTInfo(@"No default slider value; bumping to 5.0");
        value = 5.0;
    }
    self.displayTimeSlider.value = value;
    FFTDebug(@"LOADED slider value: %f", self.displayTimeSlider.value);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.displayTimeSlider setThumbImage:[UIImage imageNamed:@"slider-thumb.png"]
                                 forState:UIControlStateNormal];

    UIImage *image = [[UIImage imageNamed:@"slider-left.png"]
                      stretchableImageWithLeftCapWidth:9 topCapHeight:0];
    [self.displayTimeSlider setMinimumTrackImage:image forState:UIControlStateNormal];

    image = [[UIImage imageNamed:@"slider-right.png"] stretchableImageWithLeftCapWidth:9 topCapHeight:0];
    [self.displayTimeSlider setMaximumTrackImage:image forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self loadSliderSettings];
    [super viewDidAppear:animated];
}

- (IBAction)backClicked:(id)sender
{
    FFTDebug(@"Clicked Back");
    [self saveSliderSettings];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)favoritesClicked:(id)sender
{
    FFTDebug(@"Clicked Favorites Settings");

    self.favoritesViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:self.favoritesViewController animated:YES];
}

- (IBAction)aboutClicked:(id)sender
{
    EVENT_ABOUT;
    
    FFTDebug(@"Clicked About button");

    // Jump to Safari application.
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://mobilemethod.net"]];

    // Open in-app.
    self.aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:self.aboutViewController animated:YES];
}

- (FavoritesViewController*)favoritesViewController
{
    if (_favoritesViewController == nil)
    {
        NSString *nibName = self.appDelegate.isIPad ? @"FavoritesView-ipad" : @"FavoritesView-iphone";
        _favoritesViewController = [[FavoritesViewController alloc] initWithNibName:nibName bundle:nil];
    }
    return _favoritesViewController;
}

- (AboutViewController*)aboutViewController
{
    if (_aboutViewController == nil)
    {
        NSString *nibName = self.appDelegate.isIPad ? @"AboutView-ipad" : @"AboutView-iphone";
        _aboutViewController = [[AboutViewController alloc] initWithNibName:nibName bundle:nil];
    }
    return _aboutViewController;
}

@end
