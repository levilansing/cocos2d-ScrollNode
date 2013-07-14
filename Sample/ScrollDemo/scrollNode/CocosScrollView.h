//
//  CocosScrollView.h
//  A UISCrollView imitator for Cocos2d
//
//  Created by Levi on 5/25/13.
//
//    The MIT License (MIT)
//
//    Copyright (c) 2013 Levi Lansing, zephLabs.org
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.


#import <UIKit/UIKit.h>
#import "cocos2d.h"

@interface CocosScrollView : UIView {
    NSMutableSet *touchList;
    UITouch *draggingTouch;
    CGPoint startPoint;
    CGPoint lastPoint;
    CGPoint velocity;
    CGPoint lastVelocity;
    ccTime decelTime;
    CFTimeInterval lastTime;
    BOOL atRest;
    BOOL xLocked;
    BOOL yLocked;
}

// access the node that draws the scrollbar interface
@property (nonatomic, readonly) CCNodeRGBA *interfaceNode;
// check if the scrollview is currently being dragged
@property (nonatomic, readonly) BOOL dragging;
// the rect that represents the scroll view frame (not the content)
@property (nonatomic) CGRect scrollViewFrame;
// the current scroll position
@property (nonatomic) CGPoint scrollPosition;
// the size of the scrollable content
@property (nonatomic) CGSize contentSize;
// the number of pixels a touch must move before dragging begins
@property (nonatomic) float dragThreshold;
// the coefficient of friction for slowing scrolling content
@property (nonatomic) float friction;
// the spring constant used when snapping back from scrolling too far
@property (nonatomic) float springConstant;

// create the scroll view with a desired frame
+ (CocosScrollView*)createWithFrame:(CGRect)frame;
// set the scroll view frame (automatically set by ScrollNode)
- (void)setFrameInGLCoords:(CGRect)frame;

// get the content offset (inverse of scroll position, in Cocos2d coordinates)
- (CGPoint)getOffset;

// make the scrollbars appear and fade out
- (void)flashScrollbars;
// show or hide the interface (scrollbars)
- (BOOL)shouldShowInterface;

@end

@interface CSVInterfaceNode : CCNodeRGBA {
    CocosScrollView *scrollView;
    float uiVisible;
}

- (void)setScrollView:(CocosScrollView*)sv;
- (void)flashScrollbars;

@end