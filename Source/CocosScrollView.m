//
//  CocosScrollView.m
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


#import "CocosScrollView.h"

#define SIGNVAL(n) (((n) < 0) ? -1 : ((n) > 0) ? 1 : 0)

#pragma mark - CocosScrolLView -

@implementation CocosScrollView

+ (CocosScrollView*)createWithFrame:(CGRect)frame {
    CGSize size = [[CCDirector sharedDirector] winSize];
    CocosScrollView *scrollView = [[CocosScrollView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];

    CGPoint pt = [[CCDirector sharedDirector] convertToUI:frame.origin];
    pt.y -= frame.size.height;
    frame.origin = pt;
    scrollView.scrollViewFrame = frame;

    return scrollView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _interfaceNode = CC_ARC_RETAIN([CSVInterfaceNode node]);
        [(CSVInterfaceNode*)_interfaceNode setScrollView:self];
        touchList = CC_ARC_RETAIN([NSMutableSet setWithCapacity:15]);
        
        self.dragThreshold = 10;
        velocity = ccp(0,0);
        _friction = 0.96;
        _springConstant = 90;
        
        self.opaque = NO;
        self.clearsContextBeforeDrawing = NO;
        self.clipsToBounds = YES;
        
        [[CCDirector sharedDirector].scheduler scheduleUpdateForTarget:self priority:-100 paused:NO];
    }
    return self;
}

- (void)dealloc {
    [[CCDirector sharedDirector].scheduler unscheduleUpdateForTarget:self];
    CC_ARC_RELEASE(touchList);
    CC_ARC_RELEASE(_interfaceNode);
    [super dealloc];
}

- (void)setFrameInGLCoords:(CGRect)frame {
    CGPoint pt = [[CCDirector sharedDirector] convertToUI:frame.origin];
    pt.y -= frame.size.height;
    frame.origin = pt;
    self.scrollViewFrame = frame;
}


/*
 * Returns the offset of the scrollview as a point
 */
- (CGPoint) getOffset
{
    CGPoint offset = self.scrollPosition;
    
    // flip our y coordinate so we end up with a zero based offset
    offset.y += [[CCDirector sharedDirector] winSize].height;
    offset = [[CCDirector sharedDirector] convertToGL: offset];
    
    // offset is the inverse of the scroll position
    offset.y *= -1;
    offset.x *= -1;
    
    return offset;
}

