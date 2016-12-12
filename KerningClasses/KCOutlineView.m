//
//  KCOutlineView.m
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import "KCOutlineView.h"

@implementation KCOutlineView

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row {
    NSRect superFrame = [super frameOfCellAtColumn:column row:row];
    if (_disableIndentation && column == 0) {
        return NSMakeRect(-[self indentationPerLevel], superFrame.origin.y, [self bounds].size.width, superFrame.size.height);
    }
    return superFrame;
}

- (void)reloadData {
    if ([_dataSource respondsToSelector:@selector(reloadData)]) {
        [_dataSource reloadData];
    }
    [super reloadData];
}

@end
