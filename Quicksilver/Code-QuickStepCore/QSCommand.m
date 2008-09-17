#import "QSCommand.h"

#import "QSObject.h"
#import "QSPreferencesController.h"
#import "QSAction.h"
#import "QSRegistry.h"
#import "QSLibrarian.h"
#import "QSExecutor.h"
#import "QSController.h"
#import "QSInterfaceController.h"

#import "QSTextProxy.h"
#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSObject_FileHandling.h"
#import "QSResourceManager.h"
#import "QSDebug.h"

#import "QSObject_Menus.h"
#import "QSTypes.h"
#import "QSTrigger.h"
#import "QSTriggerCenter.h"

#import "QSTriggersPrefPane.h"

@interface QSObject (QSCommandCompletionProtocol)
- (void)completeAndExecuteCommand:(QSCommand *)command;
@end

@implementation QSCommandObjectHandler
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	if ([action isEqualToString:@"QSCommandSaveAction"])
		return nil;
	else
		return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@""]];
}
- (QSObject *)executeCommand:(QSObject *)dObject {
	return [(QSCommand*)[dObject objectForType:QSCommandType] execute];
}

NSTimeInterval QSTimeIntervalForString(NSString *intervalString) {
	NSScanner *scanner = [NSScanner scannerWithString:intervalString];

	float h = 0.0f;
	float m = 0.0f;
	float s = 0.0f;
	float f;
	NSString *string;
	while (![scanner isAtEnd]) {
		[scanner scanFloat:&f];
		if (![scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&string])
			string = nil;

		if (![string length] || [string isEqualToString:@":"]) {
			if (m != 0.0f) {
				if (h != 0.0f) {
					s += f;
				} else {
					h = m ;
					m = f;
				}
			} else {
				m = f;
			}

		} else if ([string hasPrefix:@"h"]) {
			h += f;
		} else if ([string hasPrefix:@"m"]) {
			m += f;
		} else if ([string hasPrefix:@"s"]) {
			s += f;
		}
	}
	return h*60*60+m*60+s;
}

- (QSObject *)saveCommand:(QSObject *)dObject toPath:(QSObject *)iObject {
	QSCommand *command = [dObject objectForType:QSCommandType];
	id commandObject = [command dObject];
	BOOL asDroplet = [[commandObject identifier] isEqualToString:@"QSDropletItemProxy"];

	NSLog(@"droplet %d", asDroplet);
	NSString *destination = [[[[iObject singleFilePath] stringByAppendingPathComponent:[dObject name]] stringByAppendingPathExtension:asDroplet?@"app":@"qscommand"] firstUnusedFilePath];
	if (asDroplet) {
		[[NSFileManager defaultManager] copyPath:[[NSBundle mainBundle] pathForResource:@"QSDroplet" ofType:@"app"] toPath:destination handler:nil];
		[command writeToFile:[destination stringByAppendingPathComponent:@"Contents/Command.qscommand"]];
	} else {
		[command writeToFile:destination];
		[commandObject loadIcon];
		NSImage *image = [commandObject icon];
		[image setFlipped:NO];
		[image setSize:QSSize128];
		[[NSWorkspace sharedWorkspace] setIcon:image forFile:destination options:NSExcludeQuickDrawElementsIconCreationOption];
	}
	return [QSObject fileObjectWithPath:destination];
}

- (void)addTrigger:(QSObject *)dObject {
	QSCommand *command = [dObject objectForType:QSCommandType];

	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:5];
	[info setObject:@"QSHotKeyTrigger" forKey:@"type"];
	[info setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];

	if (command)
		[info setObject:command forKey:@"command"];

	[info setObject:[NSString uniqueString] forKey:kItemID];

	QSTrigger *trigger = [QSTrigger triggerWithInfo:info];
	[trigger initializeTrigger];
	[[QSTriggerCenter sharedInstance] addTrigger:trigger];
	[[NSClassFromString(@"QSPreferencesController") sharedInstance] showPaneWithIdentifier:@"QSTriggersPrefPane"];
	[[NSClassFromString(@"QSTriggersPrefPane") sharedInstance] showTrigger:trigger];
}

