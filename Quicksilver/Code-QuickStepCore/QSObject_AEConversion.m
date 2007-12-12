//
// QSObject_AEConversion.m
// Quicksilver
//
// Created by Alcor on 3/20/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSObject_AEConversion.h"
#import "QSRegistry.h"

#define kQSAEDescriptorType @"aedesc"

@implementation QSObject (AEConversion)

- (QSObject *)initWithAEDescriptor:(NSAppleEventDescriptor *)desc {
	if (self = [self init]) {
		[self setName:@"AEObject"];

		[self setObject:desc forType:kQSAEDescriptorType];
	}
	return self;
}

+ (QSObject *)objectWithAEDescriptor:(NSAppleEventDescriptor *)desc types:(NSArray *)types {
	NSString *type = [types lastObject];
	NSLog(@"type is %@", type);
	desc = [NSAppleEventDescriptor descriptorWithDescriptorType:[desc descriptorType] data:[desc data]];
	NSLog(@"type is %@ %@", desc, [desc objectValueAPPLE]);

	id handler = [QSReg getClassInstance:[[QSReg tableNamed:@"QSAETypeConverters"] valueForKey:type]];
	if (handler)
		return [handler objectWithAEDescriptor:desc types:types];

	//	DescType t = [desc descriptorType];
	//	NSString *type = nil;
	//	if (t == typeAEList)
	//		type = NSFileTypeForHFSTypeCode([[desc descriptorAtIndex:1] descriptorType]);
	//	else
	//		type = NSFileTypeForHFSTypeCode([desc descriptorType]);

	//id ob = [desc objectValue];
	//NSLog(@"object %@", ob);

	return [[[self alloc] initWithAEDescriptor:desc] autorelease];
}

- (NSAppleEventDescriptor *)AEDescriptor {
	id handler = [self handler];
	if ([handler respondsToSelector:@selector(AEDescriptorForObject:)])
		return [handler performSelector:@selector(AEDescriptorForObject:) withObject:self];

	return nil;
}

@end
