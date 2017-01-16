//
//  KerningClasses.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KerningClassesPlugin.h"
#import <AppKit/AppKit.h>
#import "KCWindowController.h"
#import <GlyphsCore/GlyphsCore.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSFontMaster.h>
#import <GlyphsCore/GSWindowControllerProtocol.h>
#import <GlyphsCore/GSGlyphEditViewProtocol.h>
#import <GlyphsCore/GSGlyphViewControllerProtocol.h>
#import <GlyphsCore/GSGlyph.h>
#import <GlyphsCore/GSLayer.h>

static NSUInteger NSMutableIndexSetConsumeNewIndex(NSMutableIndexSet *set) {
    __block NSUInteger index = NSNotFound;
    [set enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
        if (range.location > 0) {
            index = 0;
        } else {
            index = range.location + range.length;
        }
        [set addIndex:index];
        *stop = YES;
    }];
    if (index == NSNotFound) {
        index = 0;
        [set addIndex:0];
    }
    return index;
}

@interface KerningClassesPlugin () <KCWindowControllerDelegate>
@property(nonatomic, readonly) NSMutableArray<NSMenuItem *> *menuItems;
@property(nonatomic, readonly) GSDocument *document;
@property(nonatomic, readonly) NSMutableIndexSet *mutableWindowIndexes;
@end

@interface GSDocument : NSDocument
@property(readonly, nonatomic) NSWindowController *windowController;
@property(readonly, nonatomic) GSFontMaster *selectedFontMaster;
@property(readonly, nonatomic) NSArray *selectedLayers;
@property(retain, nonatomic) GSFont *font;
- (unsigned long long)masterIndex;
@end

@implementation KerningClassesPlugin

- (id)init {
    if ((self = [super init])) {
        _windowControllers = [[NSMutableArray alloc] initWithCapacity:0];
        _menuItems = [[NSMutableArray alloc] initWithCapacity:0];
        _mutableWindowIndexes = [[NSMutableIndexSet alloc] init];
    }
    return self;
}

- (NSUInteger)interfaceVersion {
    return 1;
}

- (NSMenuItem *)newDocumentMenuItem {
    for (NSMenuItem *menuItem in [[NSApp mainMenu] itemArray]) {
        for (NSMenuItem *submenuItem in [[menuItem submenu] itemArray]) {
            if ([submenuItem action] == @selector(newDocument:)) { // [New...]
                return submenuItem;
            }
        }
    }
    return nil;
}

- (NSMenuItem *)compareFontsMenuItem {
    for (NSMenuItem *menuItem in [[NSApp mainMenu] itemArray]) {
        for (NSMenuItem *submenuItem in [[menuItem submenu] itemArray]) {
            if ([submenuItem action] == NSSelectorFromString(@"compareFonts:")) {
                return submenuItem;
            }
        }
    }
    return nil;
}


- (NSString *)title {
    return NSLocalizedString(@"New Kerning Window", nil);
}

- (void)loadPlugin {
    NSMenuItem *newDocumentMenuItem = [self newDocumentMenuItem];
    if (newDocumentMenuItem) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[self title] action:@selector(handleNewKerningWindow:) keyEquivalent:@"K"];
        [menuItem setKeyEquivalentModifierMask: NSShiftKeyMask | NSCommandKeyMask | NSAlternateKeyMask];
        [menuItem setTarget:self];
        [[newDocumentMenuItem menu] insertItem:menuItem atIndex:[[newDocumentMenuItem menu] indexOfItem:newDocumentMenuItem] + 1];
    }
    NSMenuItem *compareFontsMenuItem = [self compareFontsMenuItem];
    if (compareFontsMenuItem) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reveal in Kerning Window", nil) action:@selector(handleRevealInKerningWindow:) keyEquivalent:@""];
        [menuItem setTarget:self];
        [[compareFontsMenuItem menu] insertItem:menuItem atIndex:[[compareFontsMenuItem menu] indexOfItem:compareFontsMenuItem] + 1];
        [[compareFontsMenuItem menu] insertItem:[NSMenuItem separatorItem] atIndex:[[compareFontsMenuItem menu] indexOfItem:compareFontsMenuItem] + 1];
    }
}

