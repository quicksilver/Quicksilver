//
//  QSAppleScriptActions.m
//  Quicksilver
//
//  Created by Alcor on 7/30/04.

//

#import "QSAppleScriptActions.h"

@implementation QSAppleScriptActions
+ (void)loadPlugIn{
	
}

- (QSAction *)scriptActionForPath:(NSString *)path{
	
	NSArray *handlers=[NSAppleScript validHandlersFromArray:[NSArray arrayWithObjects:@"aevtoapp",@"DAEDopnt",@"aevtodoc",nil] 
											   inScriptFile:path];
	 
	
	QSAction *action=[QSAction actionWithIdentifier:[@"[Action]:" stringByAppendingString:path]];
	[[action actionDict]setObject:path forKey:@"actionScript"];
	
	[[action actionDict]setObject:NSStringFromClass([self class]) forKey:kActionClass];
	[[action actionDict]setObject:self forKey:kActionProvider];
	//QSLog(@"handlers %@ %@",action,handlers);
	
	if ([handlers containsObject:@"DAEDopnt"]){
		[[action actionDict]setObject:[NSArray arrayWithObject:QSTextType] forKey:@"directTypes"];
		[[action actionDict]setObject:@"QSOpenTextEventPlaceholder" forKey:@"actionHandler"];
		
	}
	
	if ([handlers containsObject:@"aevtodoc"]){
		[[action actionDict]setObject:[NSArray arrayWithObject:QSFilePathType] forKey:@"directTypes"];
		[[action actionDict]setObject:@"QSOpenFileEventPlaceholder" forKey:@"actionHandler"];
		
	}
	
	
	[action setName:[[path lastPathComponent]stringByDeletingPathExtension]];
	[action setObject:path forMeta:kQSObjectIconName];
	return action;
}



- (NSArray *) fileActionsFromPaths:(NSArray *)scripts{
	scripts=[scripts pathsMatchingExtensions:[NSArray arrayWithObjects:@"scpt",@"app",nil]];
	NSString *path;
	NSMutableArray *array=[NSMutableArray array];
	
	for(path in scripts){
		if (![[path pathExtension]isEqualToString:@"scpt"])continue;
		QSAction *action=[self scriptActionForPath:path];
		[array addObject:action];
	}
	return array;
}


- (NSString *)stringWithCorrectedLazyTell:(NSString *)string{
	NSArray *components=[string componentsSeparatedByString:@" "];
	
	if ([components count]<3
		|| ![[components objectAtIndex:0]isEqualToString:@"tell"]
		|| ![[components objectAtIndex:1]isEqualToString:@"app"]
		|| [[components objectAtIndex:2]hasPrefix:@"\""]
		|| [[components objectAtIndex:2]hasSuffix:@"\""]
		)
		return string;
	
	components=[[components mutableCopy]autorelease];
	[(NSMutableArray *)components replaceObjectAtIndex:2 withObject:
		[NSString stringWithFormat:@"\"%@\"",[components objectAtIndex:2]]];
	
	return [components componentsJoinedByString:@" "];
}


- (QSObject *) doAppleScriptRunTextAction:(QSObject *)dObject{
	NSString *text=[dObject objectForType:QSTextType];
	NSDictionary *errorDict=nil;
	
	text=[self stringWithCorrectedLazyTell:text];
	
	NSAppleScript *script=[[[NSAppleScript alloc]initWithSource:text ]autorelease];
	
	if  ([script compileAndReturnError:&errorDict]){
		NSAppleEventDescriptor *returnVal=[script executeAndReturnError:&errorDict];
		
		if (VERBOSE) QSLog(@"Returned: %@",returnVal);
		id returnObj=[returnVal stringValue];
		if (returnObj) return [QSObject objectWithString:returnObj];
	}
	
	return nil;
}

- (QSObject *) doAppleScriptRunWithArgumentsAction:(QSObject *)dObject withArguments:(QSObject *)iObject{
	[self runAppleScript:[dObject singleFilePath] withArguments:iObject];
	return nil;
}

- (QSObject *) doAppleScriptRunAction:(QSObject *)dObject{
	[self runAppleScript:[dObject singleFilePath] withArguments:nil];
	return nil;
}

- (void)runAppleScript:(NSString *)scriptPath withArguments:(QSObject *)iObject{
	NSDictionary *errorDict=nil;
	
	[[QSTaskController sharedInstance] updateTask:@"Run AppleScript" status:@"Loading Script" progress:-1];
	NSAppleScript *script=[[[NSAppleScript alloc]initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDict]autorelease];
	[[QSTaskController sharedInstance] updateTask:@"Run AppleScript" status:@"Running Script" progress:-1];
	
	//  QSLog(@"Handlers: %@",[script handlers]);
	
	if (errorDict){ 
		QSLog(@"Load Script: %@",[errorDict objectForKey:@"NSAppleScriptErrorMessage"]);
		return;
	}
	
	if (!iObject){
		[script executeAndReturnError:&errorDict];
	}else{
		NSArray *files=[iObject arrayForType:QSFilePathType];
		
		NSAppleEventDescriptor* event;
		NSDictionary *errorInfo=nil;
		int pid = [[NSProcessInfo processInfo] processIdentifier];
		NSAppleEventDescriptor* targetAddress = [[[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)]autorelease];
		
		
		if (files){
			event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]autorelease];
			[event setParamDescriptor:[NSAppleEventDescriptor aliasListDescriptorWithArray:files] forKeyword:keyDirectObject];
		}else{
			event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kQSScriptSuite eventID:kQSOpenTextScriptCommand targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]autorelease];
			[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[iObject stringValue]] forKeyword:keyDirectObject];
		}
		
		[script executeAppleEvent:event error:&errorInfo];
		
		//QSLog(@"%@",errorInfo);
	}
	if (errorDict) QSLog(@"Run Script: %@",[errorDict objectForKey:@"NSAppleScriptErrorMessage"]);
	
	
	[script storeInFile:@"scriptPath"];
	
	
	[[QSTaskController sharedInstance] removeTask:@"Run AppleScript"];
}




