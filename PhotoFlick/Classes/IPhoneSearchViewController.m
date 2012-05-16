//
//  SearchViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 3/21/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "IPhoneSearchViewController.h"

#import "SettingsViewController.h"
#import "AboutViewController.h"

#import "MMTray.h"

#define FLICKR_TAG 1
#define FFFFOUND_TAG 2
#define CUSTOM_TAG 3

@implementation IPhoneSearchViewController

@synthesize selectedService = _selectedService;

@synthesize flickrButton = _flickrButton;
@synthesize ffffoundButton = _ffffoundButton;
@synthesize customButton = _customButton;
@synthesize statusLabel = _statusLabel;
@synthesize saveButton = _saveButton;

@synthesize scrollView = _scrollView;
@synthesize flickrView = _flickrView;
@synthesize keywordTextField = _keywordTextField;
@synthesize usernameTextField = _usernameTextField;
@synthesize ffffoundView = _ffffoundView;
@synthesize customView = _customView;
@synthesize customTextField = _customTextField;

/************************************************************************/

- (void)dealloc
{
    [_settingsViewController release];
    [_frameViewController release];
    [_flickrButton release];
    [_ffffoundButton release];
    [_customButton release];

    [_flickrView release];
    [_keywordTextField release];
    [_usernameTextField release];
    [_ffffoundView release];
    [_customView release];
    [_customTextField release];

    [_statusLabel release];
    
    [super dealloc];
}


#pragma mark Button Click Actions


- (IBAction)buttonClicked:(id)sender
{
    self.selectedService = [sender tag];

    [UIView beginAnimations:@"fadeIn" context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    switch ([sender tag])
    {
        case FLICKR_TAG:
            FFTDebug(@"Clicked Flickr!");
            self.flickrButton.selected = YES;
            self.ffffoundButton.selected = NO;
            self.customButton.selected = NO;
            break;
        case FFFFOUND_TAG:
            FFTDebug(@"Clicked Ffffound!");
            self.flickrButton.selected = NO;
            self.ffffoundButton.selected = YES;
            self.customButton.selected = NO;
            break;
        case CUSTOM_TAG:
            FFTDebug(@"Clicked Http!");
            self.flickrButton.selected = NO;
            self.ffffoundButton.selected = NO;
            self.customButton.selected = YES;
            break;
        default:
            FFTError(@"Clicked Unknown Button!");
            break;
    }
    
    self.flickrView.alpha = self.flickrButton.selected ? 1 : 0;
    self.ffffoundView.alpha = self.ffffoundButton.selected ? 1 : 0;
    self.customView.alpha = self.customButton.selected ? 1 : 0;
    
    [UIView commitAnimations];
}

// PLAY button clicked.  Start off whole download and slideshow process.
- (IBAction)searchClicked:(id)sender
{
    // Check for blank custom field.
    NSString *customUrl = self.customTextField.text;
    if (self.selectedService == CUSTOM_TAG)
    {
        if (![customUrl hasPrefix:@"http://"])
        {
            customUrl = [@"http://" stringByAppendingString:customUrl];
        }
        if (![self isValidURL:customUrl])
        {
            FFTError(@"Clicked PLAY but not valid URL: %@", customUrl);
            return;
        }
    }
    
    // Save text fields in settings.
    self.searchRunner.searchUsername = self.usernameTextField.text;
    self.searchRunner.searchKeyword = self.keywordTextField.text;
    self.searchRunner.searchUrl = customUrl;
    
    PhotoSource *photoSource = nil;
    switch (self.selectedService)
    {
        case FLICKR_TAG:
            photoSource = [self flickrPhotoSource];
            FFTInfo(@"Found Flickr PhotoSource: %@", photoSource);
            break;
        case FFFFOUND_TAG:
            photoSource = [self ffffoundPhotoSource];
            FFTInfo(@"Found Ffffound PhotoSource: %@", photoSource);
            break;
        case CUSTOM_TAG:
            photoSource = [self photoSourceForPath:customUrl];
            FFTInfo(@"Found Custom PhotoSource: %@", photoSource);
            break;
        default:
            break;
    }
    
    [self runSearchForPhotoSource:photoSource];
    [self.frameViewController dismissModalViewControllerAnimated:YES];
}

- (IBAction)settingsClicked:(id)sender
{
    FFTDebug(@"Clicked Settings");
    self.settingsViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:self.settingsViewController animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    return YES;
}

/************************************************************************/

#pragma mark Overrides

//- (void)layoutControls
//{
//    // Smoothly rotate to new orientation.
//    [UIView beginAnimations:@"fadeIn" context:NULL];
//    [UIView setAnimationDuration:0.5];
//    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
//    [UIView setAnimationBeginsFromCurrentState:YES];
//    
//    if (self.interfaceOrientation == UIDeviceOrientationPortrait ||
//        self.interfaceOrientation == UIDeviceOrientationPortraitUpsideDown)
//    {
////        self.flickrKeywordView.frame = CGRectMake(0, 0, 280, 79);
////        self.flickrUsernameView.frame = CGRectMake(0, 89, 280, 79);
//        self.saveButton.frame = CGRectMake(46, 293, 227, 104);
////        self.servicesView.frame = CGRectMake(4, 20, 314, 50);
//    }
//    else if (self.interfaceOrientation == UIDeviceOrientationLandscapeLeft ||
//             self.interfaceOrientation == UIDeviceOrientationLandscapeRight)
//    {
////        self.flickrKeywordView.frame = CGRectMake(0, 0, 210, 79);
////        self.flickrUsernameView.frame = CGRectMake(230, 0, 210, 79);
//        self.saveButton.frame = CGRectMake(126, 200, 227, 104);
////        self.servicesView.frame = CGRectMake(84, 20, 314, 50);
//    }
//    
//    [UIView commitAnimations];
//}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.customTextField.delegate = self;
    self.keywordTextField.delegate = self;
    self.usernameTextField.delegate = self;
    
    NSString *username = self.searchRunner.searchUsername;
    if (username)
    {
        self.usernameTextField.text = username;
    }
    NSString *keyword = self.searchRunner.searchKeyword;
    if (keyword)
    {
        self.keywordTextField.text = keyword;
    }
    NSString *http = self.searchRunner.searchUrl;
    if (http)
    {
        self.customTextField.text = http;
    }
    
    // Initialize service.
    self.selectedService = FLICKR_TAG;

//    [self layoutControls];
//    [self registerForKeyboardNotifications];
}