- (QSObject *)executeCommand:(QSObject *)dObject afterDelay:(QSObject *)iObject {
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:QSTimeIntervalForString([iObject stringValue])] interval:0 target:self selector:@selector(runCommand:) userInfo:[dObject objectForType:QSCommandType] repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//	[timer release];
	return nil;
}

- (QSObject *)executeCommand:(QSObject *)dObject atTime:(QSObject *)iObject {
	NSDate *date = [NSDate dateWithNaturalLanguageString:[iObject stringValue]];
	if (!date) { NSBeep(); return nil; }
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:date interval:0 target:self selector:@selector(runCommand:) userInfo:[dObject objectForType:QSCommandType] repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
//	[timer release];
	return nil;
}

- (void)runCommand:(NSTimer *)timer {
	[(QSCommand*)[timer userInfo] execute];
	[timer release];
}

- (void)setQuickIconForObject:(QSObject *)object {
	[object setIcon:[NSImage imageNamed:@"defaultAction"]];
}

- (BOOL)loadIconForObject:(QSObject *)object {
	QSAction *action = (QSAction *)[[object objectForType:QSCommandType] dObject];
	[action loadIcon];
	[object setIcon:[action icon]];
	return YES;
}

- (NSString *)detailsOfObject:(QSObject *)object { return nil; }

// CommandsAsActionsHandling
- (QSObject *)performAction:(QSAction *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	[[QSCommand commandWithInfo:[[action objectForType:QSActionType] objectForKey:@"command"]] execute];
	return nil;
}
@end

@implementation QSCommand

- (QSObject *)objectValue {
	QSObject *commandObject = [QSObject objectWithName:[self description]];
	[commandObject setObject:self forType:QSCommandType];
	[commandObject setPrimaryType:QSCommandType];
	return commandObject;
}
- (NSArray *)types {return [NSArray arrayWithObject:QSCommandType];}

- (id)init {
	if (self = [super init]) {
		oDict = [[NSMutableDictionary alloc] initWithCapacity:2];
	}
	return self;
}
+ (QSCommand *)commandWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject {
	if (dObject && aObject)
		return [[[self alloc] initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject] autorelease];
	return nil;
}
- (QSCommand *)initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject {
	if (self = [self init]) {
		if (dObject) [oDict setObject:dObject forKey:@"directObject"];
		if (aObject) [oDict setObject:aObject forKey:@"actionObject"];
		if (iObject) [oDict setObject:iObject forKey:@"indirectObject"];
		if ([dObject identifier]) [oDict setObject:[dObject identifier] forKey:@"directID"];
		if ([aObject identifier]) [oDict setObject:[aObject identifier] forKey:@"actionID"];
		if ([iObject identifier]) [oDict setObject:[iObject identifier] forKey:@"indirectID"];
	}
	return self;
}

+ (QSCommand *)commandWithInfo:(id)command {
	if ([command isKindOfClass:[NSDictionary class]]) {
		command = [QSCommand commandWithDictionary:command];
	} else if ([command isKindOfClass:[NSString class]]) {
		NSDictionary *commandInfo = [QSReg valueForKey:command inTable:@"QSCommands"];
		command = [QSCommand commandWithDictionary:[commandInfo objectForKey:@"command"]];
	}
	return command;
}

+ (QSCommand *)commandWithDictionary:(NSDictionary *)newDict {
	return [[(QSCommand *)[self alloc] initWithDictionary:newDict] autorelease];
}

