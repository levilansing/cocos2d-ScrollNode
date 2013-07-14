//
//  HomeLayer.h
//  ScrollDemo
//
//  Created by Levi on 7/12/13.
//  Copyright (c) 2013 zephLabs. All rights reserved.
//

#import "cocos2d.h"
#import "CCLayer.h"
#import "ScrollNode.h"

@interface HomeLayer : CCLayerColor {
    ScrollNode *scrollNode;
}

+(CCScene *) scene;

@end
