//
//  MMTrayLogic.h
//  PhotoFrame
//
//  Created by John Sheets on 2/20/10.
//  Copyright 2010 MobileMethod, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MMTrayLogic : NSObject
{
    BOOL _activeSearch;
    BOOL _searchRunning;
    NSInteger _trayPosition;
    NSInteger _trayWidth;
    NSInteger _bumperWidth;
    NSInteger _saveWidth;
    CGSize _imageSize;
    NSInteger _prevTrayPosition;
    NSInteger _currTrayPosition;
}

@property (nonatomic, assign) BOOL activeSearch;
@property (nonatomic, assign) BOOL searchRunning;
@property (nonatomic, assign) NSInteger trayPosition;
@property (nonatomic, assign) NSInteger trayWidth;
@property (nonatomic, assign) NSInteger bumperWidth;
@property (nonatomic, assign) NSInteger saveWidth;
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) NSInteger prevTrayPosition;
@property (nonatomic, assign) NSInteger currTrayPosition;
@property (nonatomic, readonly) BOOL scrollVector;

@property (nonatomic, readonly) NSInteger jumpWidth;

- (CGSize)contentSize:(NSInteger)maxSlideCount;
- (CGRect)rectForSlide:(NSInteger)slideIndex;
- (NSInteger)nextTrayIndex:(BOOL)forward;
- (BOOL)isForward;
- (void)jumpTray:(BOOL)forward;
- (BOOL)isBlankForDirection:(BOOL)forward atIndex:(NSInteger)trayIndex;
- (NSInteger)oldTrayIndex:(BOOL)forward forNewIndex:(NSInteger)index;

- (NSInteger)atTrayIndex:(UIView*)scrollView;
- (NSInteger)atPhotoIndex:(UIView*)scrollView;
- (BOOL)isAdjacent:(NSInteger)trayIndex;
- (BOOL)isTooWide:(CGFloat)contentWidth;
@end
