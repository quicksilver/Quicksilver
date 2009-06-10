

#import "QSCommand.h"

#import "QSObject.h"
#import "QSAction.h"

#import "QSLibrarian.h"
#import "QSExecutor.h"
#import "QSInterfaceController.h"
#import "NSImage_BLTRExtensions.h"
#import "QSTextProxy.h"
#import "QSObject_PropertyList.h"
#import "QSObject_StringHandling.h"
#import "QSObject_FileHandling.h"
#import "QSResourceManager.h"
#import "QSDebug.h"

#import "QSObject_Menus.h"
#import "QSTypes.h"

@interface QSObject (QSCommandCompletionProtocol)
- (void)completeAndExecuteCommand:(QSCommand *)command;
@end

@implementation QSCommand
- (QSObject *)objectValue {
	QSObject *commandObject = [QSObject objectWithName:[self name]];
	[commandObject setObject:self forType:QSCommandType];
	[commandObject setPrimaryType:QSCommandType];
	return commandObject;
}

- (NSArray *)types { return [NSArray arrayWithObject:QSCommandType]; }

- (id)init {
    self = [super init];
    if( self ) {
        oDict = [[NSMutableDictionary alloc] initWithCapacity:2]; 
    }
    return self;
}

+ (id)commandWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject {
    if (dObject && aObject)
        return [[[self alloc] initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject] autorelease];
    return nil;
}

- (id)initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject {
    self = [self init];
    if( self ) {
        if (dObject) [oDict setObject:dObject forKey:@"directObject"];
        if (aObject) [oDict setObject:aObject  forKey:@"actionObject"];
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
	} else if([command isKindOfClass:[NSString class]]) {
		NSDictionary *commandInfo = [QSReg valueForKey:command inTable:@"QSCommands"];
		command = [QSCommand commandWithDictionary:[commandInfo objectForKey:@"command"]];
	}
	return command;
}

+ (id)commandWithDictionary:(NSDictionary *)newDict {
	return [[[self alloc] initWithDictionary:newDict] autorelease];
}

+ (id)commandWithFile:(NSString *)path {
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
	return [self commandWithDictionary:[dict objectForKey:@"command"]];
}

- (void)writeToFile:(NSString *)path {
    NSDictionary *dict = [NSDictionary dictionaryWithObject:[self dictionaryRepresentation]
                                                     forKey:@"command"];
    
	[dict writeToFile:path atomically:NO];
}

- (void)setDObject:(id)dObject {
	if (dObject) [oDict setObject:dObject forKey:@"directObject"];
	if ([dObject identifier]) [oDict setObject:[dObject identifier] forKey:@"directID"];
}

- (id)initWithDictionary:(NSDictionary *)newDict {
    if ((self = [self init])) {
        [oDict addEntriesFromDictionary:newDict];
    }
    return self;
}

- (void)dealloc {
    [oDict release];
    oDict = nil;
    [super dealloc];
}

- (NSComparisonResult)compare:(id)compareObject {
    return [[self description] compare:[compareObject description]];
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *sDict = [[oDict mutableCopy] autorelease];
    QSObject *dObject = [oDict objectForKey:@"directObject"];
    QSObject *iObject = [oDict objectForKey:@"indirectObject"];
	if (dObject && ![oDict objectForKey:@"directArchive"])
        [sDict setObject:[dObject dictionaryRepresentation] forKey:@"directArchive"];
	if (iObject && ![oDict objectForKey:@"indirectArchive"])
        [sDict setObject:[iObject dictionaryRepresentation] forKey:@"indirectArchive"];
    [sDict removeObjectsForKeys:[NSArray arrayWithObjects:@"directObject", @"indirectObject", @"actionObject", nil]];
    return sDict;
}

- (QSObject *)executeIgnoringModifiers {
	[QSAction setModifiersAreIgnored:YES];
	QSObject *result = [self execute];
	[QSAction setModifiersAreIgnored:NO];
	return result;
}

