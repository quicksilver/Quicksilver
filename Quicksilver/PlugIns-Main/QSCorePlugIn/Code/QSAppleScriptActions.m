//
//  QSAppleScriptActions.m
//  Quicksilver
//
//  Created by Alcor on 7/30/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import "QSAppleScriptActions.h"
#import "QSTaskController.h"
#import "QSObject_PropertyList.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"
#import "QSTextProxy.h"
#import "QSTypes.h"
#import "QSExecutor.h"

#import "NSAppleScript_BLTRExtensions.h"

#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

@implementation QSAppleScriptActions

+ (void)loadPlugIn {}

- (QSAction *)scriptActionForPath:(NSString *)path {
	NSArray *handlers = [NSAppleScript validHandlersFromArray:[NSArray arrayWithObjects:@"aevtoapp", @"DAEDopnt", @"aevtodoc", nil] inScriptFile:path];

	QSAction *action = [QSAction actionWithIdentifier:[@"[Action] :" stringByAppendingString:path]];
	NSMutableDictionary *actionDict = [action actionDict];
	[actionDict setObject:path forKey:@"actionScript"];
	[actionDict setObject:NSStringFromClass([self class]) forKey:kActionClass];
	[actionDict setObject:self forKey:kActionProvider];
	if ([handlers containsObject:@"DAEDopnt"]) {
		[actionDict setObject:[NSArray arrayWithObject:QSTextType] forKey:@"directTypes"];
		[actionDict setObject:@"QSOpenTextEventPlaceholder" forKey:@"actionHandler"];
	}
	if ([handlers containsObject:@"aevtodoc"]) {
		[actionDict setObject:[NSArray arrayWithObject:QSFilePathType] forKey:@"directTypes"];
		[actionDict setObject:@"QSOpenFileEventPlaceholder" forKey:@"actionHandler"];
	}
	[action setName:[[path lastPathComponent] stringByDeletingPathExtension]];
	[action setObject:path forMeta:kQSObjectIconName];
	return action;
}

- (NSArray *)fileActionsFromPaths:(NSArray *)scripts {
	NSEnumerator *e = [[scripts pathsMatchingExtensions:[NSArray arrayWithObjects:@"scpt", @"app", nil]] objectEnumerator];
	NSString *path;
	NSMutableArray *array = [NSMutableArray array];
	while(path = [e nextObject]) {
		if ([[path pathExtension] isEqualToString:@"scpt"]) {
			[array addObject:[self scriptActionForPath:path]];
		}
	}
	return array;
}

- (NSString *)stringWithCorrectedLazyTell:(NSString *)string {
	NSArray *components = [string componentsSeparatedByString:@" "];
	if ([components count] <3 || ![[components objectAtIndex:0] isEqualToString:@"tell"] || ![[components objectAtIndex:1] isEqualToString:@"app"] || [[components objectAtIndex:2] hasPrefix:@"\""] || [[components objectAtIndex:2] hasSuffix:@"\""])
		return string;

	components = [components mutableCopy];
	[(NSMutableArray *)components replaceObjectAtIndex:2 withObject:[NSString stringWithFormat:@"\"%@\"", [components objectAtIndex:2]]];
	NSString *result = [components componentsJoinedByString:@" "];
	[components release];
	return result;
}

- (QSObject *)doAppleScriptRunTextAction:(QSObject *)dObject {
	NSDictionary *errorDict = nil;
    id returnObj = nil;
	NSAppleScript *script = [[NSAppleScript alloc] initWithSource:[self stringWithCorrectedLazyTell:[dObject objectForType:QSTextType]]];
	if([script compileAndReturnError:&errorDict]) {
//		NSAppleEventDescriptor *returnVal = ;
//		if (VERBOSE) NSLog(@"Returned: %@", returnVal);
		returnObj = [[script executeAndReturnError:&errorDict] stringValue];
		if (returnObj)
			returnObj = [QSObject objectWithString:returnObj];
	}
	[script release];
	return returnObj;
}

- (QSObject *)doAppleScriptRunWithArgumentsAction:(QSObject *)dObject withArguments:(QSObject *)iObject {
	[self runAppleScript:[dObject singleFilePath] withArguments:iObject];
	return nil;
}

- (QSObject *)doAppleScriptRunAction:(QSObject *)dObject {
	[self runAppleScript:[dObject singleFilePath] withArguments:nil];
	return nil;
}

