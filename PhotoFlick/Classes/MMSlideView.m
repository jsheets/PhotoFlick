//
//  MMSlideView.m
//  PhotoFrame
//
//  Created by John Sheets on 12/19/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMSlideView.h"

#import "Photo.h"
#import "PhotoFlickAppDelegate.h"

@implementation MMSlideView

@synthesize photo = _photo;
@synthesize imageView = _imageView;
@synthesize spinner = _spinner;

// Create new slide view with imageView and spinner.
- (id)initWithFrame:(CGRect)frame
{
    // Frame is already offset within slideshow view.
    if (self = [super initWithFrame:frame])
    {
        // Initialization code
        PhotoFlickAppDelegate *appDelegate = (PhotoFlickAppDelegate*)[[UIApplication sharedApplication] delegate];
        CGSize size = [appDelegate appScreenSizeForPortrait:YES scaled:NO];
        CGRect imageFrame = CGRectMake(0, 0, size.width, size.height);
        self.imageView = [[[UIImageView alloc] initWithFrame:imageFrame] autorelease];
        [self addSubview:self.imageView];
        
        // Spinners, always spinning...spin, spinner, spin!
        self.spinner = [[[UIActivityIndicatorView alloc]
                        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge]
                        autorelease];
        
        [self resizeSpinner];
        
        [self addSubview:self.spinner];
        [self.spinner startAnimating];

        // The photo is blank until later assigned.  Slide views are pooled and
        // moved around as the tray slides forward.  Photos are removed and
        // replaced in the slideshow views.
    }

    return self;
}

- (void)dealloc
{
    [_photo release], _photo = nil;
    [_imageView release], _imageView = nil;
    [_spinner release], _spinner = nil;

    [super dealloc];
}

- (void)resizeSpinner
{
    self.spinner.frame = CGRectMake(self.frame.size.width * 0.5 - (37/2),
                                    self.frame.size.height * 0.5 - (37/2), 37, 37);
}

// If blanking out the photo, start up the spinner.
// Called from slideshow view init to set photos before downloading.
- (void)setPhoto:(Photo*)photo
{
    if (photo == nil)
    {
        // Clear out photo image.
        [_photo release], _photo = nil;
        self.imageView.image = nil;
        [self.spinner startAnimating];
    }
    else
    {
        [photo retain];
        [_photo release];
        _photo = photo;

         // Immediately copy over image from Photo to Display image.
        [self setDisplayImage];
    }
}

- (BOOL)hasDisplayImage
{
    return self.imageView != nil && self.imageView.image != nil;
}

- (void)setDisplayImage
{
    UIImage *image = [_photo image];
    if (image.CGImage)
    {
        // Find the slide's UIImageView and display the new image there.
        FFTInfo(@"Loading Photo image into slide view: %@", _photo.title);
        
        self.imageView.image = image;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self.spinner stopAnimating];
    }
    else
    {
        FFTError(@"Download completed but no Photo UIImage found: %@", _photo.title);
    }
}

- (void)unloadDisplayImage
{
    if ([self hasDisplayImage])
    {
        // Blank out the UIImage.
        self.imageView.image = nil;
        [self.spinner startAnimating];
    }
}


// Has already been downloaded.
- (BOOL)hasPhotoImage
{
    return self.photo != nil && [self.photo image] != nil;
}


@end
