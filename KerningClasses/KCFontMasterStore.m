//
//  KCFontMasterStore.m
//  KerningClasses
//
//  Created by tfuji on 21/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCFontMasterStore.h"

@interface GSDocument : NSDocument
@property(readonly, nonatomic) GSFontMaster *selectedFontMaster;
@property(retain, nonatomic) GSFont *font;
@end

@implementation KCFontMasterStore

+ (instancetype)currentFontMasterStore {
    GSFont *font = [[[NSDocumentController sharedDocumentController] currentDocument] font];
    if (!font) font = [[[[NSDocumentController sharedDocumentController] documents] lastObject] font];
    GSFontMaster *fontMaster = [[font parent] selectedFontMaster];
    return [[self alloc] initWithFontMaster:fontMaster font:font];
}

- (instancetype)initWithFontMaster:(GSFontMaster *)aFontMaster font:(GSFont *)aFont {
    if ((self = [self init])) {
        _fontMaster = aFontMaster;
        _font = aFont;
    }
    return self;
}

- (NSString *)title {
    NSString *title = nil;
    if (_font && _fontMaster) {
        NSDocument *document = (NSDocument *)[_font parent];
        title = [[[document fileURL] path] lastPathComponent];
        if (!title) title = [_font familyName];
        title = [title stringByAppendingString:@" - "];
        title = [title stringByAppendingString:[_fontMaster name]];
    } else if (_font) {
        NSDocument *document = (NSDocument *)[_font parent];
        title = [[[document fileURL] path] lastPathComponent];
        if (!title) title = [_font familyName];
    }
    return title;
}

- (RSJumpBarItem *)jumpBarItem {
    RSJumpBarItem *jumpBarItem = nil;
    if (_font && _fontMaster) {
        NSDocument *document = (NSDocument *)[_font parent];
        NSString *title = [[[document fileURL] path] lastPathComponent];
        if (!title) title = [_font familyName];
        RSJumpBarItem *parent = [[RSJumpBarItem alloc] initWithTitle:title image:[[NSBundle bundleForClass:[self class]] imageForResource:@"GSFontIcon"] objectValue:_font];
        RSJumpBarItem *child  = [[RSJumpBarItem alloc] initWithTitle:[_fontMaster name] image:[[NSBundle bundleForClass:[self class]] imageForResource:@"GSFontMasterIcon"] objectValue:_fontMaster];
        jumpBarItem = [child itemByAssigningParentItem:parent];
    } else if (_font) {
        NSDocument *document = (NSDocument *)[_font parent];
        NSString *title = [[[document fileURL] path] lastPathComponent];
        if (!title) title = [_font familyName];
        jumpBarItem = [[RSJumpBarItem alloc] initWithTitle:title image:[[NSBundle bundleForClass:[self class]] imageForResource:@"GSFontIcon"] objectValue:_font];
    } else {
        jumpBarItem = [[RSJumpBarItem alloc] initWithTitle:@"(none)" image:[[NSBundle bundleForClass:[self class]] imageForResource:@"GSFontIcon"] objectValue:nil];
    }
    return jumpBarItem;
}

- (NSUInteger)hash {
    return [_fontMaster hash] ^ [_font hash];
}

- (BOOL)isEqual:(id)object {
    BOOL isEqual = NO;
    if ([object isKindOfClass:[self class]]) {
        if ([_fontMaster isEqual:((KCFontMasterStore *)object)->_fontMaster]) {
            if ([_font isEqual:((KCFontMasterStore *)object)->_font]) {
                isEqual = YES;
            }
        }
    }
    return isEqual;
}
        
- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

@end
