//
//  NSXMLElement+BExtensions.h
//  Blocks
//
//  Copyright 2007 Blacktree. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSXMLElement (AttributeDictionary)
- (NSDictionary *)attributesAsDictionary;

- (NSXMLElement *)firstElementWithName:(NSString *)name;
- (id)firstValueForName:(NSString *)name;

- (NSXMLNode *)firstNodeForXPath:(NSString *)xpath error:(NSError **)error;
- (id)firstValueForXPath:(NSString *)xpath error:(NSError **)error;

- (id)valuesForXPath:(NSString *)xpath error:(NSError **)error;
	
@end
