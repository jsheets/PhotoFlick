//
//  SearchViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 3/21/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMSearchController.h"

@class IPhoneSearchViewController;
@class FrameViewController;
@class AboutViewController;
@class SettingsViewController;

@interface IPhoneSearchViewController : MMSearchController <UITextFieldDelegate>
{
    BOOL _keyboardShown;
    UITextField *_activeField;
    
    // Child Controllers.
    SettingsViewController *_settingsViewController;

    NSInteger _selectedService;

    UIButton *_flickrButton;
    UIButton *_ffffoundButton;
    UIButton *_customButton;
    UILabel *_statusLabel;
    UIButton *_saveButton;

    UIScrollView *_scrollView;
    UIView *_flickrView;
    UITextField *_keywordTextField;
    UITextField *_usernameTextField;
    UIView *_ffffoundView;
    UIView *_customView;
    UITextField *_customTextField;
}

@property (nonatomic, readonly) SettingsViewController *settingsViewController;

@property (assign) NSInteger selectedService;

@property (nonatomic, retain) IBOutlet UIButton *flickrButton;
@property (nonatomic, retain) IBOutlet UIButton *ffffoundButton;
@property (nonatomic, retain) IBOutlet UIButton *customButton;
@property (nonatomic, retain) IBOutlet UILabel *statusLabel;
@property (nonatomic, retain) IBOutlet UIButton *saveButton;

@property (nonatomic, retain) IBOutlet UIScrollView *scrollView;
@property (nonatomic, retain) IBOutlet UIView *flickrView;
@property (nonatomic, retain) IBOutlet UITextField *keywordTextField;
@property (nonatomic, retain) IBOutlet UITextField *usernameTextField;
@property (nonatomic, retain) IBOutlet UIView *ffffoundView;
@property (nonatomic, retain) IBOutlet UIView *customView;
@property (nonatomic, retain) IBOutlet UITextField *customTextField;

- (IBAction)buttonClicked:(id)sender;
- (IBAction)searchClicked:(id)sender;
- (IBAction)settingsClicked:(id)sender;

- (void)registerForKeyboardNotifications;

@end
