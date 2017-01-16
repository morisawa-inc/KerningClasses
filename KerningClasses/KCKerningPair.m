//
//  KCKerningPair.m
//  KerningClasses
//
//  Created by tfuji on 01/11/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCKerningPair.h"

@implementation KCKerningPair

- (instancetype)initWithLeft:(NSString *)aLeft right:(NSString *)aRight value:(NSInteger)aValue {
    if ((self = [self init])) {
        _left  = aLeft;
        _right = aRight;
        _value = aValue;
        _leftGrouped  = [aLeft  hasPrefix:@"@"];
        _rightGrouped = [aRight hasPrefix:@"@"];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    return [_left hash] ^ [_right hash];
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[self class]]) {
        if (((typeof(self))object)->_left == _left || [((typeof(self))object)->_left isEqualToString:_left]) {
            if (((typeof(self))object)->_right == _right || [((typeof(self))object)->_right isEqualToString:_right]) {
                isEqual = YES;
            }
        }
    }
    return isEqual;
}

@end
