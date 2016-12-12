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

@interface KerningClassesPlugin () <KCWindowControllerDelegate, KCWindowControllerDataSource>
@property(nonatomic, readonly) NSMutableArray<NSMenuItem *> *menuItems;
@property(nonatomic, readonly) GSDocument *document;
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidBecomeKeyNotification:) name:NSWindowDidBecomeKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowDidResignKeyNotification:) name:NSWindowDidResignKeyNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWindowWillCloseNotification:) name:NSWindowWillCloseNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:nil];
}

- (NSUInteger)interfaceVersion {
    return 1;
}

- (NSMenuItem *)windowMenu {
    for (NSMenuItem *menuItem in [[NSApp mainMenu] itemArray]) {
        for (NSMenuItem *submenuItem in [[menuItem submenu] itemArray]) {
            if ([submenuItem action] == @selector(performMiniaturize:)) { // [Minimize]
                return menuItem;
            }
        }
    }
    return nil;
}

- (NSString *)title {
    return NSLocalizedString(@"Kerning Classes", nil);
}

- (NSString *)titleForIndex:(NSUInteger)anIndex {
    if ([self numberOfInstances] >= 2) {
        return [NSString stringWithFormat:@"%@ (%lu)", [self title], anIndex + 1];
    }
    return [self title];
}

- (NSUInteger)numberOfInstances {
    NSUInteger numberOfInstances = 1;
    NSNumber *value = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"KCNumberOfInstances"];
    if (value) {
        numberOfInstances = MAX([value integerValue], 1);
    }
    return numberOfInstances;
}

- (void)loadPlugin {
    NSMenuItem *windowMenu = [self windowMenu];
    if (windowMenu) {
        [[windowMenu submenu] addItem:[NSMenuItem separatorItem]];
        for (NSUInteger i = 0; i < [self numberOfInstances]; ++i) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[self titleForIndex:i] action:@selector(handleShowWindow:) keyEquivalent:@""];
            [menuItem setTarget:self];
            [[windowMenu submenu] addItem:menuItem];
            [_menuItems addObject:menuItem];
        }
    }
}

- (void)handleShowWindow:(id)sender {
    NSInteger state = ([(NSMenuItem *)sender state] == NSOffState) ? NSOnState : NSOffState;
    if (state == NSOnState) {
        
    } else {
        for (NSWindowController *windowController in _windowControllers) {
            [windowController performSelector:@selector(close) withObject:nil afterDelay:0.0];
        }
    }
    [(NSMenuItem *)sender setState:state];
    
    KCWindowController *windowController = [[KCWindowController alloc] init];
    [windowController setDelegate:self];
    [windowController setDataSource:self];
    [[windowController window] center];
    [[windowController window] orderFrontRegardless];
    [[windowController window] makeKeyWindow];
    [windowController showWindow:nil];
    [_windowControllers addObject:windowController];
    
    [self reloadData];
}

- (void)windowControllerWillClose:(KCWindowController *)windowController {
    NSUInteger index = [_windowControllers indexOfObject:windowController];
    [_windowControllers removeObject:windowController];
    if (index != NSNotFound) {
        NSMenuItem *menuItem = [_menuItems objectAtIndex:index];
        [menuItem setState:NSOffState];
    }
}

- (void)reloadData {
    GSDocument *document = (GSDocument *)[[NSDocumentController sharedDocumentController] currentDocument];
    if (![document isEqual:_document]) {
        [[_document font] removeObserver:self forKeyPath:@"kerning" context:NULL];
        [[document  font] addObserver:self forKeyPath:@"kerning" options:0 context:NULL];
        [[_document windowController] removeObserver:self forKeyPath:@"masterIndex" context:NULL];
        [[document windowController] addObserver:self forKeyPath:@"masterIndex" options:0 context:NULL];
        _document = document;
        for (KCWindowController *windowController in _windowControllers) {
            [windowController reloadData];
        }
    }
}

- (void)handleWindowDidBecomeKeyNotification:(NSNotification *)notification {
    NSLog(@"%@", notification);
    if ([[notification object] isKindOfClass:NSClassFromString(@"GSWindow")]) {
        [self reloadData];
    }
}

- (void)handleWindowDidResignKeyNotification:(NSNotification *)notification {
    NSLog(@"%@", notification);
    if ([[notification object] isKindOfClass:NSClassFromString(@"GSWindow")]) {
        [self reloadData];
    }
}

- (void)handleWindowWillCloseNotification:(NSNotification *)notification {
    NSLog(@"%@", notification);
    if ([[notification object] isKindOfClass:NSClassFromString(@"GSWindow")]) {
        [self reloadData];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"kerning"] || [keyPath isEqualToString:@"masterIndex"]) {
        for (KCWindowController *windowController in _windowControllers) {
            [windowController reloadData];
        }
    }
}

- (GSDocument *)documentForWindowController:(KCWindowController *)windowController {
    return _document;
}

@end
