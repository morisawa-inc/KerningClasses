//
//  KCWindowController.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCWindowController.h"
#import "KCKerningOutlineViewHandler.h"
#import "KCGlyphListOutlineViewHandler.h"
#import "KCKerningEntries.h"

#import "KCJumpBar.h"

#import <GlyphsCore/GSWindowControllerProtocol.h>
#import <GlyphsCore/GSGlyphEditViewProtocol.h>
#import <GlyphsCore/GSGlyphViewControllerProtocol.h>
#import <GlyphsCore/MGOrderedDictionary.h>

typedef NS_ENUM(NSInteger, KCWindowControllerDisplayStringVerbosity) {
    KCWindowControllerDisplayStringVerbosityDefault,
    KCWindowControllerDisplayStringVerbosityAbridged
};

@protocol KCWindowControllerProtocol <GSWindowControllerProtocol>
@property(nonatomic) NSUInteger masterIndex;
@end

@interface GSDocument : NSDocument
@property(readonly, nonatomic) NSWindowController<KCWindowControllerProtocol> *windowController;
@property(readonly, nonatomic) GSFontMaster *selectedFontMaster;
@property(retain, nonatomic) GSFont *font;
@end

@interface GSTextStorage : NSObject
@property(nonatomic) NSRange selectedRange;
@end

@interface NSView (GSGraphicViewAdditions)
@property(nonatomic) NSString *displayString;
@end

@interface KCWindowController () <KCKerningOutlineViewHandlerDataSource, KCKerningOutlineViewHandlerDelegate, KCGlyphListOutlineViewHandlerDataSource, KCGlyphListOutlineViewHandlerDelegate>
@property (nonatomic) IBOutlet NSSearchField *searchField;
@property (nonatomic) IBOutlet KCJumpBar *jumpBar;
@property (nonatomic) IBOutlet NSOutlineView *kerningOutlineView;
@property (nonatomic) IBOutlet NSOutlineView *glyphListOutlineView;
@property (nonatomic) KCKerningOutlineViewHandler *kerningOutlineViewHandler;
@property (nonatomic) KCGlyphListOutlineViewHandler *glyphListOutlineViewHandler;
@property (nonatomic) KCFontMasterStore *currentFontMasterStore;
@property (nonatomic) KCKerningEntries *entries;
@property (nonatomic) KCKerningEntries *filteredEntries;
@property (nonatomic) NSArray<GSGlyph *> *leftGlyphs;
@property (nonatomic) NSArray<GSGlyph *> *rightGlyphs;
@property (nonatomic, readonly) KCKerningEntriesQueryType queryType;
@end

@implementation KCWindowController

- (instancetype)init {
    if ((self = [self initWithWindowNibName:@"KCWindowController"])) {
        
    }
    return self;
}

- (void)dealloc {
    [self setCurrentFontMasterStore:nil];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    _kerningOutlineViewHandler = [[KCKerningOutlineViewHandler alloc] init];
    [_kerningOutlineViewHandler setDataSource:self];
    [_kerningOutlineViewHandler setDelegate:self];
    [_kerningOutlineView setDelegate:_kerningOutlineViewHandler];
    [_kerningOutlineView setDataSource:_kerningOutlineViewHandler];
    _glyphListOutlineViewHandler = [[KCGlyphListOutlineViewHandler alloc] init];
    [_glyphListOutlineViewHandler setDataSource:self];
    [_glyphListOutlineViewHandler setDelegate:self];
    [_glyphListOutlineView setDelegate:_glyphListOutlineViewHandler];
    [_glyphListOutlineView setDataSource:_glyphListOutlineViewHandler];
    
    [self reloadData];
    
    [[self window] setLevel:NSFloatingWindowLevel];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:NSApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillBecomeActive:) name:NSApplicationWillBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentWillClose:) name:@"GSDocumentCloseNotification" object:nil];  
    
    [self setShouldCascadeWindows:YES];
    
    [_jumpBar setSelection:[KCFontMasterStore currentFontMasterStore]];
}

