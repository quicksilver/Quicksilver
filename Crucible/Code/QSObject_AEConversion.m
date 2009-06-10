//
//  QSObject_AEConversion.m
//  Quicksilver
//
//  Created by Alcor on 3/20/05.

//

#import "QSObject_AEConversion.h"


#define kQSAEDescriptorType @"aedesc"

@implementation QSObject (AEConversion)
+ (QSObject *)objectWithAEDescriptor:(NSAppleEventDescriptor *)desc types:(NSArray *)types {
	NSString *type = [types lastObject];
	QSLog(@"type is %@",type);
	desc = [NSAppleEventDescriptor descriptorWithDescriptorType:[desc descriptorType] data:[desc data]];
	QSLog(@"type is %@ %@",desc, [desc objectValueAPPLE]);
	
	id handler = [QSReg getClassInstance:[[QSReg elementsForPointID:@"QSAETypeConverters"] valueForKey:type]];
	if (handler)
		return [handler objectWithAEDescriptor:desc types:types];
	
	//	DescType t=[desc descriptorType];
	//	NSString *type=nil;
	//	if (t==typeAEList)
	//		type=NSFileTypeForHFSTypeCode([[desc descriptorAtIndex:1]descriptorType]);
	//	else
	//		type=NSFileTypeForHFSTypeCode([desc descriptorType]);
	
	//id ob=[desc objectValue];
	//QSLog(@"object %@", ob);
	
	
	return [[[self alloc] initWithAEDescriptor:desc] autorelease];
}

- (QSObject *)initWithAEDescriptor:(NSAppleEventDescriptor *)desc {
	if ((self = [self init])){
		[self setName:@"AEObject"];
		[self setObject:desc forType:kQSAEDescriptorType];
	}
	return self;
}

- (NSAppleEventDescriptor *)AEDescriptor {
	id handler = [self handlerForSelector:@selector(AEDescriptorForObject:)];
	if (handler)
        return [handler performSelector:@selector(AEDescriptorForObject:) withObject:self];
    
	return nil;	
}

@end
