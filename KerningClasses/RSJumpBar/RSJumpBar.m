//
//  RSJumpBar.m
//  ToolbarTest
//
//  Created by tfuji on 12/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "RSJumpBar.h"
#import "RSJumpBarButton.h"

@interface RSJumpBarCell : NSCell

@end

@implementation RSJumpBarCell

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect controlViewFrame  = [controlView frame];
    NSRect contentViewBounds = [[controlView superview] bounds];
    BOOL shouldDrawTopBorder = (controlViewFrame.origin.y + controlViewFrame.size.height == contentViewBounds.origin.y + contentViewBounds.size.height) ? NO : YES;
    [[NSColor textBackgroundColor] setFill];
    NSRectFill(cellFrame);
    [[NSColor controlColor] setStroke];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y) toPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y)];
    if (shouldDrawTopBorder) [NSBezierPath strokeLineFromPoint:NSMakePoint(cellFrame.origin.x, cellFrame.origin.y + cellFrame.size.height) toPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width, cellFrame.origin.y + cellFrame.size.height)];
}

@end

@interface RSJumpBar ()
@property (nonatomic, readonly) NSStackView *stackView;
@property (nonatomic, readonly) NSMutableArray<RSJumpBarButton *> *buttons;
@property (nonatomic, readonly) NSMutableArray<NSImageView *> *separators;
@end

@implementation RSJumpBar

+ (Class)cellClass {
    return [RSJumpBarCell class];
}

- (void)prepareForInterfaceBuilder {
    RSJumpBarItem *parent = [[RSJumpBarItem alloc] initWithTitle:@"Example.glyphs" image:[[NSBundle bundleForClass:[self class]] imageForResource:@"GSFontIcon"] objectValue:nil];
    RSJumpBarItem *child  = [[RSJumpBarItem alloc] initWithTitle:@"Regular" image:[[NSBundle bundleForClass:[self class]] imageForResource:@"GSFontMasterIcon"] objectValue:nil];
    [self setSelectedItem:[child itemByAssigningParentItem:parent]];
}

- (void)awakeFromNib {
    [self setCell:[[[[self class] cellClass] alloc] init]];
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        _buttons    = [[NSMutableArray alloc] initWithCapacity:0];
        _separators = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if ((self = [super initWithCoder:coder])) {
        _buttons    = [[NSMutableArray alloc] initWithCapacity:0];
        _separators = [[NSMutableArray alloc] initWithCapacity:0];
    }
    return self;
}

- (void)setSelectedItem:(RSJumpBarItem *)selectedItem {
    if (![_selectedItem isEqual:selectedItem]) {
        _selectedItem = selectedItem;
        [self prepareSubviewsWithLeaf:selectedItem];
        if ([_delegate respondsToSelector:@selector(jumpBar:didSelectItem:)]) {
            [_delegate jumpBar:self didSelectItem:selectedItem];
        }
    }
}

- (void)prepareSubviewsWithLeaf:(RSJumpBarItem *)aLeaf {
    [self removeConstraints:[[self constraints] copy]];
    [_stackView  removeFromSuperview];
    [_buttons    enumerateObjectsUsingBlock:^(NSView *view, NSUInteger _, BOOL *__) { [view removeFromSuperview]; }];
    [_separators enumerateObjectsUsingBlock:^(NSView *view, NSUInteger _, BOOL *__) { [view removeFromSuperview]; }];
    if (aLeaf) {
        NSStackView *stackView = [[NSStackView alloc] initWithFrame:[self bounds]];
        [stackView setSpacing:2.0];
        [stackView setOrientation:NSUserInterfaceLayoutOrientationHorizontal];
        [stackView setAlignment:NSLayoutAttributeCenterY];
        [stackView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:stackView];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:0 metrics:nil views:@{@"view":stackView}]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:0 metrics:nil views:@{@"view":stackView}]];
        
        NSMutableArray *mutableComponents = [[NSMutableArray alloc] initWithCapacity:0];
        for (RSJumpBarItem *item in [aLeaf allItems]) {
            RSJumpBarButton *button = [[RSJumpBarButton alloc] initWithFrame:NSZeroRect];
            [button setTranslatesAutoresizingMaskIntoConstraints:NO];
            [button setBarItem:item];
            [button setTarget:self];
            [button setAction:@selector(handleButtonAction:)];
            [self addSubview:button];
            [mutableComponents addObject:button];
            if (item != aLeaf) {
                NSImageView *separator = [[NSImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 7.0, 24.0)];
                [separator setTranslatesAutoresizingMaskIntoConstraints:NO];
                [separator setImage:[[NSBundle bundleForClass:[self class]] imageForResource:@"RSJumpBarChevron"]];
                [separator setImageScaling:NSImageScaleProportionallyDown];
                [self addSubview:separator];
                [mutableComponents addObject:separator];
            }
        }
        [stackView setViews:mutableComponents inGravity:NSStackViewGravityLeading];
    }
    [self updateConstraintsForSubtreeIfNeeded];
}

- (void)didAddSubview:(NSView *)subview {
    if (subview) {
        if ([subview isKindOfClass:[NSStackView class]]) {
            _stackView = (id)subview;
        } else if ([subview isKindOfClass:[RSJumpBarButton class]]) {
            [_buttons addObject:(id)subview];
        } else if ([subview isKindOfClass:[NSImageView class]]) {
            [_separators addObject:(id)subview];
        }
    }
}

- (void)willRemoveSubview:(NSView *)subview {
    if (subview) {
        if ([subview isEqual:_stackView]) {
            _stackView = nil;
        } else if ([subview isKindOfClass:[RSJumpBarButton class]]) {
            [_buttons removeObject:(id)subview];
        } else if ([subview isKindOfClass:[NSImageView class]]) {
           [_separators removeObject:(id)subview];
        }
    }
}

static void RSJumpBarItemApply(RSJumpBarItem *item, NSMenu *menu, id sender, id<RSJumpBarDataSource> dataSource) {
    [menu setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSControlSizeSmall]]];
    NSUInteger numberOfItems = [dataSource jumpBar:sender numberOfItemsForItem:item];
    for (NSUInteger i = 0; i < numberOfItems; ++i) {
        RSJumpBarItem *childItem = [dataSource jumpBar:sender childAtIndex:i ofItem:item];
        childItem = [childItem itemByAssigningParentItem:item];
        NSMenuItem *menuItem = [childItem menuItem];
        [menu addItem:menuItem];
        [menuItem setSubmenu:[[NSMenu alloc] initWithTitle:@""]];
        RSJumpBarItemApply(childItem, [menuItem submenu], sender, dataSource);
        if ([[menuItem submenu] numberOfItems] == 0) {
            [menuItem setSubmenu:nil];
            [menuItem setTarget:sender];
            [menuItem setAction:@selector(handleMenuItemAction:)];
        }
    }
}

- (void)handleButtonAction:(id)sender {
    if ([sender isKindOfClass:[RSJumpBarButton class]]) {
        NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
        RSJumpBarItem *item = [(RSJumpBarItem *)[(RSJumpBarButton *)sender barItem] parentItem];
        
        RSJumpBarItemApply(item, menu, self, _dataSource);
        
        [NSMenu popUpContextMenu:menu withEvent:[[NSApplication sharedApplication] currentEvent] forView:sender];
    }
}

- (void)handleMenuItemAction:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        [self setSelectedItem:[(NSMenuItem *)sender representedObject]];
        [self sendAction:[self action] to:[self target]];
    }
}

@end