- (void)documentWillClose:(NSNotification *)notification {
    [self performSelector:@selector(invalidateJumpBarIfNeeded) withObject:nil afterDelay:0.0];
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([_delegate respondsToSelector:@selector(windowControllerWillClose:)]) {
        [_delegate windowControllerWillClose:self];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"GSDocumentCloseNotification" object:nil];
}

- (void)setTitle:(NSString *)aString {
    [[self window] setTitle:aString ? aString : @""];
}

- (void)resetExpandedItems {
    [_kerningOutlineViewHandler resetExpandedItems];
}

- (void)reloadData {
    [_kerningOutlineView expandItem:nil expandChildren:YES];
    //
    NSMutableArray *selectedItems = [[NSMutableArray alloc] initWithCapacity:0];
    [[_kerningOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [selectedItems addObject:[_kerningOutlineView itemAtRow:idx]];
    }];
    //
    [_kerningOutlineView   reloadData];
    [_glyphListOutlineView reloadData];
    //
    NSMutableIndexSet *mutableRowIndexes = [[NSMutableIndexSet alloc] init];
    for (KCKerningEntry *selectedItem in selectedItems) {
        NSInteger row = [_kerningOutlineView rowForItem:selectedItem];
        if (row >= 0) [mutableRowIndexes addIndex:row];
    }
    [_kerningOutlineView selectRowIndexes:mutableRowIndexes byExtendingSelection:NO];
    //
    for (id item in [_kerningOutlineViewHandler expandedItems]) {
        [_kerningOutlineView expandItem:item expandChildren:YES];
    }
}

- (void)setCurrentFontMasterStore:(KCFontMasterStore *)aCurrentFontMasterStore {
    if (_currentFontMasterStore != aCurrentFontMasterStore) {
        [[_currentFontMasterStore font] removeObserver:self forKeyPath:@"kerning"];
        [[_currentFontMasterStore font] removeObserver:self forKeyPath:@"fontMasters"];
        [[aCurrentFontMasterStore font] addObserver:self forKeyPath:@"kerning" options:0 context:NULL];
        [[aCurrentFontMasterStore font] addObserver:self forKeyPath:@"fontMasters" options:0 context:NULL];
        _currentFontMasterStore = aCurrentFontMasterStore;
        [self resetExpandedItems];
        [self reloadData];
    }
}

- (NSArray<NSSortDescriptor *> *)sortDescriptorsForKerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler {
    return [_kerningOutlineView sortDescriptors];
}

- (NSArray<KCKerningEntry *> *)entriesForKerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler {
    if ([self currentFontMaster]) {
        GSFontMaster *fontMaster = [self currentFontMaster];
        KCKerningEntries *entries = [[KCKerningEntries alloc] initWithFontMaster:fontMaster];
        _entries = entries;
        if ([[_searchField stringValue] length] > 0) {
            _filteredEntries = [_entries filteredEntriesWithQueryString:[_searchField stringValue] type:_queryType];
        } else {
            _filteredEntries = nil;
        }
        entries = _filteredEntries ? _filteredEntries : _entries;
        return [entries entries];
    }
    return nil;
}

- (void)kerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler didSelectRowWithLeftIdentifiers:(NSArray<NSString *> *)leftIdentifiers rightIdentifiers:(NSArray<NSString *> *)rightIdentifiers {
    NSMutableOrderedSet *mutableLeftGlyphs  = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    NSMutableOrderedSet *mutableRightGlyphs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    for (NSString *left in leftIdentifiers) {
        [mutableLeftGlyphs addObjectsFromArray:[_entries glyphsForIdentifier:left]];
    }
    for (NSString *right in rightIdentifiers) {
        [mutableRightGlyphs addObjectsFromArray:[_entries glyphsForIdentifier:right]];
    }
    _leftGlyphs  = [mutableLeftGlyphs array];
    _rightGlyphs = [mutableRightGlyphs array];
    [_glyphListOutlineView reloadData];
    [_glyphListOutlineView expandItem:_leftGlyphs  expandChildren:YES];
    [_glyphListOutlineView expandItem:_rightGlyphs expandChildren:YES];
    NSString *displayString = [NSString stringWithFormat:@"/%@ /%@", [[_leftGlyphs firstObject] name], [[_rightGlyphs firstObject] name]];
    [self showAlertAndDisplayString:displayString];
}

