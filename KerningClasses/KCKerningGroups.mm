//
//  KCKerningGroups.m
//  KerningClasses
//
//  Created by tfuji on 24/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCKerningGroups.h"
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSFontMaster.h>
#import <GlyphsCore/GSGlyph.h>

#include <unordered_set>

struct KCGroupedGlyphEntry {
    __unsafe_unretained NSString *group;
    __unsafe_unretained NSString *name;
    struct Hash;
    KCGroupedGlyphEntry(__unsafe_unretained NSString *group, __unsafe_unretained NSString *name);
    bool operator==(const KCGroupedGlyphEntry& rhs) const;
    bool operator!=(const KCGroupedGlyphEntry& rhs) const;
};

inline KCGroupedGlyphEntry::KCGroupedGlyphEntry(__unsafe_unretained NSString *group, __unsafe_unretained NSString *name) {
    this->group = group;
    this->name  = name;
}

inline bool KCGroupedGlyphEntry::operator==(const KCGroupedGlyphEntry& rhs) const {
    const KCGroupedGlyphEntry& lhs = *this;
    return [lhs.group isEqualToString:rhs.group] && [lhs.name isEqualToString:rhs.name];
}

inline bool KCGroupedGlyphEntry::operator!=(const KCGroupedGlyphEntry& rhs) const {
    return !(this->operator==(rhs));
}

struct KCGroupedGlyphEntry::Hash {
    typedef std::size_t result_type;
    std::size_t operator()(const KCGroupedGlyphEntry& e) const;
};

inline std::size_t KCGroupedGlyphEntry::Hash::operator()(const KCGroupedGlyphEntry& e) const {
    return [e.group hash] ^ [e.name hash];
}

typedef std::unordered_set<KCGroupedGlyphEntry, KCGroupedGlyphEntry::Hash> KCGroupedGlyphEntrySet;

/*
@interface KCGroupedGlyphEntry : NSObject <NSCopying>
@property (nonatomic, readonly) NSString *group;
@property (nonatomic, readonly) NSString *name;
@end

@implementation KCGroupedGlyphEntry

- (instancetype)initWithGroup:(NSString *)aGroup name:(NSString *)aName {
    if ((self = [self init])) {
        _group = aGroup;
        _name  = aName;
    }
    return self;
}

- (NSUInteger)hash {
    return [_group hash] ^ [_name hash];
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if (self == object) {
        isEqual = YES;
    } else {
        if ([object isKindOfClass:[self class]]) {
            if ([((KCGroupedGlyphEntry *)object)->_group isEqualToString:_group]) {
                if ([((KCGroupedGlyphEntry *)object)->_name isEqualToString:_name]) {
                    isEqual = YES;
                }
            }
        }
    }
    return isEqual;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

@end

*/

@interface KCKerningGroups () {
@private
    NSOrderedSet *_leftGroups;
    NSOrderedSet *_rightGroups;
    NSOrderedSet *_allGroups;
    NSDictionary *_glyphsByGroupDictionary;
    NSDictionary *_glyphsByGroupAndNameDictionary;
    KCGroupedGlyphEntrySet _groupedEntrySet;
    // NSSet<KCGroupedGlyphEntry *> *_groupedEntrySet;
}
@end

@implementation KCKerningGroups

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster {
    if ((self = [self init])) {
        _fontMaster = aFontMaster;
        [self prepareIvarsWithFont:[aFontMaster font]];
    }
    return self;
}

- (NSOrderedSet<NSString *> *)groupsForType:(KCKerningGroupType)aType {
    NSOrderedSet *groups = nil;
    if (aType & KCKerningGroupTypeAll) {
        groups = _allGroups;
    } else if (aType & KCKerningGroupTypeLeft) {
        groups = _leftGroups;
    } else if (aType & KCKerningGroupTypeRight) {
        groups = _rightGroups;
    }
    return groups;
}

- (NSOrderedSet<GSGlyph *> *)glyphsForGroup:(__unsafe_unretained NSString *)aGroup {
    NSOrderedSet<GSGlyph *> *glyphs = nil;
    if (aGroup) {
        glyphs = [_glyphsByGroupDictionary objectForKey:aGroup];
    }
    return [glyphs copy];
}

