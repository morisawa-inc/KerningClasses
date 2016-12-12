//
//  KCKerningEntry.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCKerningEntry.h"

@implementation KCKerningEntry

- (instancetype)initWithLeft:(NSString *)aLeft right:(NSString *)aRight value:(NSInteger)aValue exceptions:(NSArray<KCKerningEntry *> *)anExceptions {
    if ((self = [self init])) {
        _left  = aLeft;
        _right = aRight;
        _value = aValue;
        _exceptions = anExceptions;
    }
    return self;
}

- (NSString *)stringValue {
    if (_value > 0) {
        return [NSString stringWithFormat:@"+%ld", _value];
    } else if (_value < 0) {
        return [NSString stringWithFormat:@"%ld", _value];
    }
    return [NSString stringWithFormat:@"±%ld", _value];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

@end
