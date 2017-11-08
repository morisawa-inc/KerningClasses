//
//  KCOutlineView.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCOutlineView.h"

@implementation KCOutlineView

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [self setTarget:self];
        [self setDoubleAction:@selector(handleDoubleAction:)];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self setTarget:self];
        [self setDoubleAction:@selector(handleDoubleAction:)];
    }
    return self;
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row {
    NSRect superFrame = [super frameOfCellAtColumn:column row:row];
    if (_disableIndentation && column == 0) {
        return NSMakeRect(-[self indentationPerLevel], superFrame.origin.y, [self bounds].size.width, superFrame.size.height);
    }
    return superFrame;
}

- (void)reloadData {
    id dataSource = [self dataSource];
    if ([dataSource respondsToSelector:@selector(reloadData)]) {
        [dataSource reloadData];
    }
    [super reloadData];
}

- (void)keyDown:(NSEvent *)event {
    if (([event keyCode] == 36 || [event keyCode] == 76)) {
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

- (void)handleDoubleAction:(id)sender {
    NSIndexSet *selection = [self selectedRowIndexes];
    if ([selection count] > 0) {
        if ([(id)_delegate respondsToSelector:@selector(outlineView:didDoubleClickWithItems:)]) {
            NSMutableArray *mutableItems = [[NSMutableArray alloc] init];
            [selection enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * stop) {
                id item = [self itemAtRow:idx];
                if (item) {
                    [mutableItems addObject:item];
                }
            }];
            [(id)_delegate outlineView:self didDoubleClickWithItems:[mutableItems copy]];
            return;
        }
    }
}

@end

@interface KCOutlineTextFieldCell () {
@private
    NSColor *_textColor;
}
@end

@implementation KCOutlineTextFieldCell

- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle {
    [super setBackgroundStyle:backgroundStyle];
    if (backgroundStyle == NSBackgroundStyleDark) {
        [super setTextColor:[NSColor controlTextColor]];
    } else {
        [super setTextColor:_textColor];
    }
}

- (void)setTextColor:(NSColor *)textColor {
    if ([self backgroundStyle] == NSBackgroundStyleDark) {
        [super setTextColor:[NSColor controlTextColor]];
    } else {
        [super setTextColor:textColor];
    }
    _textColor = textColor;
}

@end
