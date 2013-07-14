//
//  ScrollNode.m
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

#import "ScrollNode.h"
#import "cocos2d.h"

#pragma mark - ClippedMenu -

@implementation ClippedMenu

- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CCDirector *director = [CCDirector sharedDirector];
    CGPoint pt = [touch locationInView: director.view];
    pt = [director convertToGL:pt];

    // if our touch is not inside our visible area, don't process it!
    if (!CGRectContainsPoint(clipRect, pt))
        return NO;
    
    return [super ccTouchBegan:touch withEvent:event];
}

@end




#pragma mark - ScrollNode -

@implementation ScrollNode

// Disabling clipping is only useful if the ScrollNode fills the entire screen
@synthesize clipping = clipping_;
@synthesize scrollView = _scrollView;
@synthesize menu = _menu;
@synthesize container = _container;
@synthesize interfaceNode = _interfaceNode;

+ (ScrollNode*)nodeWithSize:(CGSize)size {
    ScrollNode *node = [ScrollNode node];
    node.contentSize = size;
    return node;
}

- (id)init
{
	if ((self=[super init]) ) {
        
        clipping_ = YES;
        _scrollView = CC_ARC_RETAIN([CocosScrollView createWithFrame:CGRectMake(0, 0, 100, 100)]);
        
        _container = CC_ARC_RETAIN([CCNode node]);
        _container.position = ccp(0,0);
        _container.anchorPoint = ccp(0,0);
        [self addChild:_container];
        
        _menu = CC_ARC_RETAIN([ClippedMenu menuWithItems:nil]);
        _menu->scrollView = _scrollView;
        _menu.anchorPoint = ccp(0,0);
        _menu.position = ccp(0,0);
        [self addChild:_menu];
        
        contentOffset = ccp(0,0);
        _hideInvisibleItems = YES;

        _interfaceNode = CC_ARC_RETAIN(_scrollView.interfaceNode);
        [self addChild:_interfaceNode];

    }
    return self;
}

- (void)dealloc
{
    CC_ARC_RELEASE(_scrollView);
    CC_ARC_RELEASE(_menu);
    CC_ARC_RELEASE(_container);
    CC_ARC_RELEASE(_interfaceNode);
    [super dealloc];
}

- (void)onEnter
{
    // schedule a late update so hopefully any manual adjustments to the scroll view positions are completed
    [self scheduleUpdateWithPriority:1000];
    [self enableScrollView:YES];
    [super onEnter];
}

- (void)onExit
{
    [self unscheduleUpdate];
    [self enableScrollView:NO];
    [super onExit];
}


- (void)update:(ccTime)dt {
    // offset all children by the content offset value
    CGPoint offset = ccpAdd(contentOffset,[_scrollView getOffset]);
    CCNode *node;
    CCARRAY_FOREACH(_children, node) {
        if (node != _interfaceNode) {
            if (offset.x != _position.x || offset.y != _position.y) {
                node.position = offset;
            }
        }
    }
    
    if (!_hideInvisibleItems)
        return;
    
    // automatically show and hide menu items that are outside the clipping area
    // (assumes menu item content size is accurate even if the actual node is rotated)
    CCARRAY_FOREACH(_menu.children, node) {
        
        
        float top = node->_position.y + (1-node->_anchorPoint.y)*node->_contentSize.height*node->_scaleY;
        if (top+offset.y < 0) {
            node.visible = NO;
            continue;
        }

        float bottom = node->_position.y - (node->_anchorPoint.y)*node->_contentSize.height*node->_scaleY;
        if (bottom+offset.y > _contentSize.height) {
            node.visible = NO;
            continue;
        }

        float left = node->_position.x - (node->_anchorPoint.x)*node->_contentSize.width*node->_scaleX;
        if (left+offset.x > _contentSize.width) {
            node.visible = NO;
            continue;
        }

        float right = node->_position.x + (1-node->_anchorPoint.x)*node->_contentSize.width*node->_scaleX;
        if (right+offset.x < 0) {
            node.visible = NO;
            continue;
        }
        node.visible = YES;
    }
}


- (void)addChild:(CCNode *)node z:(NSInteger)z tag:(NSInteger)tag {
    // our only children are the menu, container, and interface overlay
    if (node == _menu || node == _container || node==_interfaceNode) {
        [super addChild:node z:z tag:tag];
    } else {
        // all other children are added to our container
        [_container addChild:node z:z tag:tag];
    }
}

