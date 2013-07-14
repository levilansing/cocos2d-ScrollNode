//
//  HomeLayer.m
//  ScrollDemo
//
//  Created by Levi on 7/12/13.
//  Copyright (c) 2013 zephLabs. All rights reserved.
//

#import "HomeLayer.h"


@implementation HomeLayer

const int COUNT_WIDE = 10;
const int COUNT_TALL = 25;

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	HomeLayer *layer = [HomeLayer layerWithColor:(ccColor4B){50,50,50,255}];
    [layer load];
	[scene addChild: layer];
	return scene;
}

-(void) load {
    CGSize size = [[CCDirector sharedDirector] winSize];
    
    scrollNode = [ScrollNode nodeWithSize:CGSizeMake(size.width, size.height)];
    // our example is full screen so we don't need clipping
    scrollNode.clipping = NO;
    [self addChild:scrollNode];

    // Generate some content for the scroll view
    for (int y=0; y<COUNT_TALL; y++) {
        for (int x=0; x<COUNT_WIDE; x++) {
            CCSprite *circle1 = [CCSprite spriteWithFile:@"circle.png"];
            circle1.color = createColor(y*COUNT_WIDE+x);
            CCSprite *circle2 = [CCSprite spriteWithFile:@"circle.png"];
            circle2.color = (ccColor3B){150,150,150};
            
            CCMenuItem *item = [CCMenuItemSprite itemWithNormalSprite:circle1 selectedSprite:circle2];
            [item setTarget:self selector:@selector(onMenuItem:)];
            item.position = ccp(x * circle1.contentSize.width*1.5, -y * circle1.contentSize.height*1.5);
            item.anchorPoint = ccp(0.5, 0.5);
            item.tag = y*COUNT_WIDE+x;
            [scrollNode.menu addChild:item];
        }
    }
    
    // use the Bounding Box of all the content as the scroll area
    // this will offset the content so you don't have to make your content starts at the top left
    CGRect contentRect = [scrollNode calculateScrollViewContentRect];
    [scrollNode setScrollViewContentRect:contentRect];
    
    // alternatively you could just set the content size
    // but now you are responsible for making sure your content starts at the right position
    //[scrollNode setScrollViewContentSize:CGSizeMake(500, 1000)];
    
    scrollNode.showScrollBars = NO;
}

ccColor3B createColor(int index) {
    ccColor3B color;
    UIColor* uiColor = [UIColor colorWithHue:(index%6)/7.0f+0.03f saturation:0.6f brightness:0.8f alpha:1];
    float r,g,b,a;
    [uiColor getRed:&r green:&g blue:&b alpha:&a];
    color.r = r*255;
    color.g = g*255;
    color.b = b*255;
    return color;
}

-(void) onMenuItem:(CCMenuItemSprite*)item {
    int x = item.tag % 10;
    int y = item.tag / 10;
    for (int i=0; i<COUNT_WIDE; i++) {
        CCMenuItemSprite *menuItem = (CCMenuItemSprite*)[scrollNode.menu getChildByTag:y*COUNT_WIDE+i];
        menuItem.normalImage.color = item.normalImage.color;
    }
    
    for (int i=0; i<COUNT_TALL; i++) {
        CCMenuItemSprite *menuItem = (CCMenuItemSprite*)[scrollNode.menu getChildByTag:i*COUNT_WIDE+x];
        menuItem.normalImage.color = item.normalImage.color;
    }
}

@end