+ (QSCommand *)commandWithFile:(NSString *)path {
	return [self commandWithDictionary:[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:@"command"]];
}
- (void)writeToFile:(NSString *)path {
	[[NSDictionary dictionaryWithObject:[self dictionaryRepresentation] forKey:@"command"] writeToFile:path atomically:NO];
}
- (void)setDObject:(id)dObject {
	if (dObject) [oDict setObject:dObject forKey:@"directObject"];
	if ([dObject identifier]) [oDict setObject:[dObject identifier] forKey:@"directID"];
}
- (QSCommand *)initWithDictionary:(NSDictionary *)newDict {
	if (self = [self init]) {
		[oDict addEntriesFromDictionary:newDict];
	}
	return self;
}
- (void)dealloc {
	[oDict release];
	[super dealloc];
}
- (NSComparisonResult) compare:(id)compareObject {
	return [[self description] compare:[compareObject description]];
}
- (NSDictionary *)dictionaryRepresentation {
	NSMutableDictionary *sDict = [oDict mutableCopy];
	QSObject *dObject = [oDict objectForKey:@"directObject"];
	QSObject *iObject = [oDict objectForKey:@"indirectObject"];
	if (dObject && ![oDict objectForKey:@"directArchive"]) [sDict setObject:[dObject archiveDictionary] forKey:@"directArchive"];
	if (iObject && ![oDict objectForKey:@"indirectArchive"]) [sDict setObject:[iObject archiveDictionary] forKey:@"indirectArchive"];
	[sDict removeObjectsForKeys:[NSArray arrayWithObjects:@"directObject", @"indirectObject", @"actionObject", nil]];
	return [sDict autorelease];
}

- (QSObject *)executeIgnoringModifiers {
#if 0
	[QSAction setModifiersAreIgnored:YES];
	QSObject *result = [self execute];
	[QSAction setModifiersAreIgnored:NO];
	return result;
#endif
	return [self execute];
}

- (QSObject *)execute {
	QSAction *aObject = [self aObject];
	QSObject *dObject = [self dObject];
	QSObject *iObject = [self iObject];

	if (VERBOSE) NSLog(@"Execute Command: %@", [self description]);
	int argumentCount = [(QSAction *)aObject argumentCount];
	if (argumentCount<2) {
		return [aObject performOnDirectObject:dObject indirectObject:iObject];
	} else if (argumentCount == 2) {
		if ([iObject objectForType:QSTextProxyType]) {
			[[(QSController *)[NSApp delegate] interfaceController] executePartialCommand:[NSArray arrayWithObjects:dObject, aObject, iObject, nil]];
		} else if (iObject) {
			return [aObject performOnDirectObject:dObject indirectObject:iObject];
		} else {
			if (!iObject) {
				NSString *selectClass = [[NSUserDefaults standardUserDefaults] stringForKey:@"QSUnidentifiedObjectSelector"];
				id handler = [QSReg getClassInstance:selectClass];
				NSLog(@"handler %@ %@", selectClass, handler);
				if (handler && [handler respondsToSelector:@selector(completeAndExecuteCommand:)]) {
					[handler completeAndExecuteCommand:self];
					return nil;
				}
			}
			[[(QSController *)[NSApp delegate] interfaceController] executePartialCommand:[NSArray arrayWithObjects:dObject, aObject, iObject, nil]];
		}
		return nil;
	}
	return nil;
//		NS_DURING
//	NS_HANDLER
//		;
//	NS_ENDHANDLER
}
- (void)executeFromMenu:(id)sender {
	//NSLog(@"sender %@", NSStringFromClass([sender class]) );
	QSObject *object = [self execute];
	if (object) {
		[[(QSController *)[NSApp delegate] interfaceController] selectObject:object];
		[[(QSController *)[NSApp delegate] interfaceController] actionActivate:nil];
	}
}

