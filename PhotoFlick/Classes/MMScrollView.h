//
//  MMScrollView.h
//  PhotoFrame
//
//  Created by John Sheets on 8/17/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

@protocol MMScrollViewDelegate;

@interface MMScrollView : UIScrollView <UIScrollViewDelegate>
{
    id <MMScrollViewDelegate> _scrollDelegate;
    
    // Touch detection
    CGPoint _tapLocation;
    BOOL _multipleTouches;
    BOOL _twoFingerTapIsPossible;
}

@property (nonatomic, assign) IBOutlet id <MMScrollViewDelegate> scrollDelegate;

@end


/*
 Protocol for handling tap detection.
 */
@protocol MMScrollViewDelegate <NSObject>

@optional
- (void)imageScrollView:(MMScrollView *)view gotSingleTapAtPoint:(CGPoint)tapPoint;
- (void)imageScrollView:(MMScrollView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint;
- (void)imageScrollView:(MMScrollView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint;
@end

