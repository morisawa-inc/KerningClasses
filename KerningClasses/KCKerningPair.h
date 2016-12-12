//
//  KCKerningPair.h
//  KerningClasses
//
//  Created by tfuji on 01/11/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCKerningPair : NSObject <NSCopying>

@property (nonatomic, readonly) NSString *left;
@property (nonatomic, readonly) NSString *right;
@property (nonatomic, readonly) NSInteger value;

@property (nonatomic, readonly, getter=isLeftGrouped)  BOOL leftGrouped;
@property (nonatomic, readonly, getter=isRightGrouped) BOOL rightGrouped;

- (instancetype)initWithLeft:(NSString *)aLeft right:(NSString *)aRight value:(NSInteger)aValue;

- (BOOL)isLeftGrouped;
- (BOOL)isRightGrouped;

@end
