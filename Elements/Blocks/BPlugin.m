//
//  BPlugin.m
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import "BPlugin.h"
#import "BExtensionPoint.h"
#import "BExtension.h"
#import "BRequirement.h"
#import "BRegistry.h"
#import "BLog.h"

#import "NSXMLElement+BExtensions.h"



NSString *kBPluginWillLoadNotification = @"kBPluginWillLoadNotification";
NSString *kBPluginDidLoadNotification = @"kBPluginDidLoadNotification";
NSString *kBPluginWillRegisterNotification = @"kBPluginWillRegisterNotification";
NSString *kBPluginDidRegisterNotification = @"kBPluginDidRegisterNotification";
@interface BPlugin (Private)
- (NSURL *)pluginURL;
- (void)setPluginURL:(NSURL *)url; 
@end

@implementation BPlugin

#pragma mark init

static int BPluginLoadSequenceNumbers = 0;

- (id)initWithPluginURL:(NSURL *)url bundle:(NSBundle *)aBundle insertIntoManagedObjectContext:(NSManagedObjectContext*)context{
	if (!url) {
		[self release];
		return nil;
	}
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"plugin" inManagedObjectContext:context];
    self = [self initWithEntity:entity insertIntoManagedObjectContext:context];
	if (self) {
    [self setPluginURL:url];
		[self setBundle:aBundle];
		
		[self setValue:[NSNumber numberWithInt: ([bundle isLoaded] ? BPluginLoadSequenceNumbers++ : NSNotFound)]
				forKey:@"loadSequenceNumber"];
		
		BLogInfo(@"Loading Plugin [%@]", [(bundle ? [bundle bundlePath] : [url path]) lastPathComponent]);
		
		if (![self loadPluginXMLAttributes]) {
			BLogError(([NSString stringWithFormat:@"failed scanPluginXML for bundle %@", [bundle bundleIdentifier]]));
			[self release];
			return nil;
		}
	}
	return self;
}

- (BOOL) registerPlugin {
	if (registered) return YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:kBPluginWillRegisterNotification object:self userInfo:nil]; 
	BOOL success = [self loadPluginXMLContent];
	if (success) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kBPluginDidRegisterNotification object:self userInfo:nil]; 	
		[self setValue:[NSDate date] forKey:@"registrationDate"];
		return YES;
	}
	return NO;
}

//- (id)initWithXMLURL:(NSURL *)xmlPath
// insertIntoManagedObjectContext:(NSManagedObjectContext*)context{
//    self = [self initWithEntity:[NSEntityDescription entityForName:@"plugin" inManagedObjectContext:context]
// insertIntoManagedObjectContext:context];
//    return self;
//}




#pragma mark dealloc

- (void)dealloc {
    [bundle release];
    [info release];
    [super dealloc];
}

#pragma mark accessors
- (void)awakeFromFetch {
	[super awakeFromFetch];
	
	// Find our bundle, if possible
	if (!bundle) {
		NSString *path = [[self pluginURL] path];
		int location = [path rangeOfString:@"Contents/" options:NSBackwardsSearch|NSLiteralSearch].location;
		if (location != NSNotFound) {
			path = [path substringToIndex:location];
			[self setBundle:[NSBundle bundleWithPath:path]];
		}
	}
}
- (void)didTurnIntoFault {
	BLogDebug(@"faulted %@", self);
}
- (NSString *)description {
    return [NSString stringWithFormat:@"id: %@ loadSequence: %i", [self identifier], [self loadSequenceNumber]];
}

- (NSBundle *)bundle {
	return bundle;
}

- (void)setBundle:(NSBundle *)value {
    if (bundle != value) {
        [bundle autorelease];
        bundle = [value retain];
		[self setPrimitiveValue:[value bundleIdentifier]
						 forKey:@"id"];
    }
}
- (unsigned)loadSequenceNumber {
	return loadSequenceNumber;
}
- (NSString *)author {
	[[self info] firstValueForName:@"author"];	
}

- (NSString *)xmlPath {
	return [[self bundle] pathForResource:@"plugin" ofType:@"xml"];
}

- (NSString *)protocolsPath {
	return [[self bundle] pathForResource:[[[[self bundle] executablePath] lastPathComponent] stringByAppendingString:@"Protocols"] ofType:@"h"];
}



- (NSString *)identifier { return [self primitiveValueForKey:@"id"]; }

	// Primitive Accessors 
#define PRIMITIVE_VALUE [self primitiveValueForKey:NSStringFromSelector(_cmd)]