- (void)update:(ccTime)dt {
    float scrollSizeY = MAX(0, _contentSize.height - self.scrollViewFrame.size.height);
    float scrollSizeX = MAX(0, _contentSize.width - self.scrollViewFrame.size.width);

    // if the scroll position is outside the normal scroll positions while at rest, spring back
    if (atRest && (_scrollPosition.y < 0 || _scrollPosition.y > scrollSizeY || _scrollPosition.x < 0 || _scrollPosition.x > scrollSizeX)) {
        atRest = NO;
    }
    
    if (!self.dragging && !atRest) {
        int nResting = 0;

        // apply current velocity to scroll position
        [self offsetY:velocity.y*dt];
        [self offsetX:velocity.x*dt];
        
        // calculate drag for this frame from friction
        float drag = powf(powf(_friction, 60), dt);

        if (yLocked) {
            // change y-axis to at rest if locked
            velocity.y = 0;
            nResting++;
        } else {
            // check if we are over scrolled
            BOOL overScrolled = NO;
            if ((_scrollPosition.y < 0 || _scrollPosition.y > scrollSizeY)) {
               
                // apply a spring force to slow down our velocity
                float target = (_scrollPosition.y < 0 ? 0 : scrollSizeY);
                float d = target - _scrollPosition.y;
                float a = (d * _springConstant) / 1;     // mass of 1
                velocity.y += a*dt;
                
                // if velocity is moving with our spring, stop using velocity while we spring back
                if (SIGNVAL(velocity.y) == SIGNVAL(a)) {
                    velocity.y = 0;
                }
                // spring back with fake physics based on the spring constant
                _scrollPosition.y -= (_scrollPosition.y-target) * dt/(10/_springConstant);

                if (fabsf(_scrollPosition.y-target) > 0.05)
                    overScrolled = YES;
            }
            // apply friction to our velocity
            velocity.y = velocity.y * drag;

            // check if we should be resting
            if (!overScrolled && fabsf(velocity.y) < 0.5) {
                velocity.y = 0;
                _scrollPosition.y = roundf(_scrollPosition.y);
                nResting++;
            }
        }
        
        if (xLocked) {
            // change x-axis to at rest if locked
            velocity.x = 0;
            nResting++;
        } else {
            // check if we are over scrolled
            BOOL overScrolled = NO;
            if ((_scrollPosition.x < 0 || _scrollPosition.x > scrollSizeX)) {

                // apply a spring force to slow down our velocity
                float target = (_scrollPosition.x < 0 ? 0 : scrollSizeX);
                float d = _scrollPosition.x - target;
                float a = (d * _springConstant) / 1;     // mass of 1
                velocity.x += a*dt;
                
                // if velocity is moving with our spring, stop using velocity while we spring back
                if (SIGNVAL(velocity.x) == SIGNVAL(a)) {
                    velocity.x = 0;
                }
                // spring back with fake physics based on the spring constant
                _scrollPosition.x -= (_scrollPosition.x-target) * dt/(10/_springConstant);
                
                if (fabsf(_scrollPosition.x-target) > 0.05)
                    overScrolled = YES;

            }
            // apply friction to our velocity
            velocity.x = velocity.x * drag;
            
            // check if we should be resting
            if (!overScrolled && fabsf(velocity.x) < 0.5) {
                velocity.x = 0;
                _scrollPosition.x = roundf(_scrollPosition.x);
                nResting++;
            }
        }
        
        if (nResting == 2)
            atRest = YES;
    }
    
    if (_dragging) {
        // reduce calculated velocity at each frame for a touch that has stopped moving but hasn't released yet

        float d = 1 - MIN(1, dt*5);
        velocity.x *= d;
        velocity.y *= d;
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!self.dragging) {
        velocity = ccp(0,0);
        lastVelocity = ccp(0,0);
    
        for (UITouch* touch in touches) {
            CGPoint pt = [touch locationInView:self];
            if (CGRectContainsPoint(self.scrollViewFrame, pt)) {
                if (!draggingTouch) {
                    draggingTouch = touch;
                    startPoint = [touch locationInView:self];
                    lastPoint = startPoint;
                    _scrollPosition = ccpClamp(_scrollPosition, ccp(0, 0), ccp(MAX(0, _contentSize.width - self.scrollViewFrame.size.width), MAX(0, _contentSize.height - self.scrollViewFrame.size.height)));
                    lastTime = CACurrentMediaTime();

                    if ((fabsf(velocity.x) > 50 || fabsf(velocity.y) > 50) && !((_scrollPosition.x < 0 || _scrollPosition.x > _contentSize.width) &&  (_scrollPosition.y < 0 || _scrollPosition.y > _contentSize.height))) {
                        _dragging = YES;
                    }

                }
                id key = [NSValue valueWithPointer:touch];
                [touchList addObject:key];
            }
        }
        
        if (!self.dragging) {
            [super touchesBegan:touches withEvent: event];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    // check if we should be draging
    if (!self.dragging) {
        for (UITouch* touch in touches) {
            if (draggingTouch == touch) {
                CGPoint pt = [touch locationInView:self];
                // check if we should start draging in either or both x and y directions
                xLocked = NO;
                if (_contentSize.height <= self.scrollViewFrame.size.height) {
                    yLocked = YES;
                } else if (fabsf(startPoint.y-pt.y) > _dragThreshold) {
                    yLocked = NO;
                    if (fabsf(startPoint.x-pt.x) < _dragThreshold*0.35)
                        xLocked = YES;
                    _dragging = YES;
                }
                if (xLocked || _contentSize.width <= self.scrollViewFrame.size.width) {
                    xLocked = YES;
                } else if (fabsf(startPoint.x-pt.x) > _dragThreshold) {
                    xLocked = NO;
                    if (fabsf(startPoint.y-pt.y) < _dragThreshold*0.35)
                        yLocked = YES;
                    _dragging = YES;
                }
                
                if (_dragging) {
                    // set the effective start point to where we are now to stop jitter when drag starts
                    lastPoint = pt;
                    
                    // cancel the touches on this view because we started draging
                    [[CCDirector sharedDirector].view touchesCancelled:touches withEvent:event];
                    break;
                }
            }
        }
    }
    if (_dragging) {

        // offset the content to follow the drag
        CGPoint pt = [draggingTouch locationInView:self];
        [self offsetX:pt.x-lastPoint.x];
        [self offsetY:lastPoint.y-pt.y];
        
        // verify we have a measureable amount of time to calculate our velocity
        CFTimeInterval t = CACurrentMediaTime();
        CFTimeInterval dt = t - lastTime;
        if (dt > 0.0001) {
            CGPoint newVelocity = ccp((pt.x-lastPoint.x)/(t-lastTime), (lastPoint.y-pt.y)/(t-lastTime));
            velocity.x = (velocity.x*4 + lastVelocity.x*5 + newVelocity.x*3) / 13;
            velocity.y = (velocity.y*4 + lastVelocity.y*5 + newVelocity.y*3) / 13;
            lastVelocity = newVelocity;
        }
        
        lastPoint = pt;
        lastTime = t;
    }
    
    
    if (!self.dragging) {
        // forward our touches if we're not draging
        [[CCDirector sharedDirector].view touchesMoved:touches withEvent:event];
    }
    
    [super touchesMoved:touches withEvent: event];
}

- (void)touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
    for (UITouch* touch in touches) {
        if (draggingTouch == touch) {
            [self releaseDrag];
        }
    }
    [[CCDirector sharedDirector].view touchesEnded:touches withEvent:event];
    
    [super touchesEnded: touches withEvent: event];
}


- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    for (UITouch* touch in touches) {
        if (draggingTouch == touch) {
            [self releaseDrag];
        }
    }
    [[CCDirector sharedDirector].view touchesCancelled:touches withEvent:event];
    
    [super touchesCancelled:touches withEvent:event];
}

