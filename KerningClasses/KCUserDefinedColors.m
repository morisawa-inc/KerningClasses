//
//  KCUserDefinedColors.m
//  KerningClasses
//
//  Created by tfuji on 12/01/2017.
//  Copyright © 2017 Morisawa Inc. All rights reserved.
//

#import "KCUserDefinedColors.h"

@implementation KCUserDefinedColors

+ (NSString *)defaultJSONPath {
    return [[NSBundle bundleForClass:[self class]] pathForResource:@"Colors" ofType:@"json"];
}

+ (instancetype)sharedColors {
    static dispatch_once_t predicate;
    static KCUserDefinedColors *sharedInstance = nil;
    dispatch_once(&predicate, ^{
        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:[[self class] defaultJSONPath]];
        [inputStream open];
        id JSONObject = [NSJSONSerialization JSONObjectWithStream:inputStream options:0 error:nil];
        [inputStream close];
        sharedInstance = [[[self class] alloc] initWithJSONObject:JSONObject];
    });
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        _classToClassTextColor = [NSColor controlTextColor];
        _exceptionTextColor    = [NSColor controlTextColor];
        _orphanedTextColor     = [NSColor controlTextColor];
    }
    return self;
}

- (instancetype)initWithJSONObject:(id)anObject {
    if ((self = [self init])) {
        [self loadJSONObject:anObject];
    }
    return self;
}

- (void)loadJSONObject:(id)anObject {
    if ([anObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)anObject;
        NSColor *classToClassTextColor = [self colorWithJSONObject:[dictionary objectForKey:@"class_class"]];
        NSColor *exceptionTextColor    = [self colorWithJSONObject:[dictionary objectForKey:@"exception"]];
        NSColor *orphanedTextColor     = [self colorWithJSONObject:[dictionary objectForKey:@"orphaned"]];
        if (classToClassTextColor) _classToClassTextColor = classToClassTextColor;
        if (exceptionTextColor)    _exceptionTextColor    = exceptionTextColor;
        if (orphanedTextColor)     _orphanedTextColor     = orphanedTextColor;
    }
}

- (NSColor *)colorWithJSONObject:(id)anObject {
    NSColor *color = nil;
    if ([anObject isKindOfClass:[NSDictionary class]]) {
        NSString *style = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"] isEqualToString:@"Light"] ? @"light" : @"dark";
        NSDictionary *dictionary = [(NSDictionary *)anObject objectForKey:style];
        NSNumber *red   = [dictionary objectForKey:@"red"];
        NSNumber *green = [dictionary objectForKey:@"green"];
        NSNumber *blue  = [dictionary objectForKey:@"blue"];
        NSNumber *alpha = [dictionary objectForKey:@"alpha"];
        if (red && green && blue) {
            color = [NSColor colorWithRed:[red doubleValue] green:[green doubleValue] blue:[blue doubleValue] alpha:(alpha) ? [alpha doubleValue] : 1.0];
        }
    }
    return color;
}

@end
