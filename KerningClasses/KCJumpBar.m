//
//  KCJumpBar.m
//  KerningClasses
//
//  Created by tfuji on 21/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCJumpBar.h"
#import <GlyphsCore/GSWindowControllerProtocol.h>

@interface GSDocument : NSDocument
@property(readonly, nonatomic) NSWindowController<GSWindowControllerProtocol> *windowController;
@property(readonly, nonatomic) GSFontMaster *selectedFontMaster;
@property(retain, nonatomic) GSFont *font;
@end

@interface KCJumpBar () <RSJumpBarDelegate, RSJumpBarDataSource> {
@private
    id _delegate;
}
@end

@implementation KCJumpBar

- (void)prepareForInterfaceBuilder {
    [self setSelectedItem:[[[RSJumpBarItem alloc] initWithTitle:@"Example.glyphs" image:[NSImage imageNamed:@"NSPathTemplate"] objectValue:@"Item 3"] itemByAssigningParentItem:[[[RSJumpBarItem alloc] initWithTitle:@"Item 2" image:[NSImage imageNamed:@"NSPathTemplate"] objectValue:@"Item 2"] itemByAssigningParentItem:[[RSJumpBarItem alloc] initWithTitle:@"Item 1" image:[NSImage imageNamed:@"NSPathTemplate"] objectValue:@"Item 1"]]]];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [super setDelegate:(id)self];
        [super setDataSource:(id)self];
        [self setSelection:nil];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        [super setDelegate:(id)self];
        [super setDataSource:(id)self];
        [self setSelection:nil];
    }
    return self;
}

- (id)delegate {
    return _delegate;
}

- (void)setDelegate:(id<RSJumpBarDelegate>)aDelegate {
    _delegate = aDelegate;
}

- (KCFontMasterStore *)selection {
    GSFontMaster *fontMaster = [[self selectedItem] objectValue];
    GSFont *font = [[[self selectedItem] parentItem] objectValue];
    return [[KCFontMasterStore alloc] initWithFontMaster:fontMaster font:font];
}

- (void)setSelection:(KCFontMasterStore *)aSelection {
    if (aSelection) {
        [self setSelectedItem:[aSelection jumpBarItem]];
    } else {
        [self setSelectedItem:[[[KCFontMasterStore alloc] init] jumpBarItem]];
    }
}

- (void)jumpBar:(RSJumpBar *)jumpBar didSelectItem:(RSJumpBarItem *)item {
    if ([_delegate respondsToSelector:@selector(jumpBar:didChangeSelection:)]) {
        [_delegate jumpBar:self didChangeSelection:[self selection]];
    }
}

- (NSUInteger)jumpBar:(RSJumpBar *)jumpBar numberOfItemsForItem:(RSJumpBarItem *)item {
    NSUInteger numberOfItems = 0;
    if (item) {
        if ([[item objectValue] isKindOfClass:[GSFont class]]) {
            GSFont *font = (GSFont *)[item objectValue];
            numberOfItems = [[font fontMasters] count];
        }
    } else {
        numberOfItems = [[[NSDocumentController sharedDocumentController] documents] count];
    }
    return numberOfItems;
}

- (RSJumpBarItem *)jumpBar:(RSJumpBar *)jumpBar childAtIndex:(NSUInteger)index ofItem:(RSJumpBarItem *)item {
    RSJumpBarItem *childItem = nil;
    if (item) {
        GSFont *font = (GSFont *)[item objectValue];
        GSFontMaster *fontMaster = [[font fontMasters] objectAtIndex:index];
        KCFontMasterStore *selection = [[KCFontMasterStore alloc] initWithFontMaster:fontMaster font:font];
        childItem = [selection jumpBarItem];
    } else {
        GSDocument *document = [[[NSDocumentController sharedDocumentController] documents] objectAtIndex:index];
        KCFontMasterStore *selection = [[KCFontMasterStore alloc] initWithFontMaster:nil font:[document font]];
        childItem = [selection jumpBarItem];
    }
    return childItem;
}

@end
