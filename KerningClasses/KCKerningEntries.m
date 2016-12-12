//
//  KCKerningEntries.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCKerningEntries.h"
#import "KCKerningPair.h"

typedef NS_ENUM(NSUInteger, KCKerningValueFilterStrategy) {
    KCKerningValueFilterStrategyName,
    KCKerningValueFilterStrategyValue
};

typedef NS_ENUM(NSUInteger, KCKerningValueFilterValueComparator) {
    KCKerningValueFilterValueComparatorUndefined,
    KCKerningValueFilterValueComparatorEquals,
    KCKerningValueFilterValueComparatorGreaterThan,
    KCKerningValueFilterValueComparatorGreaterThanOrEquals,
    KCKerningValueFilterValueComparatorLessThan,
    KCKerningValueFilterValueComparatorLessThanOrEquals
};

@interface KCKerningEntryFilter : NSObject

@property (nonatomic, readonly) NSString *queryString;

- (instancetype)initWithQueryString:(NSString *)aQueryString;
- (BOOL)evaluate:(KCKerningPair *)aPair;

@end

@interface KCKerningEntryFilter ()
@property (nonatomic, readonly) KCKerningValueFilterStrategy strategy;
@property (nonatomic, readonly) KCKerningValueFilterValueComparator valueComparator;
@property (nonatomic, readonly) NSInteger thresholdValue;
@end

@implementation KCKerningEntryFilter

- (instancetype)initWithQueryString:(NSString *)aQueryString {
    if ((self = [self init])) {
        _queryString = aQueryString;
        NSRegularExpression *expression = [[NSRegularExpression alloc] initWithPattern:@"^\\s*(>=*|<=*|=+)\\s*([\\-+0-9]+)\\s*$" options:0 error:nil];
        NSTextCheckingResult *match = [expression firstMatchInString:aQueryString options:0 range:NSMakeRange(0, [aQueryString length])];
        if ([match numberOfRanges] == 3) {
            NSString *comparatorString = [aQueryString substringWithRange:[match rangeAtIndex:1]];
            if ([comparatorString hasPrefix:@">="]) {
                _valueComparator = KCKerningValueFilterValueComparatorGreaterThanOrEquals;
            } else if ([comparatorString hasPrefix:@">"]) {
                _valueComparator = KCKerningValueFilterValueComparatorGreaterThan;
            } else if ([comparatorString hasPrefix:@"<="]) {
                _valueComparator = KCKerningValueFilterValueComparatorLessThanOrEquals;
            } else if ([comparatorString hasPrefix:@"<"]) {
                _valueComparator = KCKerningValueFilterValueComparatorLessThan;
            } else if ([comparatorString hasPrefix:@"="]) {
                _valueComparator = KCKerningValueFilterValueComparatorEquals;
            }
            _thresholdValue = [[aQueryString substringWithRange:[match rangeAtIndex:2]] integerValue];
        }
        _strategy = (_valueComparator == KCKerningValueFilterValueComparatorUndefined) ? KCKerningValueFilterStrategyName : KCKerningValueFilterStrategyValue;
    }
    return self;
}

- (BOOL)evaluate:(KCKerningPair *)aPair {
    BOOL result = NO;
    if (_strategy == KCKerningValueFilterStrategyName) {
        if ([[aPair left] containsString:_queryString] || [[aPair right] containsString:_queryString]) {
            result = YES;
        }
    } else if (_strategy == KCKerningValueFilterStrategyValue) {
        switch (_valueComparator) {
            case KCKerningValueFilterValueComparatorEquals:
                result = ([aPair value] == _thresholdValue);
                break;
            case KCKerningValueFilterValueComparatorGreaterThan:
                result = ([aPair value] > _thresholdValue);
                break;
            case KCKerningValueFilterValueComparatorGreaterThanOrEquals:
                result = ([aPair value] >= _thresholdValue);
                break;
            case KCKerningValueFilterValueComparatorLessThan:
                result = ([aPair value] < _thresholdValue);
                break;
            case KCKerningValueFilterValueComparatorLessThanOrEquals:
                result = ([aPair value] <= _thresholdValue);
                break;
            default:
                result = NO;
                break;
        }
    }
    return result;
}

@end

@interface KCKerningEntries ()
@property (nonatomic, readonly) NSDictionary *glyphObjectsFromClassNameDictionary;
@property (nonatomic, readonly) NSDictionary *glyphNamesFromClassNameDictionary;
@property (nonatomic, readonly) KCKerningEntryFilter *filter;
@end

