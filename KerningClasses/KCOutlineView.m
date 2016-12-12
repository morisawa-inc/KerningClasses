//
//  KCOutlineView.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCOutlineView.h"

@implementation KCOutlineView

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row {
    NSRect superFrame = [super frameOfCellAtColumn:column row:row];
    if (_disableIndentation && column == 0) {
        return NSMakeRect(-[self indentationPerLevel], superFrame.origin.y, [self bounds].size.width, superFrame.size.height);
    }
    return superFrame;
}

- (void)reloadData {
    if ([_dataSource respondsToSelector:@selector(reloadData)]) {
        [_dataSource reloadData];
    }
    [super reloadData];
}

- (void)keyDown:(NSEvent *)event {
    if (([event keyCode] == 36 || [event keyCode] == 76) && [event modifierFlags] & NSShiftKeyMask) {
        NSIndexSet *selection = [self selectedRowIndexes];
        if ([selection count] > 0) {
            if ([(id)_delegate respondsToSelector:@selector(outlineView:didPressTriggerKeyWithItems:)]) {
                NSMutableArray *mutableItems = [[NSMutableArray alloc] init];
                [selection enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * stop) {
                    id item = [self itemAtRow:idx];
                    if (item) {
                        [mutableItems addObject:item];
                    }
                }];
                [(id)_delegate outlineView:self didPressTriggerKeyWithItems:[mutableItems copy]];
                return;
            }
        }
    }
    [super keyDown:event];
}

@end
