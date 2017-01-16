//
//  RSJumpBarButton.m
//  ToolbarTest
//
//  Created by tfuji on 13/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "RSJumpBarButton.h"

static inline void RSJumpBarButtonSetDefaultStyle(NSButton *button) {
    [button setBordered:NO];
    [button setControlSize:NSControlSizeSmall];
    [button setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]]];
    [button setBezelStyle:NSBezelStyleRegularSquare];
    [button setImagePosition:NSImageLeft];
    [button setImageScaling:NSImageScaleProportionallyDown];
    [button setContentCompressionResistancePriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[button(>=24)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(button)]];
    [button addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button(>=24)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(button)]];
    [button setLineBreakMode:NSLineBreakByTruncatingTail];
    [button setContinuous:YES];
    [button addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingInVisibleRect owner:button userInfo:nil]];
}

@interface RSJumpBarButtonCell : NSButtonCell

@end

@implementation RSJumpBarButtonCell

- (NSColor *)backgroundColor {
    return [NSColor clearColor];
}

- (void)drawImage:(NSImage *)image withFrame:(NSRect)frame inView:(NSView *)controlView {
    return [super drawImage:image withFrame:NSMakeRect(frame.origin.x + 2.0, frame.origin.y, frame.size.width - 2.0, frame.size.height) inView:controlView];
}

- (NSRect)drawTitle:(NSAttributedString *)title withFrame:(NSRect)frame inView:(NSView *)controlView {
    if (frame.size.width > 4.0) {
        return [super drawTitle:title withFrame:frame inView:controlView];
    }
    return NSZeroRect;
}

- (void)mouseEntered:(NSEvent *)event {
    if ([[super controlView] respondsToSelector:@selector(mouseEntered:)]) {
        [[super controlView] mouseEntered:event];
    }
}

- (void)mouseExited:(NSEvent *)event {
    if ([[super controlView] respondsToSelector:@selector(mouseExited:)]) {
        [[super controlView] mouseExited:event];
    }
}

@end

@implementation RSJumpBarButton

+ (Class)cellClass {
    return [RSJumpBarButtonCell class];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        RSJumpBarButtonSetDefaultStyle(self);
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        RSJumpBarButtonSetDefaultStyle(self);
    }
    return self;
}

- (instancetype)init {
    if ((self = [super init])) {
        RSJumpBarButtonSetDefaultStyle(self);
    }
    return self;
}

- (void)setBarItem:(RSJumpBarItem *)barItem {
    _barItem = barItem;
    [self setTitle:[barItem title]];
    [self setImage:[barItem image]];
}

- (void)mouseEntered:(NSEvent *)event {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * context) {
        context.duration = 0.33;
        context.allowsImplicitAnimation = true;
        [self setContentCompressionResistancePriority:NSLayoutPriorityDefaultHigh forOrientation:NSLayoutConstraintOrientationHorizontal];
        [[self superview] layoutSubtreeIfNeeded];
    } completionHandler:nil];
}

- (void)mouseExited:(NSEvent *)event {
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext * context) {
        context.duration = 0.33;
        context.allowsImplicitAnimation = true;
        [self setContentCompressionResistancePriority:(_collapsible) ? NSLayoutPriorityDefaultLow : NSLayoutPriorityDefaultLow + 1 forOrientation:NSLayoutConstraintOrientationHorizontal];
        [[self superview] layoutSubtreeIfNeeded];
    } completionHandler:nil];
}

- (NSSize)intrinsicContentSize {
    NSSize size = [[self title] sizeWithAttributes:@{NSFontAttributeName: [self font]}];
    size.width += 4.0;
    if ([self image]) {
        size.width += MIN(16.0, [[self image] size].width);
        size.width += 2.0;
    }
    size.height = MAX(size.height, 24.0);
    return size;
}

@end