- (void)releaseDrag {
    if (self.dragging) {
        CGPoint pt = [draggingTouch locationInView:self];
        
        // keep velocity reasonable with a soft and hard limit
        const float softLimit = 800;
        const float hardLimit = 5000;
        if (fabsf(velocity.y) > softLimit)
            velocity.y = SIGNVAL(velocity.y)*(softLimit + powf(fabsf(velocity.y)-softLimit, 0.94));
        if (fabsf(velocity.x) > softLimit)
            velocity.x = SIGNVAL(velocity.x)*(softLimit + powf(fabsf(velocity.x)-softLimit, 0.94));
        velocity = ccpClamp(velocity, ccp(-hardLimit, -hardLimit), ccp(hardLimit, hardLimit));
        
        _dragging = NO;
        if ((!xLocked && fabsf(velocity.x) > 50) || (!yLocked && fabsf(velocity.y) > 50)) {
            // only allow this last drag point if we are going to decelerate
            [self offsetX:pt.x-lastPoint.x];
            [self offsetY:lastPoint.y-pt.y];
            decelTime = 0;
            atRest = NO;
        } else {
            atRest = YES;
        }
    }
    
    draggingTouch = NULL;
}

// Apply an offset to the content offset
- (void)offsetX:(float)offset {
    if (xLocked || offset == 0 || self.contentSize.width <= self.scrollViewFrame.size.width)
        return;
    
    // content offset is the inverse of the scroll position
    offset = -offset;
    
    float maxOffset = self.contentSize.width - self.scrollViewFrame.size.width;
    float o = _scrollPosition.x;
    
    // apply the offset, but if we are over-scrolling, only apply half the offset that is overscrolled
    if (o <= maxOffset && o + offset > maxOffset) {
        offset -= maxOffset - o;
        o = maxOffset;
    }
    if (o >= 0 && o + offset < 0) {
        offset += o;
        o = 0;
    }
    if (o+offset < 0 || o + offset > maxOffset) {
        offset /= 2;
    }
    o += offset;
    _scrollPosition.x = o;
}

