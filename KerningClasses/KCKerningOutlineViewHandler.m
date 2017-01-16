//
//  KCKerningOutlineViewHandler.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCKerningOutlineViewHandler.h"
#import <GlyphsCore/GSGlyph.h>

@interface KCKerningOutlineViewHandler ()
@property (nonatomic, readonly) NSArray<KCKerningEntry *> *entries;
@property (nonatomic, readonly) BOOL shouldPreventReloadingData;
@property (nonatomic, readonly) NSMutableSet<KCKerningEntry *> *mutableExpandedItems;
@end

@implementation KCKerningOutlineViewHandler

- (instancetype)init {
    if ((self = [super init])) {
        _mutableExpandedItems = [[NSMutableSet alloc] init];
    }
    return self;
}

- (void)setDataSource:(id<KCKerningOutlineViewHandlerDataSource>)aDataSource {
    _dataSource = aDataSource;
    [self reloadData];
}

- (void)reloadData {
    if (!_shouldPreventReloadingData) {
        NSArray<NSSortDescriptor *> *sortDescriptors = [_dataSource sortDescriptorsForKerningOutlineViewHandler:self];
        if (sortDescriptors) {
            _entries = [[_dataSource entriesForKerningOutlineViewHandler:self] sortedArrayUsingDescriptors:sortDescriptors];
        } else {
            _entries = [_dataSource entriesForKerningOutlineViewHandler:self];
        }
    }
}

- (void)resetExpandedItems {
    [_mutableExpandedItems removeAllObjects];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if ([item isKindOfClass:[KCKerningEntry class]]) {
        return [[(KCKerningEntry *)item exceptions] count];
    }
    return [_entries count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if ([item isKindOfClass:[KCKerningEntry class]]) {
        return [[(KCKerningEntry *)item exceptions] count] > 0;
    }
    return [_entries count] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if ([item isKindOfClass:[KCKerningEntry class]]) {
        return [[(KCKerningEntry *)item exceptions] objectAtIndex:index];
    }
    return [_entries objectAtIndex:index];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *cellView = [outlineView makeViewWithIdentifier:[tableColumn identifier] owner:self];
    [cellView setObjectValue:item];
    return cellView;
}

-(void)outlineView:(NSOutlineView *)outlineView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    _entries = [_entries sortedArrayUsingDescriptors:[outlineView sortDescriptors]];
    _shouldPreventReloadingData = YES;
    [outlineView reloadData];
    _shouldPreventReloadingData = NO;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    NSOutlineView *outlineView = [notification object];
    NSMutableOrderedSet *mutableLeftIdentifiers  = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    NSMutableOrderedSet *mutableRightIdentifiers = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    [[outlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger i, BOOL * _Nonnull stop) {
        NSTableCellView *cellView = [[outlineView rowViewAtRow:i makeIfNecessary:YES] viewAtColumn:0];
        KCKerningEntry *entry = [cellView objectValue];
        [mutableLeftIdentifiers  addObject:[entry left]];
        [mutableRightIdentifiers addObject:[entry right]];
    }];
    [_delegate kerningOutlineViewHandler:self didSelectRowWithLeftIdentifiers:[mutableLeftIdentifiers array] rightIdentifiers:[mutableRightIdentifiers array]];
}

- (void)outlineView:(NSOutlineView *)outlineView didPressTriggerKeyWithItems:(NSArray *)items {
    [_delegate kerningOutlineViewHandler:self shouldDisplayTextInTabForEntries:items];
}

- (void)outlineView:(NSOutlineView *)outlineView didDoubleClickWithItems:(NSArray *)items {
    [self outlineView:outlineView didPressTriggerKeyWithItems:items];
}

- (NSArray<id> *)expandedItems {
    return [_mutableExpandedItems allObjects];
}

- (NSInteger)rowForItem:(id)item {
    NSUInteger i = 0;
    for (KCKerningEntry *entry in _entries) {
        if ([entry isEqual:item]) return i;
        for (KCKerningEntry *exception in [entry exceptions]) {
            if ([exception isEqual:item]) return i;
            ++i;
        }
        ++i;
    }
    return -1;
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification {
    KCKerningEntry *entry = [[notification userInfo] objectForKey:@"NSObject"];
    if (entry) [_mutableExpandedItems addObject:entry];
}

- (void)outlineViewItemWillCollapse:(NSNotification *)notification {
    KCKerningEntry *entry = [[notification userInfo] objectForKey:@"NSObject"];
    if (entry) [_mutableExpandedItems removeObject:entry];
}

@end
