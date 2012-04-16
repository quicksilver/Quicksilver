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

@interface QSCommand ()
- (NSMutableDictionary *)commandDict;
@end

@implementation QSCommandObjectHandler

- (void)setQuickIconForObject:(QSObject *)object {
	[object setIcon:[NSImage imageNamed:@"defaultAction"]];
}

- (BOOL)loadIconForObject:(QSObject *)object {
    id dObject = [(QSCommand*)object dObject];
	[dObject loadIcon];
	[object setIcon:[dObject icon]];
	return YES;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	if ([action isEqualToString:@"QSCommandSaveAction"])
		return nil;
	else
		return [NSArray arrayWithObject:[QSObject textProxyObjectWithDefaultValue:@""]];
}

// CommandsAsActionsHandling
- (QSObject *)performAction:(QSAction *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict=[action objectForType:QSActionType];
	QSCommand *command=[QSCommand commandWithInfo:[dict objectForKey:@"command"]];
	return [command execute];
}

- (QSObject *)executeCommand:(QSObject *)dObject {
	return [(QSCommand*)dObject execute];
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
	id commandObject = [(QSCommand*)dObject dObject];
	BOOL asDroplet = [[commandObject identifier] isEqualToString:@"QSDropletItemProxy"];
    
#ifdef DEBUG
	NSLog(@"droplet %d", asDroplet);
#endif
	NSString *destination = [[[[iObject singleFilePath] stringByAppendingPathComponent:[dObject name]] stringByAppendingPathExtension:asDroplet?@"app":@"qscommand"] firstUnusedFilePath];
	if (asDroplet) {
		[[NSFileManager defaultManager] copyItemAtPath:[[NSBundle mainBundle] pathForResource:@"QSDroplet" ofType:@"app"] toPath:destination error:nil];
		[dObject writeToFile:[destination stringByAppendingPathComponent:@"Contents/Command.qscommand"]];
	} else {
		[dObject writeToFile:destination];
		[commandObject loadIcon];
		NSImage *image = [commandObject icon];
		[image setFlipped:NO];
		[image setSize:QSSize128];
		[[NSWorkspace sharedWorkspace] setIcon:image forFile:destination options:NSExcludeQuickDrawElementsIconCreationOption];
	}
	return [QSObject fileObjectWithPath:destination];
}

- (QSObject*)addTrigger:(QSObject *)dObject withInfo:(QSObject*)iObject {
#warning TODO: iObject contains a string which allows passing missing parameters (trigger type, mainly)
    /* More TODO: Ask the trigger's trigger manager to parse the iObject stringValue,
     * so that trigger manager get a chance to customize their properties */
	QSCommand *command = (QSCommand*)dObject;
    
	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithCapacity:5];
	[info setObject:@"QSHotKeyTrigger" forKey:@"type"];
	[info setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];
    
	if (command)
		[info setObject:command forKey:@"command"];
    
	[info setObject:[NSString uniqueString] forKey:kItemID];
    
	QSTrigger *trigger = [QSTrigger triggerWithDictionary:info];
	[trigger initializeTrigger];
	[[QSTriggerCenter sharedInstance] addTrigger:trigger];
	[[NSClassFromString(@"QSPreferencesController") sharedInstance] showPaneWithIdentifier:@"QSTriggersPrefPane"];
	[[NSClassFromString(@"QSTriggersPrefPane") sharedInstance] showTrigger:trigger];
    [[NSClassFromString(@"QSTriggersPrefPane") sharedInstance] setTabViewIndex:0];
    [[NSClassFromString(@"QSTriggersPrefPane") sharedInstance] showTriggerInfo:trigger];
    return nil;
}

- (QSObject *)executeCommand:(QSObject *)dObject afterDelay:(QSObject *)iObject {
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:QSTimeIntervalForString([iObject stringValue])] interval:0 target:self selector:@selector(runCommand:) userInfo:dObject repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [timer release];
	return nil;
}

- (QSObject *)executeCommand:(QSObject *)dObject atTime:(QSObject *)iObject {
	NSDate *date = [NSDate dateWithNaturalLanguageString:[iObject stringValue]];
	if (!date) { NSBeep(); return nil; }
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:date interval:0 target:self selector:@selector(runCommand:) userInfo:dObject repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [timer release];
	return nil;
}

- (void)runCommand:(NSTimer *)timer {
	[(QSCommand*)[timer userInfo] execute];
	[timer invalidate];
}

@end

@implementation QSCommand
+ (QSCommand *)commandWithDirectObject:(QSObject *)dObject actionObject:(QSAction *)aObject indirectObject:(QSObject *)iObject {
	if (dObject && aObject)
		return [[[self alloc] initWithDirectObject:dObject actionObject:aObject indirectObject:iObject] autorelease];
	return nil;
}

+ (QSCommand *)commandWithInfo:(id)info {
    QSCommand *command = nil;
    if ([info isKindOfClass:[NSDictionary class]]) {
        command = [QSCommand commandWithDictionary:info];
    } else if ([info isKindOfClass:[NSString class]]) {
        command = [QSCommand commandWithIdentifier:info];
    } else if (![info isKindOfClass:[QSCommand class]]) {
        [self release];
        return nil;
    }
    return command;
}