- (QSObject *)objectForDescriptor:(NSAppleEventDescriptor *)desc{
	//QSLog(@"Descriptor: %@",desc);
	QSObject *object=nil;
	
	object=[desc objectValue];
	
	if ([object isKindOfClass:[NSArray class]] && [object count]){
		NSArray *paths=[object valueForKey:@"path"];
		return [QSObject fileObjectWithArray:paths];
	}
	if ([object isKindOfClass:[NSURL class]]){
		return [QSObject fileObjectWithPath:[(NSURL *)object path]];
	}
	if ([object isKindOfClass:[NSString class]])
		return [QSObject objectWithString:(NSString *)object];
	
	//QSLog(@"Object: %@",object);
	return nil;
}



- (QSObject *) performAction:(QSAction *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	NSDictionary *dict=[action objectForType:QSActionType];
	
	NSString *scriptPath=[dict objectForKey:kActionScript];
	NSString *handler=[dict objectForKey:kActionHandler];
	//NSString *eClass=[dict objectForKey:kActionEventClass];
	//NSString *eID=[dict objectForKey:kActionEventID];
	
	if (!handler){
		QSLog(@"no handler");
		return nil;
	}
	if ([scriptPath hasPrefix:@"/"] || [scriptPath hasPrefix:@"~"])
		scriptPath=[scriptPath stringByStandardizingPath];
	else
		scriptPath=[[action bundle]pathForResource:[scriptPath stringByDeletingPathExtension]
											ofType:[scriptPath pathExtension]];
	
	
	
	NSAppleEventDescriptor *event;
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	NSAppleEventDescriptor* targetAddress = [[[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)]autorelease];
	
	
	NSDictionary *errorDict=nil;
	NSAppleScript *script=[[[NSAppleScript alloc]initWithContentsOfURL:[NSURL fileURLWithPath:scriptPath] error:&errorDict]autorelease];
	
	if ([handler isEqualToString:@"QSOpenFileEventPlaceholder"]){
		NSArray *files=[dObject validPaths];	 
		event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]autorelease];
		[event setParamDescriptor:[NSAppleEventDescriptor aliasListDescriptorWithArray:files] forKeyword:keyDirectObject];
	}else if ([handler isEqualToString:@"QSOpenTextEventPlaceholder"]){
		event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kQSScriptSuite eventID:kQSOpenTextScriptCommand targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]autorelease];
		[event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:[dObject stringValue]] forKeyword:keyDirectObject];
	}else{
		id object;
		NSArray *types=[[action actionDict]objectForKey:kActionDirectTypes];
		NSString *type=([types count])?[types objectAtIndex:0]:[dObject primaryType];
		
		object=[dObject arrayForType:type];
		
		if ([type isEqual:QSFilePathType])
			object=[NSAppleEventDescriptor aliasListDescriptorWithArray:object];
		else
			object=[NSAppleEventDescriptor descriptorWithObject:object];
		
		
		event = [NSAppleEventDescriptor descriptorWithSubroutineName:handler argumentsArray:[NSArray arrayWithObject:object]];
	}
	
	
	NSAppleEventDescriptor *result=[script executeAppleEvent:event error:&errorDict];
	
	if (errorDict)QSLog(@"error %@",errorDict);
	
	
	
	return [self objectForDescriptor:result];
	return nil;
	
}


- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	//QSLog(@"valid?");
	//NSString *path=[dObject singleFilePath];
	if ([dObject objectForType:QSFilePathType]){
		
		NSArray *handlers=[NSAppleScript validHandlersFromArray:[NSArray arrayWithObjects:@"aevtoapp",@"DAEDopnt",@"aevtodoc",nil] inScriptFile:[dObject singleFilePath]];
		//QSLog(@"hanlers:%@",handlers);
		//  **** store this information in metadata
		NSMutableArray *array=[NSMutableArray array];
		if ([handlers containsObject:@"aevtoapp"] || ![handlers count])
			[array addObject:kAppleScriptRunAction];
		if ([handlers containsObject:@"DAEDopnt"])
			[array addObject:kAppleScriptOpenTextAction];
		if ([handlers containsObject:@"aevtodoc"])
			[array addObject:kAppleScriptOpenFilesAction];
		return array;
	}else if ([[dObject primaryType]isEqualToString:QSTextType]){
		return [NSArray arrayWithObjects:kAppleScriptRunTextAction,nil];
	}
	return nil;
}
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	if ([action isEqualToString:kAppleScriptOpenTextAction]){
		QSObject *textObject=[QSObject textProxyObjectWithDefaultValue:@""];
		return [NSArray arrayWithObject:textObject]; //[QSLibarrayForType:NSFilenamesPboardType];
	}
	return nil;
}


@end
