//
//  KCKerningEntries.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCKerningEntries.h"
#import "KCKerningPair.h"
#import "KCKerningGroups.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullability-completeness"
#import <GlyphsCore/GSLayer.h>
#pragma clang diagnostic pop

typedef NS_ENUM(NSUInteger, KCKerningValueFilterStrategy) {
    KCKerningValueFilterStrategyNameDefault,
    KCKerningValueFilterStrategyNameRegularExpression,
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

- (instancetype)initWithQueryString:(NSString *)aQueryString queryType:(KCKerningEntriesQueryType)aQueryType;
- (BOOL)evaluate:(KCKerningPair *)aPair;

@end

@interface KCKerningEntryFilter ()
@property (nonatomic, readonly) KCKerningValueFilterStrategy strategy;
@property (nonatomic, readonly) KCKerningValueFilterValueComparator valueComparator;
@property (nonatomic, readonly) NSInteger thresholdValue;
@end

@implementation KCKerningEntryFilter

- (instancetype)initWithQueryString:(NSString *)aQueryString queryType:(KCKerningEntriesQueryType)aQueryType {
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
        _strategy = (_valueComparator == KCKerningValueFilterValueComparatorUndefined) ? KCKerningValueFilterStrategyNameDefault : KCKerningValueFilterStrategyValue;
        if (aQueryType == KCKerningEntriesQueryTypeRegularExpression && _strategy == KCKerningValueFilterStrategyNameDefault) {
            _strategy = KCKerningValueFilterStrategyNameRegularExpression;
        }
    }
    return self;
}

