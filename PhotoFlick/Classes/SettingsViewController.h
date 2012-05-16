//
//  SettingsViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 3/21/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MMViewController.h"

@class FavoritesViewController;
@class AboutViewController;

#define kDisplayTimeKey @"displayTime"
#define kAutoCycle @"autoCycle"

@interface SettingsViewController : MMViewController
{
    FavoritesViewController *_favoritesViewController;
    AboutViewController *_aboutViewController;
    
    UISlider *_displayTimeSlider;
    UIButton *_backButton;
    UIButton *_favoritesButton;
    UIButton *_aboutButton;
}

- (IBAction)backClicked:(id)sender;
- (IBAction)favoritesClicked:(id)sender;
- (IBAction)aboutClicked:(id)sender;

@property (nonatomic, retain, readonly) FavoritesViewController *favoritesViewController;
@property (nonatomic, retain, readonly) AboutViewController *aboutViewController;

@property (nonatomic, retain) IBOutlet UISlider *displayTimeSlider;
@property (nonatomic, retain) IBOutlet UIButton *backButton;
@property (nonatomic, retain) IBOutlet UIButton *favoritesButton;
@property (nonatomic, retain) IBOutlet UIButton *aboutButton;

@end
