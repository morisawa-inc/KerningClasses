//
//  KCUserDefinedColors.h
//  KerningClasses
//
//  Created by tfuji on 12/01/2017.
//  Copyright © 2017 Morisawa Inc. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface KCUserDefinedColors : NSObject

@property (nonatomic, readonly) NSColor *classToClassTextColor;
@property (nonatomic, readonly) NSColor *exceptionTextColor;
@property (nonatomic, readonly) NSColor *orphanedTextColor;

+ (instancetype)sharedColors;

@end
