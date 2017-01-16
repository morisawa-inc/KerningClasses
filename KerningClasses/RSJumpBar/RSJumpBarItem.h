//
//  RSJumpBarItem.h
//  ToolbarTest
//
//  Created by tfuji on 12/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface RSJumpBarItem : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) NSImage  *image;
@property (nonatomic, readonly) id objectValue;

@property (nonatomic, readonly) RSJumpBarItem *parentItem;

- (instancetype)initWithTitle:(NSString *)aTitle image:(NSImage *)anImage objectValue:(id)anObjectValue;

- (instancetype)itemByAssigningParentItem:(id)aParentItem;
- (NSArray <RSJumpBarItem *> *)allItems;

- (NSMenuItem *)menuItem;

@end
