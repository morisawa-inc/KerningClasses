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

#import <GlyphsCore/GSWindowControllerProtocol.h>
#import <GlyphsCore/GSGlyphEditViewProtocol.h>
#import <GlyphsCore/GSGlyphViewControllerProtocol.h>

@interface GSDocument : NSDocument
@property(readonly, nonatomic) NSWindowController<GSWindowControllerProtocol> *windowController;
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
@property (nonatomic) IBOutlet NSOutlineView *kerningOutlineView;
@property (nonatomic) IBOutlet NSOutlineView *glyphListOutlineView;
@property (nonatomic) KCKerningOutlineViewHandler *kerningOutlineViewHandler;
@property (nonatomic) KCGlyphListOutlineViewHandler *glyphListOutlineViewHandler;
@property (nonatomic) GSDocument *currentDocument;
@property (nonatomic) KCKerningEntries *entries;
@property (nonatomic) KCKerningEntries *filteredEntries;
@property (nonatomic) NSArray<GSGlyph *> *leftGlyphs;
@property (nonatomic) NSArray<GSGlyph *> *rightGlyphs;

@end

@implementation KCWindowController

- (instancetype)init {
    if ((self = [self initWithWindowNibName:@"KCWindowController"])) {
        
    }
    return self;
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
    [[self window] setLevel:NSFloatingWindowLevel];
    [self reloadData];
    
    [self setShouldCascadeWindows:NO];
    [self setWindowFrameAutosaveName:NSStringFromClass([self class])];
}

- (void)windowWillClose:(NSNotification *)notification {
    if ([_delegate respondsToSelector:@selector(windowControllerWillClose:)]) {
        [_delegate windowControllerWillClose:self];
    }
}

- (void)reloadData {
    GSDocument *currentDocument = [_dataSource documentForWindowController:self];
    if (![currentDocument isEqual:_currentDocument]) {
        _currentDocument = currentDocument;
        _filteredEntries = nil;
        _leftGlyphs  = nil;
        _rightGlyphs = nil;
    }
    [_kerningOutlineView   reloadData];
    [_glyphListOutlineView reloadData];
}

- (NSArray<NSSortDescriptor *> *)sortDescriptorsForKerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler {
    return [_kerningOutlineView sortDescriptors];
}

- (NSArray<KCKerningEntry *> *)entriesForKerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler {
    if (_currentDocument) {
        GSFontMaster *fontMaster = [_currentDocument selectedFontMaster];
        KCKerningEntries *entries = [[KCKerningEntries alloc] initWithFontMaster:fontMaster];
        _entries = entries;
        if ([[_searchField stringValue] length] > 0) {
            _filteredEntries = [_entries filteredEntriesWithQueryString:[_searchField stringValue]];
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
    [self setDisplayString:displayString];
}

- (void)kerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler shouldDisplayTextInTabForEntries:(NSArray<KCKerningEntry *> *)entries {
    NSMutableArray *mutableTextLines = [[NSMutableArray alloc] initWithCapacity:0];
    for (KCKerningEntry *entry in entries) {
        NSMutableString *mutableDisplayString = [[NSMutableString alloc] initWithCapacity:0];
        NSArray<GSGlyph *> *leftGlyphs  = [_entries glyphsForIdentifier:[entry left]];
        NSArray<GSGlyph *> *rightGlyphs = [_entries glyphsForIdentifier:[entry right]];
        for (GSGlyph *leftGlyph in leftGlyphs) {
            for (GSGlyph *rightGlyph in rightGlyphs) {
                [mutableDisplayString appendFormat:@"/%@ /%@", [leftGlyph name], [rightGlyph name]];
            }
        }
        [mutableTextLines addObject:[mutableDisplayString copy]];
    }
    NSString *displayString = [mutableTextLines componentsJoinedByString:@"\n"];
    [self setDisplayString:displayString];
}

- (void)glyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler shouldDisplayTextInTab:(NSString *)text {
    [self setDisplayString:text];
}

- (NSArray<GSGlyph *> *)leftGlyphsForGlyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler {
    return _leftGlyphs;
}

- (NSArray<GSGlyph *> *)rightGlyphsForGlyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler {
    return _rightGlyphs;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    [_kerningOutlineView   reloadData];
    [_glyphListOutlineView reloadData];
}

- (IBAction)performFindPanelAction:(id)sender {
    [[self window] makeFirstResponder:_searchField];
}

- (NSString *)displayString {
    return [[[[_currentDocument windowController] activeEditViewController] graphicView] displayString];
}

- (void)setDisplayString:(NSString *)aDisplayString {
    NSRange range = [[[[[_currentDocument windowController] activeEditViewController] graphicView] textStorage] selectedRange];
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
            [[[[_currentDocument windowController] activeEditViewController] graphicView] setDisplayString:[currentDisplayString stringByReplacingCharactersInRange:range withString:aDisplayString]];
        } else {
            [[[[_currentDocument windowController] activeEditViewController] graphicView] setDisplayString:[currentDisplayString stringByAppendingString:aDisplayString]];
        }
    } else {
        [[[[_currentDocument windowController] activeEditViewController] graphicView] setDisplayString:aDisplayString];
    }
}

@end