- (void)removeChild: (CCNode*)child cleanup:(BOOL)cleanup {
    if ( [_children containsObject:child] )
        [super removeChild:child cleanup:cleanup];
    else
        [_container removeChild:child cleanup:cleanup];
}

- (void)removeAllChildrenWithCleanup:(BOOL)cleanup {
    [_container removeAllChildrenWithCleanup:cleanup];
    [_menu removeAllChildrenWithCleanup:cleanup];
    [_interfaceNode removeAllChildrenWithCleanup:cleanup];
}


- (void)enableScrollView:(BOOL)enabled {
    // add or remove the UIView that will handle our touches
    // (to be able to cancel cocos2d touches, we need to manage them outside cocos2d)
    if (enabled) {
        if (!_scrollView.superview) {
            [[CCDirector sharedDirector].view addSubview:_scrollView];
        }
        self.interfaceNode.visible = self.showScrollBars;
    } else {
        if (_scrollView.superview) {
            [_scrollView removeFromSuperview];
        }
        self.interfaceNode.visible = NO;
    }
}

- (void)setShowScrollBars:(BOOL)showScrollBars {
    _showScrollBars = showScrollBars;
    self.interfaceNode.visible = showScrollBars;
}

- (void)setScrollViewContentSize:(CGSize)size {
    _scrollView.contentSize = size;
}

// set the content area by a rect which will apply an offset to the content so it fits
// in the scroll view even if the origin is not the top/left of the scroll view area
- (void)setScrollViewContentRect:(CGRect)content {
    _scrollView.contentSize = content.size;
    contentOffset = ccp(-content.origin.x, -content.origin.y-content.size.height+self.contentSize.height);
    // moving the offset requires we update our positions (avoids 1 frame flicker)
    [self update:0];
}

// Compute the content rect by combining the bounding boxes of the menu's and container's children
- (CGRect)calculateScrollViewContentRect {
    CGAffineTransform nodeToWorld = [self.menu nodeToWorldTransform];
    CGRect bb = CGRectNull;
    bb = calculateBoundingBox(self.menu, bb, nodeToWorld);
    nodeToWorld = [self.container nodeToWorldTransform];
    bb = CGRectUnion(bb, calculateBoundingBox(self.container, bb, nodeToWorld));
    return CGRectApplyAffineTransform(bb, [self worldToNodeTransform]);
}

CGRect calculateBoundingBox(CCNode* node, CGRect bb, CGAffineTransform nodeToWorld) {
    CCNode *child;
    CCARRAY_FOREACH(node.children, child) {
        CGAffineTransform childToWorld = CGAffineTransformConcat([child nodeToParentTransform], nodeToWorld);
        CGRect rect = CGRectMake(0, 0, child->_contentSize.width, child->_contentSize.height);
        if (rect.size.width > 0 && rect.size.height > 0) {
            rect = CGRectApplyAffineTransform(rect, childToWorld);
            bb = CGRectUnion(bb, rect);
        }
        if (child.children.count)
            bb = calculateBoundingBox(child, bb, childToWorld);
    }
    return bb;
}

- (void)updateClipRect {
    
    CGPoint clipReferencePoint = [self convertToWorldSpace:ccp(0,0)];
    clipRect = CGRectMake(clipReferencePoint.x, clipReferencePoint.y,
                          _contentSize.width * _scaleX, _contentSize.height * _scaleY);
    
    // set the scrollview frame before we adjust it for GL_SCISSOR_TEST
    _menu->clipRect = clipRect;
    [_scrollView setFrameInGLCoords:clipRect];
        
    // convert to retina coordinates if needed
    clipRect = CC_RECT_POINTS_TO_PIXELS(clipRect);
}

- (void)setOpacity:(GLubyte)newOpacity {
    [super setOpacity:newOpacity];
    _interfaceNode.opacity = self.opacity;
}

- (void)visit {
    if (!_visible)
        return;
    
    // in order to handle all cases, we recalculate our cliping rect every frame
    [self updateClipRect];

    if (clipping_) {
        glEnable(GL_SCISSOR_TEST);
        glScissor(clipRect.origin.x, clipRect.origin.y,
                  clipRect.size.width, clipRect.size.height);
        
        [super visit];
        
        glDisable(GL_SCISSOR_TEST);
    } else {
        [super visit];
    }
}

@end