@implementation KCKerningEntries

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster queryString:(NSString *)aQueryString {
    if ((self = [self init])) {
        _fontMaster = aFontMaster;
        _queryString = aQueryString;
        _glyphObjectsFromClassNameDictionary = [self glyphObjectsFromClassNameDictionaryWithFont:[aFontMaster font]];
        _glyphNamesFromClassNameDictionary   = [self glyphNamesFromClassNameDictionaryByNameWithFont:[aFontMaster font]];
        _filter = ([aQueryString length] > 0) ? [[KCKerningEntryFilter alloc] initWithQueryString:aQueryString] : nil;
    }
    return self;
}

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster {
    if ((self = [self initWithFontMaster:aFontMaster queryString:nil])) {
        
    }
    return self;
}

- (BOOL)containsGlyphName:(NSString *)aGlyphName withinClassName:(NSString *)aClassName {
    BOOL contains = NO;
    if (aGlyphName && aClassName) {
        contains = [[_glyphNamesFromClassNameDictionary objectForKey:aClassName] containsObject:aGlyphName] ? YES : NO;
    }
    return contains;
}



- (NSArray<KCKerningEntry *> *)entries {
    //
    GSFont *font = [_fontMaster font];
    NSDictionary *dictionary = [(NSDictionary *)[font kerning] objectForKey:[_fontMaster id]];
    //
    NSMutableOrderedSet *mutableKerningPairs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
    for (NSString *left in dictionary) {
        for (NSString *right in [dictionary objectForKey:left]) {
            NSString *names[2] = {left, right};
            if (![names[0] hasPrefix:@"@"]) names[0] = [[font glyphForId:names[0]] name];
            if (![names[1] hasPrefix:@"@"]) names[1] = [[font glyphForId:names[1]] name];
            NSNumber *value = [[dictionary objectForKey:left] objectForKey:right];
            KCKerningPair *kerningPair = [[KCKerningPair alloc] initWithLeft:names[0] right:names[1] value:[value integerValue]];
            if (_filter && ![_filter evaluate:kerningPair]) continue;
            [mutableKerningPairs addObject:kerningPair];
        }
    }
    //
    NSMutableSet *mutableAggregatedExceptionPairs = [[NSMutableSet alloc] initWithCapacity:0];
    NSMutableDictionary *mutableExceptionDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    for (KCKerningPair *kerningPair in mutableKerningPairs) {
        if ([kerningPair isLeftGrouped] || [kerningPair isRightGrouped]) {
            for (KCKerningPair *anotherPair in mutableKerningPairs) {
                if ([kerningPair isEqual:anotherPair]) continue;
                if ([kerningPair isLeftGrouped] && ![anotherPair isLeftGrouped] && [self containsGlyphName:[anotherPair left] withinClassName:[kerningPair left]]) {
                    if (([kerningPair isRightGrouped] && [self containsGlyphName:[anotherPair right] withinClassName:[kerningPair right]]) || [[kerningPair right] isEqualToString:[anotherPair right]]) {
                        NSMutableOrderedSet *mutableExceptionPairs = [mutableExceptionDictionary objectForKey:kerningPair];
                        if (!mutableExceptionPairs) {
                            mutableExceptionPairs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                            [mutableExceptionDictionary setObject:mutableExceptionPairs forKey:kerningPair];
                        }
                        [mutableExceptionPairs addObject:anotherPair];
                        [mutableAggregatedExceptionPairs addObject:anotherPair];
                    }
                }
                if ([kerningPair isRightGrouped] && ![anotherPair isRightGrouped] && [self containsGlyphName:[anotherPair right] withinClassName:[kerningPair right]]) {
                    if (([kerningPair isLeftGrouped] && [self containsGlyphName:[anotherPair left] withinClassName:[kerningPair left]]) || [[kerningPair left] isEqualToString:[anotherPair left]]) {
                        NSMutableOrderedSet *mutableExceptionPairs = [mutableExceptionDictionary objectForKey:kerningPair];
                        if (!mutableExceptionPairs) {
                            mutableExceptionPairs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                            [mutableExceptionDictionary setObject:mutableExceptionPairs forKey:kerningPair];
                        }
                        [mutableExceptionPairs addObject:anotherPair];
                        [mutableAggregatedExceptionPairs addObject:anotherPair];
                    }
                }
            }
        }
    }
    //
    NSMutableArray *mutableEntries = [[NSMutableArray alloc] initWithCapacity:0];
    for (KCKerningPair *kerningPair in mutableKerningPairs) {
        if ([mutableAggregatedExceptionPairs containsObject:kerningPair]) continue;
        NSArray *exceptions = nil;
        NSOrderedSet *exceptionPairs = [mutableExceptionDictionary objectForKey:kerningPair];
        if ([exceptionPairs count] > 0) {
            NSMutableArray *mutableExceptions = [[NSMutableArray alloc] initWithCapacity:0];
            for (KCKerningPair *exceptionPair in exceptionPairs) {
                [mutableExceptions addObject:[[KCKerningEntry alloc] initWithLeft:[exceptionPair left] right:[exceptionPair right] value:[exceptionPair value] exceptions:nil]];
            }
            exceptions = [mutableExceptions copy];
        }
        KCKerningEntry *entry = [[KCKerningEntry alloc] initWithLeft:[kerningPair left] right:[kerningPair right] value:[kerningPair value] exceptions:exceptions];
        [mutableEntries addObject:entry];
    }
    return [mutableEntries copy];
}

