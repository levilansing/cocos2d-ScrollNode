//
//  ScrollNode.h
//  A clipping node with a built in scroll view, designed for menus
//
//  Created by Levi on 5/24/13.
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

#import "CCNode.h"
#import "CCMenu.h"
#import "CocosScrollView.h"

#pragma mark - ClippedMenu -

@interface ClippedMenu : CCMenu {
    @public
    CGRect clipRect;
    CocosScrollView *scrollView;
}
@end

#pragma mark - ScrollNode -

@interface ScrollNode : CCNodeRGBA {
    BOOL clipping_;
    CGRect clipRect;
    CGPoint contentOffset;
    
    ClippedMenu *_menu;
}

// creates a scroll node and sets the contentSize
+ (ScrollNode*)nodeWithSize:(CGSize)size;

// clips drawing of the content of the ScrollNode to ScrollNode.contentSize
@property (nonatomic, assign) BOOL clipping;
// hides menu items that are scrolled outside the clipping area (significantly improves performance)
@property (nonatomic, assign) BOOL hideInvisibleItems;
// the actual scroll view. access the scroll view for additional options
@property (nonatomic, readonly) CocosScrollView *scrollView;
// the built in menu
@property (nonatomic, readonly) CCMenu *menu;
// the container used for all nodes that are not added to the menu
@property (nonatomic, readonly) CCNode *container;
// the interface node that draws the scrollbars
@property (nonatomic, readonly) CCNodeRGBA *interfaceNode;
// show or hide the scroll bars
@property (nonatomic) BOOL showScrollBars;

// enable or disable the scroll view. when disabled, the interface hides and touches act normal (no scrolling)
- (void)enableScrollView:(BOOL)enabled;
// set the size of the scrollable content (without affecting the origin)
- (void)setScrollViewContentSize:(CGSize)size;
// set the rect of the scrollable content. uses the origin as the top left.
- (void)setScrollViewContentRect:(CGRect)content;
// calculate the scrollable content's bounding box based on the menu and content children
- (CGRect)calculateScrollViewContentRect;

@end