- (NSString *)combintionDisplayStringFromEntries:(NSArray<KCKerningEntry *> *)entries verbosity:(KCWindowControllerDisplayStringVerbosity)aVerbosity {
    NSString *displayString = nil;
    NSMutableArray *mutableTextLines = [[NSMutableArray alloc] initWithCapacity:0];
    for (KCKerningEntry *entry in entries) {
        NSMutableString *mutableDisplayString = [[NSMutableString alloc] initWithCapacity:0];
        NSArray<GSGlyph *> *leftGlyphs  = [_entries glyphsForIdentifier:[entry left]];
        NSArray<GSGlyph *> *rightGlyphs = [_entries glyphsForIdentifier:[entry right]];
        if (aVerbosity == KCWindowControllerDisplayStringVerbosityAbridged) {
            leftGlyphs  = [leftGlyphs  subarrayWithRange:NSMakeRange(0, 1)];
            rightGlyphs = [rightGlyphs subarrayWithRange:NSMakeRange(0, 1)];
        }
        for (GSGlyph *leftGlyph in leftGlyphs) {
            for (GSGlyph *rightGlyph in rightGlyphs) {
                [mutableDisplayString appendFormat:@"/%@ /%@", [leftGlyph name], [rightGlyph name]];
            }
        }
        [mutableTextLines addObject:[mutableDisplayString copy]];
    }
    NSString *delimiter = @"\n";
    if (aVerbosity == KCWindowControllerDisplayStringVerbosityAbridged) {
        delimiter = @"  ";
    }
    displayString = [mutableTextLines componentsJoinedByString:delimiter];
    return displayString;
}

- (NSString *)metricsStringFromEntries:(NSArray<KCKerningEntry *> *)entries {
    NSString *displayString = nil;
    NSMutableArray *mutableTextLines = [[NSMutableArray alloc] initWithCapacity:0];
    [mutableTextLines addObject:@"#First;Second;Value"];
    for (KCKerningEntry *entry in entries) {
        [mutableTextLines addObject:[NSString stringWithFormat:@"%@;%@;%ld", [entry left], [entry right], [entry value]]];
    }
    displayString = [mutableTextLines componentsJoinedByString:@"\n"];
    return displayString;
}

- (id)metricsPropertyListFromEntries:(NSArray<KCKerningEntry *> *)entries {
    MGOrderedDictionary *mutableDictionary = [[MGOrderedDictionary alloc] initWithCapacity:0];
    for (KCKerningEntry *entry in entries) {
        MGOrderedDictionary *mutableEntries = [mutableDictionary objectForKey:[entry left]];
        if (!mutableEntries) {
            mutableEntries = [[MGOrderedDictionary alloc] initWithCapacity:0];
            [mutableDictionary setObject:mutableEntries forKey:[entry left]];
        }
        [mutableEntries setObject:[NSNumber numberWithDouble:[entry value]] forKey:[entry right]];
    }
    return mutableDictionary;
}


- (void)showAlertAndDisplayString:(NSString *)aDisplayString {
    NSUInteger numberOfGlyphs = [aDisplayString length] - [[aDisplayString stringByReplacingOccurrencesOfString:@"/" withString:@""] length];
    if (numberOfGlyphs >= 2048) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Too Many Pairs Selected"];
        [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to display the possible %lu pairs? This operation may take a while.", nil), numberOfGlyphs]];
        [alert addButtonWithTitle:NSLocalizedString(@"Display", nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
        [alert setAlertStyle:NSWarningAlertStyle];
        __weak typeof(self) weakSelf = self;
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn
                ) {
                [weakSelf setDisplayString:aDisplayString];
            }
        }];
    } else {
        [self setDisplayString:aDisplayString];
    }
}

- (void)kerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler shouldDisplayTextInTabForEntries:(NSArray<KCKerningEntry *> *)entries {
    NSString *displayString = nil;
    if ([[[NSApplication sharedApplication] currentEvent] modifierFlags] & NSShiftKeyMask) {
        displayString = [self combintionDisplayStringFromEntries:entries verbosity:KCWindowControllerDisplayStringVerbosityDefault];
    } else {
        displayString = [self combintionDisplayStringFromEntries:entries verbosity:KCWindowControllerDisplayStringVerbosityAbridged];
    }
    [self showAlertAndDisplayString:displayString];
}

