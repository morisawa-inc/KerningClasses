//
//  KCFontMasterStore.h
//  KerningClasses
//
//  Created by tfuji on 21/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GlyphsCore.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSFontMaster.h>
#import "RSJumpBarItem.h"

@class GSFont;
@class GSFontMaster;

@interface KCFontMasterStore : NSObject <NSCopying>

@property (nonatomic, readonly) GSFont *font;
@property (nonatomic, readonly) GSFontMaster *fontMaster;

+ (instancetype)currentFontMasterStore;

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster font:(GSFont *)aFont;

- (NSString *)title;
- (RSJumpBarItem *)jumpBarItem;

@end
