//
//  QSObjCMessageSource.m
//  Quicksilver
//
//  Created by Alcor on 8/14/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import "QSObjCMessageSource.h"

#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSAction.h"
#import "QSTypes.h"
#import "DRColorPermutator.h"
#define kQSObjCSendMessageAction @"QSObjCSendMessageAction"

@implementation QSObjCMessageSource


-(id)init{
	if (self=[super init]){
	}
	return self;	
}

- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry{return NO;}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
	//	if (VERBOSE)NSLog(@"rescan catalog %d",firstCheck);
    return YES;
}

-(NSImage *)blueBox{
	NSImage *image=[QSResourceManager imageNamed:@"Object"];
	
	//DRColorPermutator *perm=[[[DRColorPermutator alloc]init]autorelease];
	
	//[perm rotateHueByDegrees:154 preservingLuminance:NO fromScratch:YES];
	//[perm changeSaturationBy:0.95 fromScratch:NO];
	
	//[perm applyToBitmapImageRep:(NSBitmapImageRep *)[image bestRepresentationForDevice:nil]];
	
	[image setName:@"ObjCMessageIcon"];
	return image;
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{
    return [self blueBox];
}
- (NSArray *) objectsForEntry:(NSDictionary *)theEntry{
	NSDictionary *messages=[QSReg tableNamed:@"QSInternalMessages"];
	NSMutableArray *array=[NSMutableArray arrayWithCapacity:[messages count]];
	NSEnumerator *ke=[messages keyEnumerator];
	NSString *key;
	QSObject *messageObject;
	NSDictionary *info;
	while (key=[ke nextObject]){
		info=[messages objectForKey:key];
		messageObject=[QSObject messageObjectWithInfo:info identifier:key];
//		[messageObject setIdentifier:key];
		[array addObject:messageObject];
	}
	return array;
}
// Object Handler Methods





- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{	//
	return [NSArray arrayWithObject:kQSObjCSendMessageAction];
}

- (QSObject *)sendMessage:(QSObject *)dObject{
	NSDictionary *messageInfo=[dObject objectForType:QSActionType];	
	
	NSString *selectorString=[messageInfo objectForKey:kActionSelector];
	SEL selector=NSSelectorFromString(selectorString);
	NSString *targetClass=[messageInfo objectForKey:kActionClass];
	id target=nil;
	
	BOOL sendToClass=[[messageInfo objectForKey:kActionSendMessageToClass]boolValue];
	
	
	if (sendToClass)
		target=NSClassFromString(targetClass);
	else
		target=[QSReg getClassInstance:targetClass];
	
	BOOL returnsObject=NO;
	
	if (![target respondsToSelector:selector]){
		NSBeep();
		NSLog(@"%@ does not respond to %@",target,selectorString);
		return nil;
	}
	
	id result=[target performSelector:selector];
	if (returnsObject && [result isKindOfClass:[QSBasicObject class]])return result;
	return nil;	
}

@end


@implementation QSObject (ObjCMessaging)
+ (QSObject *)messageObjectWithInfo:(NSDictionary *)dictionary identifier:(NSString *)identifier{
	NSMutableDictionary *mDict=[[dictionary mutableCopy]autorelease];
	
		//if (VERBOSE) NSLog(@"Old style message object used:%@",[dictionary objectForKey:@"name"]);
		
		id value;
		if (value=[mDict objectForKey:kQSObjCMessageAction])
			[mDict setObject:value forKey:kActionSelector];
		
		if (value=[mDict objectForKey:kQSObjCMessageTargetClass])
			[mDict setObject:value forKey:kActionClass];
		
		if (value=[mDict objectForKey:kQSObjCMessageSendToClass])
			[mDict setObject:value forKey:kActionSendMessageToClass];

	return	[QSObject actionWithDictionary:mDict
								identifier:identifier
									bundle:nil];
}	
+ (QSObject *)messageObjectWithTargetClass:(NSString *)class selectorString:(NSString *)selector{
	NSMutableDictionary *dictionary=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		class,kQSObjCMessageTargetClass,
		selector,kQSObjCMessageAction,
		nil];
	return [self messageObjectWithInfo:dictionary identifier:nil];
}


@end


