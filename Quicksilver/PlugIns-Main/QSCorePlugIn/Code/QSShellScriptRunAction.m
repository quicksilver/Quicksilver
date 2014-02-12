//
// QSShellScriptRunAction.m
// Quicksilver
//
// Created by Alcor on 9/13/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSShellScriptRunAction.h"

#import "QSCore.h"
#import "QSMacros.h"

#import "QSTextViewer.h"

#define SCRIPT_EXT [NSArray arrayWithObjects:@"sh", @"pl", @"command", @"php", @"py", @"rb", nil]
NSString *QSGetShebangPathForScript(NSString *path) {
    NSArray *args = QSGetShebangArgsForScript(path);
    if (args)
        return [args objectAtIndex:0];
    
    return nil;
}
NSArray *QSGetShebangArgsForScript(NSString *path) {
	NSString *taskArgs = nil;
	NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithContentsOfFile:path usedEncoding:nil error:nil]];
	[scanner scanString:@"#!" intoString:nil];
	[scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\r\n"] intoString:&taskArgs];
	return [taskArgs componentsSeparatedByString:@" "];
}

BOOL QSPathCanBeExecuted(NSString *path, BOOL allowApps) {
    NSLog(@"QSPathCanBeExecuted is deprecated. Is -[QSObject isExecutable] instead. For the `allowApps` arg, use -[QSObject isApplication]");
    QSObject *obj = [QSObject fileObjectWithPath:path];
    return [obj isExecutable] && (allowApps || ![obj isApplication]);
}

@implementation QSShellScriptRunAction
- (QSAction *)scriptActionForPath:(NSString *)path {

	NSString *script = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];

	NSMutableDictionary *scriptDict = [NSMutableDictionary dictionary];
	for(__strong NSString * component in [script componentsSeparatedByString: @"%%%"]) {
		if (![component hasPrefix:@" {"]) continue;
		if (![component hasSuffix:@"} "]) continue;
		component = [component substringWithRange:NSMakeRange(1, [(NSString *)component length] - 2)];
		NSArray *keyval = [component componentsSeparatedByString:@"="];

		if ([keyval count] == 2) [scriptDict setObject:[keyval objectAtIndex:1] forKey:[keyval objectAtIndex:0]];
		//NSLog(@"dictionary:%@", scriptDict);
	}
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSArray arrayWithObjects:QSFilePathType, QSTextType, nil], @"directTypes",
                                 NSStringFromClass([self class]),  kActionClass,
                                 path,         @"actionScript",
                                 scriptDict,   @"scriptAttributes",
                                 self,         kActionProvider,
                                 nil];
    
	NSString *iconName = [scriptDict objectForKey:@"QSIcon"];
	if (iconName)
		[dict setObject:iconName forKey:kActionIcon];

	QSAction *action = [QSAction actionWithDictionary:dict identifier:[@"[Action] :" stringByAppendingString:path]];
	[action setName:[[path lastPathComponent] stringByDeletingPathExtension]];
	[action setObject:path forMeta:kQSObjectIconName];
	return action;
}

- (NSArray *)fileActionsFromPaths:(NSArray *)scripts {
	scripts = [scripts pathsMatchingExtensions:SCRIPT_EXT];
	NSMutableArray *array = [NSMutableArray array];

	for(NSString *path in scripts) {
		QSAction *action = [self scriptActionForPath:path];
		[array addObject:action];
	}
	return array;
}

- (QSObject *)performAction:(QSAction *)action directObject:(QSBasicObject *)dObject indirectObject:(QSBasicObject *)iObject {
	NSDictionary *dict = [action objectForType:QSActionType];

	NSString *scriptPath = [dict objectForKey:kActionScript];
	//NSString *handler = [dict objectForKey:kActionHandler];

	//NSString *eClass = [dict objectForKey:kActionEventClass];
	//NSString *eID = [dict objectForKey:kActionEventID];

	if ([scriptPath hasPrefix:@"/"] || [scriptPath hasPrefix:@"~"])
		scriptPath = [scriptPath stringByStandardizingPath];
	else
		scriptPath = [[action bundle] pathForResource:[scriptPath stringByDeletingPathExtension] ofType:[scriptPath pathExtension]];

	NSArray *arguments = [dObject arrayForType:QSFilePathType];
	if (!arguments) arguments = [dObject arrayForType:QSTextType];

	NSString *result = [self runExecutable:scriptPath withArguments:arguments];
	//NSLog(@"dict %@", [action actionDict]);
	if ([[[action objectForKey:@"scriptAttributes"] objectForKey:@"QSHandling"] isEqualToString:@"QSTextViewer"]) {
		QSShowTextViewerWithString(result);
		return nil;
	}

	if ([result length]) {
		id object = [QSObject objectWithString:result];
		if ([object singleFilePath])
			[[NSWorkspace sharedWorkspace] noteFileSystemChanged:[object singleFilePath]];
		return object;
	}

	//	return [self objectForDescriptor:result];
	return nil;

}

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	if ([dObject isExecutable] && ![dObject isApplication])
		return [NSArray arrayWithObject:kQSShellScriptRunAction];
	return nil;
}

- (NSString *)runExecutable:(NSString *)path withArguments:(NSArray *)arguments {
	NSString *taskPath = path;
	NSMutableArray *taskArgs = [NSMutableArray array];
    NSString *taskOutput = nil;
    
	if ([arguments count])
      [taskArgs addObjectsFromArray:arguments];
    
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:taskPath];
    [task setArguments:taskArgs];
    [task setStandardOutput:[NSPipe pipe]];
    
    @try {
        [task launch];
        [task waitUntilExit];
        taskOutput = [[NSString alloc] initWithData:[[[task standardOutput] fileHandleForReading] readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    }
    @catch (NSException *e) {
        NSLog(@"Task raised exception %@", e);
    }
	// NSLog(@"Run Task: %@ %@", taskPath, argArray);

	//int status = [task terminationStatus];
	///	if (status == 0) NSLog(@"Task succeeded.");
	//	else NSLog(@"Task failed.");
	return taskOutput;
}

@end