- (void)offsetY:(float)offset {
    if (yLocked || offset == 0 || self.contentSize.height <= self.scrollViewFrame.size.height)
        return;
    
    // Y offset is not the inverse of the position because cocos2d coordinate space is upside down compared to the UI coordinate space
    
    float maxOffset = self.contentSize.height - self.scrollViewFrame.size.height;
    float o = _scrollPosition.y;
    
    // apply the offset, but if we are over-scrolling, only apply half the offset that is overscrolled
    if (o <= maxOffset && o + offset > maxOffset) {
        offset -= maxOffset - o;
        o = maxOffset;
    }
    if (o >= 0 && o + offset < 0) {
        offset += o;
        o = 0;
    }
    if (o+offset < 0 || o + offset > maxOffset) {
        offset /= 2;
    }
    o += offset;
    _scrollPosition.y = o;

}

- (BOOL)shouldShowInterface {
    return _dragging || !atRest;
}

- (void)flashScrollbars {
    [(CSVInterfaceNode*)_interfaceNode flashScrollbars];
}


@end

#pragma mark - CSVInterfaceNode -

@implementation CSVInterfaceNode

- (id)init {
    if ((self = [super init])) {
        self.cascadeColorEnabled = NO;
        self.color = (ccColor3B) {0, 0, 0};
        [self flashScrollbars];
    }
    return self;
}

- (void)onEnter {
    [self scheduleUpdate];
    [super onEnter];
}

- (void)onExit {
    [self unscheduleUpdate];
    [super onExit];
}

- (void)update:(ccTime)dt {
    if (![scrollView shouldShowInterface]) {
        uiVisible -= dt/0.3;
        uiVisible = MAX(0, uiVisible);
    } else {
        uiVisible += dt/0.1;
        uiVisible = MIN(1, uiVisible);
    }
}

- (void)flashScrollbars {
    uiVisible = 4;
}

- (void)setScrollView:(CocosScrollView*)sv {
    scrollView = sv;
}

/** drawing **/
- (void)draw {
    if (!_visible || uiVisible <= 0)
        return;
    
    /** @todo: replace this crazy drawing code with a generated texture instead. I got a little carried away. */
    
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    CGPoint points[200];
    float visibleFactor = MIN(1, uiVisible);
    
    ccColor4F whiteColor = (ccColor4F) {1,1,1, 0.125*_displayedOpacity/255.0f * visibleFactor};
    ccColor4F blackColor = (ccColor4F) {_displayedColor.r/255.0f, _displayedColor.g/255.0f, _displayedColor.b/255.0f, 0.133 * _displayedOpacity/255.0f * visibleFactor};
    
    float scaleFactor = [CCDirector sharedDirector].contentScaleFactor;
    int nPoints = [self generateScrollYPoly:points withSize:5 andOffset:2];
    if (nPoints) {
        // draw our faux-anti-aliased Y scroll bar
        ccDrawSolidPoly(points+nPoints+nPoints, nPoints, blackColor);
        ccDrawSolidPoly(points+nPoints, nPoints, blackColor);
        ccDrawSolidPoly(points, nPoints, blackColor);
        
        kmGLTranslatef(0, -.5, 0);
        nPoints = [self generateScrollYPoly:points withSize:5+1 andOffset:2-.5/scaleFactor];
        ccDrawColor4F(whiteColor.r, whiteColor.g, whiteColor.b, whiteColor.a);
        ccDrawPoly(points+nPoints+nPoints, nPoints, YES);
        ccDrawPoly(points+nPoints, nPoints, YES);
        ccDrawPoly(points, nPoints, YES);
        kmGLTranslatef(0, .5, 0);
    }

    nPoints = [self generateScrollXPoly:points withSize:5 andOffset:2];
    if (nPoints) {
        // draw our faux-anti-aliased X scroll bar
        ccDrawSolidPoly(points+nPoints+nPoints, nPoints, blackColor);
        ccDrawSolidPoly(points+nPoints, nPoints, blackColor);
        ccDrawSolidPoly(points, nPoints, blackColor);

        kmGLTranslatef(.5, 0, 0);
        nPoints = [self generateScrollXPoly:points withSize:5+1 andOffset:2-.5/scaleFactor];
        ccDrawColor4F(whiteColor.r, whiteColor.g, whiteColor.b, whiteColor.a);
        ccDrawPoly(points+nPoints+nPoints, nPoints, YES);
        ccDrawPoly(points+nPoints, nPoints, YES);
        ccDrawPoly(points, nPoints, YES);
        kmGLTranslatef(-.5, 0, 0);
    }
}

