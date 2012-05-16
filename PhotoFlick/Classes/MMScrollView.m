//
//  MMScrollView.m
//  PhotoFrame
//
//  Created by John Sheets on 8/17/09.
//  Copyright 2009 MobileMethod, LLC. All rights reserved.
//

#import "MMScrollView.h"

#define DOUBLE_TAP_DELAY 0.35


CGPoint midpointBetweenPoints(CGPoint a, CGPoint b)
{
    CGFloat x = (a.x + b.x) / 2.0;
    CGFloat y = (a.y + b.y) / 2.0;
    return CGPointMake(x, y);
}


@implementation MMScrollView

@synthesize scrollDelegate = _scrollDelegate;


#pragma mark Lifecycle Methods


//- (id)initWithFrame:(CGRect)frame
- (id)initWithCoder:(NSCoder*)coder
{
    if (self = [super initWithCoder:coder])
    {
        // Initialization code
        [self setUserInteractionEnabled:YES];
        [self setMultipleTouchEnabled:YES];
        _twoFingerTapIsPossible = YES;
        _multipleTouches = NO;
        
        self.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [_scrollDelegate release];
    [super dealloc];
}


#pragma mark -
#pragma mark Private Handler Methods
#pragma mark -


- (void)handleSingleTap
{
    if ([_scrollDelegate respondsToSelector:@selector(imageScrollView:gotSingleTapAtPoint:)])
    {
        [_scrollDelegate imageScrollView:self gotSingleTapAtPoint:_tapLocation];
    }
}

- (void)handleDoubleTap
{
    if ([_scrollDelegate respondsToSelector:@selector(imageScrollView:gotDoubleTapAtPoint:)])
    {
        [_scrollDelegate imageScrollView:self gotDoubleTapAtPoint:_tapLocation];
    }
}

- (void)handleTwoFingerTap
{
    if ([_scrollDelegate respondsToSelector:@selector(imageScrollView:gotTwoFingerTapAtPoint:)])
    {
        [_scrollDelegate imageScrollView:self gotTwoFingerTapAtPoint:_tapLocation];
    }
}


#pragma mark -
#pragma mark Multitouch Handlers


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // cancel any pending handleSingleTap messages 
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(handleSingleTap)
                                               object:nil];
    
    // update our touch state
    if ([[event touchesForView:self] count] > 1)
    {
        _multipleTouches = YES;
    }
    if ([[event touchesForView:self] count] > 2)
    {
        _twoFingerTapIsPossible = NO;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    BOOL allTouchesEnded = ([touches count] == [[event touchesForView:self] count]);
    
    // first check for plain single/double tap, which is only possible if we haven't seen multiple touches
    if (!_multipleTouches)
    {
        UITouch *touch = [touches anyObject];
        _tapLocation = [touch locationInView:self];
        
        if ([touch tapCount] == 1)
        {
            [self performSelector:@selector(handleSingleTap)
                       withObject:nil
                       afterDelay:DOUBLE_TAP_DELAY];
        }
        else if([touch tapCount] == 2)
        {
            [self handleDoubleTap];
        }
    }
    else if (_multipleTouches && _twoFingerTapIsPossible)
    {
        // check for 2-finger tap if we've seen multiple touches and
        // haven't yet ruled out that possibility
        if ([touches count] == 2 && allTouchesEnded)
        {
            // case 1: this is the end of both touches at once 
            int i = 0; 
            int tapCounts[2]; CGPoint tapLocations[2];
            for (UITouch *touch in touches)
            {
                tapCounts[i]    = [touch tapCount];
                tapLocations[i] = [touch locationInView:self];
                i++;
            }
            if (tapCounts[0] == 1 && tapCounts[1] == 1)
            { // it's a two-finger tap if they're both single taps
                _tapLocation = midpointBetweenPoints(tapLocations[0], tapLocations[1]);
                [self handleTwoFingerTap];
            }
        }
        else if ([touches count] == 1 && !allTouchesEnded)
        {
            // case 2: this is the end of one touch, and the other hasn't ended yet
            UITouch *touch = [touches anyObject];
            if ([touch tapCount] == 1)
            {
                // if touch is a single tap, store its location so we
                // can average it with the second touch location
                _tapLocation = [touch locationInView:self];
            }
            else
            {
                _twoFingerTapIsPossible = NO;
            }
        }
        else if ([touches count] == 1 && allTouchesEnded)
        {
            // case 3: this is the end of the second of the two touches
            UITouch *touch = [touches anyObject];
            if ([touch tapCount] == 1)
            {
                // if the last touch up is a single tap, this was a 2-finger tap
                _tapLocation = midpointBetweenPoints(_tapLocation, [touch locationInView:self]);
                [self handleTwoFingerTap];
            }
        }
    }
    
    // if all touches are up, reset touch monitoring state
    if (allTouchesEnded)
    {
        _twoFingerTapIsPossible = YES;
        _multipleTouches = NO;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _twoFingerTapIsPossible = YES;
    _multipleTouches = NO;
}


@end