- (NSOrderedSet<GSGlyph *> *)glyphsForIdentifier:(__unsafe_unretained NSString *)anIdentifier {
    NSOrderedSet<GSGlyph *> *glyphs = nil;
    if (anIdentifier) {
        glyphs = [_glyphsByGroupAndNameDictionary objectForKey:anIdentifier];
    }
    return [glyphs copy];
}


- (BOOL)containsGlyphName:(__unsafe_unretained NSString *)aGlyphName withinGroup:(__unsafe_unretained NSString *)aGroup {
    BOOL containsGlyphName = NO;
    if (aGlyphName && aGroup) {
        containsGlyphName = _groupedEntrySet.find(KCGroupedGlyphEntry(aGroup, aGlyphName)) != _groupedEntrySet.end();
        // __autoreleasing KCGroupedGlyphEntry *entry = [[KCGroupedGlyphEntry alloc] initWithGroup:aGroup name:aGlyphName];
        // containsGlyphName = [_groupedEntrySet containsObject:entry];
    }
    return containsGlyphName;
}

- (void)prepareIvarsWithFont:(GSFont *)aFont {
    NSMutableDictionary *mutableGroupedGlyphsDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    // NSMutableSet *mutableGroupedEntrySet    = [[NSMutableSet alloc] initWithCapacity:0];
    NSMutableOrderedSet *mutableAllGroups   = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    NSMutableOrderedSet *mutableLeftGroups  = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    NSMutableOrderedSet *mutableRightGroups = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    for (GSGlyph *glyph in [aFont glyphs]) {
        if ([[glyph leftKerningGroupId] length] > 0) {
            // Dictionary
            NSMutableOrderedSet *mutableGlyphs = [mutableGroupedGlyphsDictionary objectForKey:[glyph leftKerningGroupId]];
            if (!mutableGlyphs) {
                mutableGlyphs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                [mutableGroupedGlyphsDictionary setObject:mutableGlyphs forKey:[glyph leftKerningGroupId]];
            }
            [mutableGlyphs addObject:glyph];
            // Set
            // KCGroupedGlyphEntry *entry = [[KCGroupedGlyphEntry alloc] initWithGroup:[glyph leftKerningGroupId] name:[glyph name]];
            // [mutableGroupedEntrySet addObject:entry];
            _groupedEntrySet.emplace(KCGroupedGlyphEntry([glyph leftKerningGroupId], [glyph name]));
            [mutableLeftGroups addObject:[glyph leftKerningGroupId]];
            [mutableAllGroups  addObject:[glyph leftKerningGroupId]];
        }
        if ([[glyph rightKerningGroupId] length] > 0) {
            // Dictionary
            NSMutableOrderedSet *mutableGlyphs = [mutableGroupedGlyphsDictionary objectForKey:[glyph rightKerningGroupId]];
            if (!mutableGlyphs) {
                mutableGlyphs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                [mutableGroupedGlyphsDictionary setObject:mutableGlyphs forKey:[glyph rightKerningGroupId]];
            }
            [mutableGlyphs addObject:glyph];
            // Set
            // KCGroupedGlyphEntry *entry = [[KCGroupedGlyphEntry alloc] initWithGroup:[glyph rightKerningGroupId] name:[glyph name]];
            // [mutableGroupedEntrySet addObject:entry];
            _groupedEntrySet.emplace(KCGroupedGlyphEntry([glyph rightKerningGroupId], [glyph name]));
            [mutableRightGroups addObject:[glyph rightKerningGroupId]];
            [mutableAllGroups   addObject:[glyph rightKerningGroupId]];
        }
    }
    _glyphsByGroupDictionary = [mutableGroupedGlyphsDictionary copy];
    // _groupedEntrySet = [mutableGroupedEntrySet copy];
    _leftGroups  = [mutableLeftGroups copy];
    _rightGroups = [mutableRightGroups copy];
    _allGroups   = [mutableAllGroups copy];
    for (GSGlyph *glyph in [aFont glyphs]) {
        [mutableGroupedGlyphsDictionary setObject:[NSOrderedSet orderedSetWithObject:glyph] forKey:[glyph name]];
    }
    _glyphsByGroupAndNameDictionary = [mutableGroupedGlyphsDictionary copy];
}

@end