- (NSArray<GSGlyph *> *)glyphsForIdentifier:(NSString *)anIdentifier {
    NSArray *glyphs = nil;
    if (anIdentifier) {
        glyphs = [[_glyphObjectsFromClassNameDictionary objectForKey:anIdentifier] array];
        if (!glyphs) {
            GSFont *font = [_fontMaster font];
            GSGlyph *glyph = [font glyphForId:anIdentifier];
            if (glyph) {
                glyphs = [NSArray arrayWithObject:glyph];
            } else {
                glyph = [font glyphForName:anIdentifier];
                if (glyph) {
                    glyphs = [NSArray arrayWithObject:glyph];
                }
            }
        }
    }
    return glyphs;
}

- (KCKerningEntries *)filteredEntriesWithQueryString:(NSString *)aQueryString {
    return [[[self class] alloc] initWithFontMaster:_fontMaster queryString:aQueryString];
}

#pragma mark -

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark -

- (NSDictionary<NSString *, GSGlyph *> *)glyphObjectsFromClassNameDictionaryWithFont:(GSFont *)aFont {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    for (GSGlyph *glyph in [aFont glyphs]) {
        if ([[glyph leftKerningGroupId] length] > 0) {
            NSMutableOrderedSet *mutableGlyphs = [mutableDictionary objectForKey:[glyph leftKerningGroupId]];
            if (!mutableGlyphs) {
                mutableGlyphs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                [mutableDictionary setObject:mutableGlyphs forKey:[glyph leftKerningGroupId]];
            }
            [mutableGlyphs addObject:glyph];
        }
        if ([[glyph rightKerningGroupId] length] > 0) {
            NSMutableOrderedSet *mutableGlyphs = [mutableDictionary objectForKey:[glyph rightKerningGroupId]];
            if (!mutableGlyphs) {
                mutableGlyphs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                [mutableDictionary setObject:mutableGlyphs forKey:[glyph rightKerningGroupId]];
            }
            [mutableGlyphs addObject:glyph];
        }
    }
    return (NSDictionary *)mutableDictionary;
}

- (NSDictionary<NSString *, NSString *> *)glyphNamesFromClassNameDictionaryByNameWithFont:(GSFont *)aFont {
    NSMutableDictionary *mutableDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    for (GSGlyph *glyph in [aFont glyphs]) {
        if ([[glyph leftKerningGroupId] length] > 0) {
            NSMutableOrderedSet *mutableGlyphs = [mutableDictionary objectForKey:[glyph leftKerningGroupId]];
            if (!mutableGlyphs) {
                mutableGlyphs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                [mutableDictionary setObject:mutableGlyphs forKey:[glyph leftKerningGroupId]];
            }
            [mutableGlyphs addObject:[glyph name]];
        }
        if ([[glyph rightKerningGroupId] length] > 0) {
            NSMutableOrderedSet *mutableGlyphs = [mutableDictionary objectForKey:[glyph rightKerningGroupId]];
            if (!mutableGlyphs) {
                mutableGlyphs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                [mutableDictionary setObject:mutableGlyphs forKey:[glyph rightKerningGroupId]];
            }
            [mutableGlyphs addObject:[glyph name]];
        }
    }
    return (NSDictionary *)mutableDictionary;
}


@end