- (NSString *)name { return PRIMITIVE_VALUE; }
- (NSString *)version { return PRIMITIVE_VALUE; }
- (NSArray *)requirements { return PRIMITIVE_VALUE; }
- (NSArray *)extensions { return PRIMITIVE_VALUE; }
- (NSArray *)extensionPoints { return PRIMITIVE_VALUE; }

- (BOOL)enabled {
	return YES;
}

- (void)setPluginURL:(NSURL *)url {
		[self setValue:[url absoluteString] forKey:@"url"];
}

- (NSURL *)pluginURL {
	NSString *urlString = [self valueForKey:@"url"];
	NSURL *url = urlString ? [NSURL URLWithString:urlString] : nil;
  return url;
}


- (NSManagedObject *)scanElement:(NSXMLElement *)elementInfo forPoint:(NSString *)point{
	NSString *name = [elementInfo name];
	
	NSManagedObject *element = [NSEntityDescription insertNewObjectForEntityForName:@"element"
															 inManagedObjectContext:[self managedObjectContext]];
	
	//NSMutableDictionary *attributeDict = [NSMutableDictionary dictionaryWithDictionary:inheritedAttributes];
	
	[element setValuesForKeysWithDictionary:[elementInfo attributesAsDictionary]];
	[element setValue:self forKey:@"plugin"];
	[element setValue:point forKey:@"point"];
	
	[element setValue:[elementInfo XMLString] forKey:@"content"];
	return element;
}

- (BOOL)scanExtensionPoint:(NSXMLElement *)extensionPointInfo {
	
	NSDictionary *pointAttributes = [extensionPointInfo attributesAsDictionary];
	NSString *identifier = [pointAttributes objectForKey:@"id"];
	
	NSManagedObject *point = [[BRegistry sharedInstance] extensionPointWithID:identifier];
	if (point) BLogDebug(@"using existing point %@", identifier);
	if (!point) {
		point = [NSEntityDescription insertNewObjectForEntityForName:@"extensionPoint"
											  inManagedObjectContext:[self managedObjectContext]];
	}
	[point setValuesForKeysWithDictionary:pointAttributes];
	
	BLog(@"[extensionPointInfo XMLString] %@", [extensionPointInfo XMLString]);
	[point setValue:[extensionPointInfo XMLString] forKey:@"content"];
	
	NSMutableSet *points = [self mutableSetValueForKey:@"extensionPoints"];
	[points addObject:point];
	[point setValue:self forKey:@"plugin"];
	
	return YES;
}


#pragma mark loading
- (BOOL)scanExtension:(NSXMLElement *)extensionInfo {
	//BLog(@"extension %@", extensionInfo);
	NSManagedObject *extension = [NSEntityDescription insertNewObjectForEntityForName:@"extension"
															   inManagedObjectContext:[self managedObjectContext]];
	
	NSMutableSet *extensions = [self mutableSetValueForKey:@"extensions"];
	[extensions addObject:extension];
	[extension setValue:self forKey:@"plugin"];
	
	
	NSMutableSet *pluginElements = [self mutableSetValueForKey:@"elements"];
	NSMutableSet *extensionElements = [extension mutableSetValueForKey:@"elements"];
	
	NSDictionary *attributeDict = [extensionInfo attributesAsDictionary];
	NSString *point = [attributeDict valueForKey:@"point"];
	//		if (![name isEqualToString:@"extension"]) // default point is the name of the element
	//		[attributeDict setObject:name forKey:@"point"]; 
	
	BExtensionPoint *extensionPoint = nil;
	
	
	extensionPoint = [[BRegistry sharedInstance] extensionPointWithID:point];
	if (!extensionPoint) {
		extensionPoint = [NSEntityDescription insertNewObjectForEntityForName:@"extensionPoint"
								  inManagedObjectContext:[self managedObjectContext]];
		[extensionPoint setValue:point forKey:@"id"];
	}
	//BLog(@"point %@", extensionPoint);
	//
//	
	for (int i = 0,  count = [extensionInfo childCount]; i < count; i++) {
		NSManagedObject *element = [self scanElement:(NSXMLElement *)[extensionInfo childAtIndex:i]
											forPoint:point];
		
		[pluginElements addObject:element];
		[extensionElements addObject:element];
	}
	
	
	
	return YES;
}

- (NSXMLDocument *)pluginXMLDocument {
	if (!pluginXMLDocument) {
		NSURL *pluginURL = [self pluginURL];
		
		if (!pluginURL) {
			BLogError(([NSString stringWithFormat:@"failed to find plugin.xml for bundle %@", bundle]));
			return NO;
		}
		NSError *error = nil;
		pluginXMLDocument = [[NSXMLDocument alloc] initWithContentsOfURL:pluginURL
																 options:NSXMLDocumentValidate
																   error: &error];
		
		
		if (!pluginXMLDocument) {
			BLogError(([NSString stringWithFormat:@"failed to parse plugin.xml file %@ - %@", pluginURL, error]));
			return NO;
		}
	}
	return pluginXMLDocument;
}

