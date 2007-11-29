//
//  NSXMLElement+BExtensions.m
//  Blocks
//
//  Copyright 2007 Blacktree. All rights reserved.
//

#import "NSXMLElement+BExtensions.h"

@implementation NSXMLElement (BExtensions)
- (NSDictionary *)attributesAsDictionary{
	NSArray *attributes = [self attributes];
	int i;
	int count = [attributes count];
	
	NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:count];
	
	for (i = 0; i < count; i++) {
		NSXMLNode *attribute = [attributes objectAtIndex:i];
		[dict setObject:[attribute stringValue] forKey:[attribute name]];
	}
	
	return dict;
}

- (NSXMLElement *)firstElementWithName:(NSString *)name{
	NSArray *elements = [self elementsForName:name];
	return [elements count] ? [elements objectAtIndex:0] : nil;
}

- (id)firstValueForName:(NSString *)name{
	return [[self firstElementWithName:name] objectValue];
}

- (NSXMLNode *)firstNodeForXPath:(NSString *)xpath error:(NSError **)error{	
	NSArray *nodes = [self nodesForXPath:xpath error:error];
	return [nodes count] ? [nodes objectAtIndex:0] : nil;
}

- (id)firstValueForXPath:(NSString *)xpath error:(NSError **)error{
	NSXMLNode *node = [self firstNodeForXPath:xpath error:error];
	return [node valueForKey:@"objectValue"];
}

- (id)valuesForXPath:(NSString *)xpath error:(NSError **)error{
	NSArray *nodes = [self nodesForXPath:xpath error:error];
	if (![nodes count]) return nil;
	return [nodes valueForKey:@"objectValue"];
}
@end