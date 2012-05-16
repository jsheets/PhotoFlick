//
//  FlickrCustomSearchViewController.h
//  PhotoFrame
//
//  Created by John Sheets on 4/11/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import "MMSearchController.h"

@interface FlickrCustomSearchViewController : MMSearchController <UITextFieldDelegate>
{
    UITextField *_keywordTextField;
    UITextField *_usernameTextField;
}

@property (nonatomic, retain) IBOutlet UITextField *keywordTextField;
@property (nonatomic, retain) IBOutlet UITextField *usernameTextField;

@end