+ (QSCommand *)commandWithIdentifier:(NSString*)identifier {
    NSDictionary *commandInfo = [QSReg valueForKey:identifier inTable:@"QSCommands"];
    QSCommand *cmd = nil;
    if (commandInfo) {
        cmd = [QSCommand commandWithDictionary:[commandInfo objectForKey:@"command"]];
        [cmd setIdentifier:identifier];
    }
    return cmd;
}

+ (QSCommand *)commandWithDictionary:(NSDictionary *)dict {
    QSCommand *cmd = [[self alloc] init];
    [cmd setObject:dict forType:QSCommandType];
    return [cmd autorelease];
}

+ (QSCommand *)commandWithFile:(NSString *)path {
	return [self objectWithDictionary:[[NSDictionary dictionaryWithContentsOfFile:path] objectForKey:@"command"]];
}

- (QSCommand *)initWithDirectObject:(QSObject *)directObject actionObject:(QSAction *)actionObject indirectObject:(QSObject *)indirectObject {
	if (self = [self init]) {
		if (directObject) [self setDirectObject:directObject];
		if (actionObject) [self setActionObject:actionObject];
		if (indirectObject) [self setIndirectObject:indirectObject];
	}
	return self;
}

- (id)init {
	if (self = [super init]) {
        [self setPrimaryType:QSCommandType];
	}
	return self;
}

- (NSMutableDictionary*)commandDict {
    NSMutableDictionary *dict = [self objectForType:QSCommandType];
    if(!dict) [self setObject:(dict = [NSMutableDictionary dictionary]) forType:QSCommandType];
    return dict;
}

- (void)writeToFile:(NSString *)path {
	[[NSDictionary dictionaryWithObject:[self dictionaryRepresentation] forKey:@"command"] writeToFile:path atomically:NO];
}

- (void)setDirectObject:(QSObject*)newObject {
    if (newObject != nil && dObject != newObject) {
        [dObject release];
        dObject = [newObject retain];
        
        id rep = [dObject identifier];
        if(rep != nil)
            [[self commandDict] setObject:rep forKey:@"directID"];
        else {
            rep = [dObject dictionaryRepresentation];
            if(rep)
                [[self commandDict] setObject:rep forKey:@"directArchive"];
        }
        
    }
}

- (void)setActionObject:(QSAction*)newObject {
    if (newObject != nil && aObject != newObject) {
        [aObject release];
        aObject = [newObject retain];
    
        id rep = [aObject identifier];
        if(rep != nil)
            [[self commandDict] setObject:rep forKey:@"actionID"];
        else {
            rep = [aObject dictionaryRepresentation];
            if(rep)
                [[self commandDict] setObject:rep forKey:@"actionArchive"];
        }
    }
}

- (void)setIndirectObject:(QSObject*)newObject {
    if (newObject != nil && iObject != newObject) {
        [iObject release];
        iObject = [newObject retain];
    
        id rep = [iObject identifier];
        if(rep != nil)
            [[self commandDict] setObject:rep forKey:@"indirectID"];
        else {
            rep = [iObject dictionaryRepresentation];
            if(rep)
                [[self commandDict] setObject:rep forKey:@"indirectArchive"];
        }
    }
}

- (QSAction *)aObject {
    QSAction *action = aObject;
	if (action) {
		return action;
	}
	
	NSDictionary *cmdDict = [self commandDict];
	
    action = [QSAction actionWithIdentifier:[cmdDict objectForKey:@"actionID"]];
    
	if (!action) {
        action = [QSAction actionWithDictionary:[cmdDict objectForKey:@"actionArchive"]];
    }
	
	if (!action) {
		NSLog(@"Warning: no action object for Command %@\nCommand Dictionary: %@", self, cmdDict);
	}
	else {
		[self setActionObject:action];
	}

    return action;
}

- (QSObject *)dObject {
	QSObject *object = dObject;
	// Return the object if it already exists, and has been resolved (i.e. has an identifier)
	if (object && [object identifier]) {
		return object;
	}
	
	NSDictionary *cmdDict = [self commandDict];
	NSString *directID = [cmdDict objectForKey:@"directID"];

	if (directID) {
        object = [QSObject objectWithIdentifier:directID];
	}
	
	if (!object) {
        object = [QSObject objectWithDictionary:[cmdDict objectForKey:@"directArchive"]];
    }

    if (!object) {
        object = [QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:[cmdDict objectForKey:@"directResource"]]];
	}
	
	// For cases where the command has a directID/directArchive, but it's corresponding object hasn't already been created (i.e. *not* in the catalog)
	if (!object && directID) {
		// sniffs the string to create a new object
		object = [QSObject objectWithString:directID];
	}
	
	
	// For cases where we really can't determine the object
	if (!object) {
		NSLog(@"Warning: no direct object for Command %@\nCommand Dictionary: %@", self, cmdDict);
	}
	else {
		[self setDirectObject:object];
	}
    return object;
}

