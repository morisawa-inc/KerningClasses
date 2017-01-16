//
//  KCWindowController.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <GlyphsCore/GlyphsCore.h>
#import "KCKerningEntry.h"

@protocol KCWindowControllerDelegate;

@interface KCWindowController : NSWindowController

@property (nonatomic, weak) id<KCWindowControllerDelegate> delegate;

- (void)revealEntryIfAvailable:(KCKerningEntry *)anEntry;

@end

@protocol KCWindowControllerDelegate <NSObject>
@optional
- (void)windowControllerWillClose:(KCWindowController *)windowController;
- (void)windowControllerDidMove:(KCWindowController *)windowController;
- (void)windowControllerDidResize:(KCWindowController *)windowController;
@end
