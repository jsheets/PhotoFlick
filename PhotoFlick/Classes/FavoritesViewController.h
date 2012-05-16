//
//  FavoritesViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 9/25/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "MMViewController.h"

@interface FavoritesViewController : MMViewController <MFMailComposeViewControllerDelegate>
{
    UILabel *_countLabel;
    UIButton *_emailButton;
}

@property (nonatomic, retain) IBOutlet UILabel *countLabel;
@property (nonatomic, retain) IBOutlet UIButton *emailButton;

- (IBAction)backClicked:(id)sender;
- (IBAction)clearClicked:(id)sender;
- (IBAction)emailClicked:(id)sender;

@end
