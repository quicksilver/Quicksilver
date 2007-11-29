//
//  BExtension.h
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BPlugin;
@class BExtensionPoint;

// This class is similar to Eclipse's IExtension
// It also acts as a base implementation for both IElement and IExtension point since they need similar accessors
@interface BExtension : NSManagedObject {
//    BPlugin *plugin;
//    NSString *extensionPointID;
//	NSDate *accessTime;
}

#pragma mark accessors

- (BPlugin *)plugin;
- (NSString *)extensionPointID;
- (BExtensionPoint *)extensionPoint;
- (NSString *)identifier;

#pragma mark declaration order

// Compare the load ordering of this extension with the given extension. If the extensions plugins are different the load order of the plugin is used to compare. If the plugins are the same then the extension declaration order is used to compare. This ordering is used by some extension points (such as menu extensions) to decide which extensions are processed first.
- (NSComparisonResult)compareDeclarationOrder:(BExtension *)extension;

- (NSXMLElement *)XMLContent;
- (id)plistContent;

@end