- (void)executeFromMenuWithIndirect:(id)sender {
	QSObject *object = [sender representedObject];
	[oDict setObject:object forKey:@"indirectObject"];
	[self executeFromMenu:sender];
}
- (void)executeWithIndirect:(id)iObject {
	QSObject *object = (QSObject *)[iObject resolvedObject];
	[oDict setObject:object forKey:@"indirectObject"];
	[self executeFromMenu:nil];
}
- (id)copyWithZone:(NSZone *)zone {
	return [[QSCommand alloc] initWithDictionary:[[oDict mutableCopy] autorelease]];
}
- (NSArray *)validIndirects {
	  NSArray *indirects = [[[self aObject] provider] validIndirectObjectsForAction:[[self aObject] identifier] directObject:[self dObject]];
	  if ([indirects count] >1 && [[indirects objectAtIndex:1] isKindOfClass:[NSArray class]]) indirects = [indirects objectAtIndex:1];
	  if ([indirects count] == 1 && [[indirects objectAtIndex:0] containsType:QSTextProxyType]) {
		  indirects = nil;
	  }
	  return indirects;
}
- (void)menuNeedsUpdate:(NSMenu *)menu {
	  NSArray *indirects = [self validIndirects];
	  NSMenuItem *item;
	  if ([indirects count]) {
		  int i;
		  for (i = 0; i < [indirects count] && i < 10; i++) {
			  QSBasicObject *indirect = [indirects objectAtIndex:i];
			  if ([indirect isKindOfClass:[NSNull class]]) continue;
			  item = [indirect menuItem];
			  [menu addItem:item];
			  [item setAction:@selector(executeFromMenuWithIndirect:)];
			  [item setTarget:self];
			  [item setRepresentedObject:indirect];
		  }
	  } else {
		  item = [menu addItemWithTitle:@"Choose..." action:@selector(executeFromMenu:) keyEquivalent:@""];
		  [item setImage:[[NSImage imageNamed:@"Quicksilver"] duplicateOfSize:QSSize16]];
		  [[item image] setFlipped:NO];
		  [item setTarget:self];
	  }
	  [menu setDelegate:nil];
}

- (QSAction *)aObject {
	QSAction *aObject;
	return ((aObject = [oDict objectForKey:@"actionObject"])) ? aObject : [QSExec actionForIdentifier:[oDict objectForKey:@"actionID"]];
}
- (QSObject *)dObject {
	QSObject *dObject = [oDict objectForKey:@"directObject"];
	if (!dObject) dObject = [QSObject objectWithIdentifier:[oDict objectForKey:@"directID"]];
	if (!dObject) {
		dObject = [QSObject objectWithDictionary:[oDict objectForKey:@"directArchive"]];
		if (dObject) [oDict setObject:dObject forKey:@"directObject"];
	}
	if (!dObject) {
		dObject = [QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:[oDict objectForKey:@"directResource"]]];
		if (dObject) [oDict setObject:dObject forKey:@"directObject"];
	}
	return dObject;
}
- (QSObject *)iObject {
	QSObject *iObject = [oDict objectForKey:@"indirectObject"];
	if (!iObject) iObject = [QSObject objectWithIdentifier:[oDict objectForKey:@"indirectID"]];
	if (!iObject) {
		iObject = [QSObject objectWithDictionary:[oDict objectForKey:@"indirectArchive"]];
		if (iObject) [oDict setObject:iObject forKey:@"indirectObject"];
	}
	if (!iObject) {
		iObject = [QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:[oDict objectForKey:@"indirectResource"]]];
		if (iObject) [oDict setObject:iObject forKey:@"indirectObject"];
	}
	return iObject;
}

- (NSString *)description {
	if ([self aObject])
		return [[self aObject] commandDescriptionWithDirectObject:[self dObject] indirectObject:[self iObject]];
	else
		return [NSString stringWithFormat:@"[Action Missing: %@] ", [oDict objectForKey:@"actionID"]];
}

- (NSImage *)icon {
	QSObject *direct = [self dObject];
	[direct loadIcon];
	return [direct icon];
}

- (NSString *)text { return [self description]; }
- (NSImage *)image { return [self icon]; }

@end
