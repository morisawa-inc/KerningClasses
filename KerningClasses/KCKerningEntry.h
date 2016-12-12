//
//  KCKerningEntry.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCKerningEntry : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *left;
@property (nonatomic, readonly) NSString *right;
@property (nonatomic, readonly) NSInteger value;
@property (nonatomic, readonly) NSArray<KCKerningEntry *> *exceptions;

@property (nonatomic, readonly) NSString *stringValue;

- (instancetype)initWithLeft:(NSString *)aLeft right:(NSString *)aRight value:(NSInteger)aValue exceptions:(NSArray<KCKerningEntry *> *)anExceptions;

@end
