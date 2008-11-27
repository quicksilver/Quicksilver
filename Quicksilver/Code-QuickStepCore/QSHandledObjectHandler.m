//
// QSHandledObjectHandler.m
// Quicksilver
//
// Created by Nicholas Jitkoff on 9/24/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "QSHandledObjectHandler.h"

#import "QSRegistry.h"
#import "QSObject.h"
#import "QSAction.h"
#import "QSTypes.h"
#import "QSResourceManager.h"

@implementation QSInternalObjectSource
- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry {return NO;}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry { return YES; }
- (NSImage *)iconForEntry:(NSDictionary *)dict { return [QSResourceManager imageNamed:@"Object"]; }
- (NSArray *)objectsForEntry:(NSDictionary *)theEntry {
	NSDictionary *messages = [QSReg tableNamed:@"QSInternalObjects"];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[messages count]];
	NSEnumerator *ke = [messages keyEnumerator];
	NSString *key;
	QSObject *messageObject;
	NSDictionary *info;
	while (key = [ke nextObject]) {
		info = [messages objectForKey:key];
        NSDictionary *objDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSDictionary dictionaryWithObjectsAndKeys:
                                  [info objectForKey:@"name"], kQSObjectPrimaryName,
                                  [info objectForKey:@"icon"], kQSObjectIcon,
                                  nil], kData,
                                 [NSDictionary dictionaryWithObjectsAndKeys:
                                  key, kQSObjectObjectID,
                                  QSHandledType, kQSObjectPrimaryType,
                                  nil], kMeta,
                                 nil];
		messageObject = [QSObject objectWithDictionary:objDict];
        if( messageObject != nil )
            [array addObject:messageObject];
	}
	return array;
}

@end

@implementation QSHandledObjectHandler

//- (NSString *)identifierForObject:(QSObject *)object { return nil; }

/*- (void)setQuickIconForObject:(QSObject *)object {
	[object setIcon:[QSResourceManager imageNamed:@"Object"]];
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	return NO;
}

- (id)handlerForObject:(QSObject *)object {
	NSString *name = [[object objectForType:QSHandledType] objectForKey:@"handler"];
	return [QSReg getClassInstance:name];
}

- (BOOL)loadIconForObject:(QSObject *)object {
	NSImage *icon = nil;
	NSString *name = [[object objectForType:QSHandledType] objectForKey:@"icon"];
	if (name) icon = [QSResourceManager imageNamed:name inBundle:[object bundle]];

	if (icon) {
		[object setIcon:icon];
		return YES;
	} else {
		id handler = [self handlerForObject:object];
		if ([handler respondsToSelector:@selector(loadIconForObject:)])
			return [handler loadIconForObject:object];
	}
	return NO;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
	id handler = [self handlerForObject:object];
	if ([handler respondsToSelector:@selector(loadChildrenForObject:indirectObject:)])
		return [handler loadChildrenForObject:object];
	return NO;
}
*/
@end
