//
// QSObjCMessageSource.m
// Quicksilver
//
// Created by Alcor on 8/14/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSObjCMessageSource.h"

#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSAction.h"
#import "QSTypes.h"
//#import "DRColorPermutator.h"
#define kQSObjCSendMessageAction @"QSObjCSendMessageAction"

@implementation QSObjCMessageSource

- (id)init {
	if (self = [super init]) {
	}
	return self;
}

- (BOOL)entryCanBeIndexed:(QSCatalogEntry *)theEntry {return NO;}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(QSCatalogEntry *)theEntry {
	//	if (VERBOSE) NSLog(@"rescan catalog %d", firstCheck);
	return YES;
}

- (NSImage *)blueBox {
	NSImage *image = [QSResourceManager imageNamed:@"Object"];

	//DRColorPermutator *perm = [[[DRColorPermutator alloc] init] autorelease];

	//[perm rotateHueByDegrees:154 preservingLuminance:NO fromScratch:YES];
	//[perm changeSaturationBy:0.95 fromScratch:NO];

	[image setName:@"ObjCMessageIcon"];
	return image;
}

- (NSImage *)iconForEntry:(NSDictionary *)dict {
	return [self blueBox];
}
- (NSArray *)objectsForEntry:(QSCatalogEntry *)theEntry {
	NSDictionary *messages = [QSReg tableNamed:@"QSInternalMessages"];
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[messages count]];
	QSObject *messageObject;
	NSDictionary *info;
	for (NSString *key in messages) {
		info = [messages objectForKey:key];
		messageObject = [QSObject messageObjectWithInfo:info identifier:key];
//		[messageObject setIdentifier:key];
		[array addObject:messageObject];
	}
	return array;
}
// Object Handler Methods

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject
{
    if ([[dObject primaryType] isEqualToString:QSActionType] && [(QSAction *)dObject argumentCount] == 0) {
        return @[kQSObjCSendMessageAction];
    }
    return nil;
}

- (QSObject *)sendMessage:(QSObject *)dObject {
	NSDictionary *messageInfo = [dObject objectForType:QSActionType];

	NSString *selectorString = [messageInfo objectForKey:kActionSelector];
	SEL selector = NSSelectorFromString(selectorString);
	NSString *targetClass = [messageInfo objectForKey:kActionClass];
	id target = nil;

	BOOL sendToClass = [[messageInfo objectForKey:kActionSendMessageToClass] boolValue];

	if (sendToClass)
		target = NSClassFromString(targetClass);
	else
		target = [QSReg getClassInstance:targetClass];



	if (![target respondsToSelector:selector]) {
		NSBeep();
		NSLog(@"%@ does not respond to %@", target, selectorString);
		return nil;
	}
    
    // returnsObject and result are never used (never implemented?). See result = comment below
    //	BOOL returnsObject = NO;
    //  id result;
    
    id argument = nil;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    // NSMethodSignature numberOfArguments is always +2 from the number of 'visible' arguments. So numberOfArguments == 3 means 1 visible arg.
    if ((argument = messageInfo[kActionArgument]) || [[target methodSignatureForSelector:selector] numberOfArguments] == 3) {
        /* Results should never be directly taken from performSelector (according to the docs). Instead NSInvocation should be used. Since the result is never used (returnsObject is always NO) then we don't need it here */
//        result =
        [target performSelector:selector withObject:argument];
    } else {
//        result =
        [target performSelector:selector];
    }
#pragma clang diagnostic pop
	/* if (returnsObject && [result isKindOfClass:[QSBasicObject class]]) return result; */
	return nil;
}

@end

@implementation QSObject (ObjCMessaging)
+ (QSObject *)messageObjectWithInfo:(NSDictionary *)dictionary identifier:(NSString *)identifier {
	NSMutableDictionary *mDict = [dictionary mutableCopy];
    
    //if (VERBOSE) NSLog(@"Old style message object used:%@", [dictionary objectForKey:@"name"]);
    
    id value;
    if (value = [mDict objectForKey:kQSObjCMessageAction])
        [mDict setObject:value forKey:kActionSelector];
    
    if (value = [mDict objectForKey:kQSObjCMessageTargetClass])
        [mDict setObject:value forKey:kActionClass];
    
    if (value = [mDict objectForKey:kQSObjCMessageSendToClass])
        [mDict setObject:value forKey:kActionSendMessageToClass];

	return [QSAction actionWithDictionary:mDict identifier:identifier];
}
+ (QSObject *)messageObjectWithTargetClass:(NSString *)aClass selectorString:(NSString *)selector {
	NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		aClass, kQSObjCMessageTargetClass,
		selector, kQSObjCMessageAction,
		nil];
	return [self messageObjectWithInfo:dictionary identifier:nil];
}

@end

