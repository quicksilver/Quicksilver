//
//  BExtension.m
//  Blocks
//
//
//  Copyright 2006 Blocks. All rights reserved.
//

#import "BExtension.h"
#import "BRegistry.h"
#import "BPlugin.h"
#import "BExtensionPoint.h"
#import "BLog.h"

#import "NSXMLElement+BExtensions.h"

@implementation BExtension

#pragma mark accessors

- (NSString *)identifier { 
	return [self primitiveValueForKey:@"id"]; 
}

- (BPlugin *)plugin {
  return [self primitiveValueForKey:@"plugin"];
}

- (NSString *)extensionPointID {
  return [self valueForKey:@"point"];
}

#pragma mark content accessors

- (NSXMLElement *)XMLContent {
	NSString *string = [self valueForKey:@"content"];
	if (!string) return nil;
	return [[[NSXMLElement alloc] initWithXMLString:string
                                            error:nil] autorelease];
}

- (id)plistContent {
	NSString *plistString = [[[self XMLContent] firstElementWithName:@"plist"] XMLStringWithOptions:NSXMLNodeCompactEmptyElement];
	if (!plistString) return nil;
	NSString *error = nil;
	id plist = [NSPropertyListSerialization propertyListFromData:[plistString dataUsingEncoding:NSUTF8StringEncoding]
                                              mutabilityOption:NSPropertyListImmutable
                                                        format:nil
                                              errorDescription:&error];
	if (error) BLogError(error);
	return plist;
}

- (BExtensionPoint *)extensionPoint {
  BExtensionPoint *extensionPoint = [[BRegistry sharedInstance] extensionPointWithID:[self extensionPointID]];
	BLog(@"id %@", [self extensionPointID]);
  BLogAssert(extensionPoint != nil, @"failed to find extension point for id");
  return extensionPoint;
}

#pragma mark declaration order

- (NSComparisonResult)compareDeclarationOrder:(BExtension *)extension {
	return NSOrderedSame; 
  //	BPlugin *plugin1 = [self plugin];
  //	BPlugin *plugin2 = [extension plugin];
  //	
  //	if (plugin1 == plugin2) {
  //		int index1 = [[plugin1 extensions] indexOfObject:self];
  //		int index2 = [[plugin2 extensions] indexOfObject:extension];
  //		
  //		if (index1 < index2) {
  //			return NSOrderedAscending;
  //		} else if (index1 > index2) {
  //			return NSOrderedDescending;
  //		} else {
  //			return NSOrderedSame;
  //		}
  //	} else {
  //		int loadSequenceNumber1 = [plugin1 loadSequenceNumber];
  //		int loadSequenceNumber2 = [plugin2 loadSequenceNumber];
  //		
  //		if (loadSequenceNumber1 < loadSequenceNumber2) {
  //			return NSOrderedAscending;
  //		} else if (loadSequenceNumber1 > loadSequenceNumber2) {
  //			return NSOrderedDescending;
  //		} else {
  //			return NSOrderedSame;
  //		}
  //	}
}


- (id)valueForUndefinedKey:(NSString *)key {
  return nil;
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key{
		BLogInfo(@"%@ %@ could not set value %@ to %@", NSStringFromClass([self class]), self,  key, value);	
		return;
}
@end