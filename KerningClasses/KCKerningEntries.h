//
//  KCKerningEntries.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GlyphsCore/GlyphsCore.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSFontMaster.h>
#import <GlyphsCore/GSGlyph.h>
#import "KCKerningEntry.h"

@interface KCKerningEntries : NSObject <NSCopying>

@property (nonatomic, readonly) GSFontMaster *fontMaster;
@property (nonatomic, readonly) NSString *queryString;

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster;

- (NSArray<KCKerningEntry *> *)entries;
- (NSArray<GSGlyph *> *)glyphsForIdentifier:(NSString *)aIdentifier;

- (KCKerningEntries *)filteredEntriesWithQueryString:(NSString *)aQueryString;

@end