//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
//{
//    [self layoutControls];
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview

    [_settingsViewController release]; _settingsViewController = nil;
}


#pragma mark -
#pragma mark Text Field Scrolling


- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    _activeField = nil;
}

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasHidden:)
                                                 name:UIKeyboardFrameBeginUserInfoKey object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    if (_keyboardShown)
        return;
    
    NSDictionary* info = [aNotification userInfo];
    FFTDebug(@"keyboard shown with notification params: %@", info);
    
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
    
    // Resize the scroll view (which is the root view of the window)
    CGRect viewFrame = [self.scrollView frame];
    CGFloat bottomBuffer = 320 - CGRectGetMaxY(self.flickrView.frame);
    viewFrame.origin.y -= (keyboardSize.height - bottomBuffer);
    
    [UIView beginAnimations:@"fadeIn" context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    self.scrollView.frame = viewFrame;
    
    [UIView commitAnimations];
    
    // Scroll the active text field into view.
    CGRect textFieldRect = [_activeField frame];
    [self.scrollView scrollRectToVisible:textFieldRect animated:YES];
    
    _keyboardShown = YES;
}


// Called when the UIKeyboardDidHideNotification is sent
- (void)keyboardWasHidden:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    FFTDebug(@"keyboard hidden with notification params: %@", info);
    
    // Get the size of the keyboard.
    NSValue* aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGSize keyboardSize = [aValue CGRectValue].size;
    
    // Reset the height of the scroll view to its original value
    CGRect viewFrame = [self.scrollView frame];
    CGFloat bottomBuffer = 320 - CGRectGetMaxY(self.flickrView.frame);
    viewFrame.origin.y += (keyboardSize.height - bottomBuffer);

    [UIView beginAnimations:@"fadeIn" context:NULL];
    [UIView setAnimationDuration:0.5];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    self.scrollView.frame = viewFrame;
    
    [UIView commitAnimations];
    
    _keyboardShown = NO;
}

/************************************************************************/

#pragma mark Controller Property Initializers.

- (SettingsViewController*)settingsViewController
{
    if (_settingsViewController == nil)
    {
        NSString *nibName = self.appDelegate.isIPad ? @"SettingsView-ipad" : @"SettingsView-iphone";
        _settingsViewController = [[SettingsViewController alloc] initWithNibName:nibName bundle:nil];
    }
    return _settingsViewController;
}

@end
