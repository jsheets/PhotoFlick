//
//  MMSlideView.h
//  PhotoFrame
//
//  Created by John Sheets on 12/19/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

@class Photo;

// A single slide.
@interface MMSlideView : UIView
{
    Photo *_photo;
    UIImageView *_imageView;
    UIActivityIndicatorView *_spinner;
}

@property (nonatomic, retain) Photo *photo;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *spinner;

//- (void)checkImage;
- (void)setPhoto:(Photo*)photo;
- (BOOL)hasDisplayImage;
- (void)setDisplayImage;
- (void)unloadDisplayImage;
- (BOOL)hasPhotoImage;
- (void)resizeSpinner;

@end
