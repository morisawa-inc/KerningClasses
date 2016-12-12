//
//  KerningClassesPlugin.h
//  KerningClasses
//
//  Created by tfuji on 31/10/2016.
//  Copyright © 2016 Morisawa Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GlyphsPluginProtocol.h>

@class KCWindowController;

@interface KerningClassesPlugin : NSObject <GlyphsPlugin> {
@private
    NSMutableArray<KCWindowController *> *_windowControllers;
}
@end