- (void)handleNewKerningWindow:(id)sender {
    KCWindowController *windowController = [[KCWindowController alloc] init];
    [windowController setDelegate:self];
    [[windowController window] orderFrontRegardless];
    [[windowController window] makeKeyWindow];
    [windowController showWindow:nil];
    NSUInteger index = NSMutableIndexSetConsumeNewIndex(_mutableWindowIndexes);
    [_windowControllers insertObject:windowController atIndex:index];
    {
        NSString *name = [NSString stringWithFormat:@"KerningClassesPluginWindow%lu", index + 1];
        [[windowController window] setFrameUsingName:name];
        [[windowController window] setTitle:[NSString stringWithFormat:@"Kerning Window: #%lu", index + 1]];
    }
}

- (void)handleRevealInKerningWindow:(id)sender {
    GSDocument *currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
    NSViewController<GSGlyphEditViewControllerProtocol> *editViewController = [(NSViewController<GSWindowControllerProtocol> *)[currentDocument windowController] activeEditViewController];
    NSView <GSGlyphEditViewProtocol, NSTextInputClient> *graphicView = [editViewController graphicView];
    NSUInteger location = [graphicView cachedSelectionRange].location;
    if (location > 0) {
        GSLayer *leftLayer  = [graphicView cachedGlyphAtIndex:location - 1];
        GSLayer *rightLayer = [graphicView cachedGlyphAtIndex:location + 0];
        if (leftLayer && rightLayer) {
            NSString *leftGroup  = [[leftLayer  glyph] rightKerningGroupId];
            NSString *rightGroup = [[rightLayer glyph] leftKerningGroupId];
            //
            KCWindowController *windowController = [[KCWindowController alloc] init];
            [windowController setDelegate:self];
            [[windowController window] orderFrontRegardless];
            [[windowController window] makeKeyWindow];
            [windowController showWindow:nil];
            NSUInteger index = NSMutableIndexSetConsumeNewIndex(_mutableWindowIndexes);
            [_windowControllers insertObject:windowController atIndex:index];
            {
                NSString *name = [NSString stringWithFormat:@"KerningClassesPluginWindow%lu", index + 1];
                [[windowController window] setFrameUsingName:name];
                [[windowController window] setTitle:[NSString stringWithFormat:@"Kerning Window: #%lu", index + 1]];
                [windowController revealEntryIfAvailable:[[KCKerningEntry alloc] initWithLeft:leftGroup right:rightGroup]];
            }
        }
    }
}

- (void)windowControllerWillClose:(KCWindowController *)windowController {
    NSUInteger index = [_windowControllers indexOfObject:windowController];
    if (index != NSNotFound) {
        NSString *name = [NSString stringWithFormat:@"KerningClassesPluginWindow%lu", index + 1];
        [[windowController window] saveFrameUsingName:name];
    }
    [_windowControllers removeObject:windowController];
    [_mutableWindowIndexes removeIndex:index];
}

- (void)windowControllerDidMove:(KCWindowController *)windowController {
    NSUInteger index = [_windowControllers indexOfObject:windowController];
    if (index != NSNotFound) {
        NSString *name = [NSString stringWithFormat:@"KerningClassesPluginWindow%lu", index + 1];
        [[windowController window] saveFrameUsingName:name];
    }
}

- (void)windowControllerDidResize:(KCWindowController *)windowController {
    NSUInteger index = [_windowControllers indexOfObject:windowController];
    if (index != NSNotFound) {
        NSString *name = [NSString stringWithFormat:@"KerningClassesPluginWindow%lu", index + 1];
        [[windowController window] saveFrameUsingName:name];
    }
}

@end
