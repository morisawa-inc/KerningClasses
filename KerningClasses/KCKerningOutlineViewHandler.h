//
//  KCKerningOutlineViewHandler.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "KCKerningEntry.h"
#import <GlyphsCore/GlyphsCore.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSFontMaster.h>

@protocol KCKerningOutlineViewHandlerDelegate;
@protocol KCKerningOutlineViewHandlerDataSource;

@interface KCKerningOutlineViewHandler : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (nonatomic, weak) id<KCKerningOutlineViewHandlerDelegate> delegate;
@property (nonatomic, weak) id<KCKerningOutlineViewHandlerDataSource> dataSource;

- (NSArray<id> *)expandedItems;

- (void)reloadData;
- (void)resetExpandedItems;

- (NSInteger)rowForItem:(id)item;

@end

@protocol KCKerningOutlineViewHandlerDelegate <NSObject>
- (void)kerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler didSelectRowWithLeftIdentifiers:(NSArray<NSString *> *)leftIdentifiers rightIdentifiers:(NSArray<NSString *> *)rightIdentifiers;
- (void)kerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler shouldDisplayTextInTabForEntries:(NSArray<KCKerningEntry *> *)entries;
@end

@protocol KCKerningOutlineViewHandlerDataSource <NSObject>
- (NSArray<NSSortDescriptor *> *)sortDescriptorsForKerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler;
- (NSArray<KCKerningEntry *> *)entriesForKerningOutlineViewHandler:(KCKerningOutlineViewHandler *)handler;
@end