- (void)glyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler shouldDisplayTextInTab:(NSString *)text {
    [self showAlertAndDisplayString:text];
}

- (NSArray<GSGlyph *> *)leftGlyphsForGlyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler {
    return _leftGlyphs;
}

- (NSArray<GSGlyph *> *)rightGlyphsForGlyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler {
    return _rightGlyphs;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
    [self performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
    // [_kerningOutlineView   reloadData];
    // [_glyphListOutlineView reloadData];
}

- (IBAction)performFindPanelAction:(id)sender {
    [[self window] makeFirstResponder:_searchField];
}

- (GSDocument *)currentDocument {
    return [[_currentFontMasterStore font] parent];
}

- (GSFont *)currentFont {
    return [_currentFontMasterStore font];
}

- (GSFontMaster *)currentFontMaster {
    return [_currentFontMasterStore fontMaster];
}

- (NSString *)displayString {
    return [[[[[self currentDocument] windowController] activeEditViewController] graphicView] displayString];
}

- (void)setDisplayString:(NSString *)aDisplayString {
    NSRange range = [[[[[[self currentDocument] windowController] activeEditViewController] graphicView] textStorage] selectedRange];
    NSString *currentDisplayString = [self displayString];
    if (range.length == 0) {
        range = [currentDisplayString lineRangeForRange:range];
        if (range.length > 0) {
            if ([[currentDisplayString substringWithRange:NSMakeRange(range.location + range.length - 1, 1)] isEqualToString:@"\n"]) {
                range.length -= 1;
            }
        }
    }
    if (range.location > 0) {
        if (range.location < [currentDisplayString length]) {
            [[[[[self currentDocument] windowController] activeEditViewController] graphicView] setDisplayString:[currentDisplayString stringByReplacingCharactersInRange:range withString:aDisplayString]];
        } else {
            [[[[[self currentDocument] windowController] activeEditViewController] graphicView] setDisplayString:[currentDisplayString stringByAppendingString:aDisplayString]];
        }
    } else {
        [[[[[self currentDocument] windowController] activeEditViewController] graphicView] setDisplayString:aDisplayString];
    }
    //
    [[[[self currentDocument] windowController] window] orderFront:nil];
    [[self window] orderFront:nil];
    NSUInteger index = [[[_currentFontMasterStore font] fontMasters] indexOfObject:[_currentFontMasterStore fontMaster]];
    if (index != NSNotFound) {
        [[[self currentDocument] windowController] setMasterIndex:index];
    }
}

- (void)jumpBar:(KCJumpBar *)jumpBar didChangeSelection:(KCFontMasterStore *)selection {
    [self setCurrentFontMasterStore:selection];
}

- (void)invalidateJumpBarIfNeeded {
    BOOL shouldInvalidate = NO;
    if (![[[_currentFontMasterStore font] fontMasters] containsObject:[_currentFontMasterStore fontMaster]]) {
        shouldInvalidate = YES;
    }
    if (!shouldInvalidate) {
        shouldInvalidate = YES;
        for (GSDocument *document in [[NSDocumentController sharedDocumentController] documents]) {
            GSFont *font = [document font];
            if ([font isEqual:[_currentFontMasterStore font]]) {
                shouldInvalidate = NO;
                break;
            }
        }
    }
    if (shouldInvalidate) {
        [_jumpBar setSelection:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"kerning"]) {
        [self reloadData];
    } else if ([keyPath isEqualToString:@"fontMasters"]) {
        [self invalidateJumpBarIfNeeded];
    }
}

- (void)copy:(id)sender {
    [self handleCopySlashedGlyphNamesAction:sender];
}

- (void)setSearchType:(KCKerningEntriesQueryType)queryType {
    if (_queryType != queryType) {
        if ([[_searchField stringValue] length] > 0) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reloadData) object:nil];
            [self performSelector:@selector(reloadData) withObject:nil afterDelay:0.33];
        }
        _queryType = queryType;
    }
}