- (QSObject *)iObject {
	QSObject *object = iObject;
	if (object) {
		return object;
	}
	
	NSDictionary *cmdDict = [self commandDict];
	NSString *indirectID = [cmdDict objectForKey:@"indirectID"];
	
    if (indirectID) {
        object = [QSObject objectWithIdentifier:indirectID];
	}
	
	if (!object) {
        object = [QSObject objectWithDictionary:[cmdDict objectForKey:@"indirectArchive"]];
    }
		
	if (!object) {
		object = [QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:[cmdDict objectForKey:@"indirectResource"]]];
	}
	
	// For cases where the object doesn't exist (not in the catalog)
	if (!object && indirectID) {
		// create an object by sniffing the string
		object = [QSObject objectWithString:indirectID];
	}
	
	if (object) {
		[self setIndirectObject:object];
	}
	return object;
}

- (NSComparisonResult) compare:(id)compareObject {
	return [[self description] compare:[compareObject description]];
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
	QSAction *actionObject = [self aObject];
	QSObject *directObject = [self dObject];
	QSObject *indirectObject = [self iObject];
#ifdef DEBUG
	if (VERBOSE) NSLog(@"Execute Command: %@", self);
#endif
	QSInterfaceController *controller = [(QSController *)[NSApp delegate] interfaceController];
	int argumentCount = [(QSAction *)actionObject argumentCount];
	if (argumentCount == 2 && ![actionObject indirectOptional] && (!indirectObject || [[indirectObject primaryType] isEqualToString:QSTextProxyType])) {
		// indirect object required, but is either missing or asking for text input
		if (!indirectObject) {
			// attempt to use the Missing Object Selector
			NSString *selectClass = [[NSUserDefaults standardUserDefaults] stringForKey:@"QSUnidentifiedObjectSelector"];
			id handler = [QSReg getClassInstance:selectClass];
#ifdef DEBUG
			NSLog(@"handler %@ %@", selectClass, handler);
#endif
			if (handler && [handler respondsToSelector:@selector(completeAndExecuteCommand:)]) {
				[handler completeAndExecuteCommand:self];
				return nil;
			}
		}
		// use Quicksilver's interface to get the missing object
		[controller executePartialCommand:[NSArray arrayWithObjects:directObject, actionObject, indirectObject, nil]];
	} else {
		// indirect object is either present, or unnecessary - run the action
		QSObject *returnValue = [actionObject performOnDirectObject:directObject indirectObject:indirectObject];
		if (returnValue) {
			// if the action returns something, wipe out the first pane
			/* (The main object would get replaced anyway. This is only done to
			 remove objects selected by the comma trick before the action was run.) */
			[controller clearObjectView:[controller dSelector]];
			// put the result in the first pane and in the results list
			[[controller dSelector] performSelectorOnMainThread:@selector(setObjectValue:) withObject:returnValue waitUntilDone:YES];
			if (actionObject) {
				if ([actionObject isKindOfClass:[QSRankedObject class]] && [(QSRankedObject *)actionObject object]) {
					QSAction* rankedAction = [(QSRankedObject *)actionObject object];
					if (rankedAction != actionObject) {
						[rankedAction retain];
						[actionObject release];
						actionObject = rankedAction;
					}
				}
				// bring the interface back to show the result
				if ([actionObject displaysResult]) {
					// send focus to the second pane if the user has set the preference
					if ([[NSUserDefaults standardUserDefaults] boolForKey:@"QSJumpToActionOnResult"]) {
						[controller actionActivate:nil];
					}
					[controller showMainWindow:controller];
				}
			}
			return returnValue;
		}
	}
	return nil;
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
	[self setIndirectObject:[sender representedObject]];
	[self executeFromMenu:sender];
}

- (void)executeWithIndirect:(id)indirectObject {
    [self setIndirectObject:(QSObject *)[indirectObject resolvedObject]];
	[self executeFromMenu:nil];
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
			  QSObject *indirect = [indirects objectAtIndex:i];
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

- (QSObject *)objectValue {    
	QSCommand *commandObject = [QSCommand objectWithName:[self name]];
    [commandObject setDirectObject:self];
	return commandObject;
}

- (NSArray *)types {return [NSArray arrayWithObject:QSCommandType];}

- (NSString *)name {
    QSAction *actionObject = [self aObject];
    QSObject *directObject = [self dObject];
    QSObject *indirectObject = [self iObject];
    NSString *format = [actionObject commandFormat];
	if (format)
        return [NSString stringWithFormat:format, [directObject name], (indirectObject ? [indirectObject name] : @"<?>")];
	else
		return [NSString stringWithFormat:@"[Action Missing: %@] ", [[self commandDict] objectForKey:@"actionID"]];
}

- (NSString *)description {
	/* Because some interfaces use -description */
	return [self name];
}

- (NSImage *)icon {
	QSObject *direct = [self dObject];
	[direct loadIcon];
	return [direct icon];
}

- (NSString *)text { return [self name]; }
- (NSImage *)image { return [self icon]; }

@end