- (BOOL)evaluate:(KCKerningPair *)aPair {
    BOOL result = NO;
    if (_strategy == KCKerningValueFilterStrategyNameDefault) {
        if ([[aPair left] containsString:_queryString] || [[aPair right] containsString:_queryString]) {
            result = YES;
        }
    } else if (_strategy == KCKerningValueFilterStrategyNameRegularExpression) {
        NSString *queryString = _queryString;
        if (![queryString hasPrefix:@"^"]) queryString = [@"^" stringByAppendingString:queryString];
        if (![queryString hasSuffix:@"$"]) queryString = [queryString stringByAppendingString:@"$"];
        NSRegularExpression *pattern = [[NSRegularExpression alloc] initWithPattern:queryString options:0 error:nil];
        if ([pattern rangeOfFirstMatchInString:[aPair left]  options:0 range:NSMakeRange(0, [[aPair left]  length])].location != NSNotFound ||
            [pattern rangeOfFirstMatchInString:[aPair right] options:0 range:NSMakeRange(0, [[aPair right] length])].location != NSNotFound) {
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
@property (nonatomic, readonly) KCKerningGroups *kerningGroups;
@end

@implementation KCKerningEntries

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster queryString:(NSString *)aQueryString type:(KCKerningEntriesQueryType)aQueryType {
    if ((self = [self init])) {
        
        _fontMaster = aFontMaster;
        _queryString = aQueryString;
        _queryType = aQueryType;
        _kerningGroups = [[KCKerningGroups alloc] initWithFontMaster:aFontMaster];
        _filter = ([aQueryString length] > 0) ? [[KCKerningEntryFilter alloc] initWithQueryString:aQueryString queryType:aQueryType] : nil;
    }
    return self;
}

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster {
    if ((self = [self initWithFontMaster:aFontMaster queryString:nil type:KCKerningEntriesQueryTypeDefault])) {
        
    }
    return self;
}

- (BOOL)containsGlyphName:(NSString *)aGlyphName withinClassName:(NSString *)aClassName {
    return [_kerningGroups containsGlyphName:aGlyphName withinGroup:aClassName];
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
                BOOL isLeftGlyphContainedInGroup  = NO;
                BOOL isRightGlyphContainedInGroup = NO;
                if ([kerningPair isLeftGrouped] && ![anotherPair isLeftGrouped]) {
                    isLeftGlyphContainedInGroup = [_kerningGroups containsGlyphName:[anotherPair left] withinGroup:[kerningPair left]];
                }
                if ([kerningPair isRightGrouped] && ![anotherPair isRightGrouped]) {
                    isRightGlyphContainedInGroup = [_kerningGroups containsGlyphName:[anotherPair right] withinGroup:[kerningPair right]];
                }
                if (isLeftGlyphContainedInGroup) {
                    if (isRightGlyphContainedInGroup || [[kerningPair right] isEqualToString:[anotherPair right]]) {
                        NSMutableOrderedSet *mutableExceptionPairs = [mutableExceptionDictionary objectForKey:kerningPair];
                        if (!mutableExceptionPairs) {
                            mutableExceptionPairs = [[NSMutableOrderedSet alloc] initWithCapacity:0];
                            [mutableExceptionDictionary setObject:mutableExceptionPairs forKey:kerningPair];
                        }
                        [mutableExceptionPairs addObject:anotherPair];
                        [mutableAggregatedExceptionPairs addObject:anotherPair];
                    }
                }
                if (isRightGlyphContainedInGroup) {
                    if (isLeftGlyphContainedInGroup || [[kerningPair left] isEqualToString:[anotherPair left]]) {
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
        //
        BOOL orphanedException = NO;
        if (!([kerningPair isLeftGrouped] && [kerningPair isRightGrouped])) {
            GSGlyph *leftGlyph  = [[self glyphsForIdentifier:[kerningPair left]]  firstObject];
            GSGlyph *rightGlyph = [[self glyphsForIdentifier:[kerningPair right]] firstObject];
            if (leftGlyph && rightGlyph) {
                GSLayer *leftLayer  = [[leftGlyph  layers] objectForKey:[_fontMaster id]];
                GSLayer *rightLayer = [[rightGlyph layers] objectForKey:[_fontMaster id]];
                if (leftLayer && rightLayer) {
                    if ([leftLayer rightKerningExeptionForLayer:rightLayer]) {
                        NSString *leftKey = [leftGlyph rightKerningGroup];
                        if (leftKey) {
                            leftKey = [NSString stringWithFormat:@"@MMK_L_%@", leftKey];
                        } else {
                            leftKey = [leftGlyph id];
                        }
                        NSString *rightKey = [rightGlyph leftKerningGroup];
                        if (rightKey) {
                            rightKey = [NSString stringWithFormat:@"@MMK_R_%@", rightKey];
                        } else {
                            rightKey = [rightGlyph id];
                        }
                        if (![[dictionary objectForKey:leftKey] objectForKey:rightKey]) {
                            orphanedException = YES;
                        }
                    }
                }
            }
        }
        //
        NSArray *exceptions = nil;
        NSOrderedSet *exceptionPairs = [mutableExceptionDictionary objectForKey:kerningPair];
        if ([exceptionPairs count] > 0) {
            NSMutableArray *mutableExceptions = [[NSMutableArray alloc] initWithCapacity:0];
            for (KCKerningPair *exceptionPair in exceptionPairs) {
                [mutableExceptions addObject:[[KCKerningEntry alloc] initWithLeft:[exceptionPair left] right:[exceptionPair right] value:[exceptionPair value] exceptions:nil orphanedException:orphanedException]];
            }
            exceptions = [mutableExceptions copy];
        }
        KCKerningEntry *entry = [[KCKerningEntry alloc] initWithLeft:[kerningPair left] right:[kerningPair right] value:[kerningPair value] exceptions:exceptions orphanedException:orphanedException];
        [mutableEntries addObject:entry];
    }
    return [mutableEntries copy];
}

- (NSArray<GSGlyph *> *)glyphsForIdentifier:(NSString *)anIdentifier {
    return [[_kerningGroups glyphsForIdentifier:anIdentifier] array];
}

- (KCKerningEntries *)filteredEntriesWithQueryString:(NSString *)aQueryString type:(KCKerningEntriesQueryType)aType {
    return [[[self class] alloc] initWithFontMaster:_fontMaster queryString:aQueryString type:aType];
}

#pragma mark -

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

@end
