//
//  QSAppleScriptActions.m
//  Quicksilver
//
//  Created by Alcor on 7/30/04.
//  Copyright 2004 Blacktree. All rights reserved.
//

#import "QSAppleScriptActions.h"
#import "QSTaskController.h"
#import "QSObject_AEConversion.h"
#import "QSObject_PropertyList.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"
#import "QSTextProxy.h"
#import "QSTypes.h"
#import "QSExecutor.h"

#import "NSAppleScript_BLTRExtensions.h"

#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

@implementation QSAppleScriptActions

- (QSAction *)scriptActionForPath:(NSString *)path {
	NSArray *handlers = [NSAppleScript validHandlersFromArray:[NSArray arrayWithObjects:@"aevtoapp", @"DAEDopnt", @"aevtodoc", nil] inScriptFile:path];

	NSMutableDictionary *actionDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       NSStringFromClass([self class]),    kActionClass,
                                       self,    kActionProvider,
                                       path,    kActionScript,
                                       [NSNumber numberWithBool:YES],      kActionDisplaysResult,
                                       nil];
    
	if ([handlers containsObject:@"DAEDopnt"]) {
		[actionDict setObject:[NSArray arrayWithObject:QSTextType] forKey:kActionDirectTypes];
		[actionDict setObject:@"QSOpenTextEventPlaceholder" forKey:kActionHandler];
		[actionDict setObject:[NSArray arrayWithObject:QSTextType] forKey:kActionIndirectTypes];
	}
	if ([handlers containsObject:@"aevtodoc"]) {
		[actionDict setObject:[NSArray arrayWithObject:QSFilePathType] forKey:kActionDirectTypes];
		[actionDict setObject:@"QSOpenFileEventPlaceholder" forKey:kActionHandler];
	}
    NSString *actionName = [[path lastPathComponent] stringByDeletingPathExtension];
    QSAction *action = [QSAction actionWithDictionary:actionDict identifier:[@"[Action]:" stringByAppendingString:path]];
    [action setName:actionName];
	[action setObject:path forMeta:kQSObjectIconName];
	return action;
}