- (void)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject {
	NSDictionary *errorDict = nil;

	[[QSTaskController sharedInstance] updateTask:@"Run AppleScript" status:@"Loading Script" progress:-1];
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDict];
	[[QSTaskController sharedInstance] updateTask:@"Run AppleScript" status:@"Running Script" progress:-1];

	if (errorDict) {
		NSLog(@"Load Script: %@", [errorDict objectForKey:@"NSAppleScriptErrorMessage"]);
		return;
	}

	if (!iObject) {
		[script executeAndReturnError:&errorDict];
	} else {
		NSArray *files = [iObject arrayForType:QSFilePathType];

		NSAppleEventDescriptor* event;
		NSDictionary *errorInfo = nil;
		int pid = [[NSProcessInfo processInfo] processIdentifier];
		NSAppleEventDescriptor* targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
		if (files) {
			event = [[NSAppleEventDescriptor alloc] initWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
			[event setParamDescriptor:[NSAppleEventDescriptor aliasListDescriptorWithArray:files] forKeyword:keyDirectObject];
		} else {
			event = [[NSAppleEventDescriptor alloc] initWithEventClass:kQSScriptSuite eventID:kQSOpenTextScriptCommand targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
			[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[iObject stringValue]] forKeyword:keyDirectObject];
		}
		[targetAddress release];
		[script executeAppleEvent:event error:&errorInfo];
		[event release];
		//NSLog(@"%@", errorInfo);
	}
	if (errorDict) NSLog(@"Run Script: %@", [errorDict objectForKey:@"NSAppleScriptErrorMessage"]);
	[script storeInFile:@"scriptPath"];
	[[QSTaskController sharedInstance] removeTask:@"Run AppleScript"];
	[script release];
}

- (QSObject *)objectForDescriptor:(NSAppleEventDescriptor *)desc {
	QSObject *object = [desc objectValue];
	if ([object isKindOfClass:[NSArray class]] && [object count])
		return [QSObject fileObjectWithArray:[object valueForKey:@"path"]];
	else if ([object isKindOfClass:[NSURL class]])
		return [QSObject fileObjectWithPath:[(NSURL *)object path]];
	else if ([object isKindOfClass:[NSString class]])
		return [QSObject objectWithString:(NSString *)object];
	else
		return nil;
}

- (QSObject *)performAction:(QSAction *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict = [action objectForType:QSActionType];
	NSString *scriptPath = [dict objectForKey:kActionScript];
	NSString *handler = [dict objectForKey:kActionHandler];
	if (!handler) {
		NSLog(@"no handler");
		return nil;
	}
	if ([scriptPath hasPrefix:@"/"] || [scriptPath hasPrefix:@"~"])
		scriptPath = [scriptPath stringByStandardizingPath];
	else
		scriptPath = [[action bundle] pathForResource:[scriptPath stringByDeletingPathExtension] ofType:[scriptPath pathExtension]];

	NSAppleEventDescriptor *event;
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	NSAppleEventDescriptor* targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];

	NSDictionary *errorDict = nil;
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDict];

	if ([handler isEqualToString:@"QSOpenFileEventPlaceholder"]) {
		NSArray *files = [dObject validPaths];
		event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] autorelease];
		[event setParamDescriptor:[NSAppleEventDescriptor aliasListDescriptorWithArray:files] forKeyword:keyDirectObject];
	} else if ([handler isEqualToString:@"QSOpenTextEventPlaceholder"]) {
		event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kQSScriptSuite eventID:kQSOpenTextScriptCommand targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] autorelease];
		[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[dObject stringValue]] forKeyword:keyDirectObject];
	} else {
		id object;
		NSArray *types = [[action actionDict] objectForKey:kActionDirectTypes];
		NSString *type = ([types count]) ? [types objectAtIndex:0] :[dObject primaryType];
		object = [dObject arrayForType:type];
		object = ([type isEqual:QSFilePathType]) ? [NSAppleEventDescriptor aliasListDescriptorWithArray:object] : [NSAppleEventDescriptor descriptorWithObject:object];
		event = [NSAppleEventDescriptor descriptorWithSubroutineName:handler argumentsArray:[NSArray arrayWithObject:object]];
	}

	id result = [self objectForDescriptor:[script executeAppleEvent:event error:&errorDict]];
	[targetAddress release];
	[script release];
	if (errorDict) NSLog(@"error %@", errorDict);
	return result;
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	if ([dObject objectForType:QSFilePathType]) {
		NSArray *handlers = [NSAppleScript validHandlersFromArray:[NSArray arrayWithObjects:@"aevtoapp", @"DAEDopnt", @"aevtodoc", nil] inScriptFile:[dObject singleFilePath]];
		//  **** store this information in metadata
		NSMutableArray *array = [NSMutableArray array];
		if ([handlers containsObject:@"aevtoapp"] || ![handlers count])
			[array addObject:kAppleScriptRunAction];
		if ([handlers containsObject:@"DAEDopnt"])
			[array addObject:kAppleScriptOpenTextAction];
		if ([handlers containsObject:@"aevtodoc"])
			[array addObject:kAppleScriptOpenFilesAction];
		return array;
	} else if ([[dObject primaryType] isEqualToString:QSTextType]) {
		return [NSArray arrayWithObjects:kAppleScriptRunTextAction, nil];
	}
	return nil;
}
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	return ([action isEqualToString:kAppleScriptOpenTextAction]) ? [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@""]] : nil;
}

@end