- (int)makeArc:(CGPoint*)points index:(int)index anchor:(CGPoint)anchor radius:(float)radius start:(float)start end:(float)end {
    
    float distance = 2 * 3.1415926535898 * radius * fabsf(end-start) / 360;
    int nPoints = (distance);
    nPoints = MAX(2, nPoints);
    
    end = CC_DEGREES_TO_RADIANS(end);
    start = CC_DEGREES_TO_RADIANS(start);
    for (float i=0; i<nPoints; i++) {
        float angle = start + (end-start) * i/(nPoints-1);
        points[index].x = anchor.x-cosf(angle)*radius;
        points[index++].y = anchor.y+sinf(angle)*radius;
    }
    
    return nPoints;
}

- (int)generateScrollYPoly:(CGPoint*)points withSize:(float)size andOffset:(float)offset {

    CGSize contentSize = scrollView.contentSize;
    CGRect frame = scrollView.scrollViewFrame;
    CGPoint scrollPosition = scrollView.scrollPosition;
    
    BOOL showVBar = contentSize.height > frame.size.height;
    BOOL showHBar = contentSize.width > frame.size.width;
    
    if (showVBar) {
        // carefully calculate the position and size of our scroll bar
        float sbVertSpace = frame.size.height;
        
        // include an offset if we are also showing an X scroll bar
        if (showHBar)
            sbVertSpace -= size+offset;
        float height = (frame.size.height) / (contentSize.height) * (sbVertSpace-offset*2);
        float position = offset + scrollPosition.y / (contentSize.height - frame.size.height) * (sbVertSpace-height-offset*2);
        CGRect scrollbarRect = CGRectMake(frame.size.width-size-offset, position, size, height);
        
        // handle scrunching at the ends when overscrolling
        if (scrollbarRect.origin.y < offset) {
            scrollbarRect.size.height -= (offset-scrollbarRect.origin.y)*2;
            scrollbarRect.origin.y = offset;
            if (scrollbarRect.size.height < size)
                scrollbarRect.size.height = size;
        }
        if (CGRectGetMaxY(scrollbarRect) > sbVertSpace-offset) {
            scrollbarRect.size.height -= (CGRectGetMaxY(scrollbarRect) - (sbVertSpace-offset))*2;
            scrollbarRect.origin.y = sbVertSpace-offset-scrollbarRect.size.height;
            if (scrollbarRect.size.height < size) {
                scrollbarRect.origin.y = sbVertSpace-offset-size;
                scrollbarRect.size.height = size;
            }
        }

        // flip origin (convert from UI coords to GL coords)
        scrollbarRect.origin.y = frame.size.height - scrollbarRect.origin.y;
        
        float radius = size/2;
        int index = 0;
        index += [self makeArc:points index:index anchor:ccp(scrollbarRect.origin.x + radius, scrollbarRect.origin.y - radius) radius:radius start:0 end:180];
        int i1 = index;
        index += [self makeArc:points index:index anchor:ccp(scrollbarRect.origin.x + radius, scrollbarRect.origin.y - scrollbarRect.size.height + radius) radius:radius start:180 end:360];
        int nPoints = index;

        // add some fake anti-aliasing (these slightly shifted versions are all drawn with an even percentage of the opacity
        float aliasing = -0.333f;
        for (int o=nPoints; o<nPoints*3; o+=nPoints) {
            for (int i=o; i<o+i1; i++) {
                points[i] = ccp(points[i-o].x, points[i-o].y+aliasing);
            }
            for (int i=o+i1; i<o+nPoints; i++) {
                points[i] = ccp(points[i-o].x, points[i-o].y-aliasing);
            }
            aliasing += 0.666f;
        }
        
        return nPoints;
    }
    
    return 0;
}

