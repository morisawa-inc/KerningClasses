//
//  KCGlyphListOutlineViewHandler.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <AppKit/AppKit.h>
#import <GlyphsCore/GlyphsCore.h>
#import <GlyphsCore/GSGlyph.h>

@protocol KCGlyphListOutlineViewHandlerDelegate;
@protocol KCGlyphListOutlineViewHandlerDataSource;

@interface KCGlyphListOutlineViewHandler : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource>

@property (nonatomic, weak) id<KCGlyphListOutlineViewHandlerDelegate> delegate;
@property (nonatomic, weak) id<KCGlyphListOutlineViewHandlerDataSource> dataSource;

- (void)reloadData;

@end

@protocol KCGlyphListOutlineViewHandlerDelegate <NSObject>
- (void)glyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler shouldDisplayTextInTab:(NSString *)text;
@end

@protocol KCGlyphListOutlineViewHandlerDataSource <NSObject>
- (NSArray<GSGlyph *> *)leftGlyphsForGlyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler;
- (NSArray<GSGlyph *> *)rightGlyphsForGlyphListOutlineViewHandler:(KCGlyphListOutlineViewHandler *)handler;
@end
