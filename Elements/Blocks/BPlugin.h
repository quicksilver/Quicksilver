//
//  BPlugin.h
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *kBPluginWillLoadNotification;
extern NSString *kBPluginDidLoadNotification;

extern NSString *kBPluginWillRegisterNotification;
extern NSString *kBPluginDidRegisterNotification;

@interface BPlugin : NSManagedObject {
    NSBundle *bundle;
	NSXMLDocument *pluginXMLDocument;
    NSDictionary *attributes;
	unsigned loadSequenceNumber;
	BOOL registered;
	NSXMLElement *info;
}

#pragma mark init

- (id)initWithPluginURL:(NSURL *)url bundle:(NSBundle *)bundle insertIntoManagedObjectContext:(NSManagedObjectContext*)context;

#pragma mark accessors

- (NSBundle *)bundle;
- (void)setBundle:(NSBundle *)value;
- (NSString *)name;
- (NSString *)identifier;
- (NSString *)version;
- (NSArray *)requirements;
- (NSArray *)extensionPoints;
- (NSArray *)extensions;
- (NSString *)xmlPath;
- (NSString *)protocolsPath;
- (BOOL)enabled;

- (NSXMLElement *)info;
- (NSXMLDocument *)pluginXMLDocument;

#pragma mark loading

- (BOOL) loadPluginXMLAttributes;
- (BOOL) loadPluginXMLContent;

- (unsigned)loadSequenceNumber;
- (BOOL)isLoaded;
- (BOOL)load;
- (BOOL) registerPlugin;
- (NSURL *)pluginURL;

@end