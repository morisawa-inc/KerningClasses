//
//  KCKerningEntry.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCKerningEntry.h"
#import "KCUserDefinedColors.h"

@interface KCKerningEntry ()
@property (nonatomic, readonly, getter=isException) BOOL exception;
@end

@implementation KCKerningEntry

- (instancetype)initWithLeft:(NSString *)aLeft right:(NSString *)aRight {
    if ((self = [self initWithLeft:aLeft right:aRight value:0 exceptions:nil orphanedException:NO])) {
        
    }
    return self;
}

- (instancetype)initWithLeft:(NSString *)aLeft right:(NSString *)aRight value:(NSInteger)aValue exceptions:(NSArray<KCKerningEntry *> *)anExceptions {
    if ((self = [self initWithLeft:aLeft right:aRight value:aValue exceptions:anExceptions orphanedException:NO])) {
        
    }
    return self;
}

- (instancetype)initWithLeft:(NSString *)aLeft right:(NSString *)aRight value:(NSInteger)aValue exceptions:(NSArray<KCKerningEntry *> *)anExceptions orphanedException:(BOOL)anOrphanedException {
    if ((self = [self init])) {
        _left  = aLeft;
        _right = aRight;
        _value = aValue;
        _exceptions = [self exceptionEntiresFromArray:anExceptions];
        _orphanedException = anOrphanedException;
    }
    return self;
}

- (NSColor *)textColor {
    NSColor *textColor = [NSColor controlTextColor];
    if (_orphanedException) {
        textColor = [[KCUserDefinedColors sharedColors] orphanedTextColor];
    } else if (_exception) {
        textColor = [[KCUserDefinedColors sharedColors] exceptionTextColor];
    } else if ([_left hasPrefix:@"@"] && [_right hasPrefix:@"@"]) {
        textColor = [[KCUserDefinedColors sharedColors] classToClassTextColor];
    }
    return textColor;
}

- (NSString *)stringValue {
    if (_value > 0) {
        return [NSString stringWithFormat:@"+%ld", _value];
    } else if (_value < 0) {
        return [NSString stringWithFormat:@"%ld", _value];
    }
    return [NSString stringWithFormat:@"±%ld", _value];
}

- (NSUInteger)hash {
    return [_left hash] ^ [_right hash];
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[self class]]) {
        if ([_left isEqualToString:((KCKerningEntry *)object)->_left]) {
            if ([_right isEqualToString:((KCKerningEntry *)object)->_right]) {
                isEqual = YES;
            }
        }
    }
    return isEqual;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

#pragma mark -

- (instancetype)exceptionEntry {
    KCKerningEntry *entry = [[KCKerningEntry alloc] initWithLeft:_left right:_right value:_value exceptions:_exceptions orphanedException:_orphanedException];
    entry->_exception = YES;
    return entry;
}

- (NSArray<KCKerningEntry *> *)exceptionEntiresFromArray:(NSArray<KCKerningEntry *> *)anArray {
    NSMutableArray *mutableExceptions = [[NSMutableArray alloc] initWithCapacity:0];
    for (KCKerningEntry *entry in anArray) {
        [mutableExceptions addObject:[entry exceptionEntry]];
    }
    return [mutableExceptions copy];
}

@end
