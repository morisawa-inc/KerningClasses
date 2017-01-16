//
//  RSJumpBar.h
//  ToolbarTest
//
//  Created by tfuji on 12/12/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RSJumpBarItem.h"

@protocol RSJumpBarDelegate;
@protocol RSJumpBarDataSource;

IB_DESIGNABLE
@interface RSJumpBar : NSControl

@property (nonatomic, weak) IBOutlet id<RSJumpBarDelegate> delegate;
@property (nonatomic, weak) IBOutlet id<RSJumpBarDataSource> dataSource;
@property (nonatomic) RSJumpBarItem *selectedItem;

@end

@protocol RSJumpBarDelegate <NSObject>
- (void)jumpBar:(RSJumpBar *)jumpBar didSelectItem:(RSJumpBarItem *)item;
@end

@protocol RSJumpBarDataSource <NSObject>
- (NSUInteger)jumpBar:(RSJumpBar *)jumpBar numberOfItemsForItem:(RSJumpBarItem *)item;
- (RSJumpBarItem *)jumpBar:(RSJumpBar *)jumpBar childAtIndex:(NSUInteger)index ofItem:(RSJumpBarItem *)item;
@end