- (NSArray *)fileActionsFromPaths:(NSArray *)scripts {
	NSArray *paths = [scripts pathsMatchingExtensions:[NSArray arrayWithObjects:@"scpt", @"app", nil]];
    NSMutableArray *array = [NSMutableArray array]; 
	for (NSString *path in paths) {
		if ([QSUTIOfFile(path) isEqualToString:QSUTIForExtensionOrType(@"scpt", 0)]) {
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
		returnObj = [[script executeAndReturnError:&errorDict] stringValue];
		if (returnObj)
			returnObj = [QSObject objectWithString:returnObj];
	}
	[script release];
	return returnObj;
}

- (QSObject *)doAppleScriptRunAction:(QSObject *)dObject withArguments:(QSObject *)iObject {
	[self runAppleScript:[dObject singleFilePath] withArguments:iObject];
	return nil;
}

- (QSObject *)doAppleScriptRunWithArgumentsAction:(QSObject *)dObject withArguments:(QSObject *)iObject {
	[self runAppleScript:[dObject singleFilePath] withArguments:iObject];
	return nil;
}

- (QSObject *)doAppleScriptRunAction:(QSObject *)dObject {
	[self runAppleScript:[dObject singleFilePath] withArguments:nil];
	return nil;
}

- (QSObject*)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject {
	NSDictionary *errorDict = nil;
    NSAppleEventDescriptor * returnDesc = nil;

	[[QSTaskController sharedInstance] updateTask:@"Run AppleScript" status:@"Loading Script" progress:-1];
	NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDict];
	[[QSTaskController sharedInstance] updateTask:@"Run AppleScript" status:@"Running Script" progress:-1];

	if (errorDict) {
		NSLog(@"Load Script: %@", [errorDict objectForKey:@"NSAppleScriptErrorMessage"]);
        [script release];
		return nil;
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
		} else if([iObject AEDescriptor]) {
            event = [[NSAppleEventDescriptor alloc] initWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
			[event setParamDescriptor:[iObject AEDescriptor] forKeyword:keyDirectObject];
        } else {
			event = [[NSAppleEventDescriptor alloc] initWithEventClass:kQSScriptSuite eventID:kQSOpenTextScriptCommand targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
			[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[iObject stringValue]] forKeyword:keyDirectObject];
			[event setDescriptor:[NSAppleEventDescriptor descriptorWithString:@""] forKeyword:kQSOpenTextIndirectParameter];
		}
		[targetAddress release];
		returnDesc = [script executeAppleEvent:event error:&errorInfo];
		[event release];
		//NSLog(@"%@", errorInfo);
	}
	if (errorDict) NSLog(@"Run Script: %@", [errorDict objectForKey:@"NSAppleScriptErrorMessage"]);
	[script storeInFile:@"scriptPath"];
	[[QSTaskController sharedInstance] removeTask:@"Run AppleScript"];
	[script release];
	return iObject?[QSObject objectWithAEDescriptor:returnDesc]:nil;
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
		NSLog(@"AppleScript Action: No handler? Aborting...");
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
		event = [[NSAppleEventDescriptor alloc] initWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
		[event setParamDescriptor:[NSAppleEventDescriptor aliasListDescriptorWithArray:files] forKeyword:keyDirectObject];
	} else if ([handler isEqualToString:@"QSOpenTextEventPlaceholder"]) {
    event = [[NSAppleEventDescriptor alloc] initWithEventClass:kQSScriptSuite
                                                       eventID:kQSOpenTextScriptCommand
                                              targetDescriptor:targetAddress
                                                      returnID:kAutoGenerateReturnID
                                                 transactionID:kAnyTransactionID];
		[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[dObject stringValue]] forKeyword:keyDirectObject];
    NSArray *indirectPaths = [iObject validPaths];
    NSAppleEventDescriptor *iObjectDescriptor = nil;
    NSUInteger indirectPathCount = [indirectPaths count];
    if (indirectPathCount == 1) {
      iObjectDescriptor = [NSAppleEventDescriptor descriptorWithString:[indirectPaths objectAtIndex:0]];
    } else if (indirectPathCount > 1) {
      iObjectDescriptor = [NSAppleEventDescriptor listDescriptor];
      for (NSString *path in indirectPaths) {
        [iObjectDescriptor insertDescriptor:[NSAppleEventDescriptor descriptorWithString:path] atIndex:0];
      }
    } else {
      iObjectDescriptor = [NSAppleEventDescriptor descriptorWithString:[iObject stringValue]];
    }
		[event setDescriptor:iObjectDescriptor forKeyword:kQSOpenTextIndirectParameter];
	} else {
		id object;
		NSArray *types = [action directTypes];
		NSString *type = ([types count]) ? [types objectAtIndex:0] : [dObject primaryType];
		object = [dObject arrayForType:type];
		object = ([type isEqual:QSFilePathType] ? [NSAppleEventDescriptor aliasListDescriptorWithArray:object] : [NSAppleEventDescriptor descriptorWithObject:object]);
        
		event = [[NSAppleEventDescriptor alloc] initWithSubroutineName:handler argumentsArray:[NSArray arrayWithObject:object]];
	}

	id result = [self objectForDescriptor:[script executeAppleEvent:event error:&errorDict]];
    [event release];
	[targetAddress release];
	[script release];
	if (errorDict) NSLog(@"Perform AppleScript Action Error: %@", [errorDict descriptionInStringsFileFormat]);
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
	return ([action isEqualToString:kAppleScriptOpenTextAction] ? [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@""]] : nil);
}

- (int)argumentCountForAction:(NSString *)actionId {
    int argumentCount = 1;
    QSAction *action = [QSAction actionWithIdentifier:actionId];
	NSString *scriptPath = [action objectForKey:kActionScript];
    
    if ([actionId isEqualToString:kAppleScriptOpenTextAction])
        argumentCount = 2;
    
    // TODO: figure out why all this code is here - scriptPath always seems to be nil

	if (!scriptPath)
		return argumentCount;

	if ([scriptPath hasPrefix:@"/"] || [scriptPath hasPrefix:@"~"])
		scriptPath = [scriptPath stringByStandardizingPath];
	else
		scriptPath = [[action bundle] pathForResource:[scriptPath stringByDeletingPathExtension] ofType:[scriptPath pathExtension]];

    NSArray *handlers = [NSAppleScript validHandlersFromArray:[NSArray arrayWithObject:@"DAEDgarc"] inScriptFile:scriptPath];
    if( handlers != nil && [handlers count] != 0 ) {
        NSAppleEventDescriptor *event;
        int pid = [[NSProcessInfo processInfo] processIdentifier];
        NSAppleEventDescriptor* targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
        
        NSDictionary *errorDict = nil;
        NSAppleScript *script = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDict];
        
		event = [[NSAppleEventDescriptor alloc] initWithEventClass:kQSScriptSuite eventID:kQSGetArgumentCountCommand targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
        
        NSAppleEventDescriptor *result = [script executeAppleEvent:event error:&errorDict];
        if( result ) {
            argumentCount = [result int32Value];
        } else if( errorDict != nil )
            NSLog(@"error %@", errorDict);
        
        [event release];
        [targetAddress release];
        [script release];
        
    }

#ifdef DEBUG
	NSLog(@"argument count for %@ is %d", actionId, argumentCount);
#endif
    
    return argumentCount;
}
@end
