//
//  MMTransitionManager.h
//  PhotoFrame
//
//  Created by John Sheets on 7/27/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MMTransitionManager : NSObject
{

}

- (void)showOverlay:(UIView*)view;
- (void)showOverlay:(UIView*)view withDuration:(CGFloat)duration;

- (void)hideOverlay:(UIView*)view;
- (void)hideOverlay:(UIView*)view withDuration:(CGFloat)duration;

- (void)panZoomView:(UIImageView*)view inParentView:(UIView*)frameSize;
- (void)fadeView:(UIView*)view;
- (void)snapView:(UIView*)view;

- (CGAffineTransform)fullScreenTransform:(CGSize)imageSize inFrameSize:(CGSize)frameSize;
- (CGAffineTransform)panZoomTransform:(CGSize)imageSize inFrameSize:(CGSize)frameSize;

@end
