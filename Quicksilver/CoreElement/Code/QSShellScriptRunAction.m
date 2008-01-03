//
//  QSShellScriptRunAction.m
//  Quicksilver
//
//  Created by Alcor on 9/13/04.

//

#import "QSShellScriptRunAction.h"

#define SCRIPT_EXT [NSArray arrayWithObjects:@"sh",@"pl",@"command",@"php",@"py",@"rb",nil]
NSString *QSGetShebangPathForScript(NSString *path){	
	   NSString *taskPath=nil;
	NSString *contents=[NSString stringWithContentsOfFile:path];
	NSScanner *scanner=[NSScanner scannerWithString:contents];
	[scanner scanString:@"#!" intoString:nil];
	[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] intoString:&taskPath];
	return taskPath;
}

BOOL QSPathCanBeExecuted(NSString *path,BOOL allowApps){
	BOOL isDirectory;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
		return NO;
	if (isDirectory)
		return NO;
	BOOL executable=[[NSFileManager defaultManager] isExecutableFileAtPath:path];
	if (!executable) {
		NSString *contents=[NSString stringWithContentsOfFile:path];
		if ([contents hasPrefix:@"#!"]) executable=YES;
		else if (VERBOSE) QSLog(@"No Shebang found");
	} else if (!allowApps) {
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path], kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication) // Ignore applications
			return NO;
	}
	return executable;	
}



@implementation QSShellScriptRunAction
- (QSAction *)scriptActionForPath:(NSString *)path{
	
	NSString *script=[NSString stringWithContentsOfFile:path];
	
	NSMutableDictionary *scriptDict=[NSMutableDictionary dictionary];
	foreach(component,[script componentsSeparatedByString: @"%%%"]){
		if (![component hasPrefix:@"{"]) continue;
		if (![component hasSuffix:@"}"]) continue;
		component=[component substringWithRange:NSMakeRange(1,[(NSString *)component length]-2)];
		NSArray *keyval=[component componentsSeparatedByString:@"="];
		
		if ([keyval count]==2)[scriptDict setObject:[keyval objectAtIndex:1] forKey:[keyval objectAtIndex:0]];
		//QSLog(@"dictionary:%@",scriptDict);	
	}

//	QSLog(@"script %@",scriptDict);
	QSAction *action=[QSAction actionWithIdentifier:[@"[Action]:" stringByAppendingString:path]];
	[[action actionDict]setObject:path forKey:@"actionScript"];
	
	[[action actionDict]setObject:scriptDict forKey:@"scriptAttributes"];
	[[action actionDict]setObject:NSStringFromClass([self class]) forKey:kActionClass];
	[[action actionDict]setObject:self forKey:kActionProvider];
	
	[[action actionDict]setObject:[NSArray arrayWithObjects:QSFilePathType,QSTextType,nil] forKey:@"directTypes"];

	NSString *iconName=[scriptDict objectForKey:@"QSIcon"];
	if (iconName)
		[[action actionDict]setObject:iconName forKey:@"icon"];
//	if ([handlers containsObject:@"DAEDopnt"]){
//		[[action actionDict]setObject:[NSArray arrayWithObject:QSTextType] forKey:@"directTypes"];
//	}
	
//	if ([handlers containsObject:@"aevtodoc"]){
//		[[action actionDict]setObject:[NSArray arrayWithObject:QSFilePathType] forKey:@"directTypes"];
//	}
	
	[action setName:[[path lastPathComponent]stringByDeletingPathExtension]];
	[action setObject:path forMeta:kQSObjectIconName];
	return action;
}


- (NSArray *) fileActionsFromPaths:(NSArray *)scripts{
	scripts=[scripts pathsMatchingExtensions:SCRIPT_EXT];
	NSEnumerator *e=[scripts objectEnumerator];
	NSString *path;
	NSMutableArray *array=[NSMutableArray array];
	
	while((path=[e nextObject])){
		QSAction *action=[self scriptActionForPath:path];
		[array addObject:action];
	}
	return array;
}