- (int)generateScrollXPoly:(CGPoint*)points withSize:(float)size andOffset:(float)offset {
    
    CGSize contentSize = scrollView.contentSize;
    CGRect frame = scrollView.scrollViewFrame;
    CGPoint scrollPosition = scrollView.scrollPosition;
    
    BOOL showVBar = contentSize.height > frame.size.height;
    BOOL showHBar = contentSize.width > frame.size.width;
    
    if (showHBar) {
        // carefully calculate the position and size of our scroll bar
        float sbHorizSpace = frame.size.width;
        
        // include an offset if we are also showing an X scroll bar
        if (showVBar)
            sbHorizSpace -= size+offset;
        float width = (frame.size.width) / (contentSize.width) * (sbHorizSpace-offset*2);
        float position = offset + scrollPosition.x / (contentSize.width - frame.size.width) * (sbHorizSpace-width-offset*2);
        CGRect scrollbarRect = CGRectMake(position, offset, width, size);
        
        // handle scrunching at the ends when overscrolling
        if (scrollbarRect.origin.x < offset) {
            scrollbarRect.size.width -= (offset-scrollbarRect.origin.x)*2;
            scrollbarRect.origin.x = offset;
            if (scrollbarRect.size.width < size)
                scrollbarRect.size.width = size;
        }
        if (CGRectGetMaxX(scrollbarRect) > sbHorizSpace-offset) {
            scrollbarRect.size.width -= (CGRectGetMaxX(scrollbarRect) - (sbHorizSpace-offset))*2;
            scrollbarRect.origin.x = sbHorizSpace-offset-scrollbarRect.size.width;
            if (scrollbarRect.size.width < size) {
                scrollbarRect.origin.x = sbHorizSpace-offset-size;
                scrollbarRect.size.width = size;
            }
        }
        
        
        float radius = size/2;
        int index = 0;
        index += [self makeArc:points index:index anchor:ccp(scrollbarRect.origin.x + radius, scrollbarRect.origin.y + radius) radius:radius start:-90 end:90];
        int i1 = index;
        index += [self makeArc:points index:index anchor:ccp(scrollbarRect.origin.x + scrollbarRect.size.width - radius, scrollbarRect.origin.y + radius) radius:radius start:90 end:270];
        int nPoints = index;
        
        // add some fake anti-aliasing (these slightly shifted versions are all drawn with an even percentage of the opacity
        float aliasing = -0.333f;
        for (int o=nPoints; o<nPoints*3; o+=nPoints) {
            for (int i=o; i<o+i1; i++) {
                points[i] = ccp(points[i-o].x+aliasing, points[i-o].y);
            }
            for (int i=o+i1; i<o+nPoints; i++) {
                points[i] = ccp(points[i-o].x-aliasing, points[i-o].y);
            }
            aliasing += 0.666f;
        }
        
        return nPoints;
    }
    
    return 0;
}

@end