cocos2d-ScrollNode
==================

A cocos2d ScrollNode that mimics the behavior of a UIScrollView. 
- Requires NO modifications to cocos2d source! 
- Compatible with cocos2d-iphone 2.0 and 2.1 (see separate versions in Source folder).
- ScrollNode mimics the standard horizontal and/or vertical scrolling of a UIScrollView
- At this time it does not support paging or pinch to zoom.

History
==================
Almost every game I make needs a scroll view. Every solution I could find either required modifications to the cocos2d source code (always a bad idea!), or it just didn't feel right. After being disappointed with every option I tried, ScrollNode was born.


Usage
==================

```Objective-C
// create the scroll node
ScrollNode *scrollNode = [ScrollNode nodeWithSize:CGSizeMake(size.width, size.height)];
[self addChild:scrollNode];

// Generate some content for the scroll view
// add it directly to scrollView, or to the built in menu (scrollView.menu)
[scrollNode.menu addChild:yourMenuItem];

// Set the content rect to represent the scroll area
CGRect contentRect = [scrollNode calculateScrollViewContentRect];
[scrollNode setScrollViewContentRect:contentRect];

// OR
// alternatively you could just set the content size
// but now you are responsible for making sure your content starts at the right position
[scrollNode setScrollViewContentSize:CGSizeMake(500, 1000)];

// you can hide the user interface if desired
scrollNode.showScrollBars = NO;
```

The ScrollNode
==================
The ScrollNode is the node you create and add your content to. It has a built in menu you should use if you plan to put menu items in the scroll view. The built in menu will ignore touches outside the scroll view so you don't have to check.
```Objective-C
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
```

The CocosScrollView
==================
The CocosScrollView is created by and accessible from the ScrollNode. Use its public interface to change properties and options.
```Objective-C
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
// check if the interface should be visible (used for custom scrollbar ui)
- (BOOL)shouldShowInterface;
```
