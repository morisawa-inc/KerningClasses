//
//  RSJumpBarButton.h
//  ToolbarTest
//
//  Created by tfuji on 13/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSJumpBarItem.h"

IB_DESIGNABLE
@interface RSJumpBarButton : NSButton

@property (nonatomic) RSJumpBarItem *barItem;
@property (nonatomic, getter=isCollapsible) BOOL collapsible;

@end