- (QSObject *) performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject{
	NSDictionary *dict=[action objectForType:QSActionType];
	
	NSString *scriptPath=[dict objectForKey:kActionScript];
	//NSString *handler=[dict objectForKey:kActionHandler];
	
	//NSString *eClass=[dict objectForKey:kActionEventClass];
	//NSString *eID=[dict objectForKey:kActionEventID];
	
	if ([scriptPath hasPrefix:@"/"] || [scriptPath hasPrefix:@"~"])
		scriptPath=[scriptPath stringByStandardizingPath];
	else
		scriptPath=[[action bundle]pathForResource:[scriptPath stringByDeletingPathExtension]
											ofType:[scriptPath pathExtension]];
	
	NSArray *arguments=[dObject arrayForType:QSFilePathType];
	if (!arguments) arguments=[dObject arrayForType:QSTextType];
	
	NSString *result=[self runExecutable:scriptPath withArguments:arguments];
	//QSLog(@"dict %@",[action actionDict]);
	if ([[[action actionDict]valueForKeyPath:@"scriptAttributes.QSHandling"]isEqualToString:@"QSTextViewer"]){

		
		QSShowTextViewerWithString(result);
		return nil;
	}
	
	if ([result length]){
		id object=[QSObject objectWithString:result];
		if ([object singleFilePath])
			[[NSWorkspace sharedWorkspace]noteFileSystemChanged:[object singleFilePath]];
		return object;
	}
	
	
	//	return [self objectForDescriptor:result];
	return nil;
	
}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	if (QSPathCanBeExecuted([dObject singleFilePath],NO))
		return [NSArray arrayWithObject:kQSShellScriptRunAction];
	return nil;
}

- (QSObject *)runShellScript:(QSObject *)dObject{
	NSString *result=[self runScript:[(QSObject *)dObject singleFilePath]];
	if ([result length])
		return [QSObject objectWithString:result];
	return nil;
}

- (NSString *)runScript:(NSString *)path{
    BOOL executable=[[NSFileManager defaultManager] isExecutableFileAtPath:path];
    
    NSString *taskPath=path;
    NSMutableArray *argArray=[NSMutableArray array]; 
    
    if (!executable){
		
		[argArray addObject:taskPath];
		taskPath=QSGetShebangPathForScript(path);
	}
	NSTask *task=[[[NSTask alloc]init]autorelease];
	[task setLaunchPath:taskPath];
	[task setArguments:argArray];
	[task setStandardOutput:[NSPipe pipe]];
	[task launch];
	[task waitUntilExit];
	
	NSString *string=[[[NSString alloc] initWithData:[[[task standardOutput]fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding]autorelease];
//	int status = [task terminationStatus];
	//if (status == 0) QSLog(@"Task succeeded.");
	//else QSLog(@"Task failed.");
	return string;
}







- (NSString *)runExecutable:(NSString *)path withArguments:(NSArray *)arguments{
    BOOL executable=[[NSFileManager defaultManager] isExecutableFileAtPath:path];
    
    NSString *taskPath=path;
    NSMutableArray *argArray=[NSMutableArray array]; 
    
    if (!executable){
        NSString *contents=[NSString stringWithContentsOfFile:path];
        NSScanner *scanner=[NSScanner scannerWithString:contents];
        [argArray addObject:taskPath];
        [scanner scanString:@"#!" intoString:nil];
        [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] intoString:&taskPath];
    }
    
    if ([arguments count]);
    [argArray addObjectsFromArray:arguments];


	NSTask *task=[[[NSTask alloc]init]autorelease];
	[task setLaunchPath:taskPath];
	[task setArguments:argArray];
	[task setStandardOutput:[NSPipe pipe]];
	[task launch];
	[task waitUntilExit];
	// QSLog(@"Run Task: %@ %@",taskPath,argArray);

	NSString *string=[[[NSString alloc] initWithData:[[[task standardOutput]fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding]autorelease];

	//int status = [task terminationStatus];
	///	if (status == 0) QSLog(@"Task succeeded.");
	//	else QSLog(@"Task failed.");
	return string;
}


@end
