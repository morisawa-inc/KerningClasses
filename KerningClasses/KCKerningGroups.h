//
//  KCKerningGroups.h
//  KerningClasses
//
//  Created by tfuji on 24/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GlyphsCore/GSFont.h>

typedef enum KCKerningGroupType {
    KCKerningGroupTypeNone  = 0,
    KCKerningGroupTypeLeft  = 1 << 0,
    KCKerningGroupTypeRight = 1 << 1,
    KCKerningGroupTypeAll   = KCKerningGroupTypeLeft | KCKerningGroupTypeRight
} KCKerningGroupType;

@interface KCKerningGroups : NSObject

@property (nonatomic, readonly) GSFontMaster *fontMaster;

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster;

- (NSArray<NSString *> *)groupsForType:(KCKerningGroupType)aType;
- (NSOrderedSet<GSGlyph *> *)glyphsForGroup:(__unsafe_unretained NSString *)aGroup;
- (NSOrderedSet<GSGlyph *> *)glyphsForIdentifier:(__unsafe_unretained NSString *)anIdentifier;
- (BOOL)containsGlyphName:(__unsafe_unretained NSString *)aGlyphName withinGroup:(__unsafe_unretained NSString *)aGroup;

@end