- (BOOL) loadPluginXMLAttributes {
	NSXMLDocument *document = [self pluginXMLDocument];
	NSXMLElement *root = [document rootElement];
	[self setValuesForKeysWithDictionary:[root attributesAsDictionary]];
	if (bundle && ![[self identifier] isEqualToString:[bundle bundleIdentifier]]) {
		BLogError(([NSString stringWithFormat:@"plugin id %@ doesn't match bundle id %@", [self identifier], [bundle bundleIdentifier]]));
		return NO;
	}
	return YES;
}

- (BOOL) loadPluginXMLContent {
	NSXMLDocument *document = [self pluginXMLDocument];
	NSXMLElement *root = [document rootElement];
	
	NSArray *requirements = [[root firstElementWithName:@"requirements"] elementsForName:@"requirement"];
	NSEnumerator *enumerator = [[self requirements] objectEnumerator];
	id element;
	while (element = [enumerator nextObject]) {
		NSManagedObject *requirement = [NSEntityDescription insertNewObjectForEntityForName:@"requirement"
																	 inManagedObjectContext:[self managedObjectContext]];
		NSDictionary *attributeDict = [element attributesAsDictionary];
		[requirement setValuesForKeysWithDictionary:attributeDict];
	}
	
	NSXMLElement *infoChildren = [root firstElementWithName:@"info"];
	[self setValue:info forKey:@"info"];
	
	NSXMLElement *extensionsChildren = [root firstElementWithName:@"extensions"];
	
	NSArray *extensions = [extensionsChildren elementsForName:@"extension"];
	for (int i = 0,  count = [extensions count]; i < count; i++) {
		[self scanExtension:[extensions objectAtIndex:i]];
	}
	NSArray *points = [extensionsChildren elementsForName:@"extension-point"];
	for (int i = 0,  count = [points count]; i < count; i++) {
		[self scanExtensionPoint:[points objectAtIndex:i]];
	}
	return YES;
}


- (BOOL)isLoaded {
	return [bundle isLoaded];
}

- (BOOL)load {
    if (![bundle isLoaded]) {
		if (![self enabled]) {
			BLogError(([NSString stringWithFormat:@"Failed to load plugin %@ because it isn't enabled.", [self identifier]]));
			return NO;
		}
		
		NSEnumerator *enumerator = [[self requirements] objectEnumerator];
		BRequirement *eachImport;
		
		while (eachImport = [enumerator nextObject]) {
			if (![eachImport isLoaded]) {
				if ([eachImport load]) {
					BLogInfo(([NSString stringWithFormat:@"Loaded code for requirement %@ by plugin %@", eachImport, [self identifier]]));
				} else {
					if ([[eachImport valueForKey:@"optional"] boolValue]) {
						BLogError(([NSString stringWithFormat:@"Failed to load code for optioinal requirement %@ by plugin %@", eachImport, [self identifier]]));
					} else {
						BLogError(([NSString stringWithFormat:@"Failed to load code for requirement %@ by plugin %@", eachImport, [self identifier]]));
						BLogError(([NSString stringWithFormat:@"Failed to load code for plugin with identifier %@", [self identifier]]));
						return NO;
					}
				}
			}
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:kBPluginWillLoadNotification object:self userInfo:nil]; 
    
    [self willChangeValueForKey:@"isLoaded"];
		if ([bundle load]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:kBPluginDidLoadNotification object:self userInfo:nil];
			[self setValue:[NSNumber numberWithInt: BPluginLoadSequenceNumbers++]
              forKey:@"loadSequenceNumber"];
			BLogInfo(([NSString stringWithFormat:@"Loaded plugin %@", [self identifier]]));
		} else {
			BLogError(@"Failed to load bundle with identifier %@: %@", [self identifier], bundle);
			return NO;
		}
    
    [self didChangeValueForKey:@"isLoaded"];
    }
  
  return YES;
}

- (NSXMLElement *)info {
	if (!info) {
		NSString *infoString = [self primitiveValueForKey:@"info"];
		if (!infoString) return nil;
		info = [[[[NSXMLDocument alloc] initWithXMLString:infoString
												  options:nil
													error:nil] autorelease] rootElement];
		[info retain];
	}
    return [[info retain] autorelease];
}

- (void)setInfo:(NSXMLElement *)value {
    if (info != value) {
        [info release];
        info = [value copy];
    }
}

- (id)valueForUndefinedKey:(NSString *)key {
  return nil;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
	BLogDebug(@"key %@", key);
}
@end
