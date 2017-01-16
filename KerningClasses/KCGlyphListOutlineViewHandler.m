//
//  KCGlyphListOutlineViewHandler.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCGlyphListOutlineViewHandler.h"
#import <GlyphsCore/GSGlyph.h>

@interface KCGlyphListOutlineViewHandler ()
@property (nonatomic, readonly) NSArray<GSGlyph *> *leftGlyphs;
@property (nonatomic, readonly) NSArray<GSGlyph *> *rightGlyphs;
@end

@implementation KCGlyphListOutlineViewHandler

- (void)setDataSource:(id<KCGlyphListOutlineViewHandlerDataSource>)aDataSource {
    _dataSource = aDataSource;
    [self reloadData];
}

- (void)reloadData {
    _leftGlyphs  = [_dataSource leftGlyphsForGlyphListOutlineViewHandler:self];
    _rightGlyphs = [_dataSource rightGlyphsForGlyphListOutlineViewHandler:self];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSUInteger numberOfChildren = 0;
    if ([item isKindOfClass:[NSArray class]]) {
        numberOfChildren = [(NSArray *)item count];
    } else if (!item) {
        if ([_leftGlyphs count]  > 0) numberOfChildren++;
        if ([_rightGlyphs count] > 0) numberOfChildren++;
    }
    return numberOfChildren;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[NSArray class]]) {
        return YES;
    }
    return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if ([item isKindOfClass:[NSArray class]]) {
        return [item objectAtIndex:index];
    } else if (!item) {
        if (index == 0) {
            return _leftGlyphs;
        }
        return _rightGlyphs;
    }
    return [NSNull null];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    if ([item isKindOfClass:[NSArray class]]) {
        return YES;
    }
    return NO;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *cellView = nil;
    if (item == _leftGlyphs) {
        cellView = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        [cellView setObjectValue:@"LEFT"];
    } else if (item == _rightGlyphs) {
        cellView = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        [cellView setObjectValue:@"RIGHT"];
    } else {
        cellView = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
        [cellView setObjectValue:[item name]];
    }
    return cellView;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSOutlineView *outlineView = [notification object];
    NSMutableOrderedSet *mutableLeftGlyphNames  = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    NSMutableOrderedSet *mutableRightGlyphNames = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    NSInteger rightRowIndex = [_leftGlyphs count] + 1;
    [[outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL * _Nonnull stop) {
        NSTableCellView *cellView = [[outlineView rowViewAtRow:i makeIfNecessary:YES] viewAtColumn:0];
        NSString *name = [cellView objectValue];
        if (![name isEqualToString:@"LEFT"] && ![name isEqualToString:@"RIGHT"]) {
            if (i < rightRowIndex) {
                [mutableLeftGlyphNames addObject:name];
            } else {
                [mutableRightGlyphNames addObject:name];
            }
        }
    }];
    NSMutableString *mutableText = [[NSMutableString alloc] initWithCapacity:0];
    if ([mutableLeftGlyphNames count] > 0 && [mutableRightGlyphNames count] > 0) {
        for (NSString *left in mutableLeftGlyphNames) {
            for (NSString *right in mutableRightGlyphNames) {
                [mutableText appendString:@"/"];
                [mutableText appendString:left];
                [mutableText appendString:@" "];
                [mutableText appendString:@"/"];
                [mutableText appendString:right];
                [mutableText appendString:@" "];
            }
        }
    } else {
        for (NSString *left in mutableLeftGlyphNames) {
            [mutableText appendString:@"/"];
            [mutableText appendString:left];
            [mutableText appendString:@" "];
        }
        for (NSString *right in mutableRightGlyphNames) {
            [mutableText appendString:@"/"];
            [mutableText appendString:right];
            [mutableText appendString:@" "];
        }
    }
    if ([mutableText length] > 0) {
        [_delegate glyphListOutlineViewHandler:self shouldDisplayTextInTab:[mutableText copy]];
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if (item == _leftGlyphs || item == _rightGlyphs) {
        return NO;
    }
    return YES;
}

@end
