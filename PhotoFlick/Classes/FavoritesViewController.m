//
//  FavoritesViewController.m
//  PhotoFrame
//
//  Created by John Sheets on 9/25/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "FavoritesViewController.h"

@implementation FavoritesViewController

@synthesize countLabel = _countLabel;
@synthesize emailButton = _emailButton;

- (void)dealloc
{
    [_countLabel release], _countLabel = nil;
    [_emailButton release], _emailButton = nil;
    
    [super dealloc];
}

- (void)updateCount
{
    NSUInteger count = [[self.appDelegate.dataManager favoritePhotos] count];
    self.countLabel.text = [NSString stringWithFormat:@"%i", count];
//    self.emailButton.hidden = count == 0;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateCount];
}

- (IBAction)backClicked:(id)sender
{
    FFTDebug(@"Clicked Back");
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)clearClicked:(id)sender
{
    FFTDebug(@"Clicked Clear All");
    EVENT_FAVORITES_CLEAR;
    [self.appDelegate.dataManager unfavoriteAll];
    [self updateCount];
}

- (NSString *)favoritesEmailBody
{
    NSMutableString *body = [NSMutableString string];
    
    NSArray *favorites = [self.appDelegate.dataManager favoritePhotos];
    [body appendFormat:@"My Favorite %i Images from PhotoFrame:\n\n", [favorites count]];
    for (Photo *image in favorites)
    {
        [body appendFormat:@"Title: %@\n%@\n\n", image.title, image.remoteUrl];
    }
    
    FFTInfo(@"Emailing Favorites Message Body: %@", body);
    return body;
}

- (IBAction)emailClicked:(id)sender
{
    FFTDebug(@"Clicked Email");
    
    if ([MFMailComposeViewController canSendMail])
    {
        FFTInfo(@"Sending Email");
        FFTInfo(@"Favorites email:\n%@", [self favoritesEmailBody]);
        
        // Bring up email pane.
        MFMailComposeViewController *emailer = [[[MFMailComposeViewController alloc] init] autorelease];
        [emailer setSubject:@"PhotoFrame Favorites"];
        [emailer setMessageBody:[self favoritesEmailBody] isHTML:NO];
        emailer.mailComposeDelegate = self;
        [self presentModalViewController:emailer animated:YES];
        EVENT_FAVORITES_SEND;
    }
    else
    {
        // Pop up warning dialog.
        FFTError(@"Unable to send Email");
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Error" message:@"Email is not configured on this device" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:NULL];
        [alert show];
        [alert release];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    FFTInfo(@"Sent email");
    if (error)
    {
        UIAlertView *cantMailAlert = [[UIAlertView alloc] initWithTitle:@"Mail error" message: [error localizedDescription] delegate:NULL cancelButtonTitle:@"OK" otherButtonTitles:NULL];
        [cantMailAlert show];
        [cantMailAlert release];
    }
    
//    NSString *resultString;
//    switch (result)
//    {
//        case MFMailComposeResultSent: resultString = @"Sent mail"; break;
//        case MFMailComposeResultSaved: resultString = @"Saved mail"; break;
//        case MFMailComposeResultCancelled: resultString = @"Cancelled mail"; break;
//        case MFMailComposeResultFailed: resultString = @"Mail failed"; break;
//    };
    
    [controller dismissModalViewControllerAnimated:YES];
    // FIXME: Crashes if we release emailer here.
//    [controller release];
}

@end
