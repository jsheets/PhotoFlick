//
//  MMTransitionManager.m
//  PhotoFrame
//
//  Created by John Sheets on 7/27/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

//
// DELETE ME?!?
//

#import "MMTransitionManager.h"

#define DEFAULT_DURATION (0.5)

@implementation MMTransitionManager

- (void)showOverlay:(UIView*)view withDuration:(CGFloat)duration
{
    [UIView beginAnimations:@"showOverlay" context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    view.alpha = 0.8;
    [UIView commitAnimations];
}

- (void)hideOverlay:(UIView*)view withDuration:(CGFloat)duration
{
    [UIView beginAnimations:@"hideOverlay" context:NULL];
    [UIView setAnimationDuration:duration];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    view.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)showOverlay:(UIView*)view
{
    [self showOverlay:view withDuration:DEFAULT_DURATION];
}

- (void)hideOverlay:(UIView*)view
{
    [self hideOverlay:view withDuration:DEFAULT_DURATION];
}

// Zoom in so all edges of the picture are at least touching the frame.
- (CGAffineTransform)fullScreenTransform:(CGSize)imageSize inFrameSize:(CGSize)frameSize
{
    FFTDebug(@"XMGR FS Image size: %@", NSStringFromCGSize(imageSize));
    FFTDebug(@"XMGR FS Frame size: %@", NSStringFromCGSize(frameSize));
    if (imageSize.width == 0 || imageSize.height == 0)
    {
        return CGAffineTransformIdentity;
    }

    // FIXME: Should scale downwards if image too large.
    CGFloat xScale = MAX(frameSize.width / imageSize.width, 1.0);
    CGFloat yScale = MAX(frameSize.height / imageSize.height, 1.0);
    CGFloat scale = MAX(xScale, yScale);
    
    FFTDebug(@"XMGR SCALE: %.4f --> NEW (%.4f, %.4f)", scale, imageSize.width * scale, imageSize.height * scale);
    return CGAffineTransformMakeScale(scale, scale);
}


- (CGAffineTransform)panZoomTransform:(CGSize)imageSize inFrameSize:(CGSize)frameSize
{
    FFTDebug(@"XMGR PZ Image size: %@", NSStringFromCGSize(imageSize));
    FFTDebug(@"XMGR PZ Frame size: %@", NSStringFromCGSize(frameSize));
    
    if (imageSize.width > imageSize.height)
    {
        FFTDebug(@"XMGR wider by: %.4f", imageSize.width / imageSize.height);
    }
    else
    {
        FFTDebug(@"XMGR taller by: %.4f", imageSize.height / imageSize.width);
    }
    
    // Translate +/- 40; scale 1.1 - 1.4.
    CGFloat x = (random() % 80) + 40;
    CGFloat y = (random() % 80) + 40;
    CGFloat scale = (random() % 4) / 10.0 + 1.1;
    FFTDebug(@"Random transform (%.1f, %.1f) x %.1f", x, y, scale);
    
    CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
    transform = CGAffineTransformTranslate(transform, x, y);
    return transform;
}


- (void)panZoomView:(UIImageView*)view inParentView:(UIView*)parentView
{
//    view.transform = [self fullScreenTransform:view.image.size inFrameSize:parentView.frame.size];
    
    FFTDebug(@"XMGR: Pan+Zoom Transition");
    [UIView beginAnimations:@"kenBurns" context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationDuration:4.2];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    
    view.transform = CGAffineTransformConcat(view.transform, [self panZoomTransform:view.image.size inFrameSize:parentView.frame.size]);
    
    [UIView commitAnimations];
}

- (void)fadeView:(UIView*)view
{
    FFTDebug(@"XMGR: Fade Transition");
    
}

- (void)snapView:(UIView*)view
{
    FFTDebug(@"XMGR: Snap Transition");
    
}

@end
