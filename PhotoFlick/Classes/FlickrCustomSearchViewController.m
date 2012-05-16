    //
//  FlickrCustomSearchViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 4/11/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "FlickrCustomSearchViewController.h"

#import "SettingsViewController.h"
#import "MMSlideshowView.h"
#import "MMTray.h"

@implementation FlickrCustomSearchViewController

@synthesize keywordTextField = _keywordTextField;
@synthesize usernameTextField = _usernameTextField;

- (void)dealloc
{
    [_keywordTextField release], _keywordTextField = nil;
    [_usernameTextField release], _usernameTextField = nil;

    [super dealloc];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *keyword = self.searchRunner.searchKeyword;
    if (keyword)
    {
        self.keywordTextField.text = keyword;
    }
    NSString *username = self.searchRunner.searchUsername;
    if (username)
    {
        self.usernameTextField.text = username;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self runFlickrSearchWithKeyword:self.keywordTextField.text username:self.usernameTextField.text];
    [self.frameViewController.flickrPopoverController dismissPopoverAnimated:YES];
    
    return YES;
}

@end
