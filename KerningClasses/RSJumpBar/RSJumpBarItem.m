//
//  RSJumpBarItem.m
//  ToolbarTest
//
//  Created by tfuji on 12/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "RSJumpBarItem.h"

@implementation RSJumpBarItem

- (instancetype)initWithTitle:(NSString *)aTitle image:(NSImage *)anImage objectValue:(id)anObjectValue {
    if ((self = [self init])) {
        _title       = aTitle;
        _image       = anImage;
        _objectValue = anObjectValue;
    }
    return self;
}

- (instancetype)itemByAssigningParentItem:(id)aParentItem {
    RSJumpBarItem *item = [[[self class] alloc] initWithTitle:_title image:_image objectValue:_objectValue];
    item->_parentItem = aParentItem;
    return item;
}

- (NSArray <RSJumpBarItem *> *)allItems {
    NSMutableArray *mutableItems = [[NSMutableArray alloc] initWithCapacity:0];
    RSJumpBarItem *item = self;
    while (item) {
        [mutableItems insertObject:item atIndex:0];
        item = [item parentItem];
    }
    return [mutableItems copy];
}

- (NSMenuItem *)menuItem {
    NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:_title action:nil keyEquivalent:@""];
    [menuItem setImage:_image];
    [menuItem setRepresentedObject:self];
    return menuItem;
}

- (NSUInteger)hash {
    return [NSStringFromClass([self class]) hash] ^ [_objectValue hash];
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[self class]]) {
        if ([_objectValue isEqual:((RSJumpBarItem *)object)->_objectValue]) {
            isEqual = YES;
        } else if (self == object) {
            isEqual = YES;
        }
    }
    return isEqual;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

@end
