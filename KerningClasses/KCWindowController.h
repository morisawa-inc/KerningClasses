//
//  KCWindowController.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <GlyphsCore/GlyphsCore.h>

@class GSDocument;
@protocol KCWindowControllerDelegate;
@protocol KCWindowControllerDataSource;

@interface KCWindowController : NSWindowController

@property (nonatomic, weak) id<KCWindowControllerDelegate> delegate;
@property (nonatomic, weak) id<KCWindowControllerDataSource> dataSource;

- (void)reloadData;

@end

@protocol KCWindowControllerDelegate <NSObject>
@optional
- (void)windowControllerWillClose:(KCWindowController *)windowController;
@end

@protocol KCWindowControllerDataSource <NSObject>
@optional
- (GSDocument *)documentForWindowController:(KCWindowController *)windowController;
@end
