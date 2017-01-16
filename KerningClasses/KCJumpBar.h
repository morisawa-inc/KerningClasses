//
//  KCJumpBar.h
//  KerningClasses
//
//  Created by tfuji on 21/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GlyphsCore.h>
#import <GlyphsCore/GSFontMaster.h>
#import "KCFontMasterStore.h"
#import "RSJumpBar.h"

IB_DESIGNABLE
@interface KCJumpBar : RSJumpBar

@property (nonatomic) KCFontMasterStore *selection;

@end

@protocol KCJumpBarDelegate <NSObject>
- (void)jumpBar:(KCJumpBar *)jumpBar didChangeSelection:(KCFontMasterStore *)selection;
@end