- (IBAction)handleRegularExpressionMenuAction:(id)sender {
    KCKerningEntriesQueryType queryType = ([sender state] != NSOnState) ? KCKerningEntriesQueryTypeDefault : KCKerningEntriesQueryTypeRegularExpression;
    queryType = (queryType == KCKerningEntriesQueryTypeDefault) ? KCKerningEntriesQueryTypeRegularExpression : KCKerningEntriesQueryTypeDefault;
    [sender setState:(queryType == KCKerningEntriesQueryTypeRegularExpression) ? NSOnState : NSOffState];
    [self setSearchType:queryType];
}

- (void)applicationWillResignActive:(NSNotification *)notifiction {
    [[self window] setLevel:NSNormalWindowLevel];
    NSWindow *parentWindow = [[[NSDocumentController sharedDocumentController] currentDocument] windowForSheet];
    if (parentWindow) {
        [[self window] orderWindow:NSWindowAbove relativeTo:[parentWindow windowNumber]];
    } else {
        [[self window] orderWindow:NSWindowBelow relativeTo:0];
    }
}

- (void)applicationWillBecomeActive:(NSNotification *)notifiction {
    [[self window] setLevel:NSFloatingWindowLevel];
}

- (void)windowDidMove:(NSNotification *)notification {
    if ([_delegate respondsToSelector:@selector(windowControllerDidMove:)]) {
        [_delegate windowControllerDidMove:self];
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    if ([_delegate respondsToSelector:@selector(windowControllerDidResize:)]) {
        [_delegate windowControllerDidResize:self];
    }
}

- (void)revealEntryIfAvailable:(KCKerningEntry *)anEntry {
    [_kerningOutlineView expandItem:nil expandChildren:YES];
    NSInteger row = [_kerningOutlineViewHandler rowForItem:anEntry];
    if (row >= 0) {
        [_kerningOutlineView scrollRowToVisible:row];
        [_kerningOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    } else {
        [_kerningOutlineView collapseItem:nil collapseChildren:YES];
    }
}

- (IBAction)handleCopySlashedGlyphNamesAction:(id)sender {
    NSMutableArray *mutableSelectedItems = [[NSMutableArray alloc] initWithCapacity:0];
    [[_kerningOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableSelectedItems addObject:[_kerningOutlineView itemAtRow:idx]];
    }];
    
    NSString *displayString = [self combintionDisplayStringFromEntries:mutableSelectedItems verbosity:KCWindowControllerDisplayStringVerbosityAbridged];
    [[NSPasteboard generalPasteboard] clearContents];
    [[NSPasteboard generalPasteboard] writeObjects:[NSArray arrayWithObject:displayString]];
}

- (IBAction)handleCopyMetricsAction:(id)sender {
    NSMutableArray *mutableSelectedItems = [[NSMutableArray alloc] initWithCapacity:0];
    [[_kerningOutlineView selectedRowIndexes] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
        [mutableSelectedItems addObject:[_kerningOutlineView itemAtRow:idx]];
    }];
    [[NSPasteboard generalPasteboard] clearContents];
    NSString *metricsString = [self metricsStringFromEntries:mutableSelectedItems];
    [[NSPasteboard generalPasteboard] addTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [[NSPasteboard generalPasteboard] setString:metricsString forType:NSStringPboardType];
    id metricsPropertyList = [self metricsPropertyListFromEntries:mutableSelectedItems];
    [[NSPasteboard generalPasteboard] addTypes:[NSArray arrayWithObject:@"GSGlyphsKeringPasteboardType"] owner:nil]; // not GSGlyphsKerningPasteboardType
    [[NSPasteboard generalPasteboard] setPropertyList:metricsPropertyList forType:@"GSGlyphsKeringPasteboardType"];
}

- (IBAction)handleExpandAllAction:(id)sender {
    [_kerningOutlineView expandItem:nil expandChildren:YES];
}

- (IBAction)handleCollapseAllAction:(id)sender {
    [_kerningOutlineView collapseItem:nil collapseChildren:YES];
}

@end