- (QSObject *)execute {
	QSAction *aObject = [self aObject];
    QSObject *dObject = [self dObject];
    QSObject *iObject = [self iObject];
    
	if (VERBOSE) QSLog(@"Execute Command: %@",[self description]);
    int argumentCount = [aObject argumentCount];
	if (argumentCount < 2) {
		return [aObject performOnDirectObject:dObject indirectObject:iObject];
	} else if (argumentCount == 2) {
		if ([iObject objectForType:QSTextProxyType]) {
			[[[NSApp delegate] interfaceController] executePartialCommand:[NSArray arrayWithObjects:dObject, aObject, iObject, nil]];
		} else if (iObject) {
			return [aObject performOnDirectObject:dObject indirectObject:iObject];
		} else {
			if (!iObject) {
				NSString *selectClass = [[NSUserDefaults standardUserDefaults] stringForKey:@"QSUnidentifiedObjectSelector"];
				id handler = [QSReg getClassInstance:selectClass];
				QSLog(@"handler %@ %@", selectClass, handler);
				if (handler && [handler respondsToSelector:@selector(completeAndExecuteCommand:)]) {
					[handler completeAndExecuteCommand:self];
					return nil;
				}
			}
            
			[[[NSApp delegate] interfaceController] executePartialCommand:[NSArray arrayWithObjects:dObject, aObject, iObject, nil]];
		}
	}
	return nil;
}

- (void)executeFromMenu:(id)sender {	
	//QSLog(@"sender %@", NSStringFromClass([sender class]));	
	QSObject *object = [self execute];
	if (object) {
		[[[NSApp delegate] interfaceController] selectObject:object];
		[[[NSApp delegate] interfaceController] actionActivate:nil];		
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
    id copy = [[QSCommand alloc] initWithDictionary:[[oDict mutableCopy] autorelease]];
    return copy;
}

- (NSArray *)validIndirects {
    NSArray *indirects = [[[self aObject] provider] validIndirectObjectsForAction:[[self aObject]identifier] directObject:[self dObject]];
    if ([indirects count] > 1 && [[indirects objectAtIndex:1] isKindOfClass:[NSArray class]]) {
           indirects = [indirects objectAtIndex:1];
    }
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
            if ([indirect isKindOfClass:[NSNull class]])
                continue;
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
    QSAction *aObject = [oDict objectForKey:@"actionObject"];
	if (!aObject)
        aObject = [QSExec actionForIdentifier:[oDict objectForKey:@"actionID"]];
	return aObject;  
}

- (QSObject *)dObject {
	QSObject *dObject = [oDict objectForKey:@"directObject"];
	if (!dObject)
        dObject = [QSObject objectWithIdentifier:[oDict objectForKey:@"directID"]];
	if (!dObject){
		dObject = [QSObject objectWithDictionary:[oDict objectForKey:@"directArchive"]];
		if (dObject)
            [oDict setObject:dObject forKey:@"directObject"];
	}
	if (!dObject) {
		id resource = [oDict objectForKey:@"directResource"];
		dObject = [QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:resource]];
		if (dObject)
            [oDict setObject:dObject forKey:@"directObject"];
        //QSLog(@"rez %@ %@", resource, [QSRez pathWithLocatorInformation:resource]);
	}
	
	return dObject;
}

- (QSObject *)iObject {
	QSObject *iObject = [oDict objectForKey:@"indirectObject"];
	if (!iObject)
        iObject = [QSObject objectWithIdentifier:[oDict objectForKey:@"indirectID"]];
	if (!iObject) {
		iObject = [QSObject objectWithDictionary:[oDict objectForKey:@"indirectArchive"]];
		if (iObject)
            [oDict setObject:iObject forKey:@"indirectObject"];
	}
	if (!iObject) {
		id resource = [oDict objectForKey:@"indirectResource"];
		iObject = [QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:resource]];
		if (iObject)
            [oDict setObject:iObject forKey:@"indirectObject"];
	}
	return iObject;
}

- (NSString *)description {
	if (![self aObject])
        return [NSString stringWithFormat:@"[Action Missing: %@]", [oDict objectForKey:@"actionID"]];
    
    NSString *format = [[self aObject] commandFormat];
    
    return [NSString stringWithFormat:format, [[self dObject] displayName], [self iObject] ? [[self iObject] displayName] : @"<?>"];
}

- (NSImage *)icon {
	QSObject *direct = [self dObject];
	[direct loadIcon];
	return [direct icon];
}	

- (NSString *)text { return [self name]; }
- (NSImage *)image { return [self icon]; }

@end
