//
//  KCOutlineView.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol KCOutlineViewDelegate;

@interface KCOutlineView : NSOutlineView

@property (nonatomic) IBInspectable BOOL disableIndentation;

@end

@protocol KCOutlineViewDelegate <NSObject>
- (void)outlineView:(NSOutlineView *)outlineView didPressTriggerKeyWithItems:(NSArray *)items;
@end
