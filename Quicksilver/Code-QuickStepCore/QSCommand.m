

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
@interface QSObject (QSCommandCompletionProtocol)
- (void) completeAndExecuteCommand:(QSCommand *)command;
@end
@implementation QSCommandObjectHandler



- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject{
	if ([action isEqualToString:@"QSCommandSaveAction"]){
		return nil;
	}else{
		QSObject *textObject=[QSObject textProxyObjectWithDefaultValue:@""];
		return [NSArray arrayWithObject:textObject]; //[QSLibarrayForType:NSFilenamesPboardType];
	}
}

- (QSObject *)executeCommand:(QSObject *)dObject{
	QSCommand *command=[dObject objectForType:QSCommandType];
	NSLog(@"command %@",command);
	return [command execute];
}

NSTimeInterval QSTimeIntervalForString(NSString *intervalString){
	NSScanner *scanner=[NSScanner scannerWithString:intervalString];
	
	float h=0.0f;
	float m=0.0f;
	float s=0.0f;
	float f;
	NSString *string;
	while (![scanner isAtEnd]){
		[scanner scanFloat:&f];
		if (![scanner scanUpToCharactersFromSet:[NSCharacterSet decimalDigitCharacterSet] intoString:&string])
			string=nil;
		
		if (![string length] || [string isEqualToString:@":"]){
			if (m!=0.0f){
				if (h!=0.0f){
					s+=f;
				}else{
					h=m ;
					m=f;
				}
			}else{
				m=f;
			}
			
		}else if ([string hasPrefix:@"h"]){
			h+=f;
		}else if ([string hasPrefix:@"m"]){
			m+=f;
		}else if ([string hasPrefix:@"s"]){
			s+=f;
			
			
			//	NSLog(@"string %@",string);
		}
	}
	//NSLog(@"%f %f %f",h,m,s);
	return h*60*60+m*60+s;
}

- (QSObject *)saveCommand:(QSObject *)dObject toPath:(QSObject *)iObject{
	QSCommand *command=[dObject objectForType:QSCommandType];
	
	NSString *destination=[iObject singleFilePath];
	
	destination=[destination stringByAppendingPathComponent:[dObject name]];
	
	BOOL asDroplet=[[[command dObject] identifier]isEqualToString:@"QSDropletItemProxy"];
	
	NSLog(@"droplet %d",asDroplet);
	destination=[destination stringByAppendingPathExtension:asDroplet?@"app":@"qscommand"];
	destination=[destination firstUnusedFilePath];
	
	if (asDroplet){
		NSString *dropletTemplate=[[NSBundle mainBundle]pathForResource:@"QSDroplet" ofType:@"app"];
		NSFileManager *fm=[NSFileManager defaultManager];
		[fm copyPath:dropletTemplate toPath:destination handler:nil];
		
		NSString *commandFile=[destination stringByAppendingPathComponent:@"Contents/Command.qscommand"];
		[command writeToFile:commandFile];
		
		
		//		[[NSWorkspace sharedWorkspace]setIcon:[[command aObject]icon]
		//									  forFile:destination
		//									  options:NSExcludeQuickDrawElementsIconCreationOption];
	}else{
		[command writeToFile:destination];
		[[command dObject]loadIcon];
		NSImage *image=[[command dObject]icon];
		[image setFlipped:NO];
		[image setSize:QSSize128];
		[[NSWorkspace sharedWorkspace]setIcon:image
									  forFile:destination
									  options:NSExcludeQuickDrawElementsIconCreationOption];
	}	
	return [QSObject fileObjectWithPath:destination];
	
}



- (QSObject *) addTrigger:(QSObject *)dObject{
	QSCommand *command=[dObject objectForType:QSCommandType];
	
	NSMutableDictionary *info=[NSMutableDictionary dictionaryWithCapacity:5];
	[info setObject:@"QSHotKeyTrigger" forKey:@"type"];
	[info setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];
	
	if (command){
		[info setObject:command forKey:@"command"];
	}
	[info setObject:[NSString uniqueString] forKey:kItemID];
	
	
	QSTrigger *trigger=[QSTrigger triggerWithInfo:info];
	[trigger initializeTrigger];
	[[QSTriggerCenter sharedInstance]addTrigger:trigger];
	[[NSClassFromString(@"QSPreferencesController") sharedInstance]showPaneWithIdentifier:@"QSTriggersPrefPane"];
	[[NSClassFromString(@"QSTriggersPrefPane") sharedInstance]showTrigger:trigger];
	return nil;
}

- (QSObject *)executeCommand:(QSObject *)dObject afterDelay:(QSObject *)iObject{
	//NSLog(@"delay");
	QSCommand *command=[dObject objectForType:QSCommandType];
	
	NSString *string=[iObject stringValue];
	float delay=QSTimeIntervalForString(string);
	//NSLog(@"delay %@ %@ %f",command,string,delay);
	NSTimer *timer=[[NSTimer alloc]initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:delay] interval:0 target:self selector:@selector(runCommand:)
										   userInfo:command repeats:NO];
	//[timer autorelease];
	[[NSRunLoop currentRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
	
	
	return nil;//[command execute];
}

- (QSObject *)executeCommand:(QSObject *)dObject atTime:(QSObject *)iObject{
	QSCommand *command=[dObject objectForType:QSCommandType];
	NSString *string=[iObject stringValue];
	
	
	//	NSDateFormatter *dateFormat = [[[NSDateFormatter alloc]initWithDateFormat:@"%X" allowNaturalLanguage:YES]autorelease];
	NSDate *date=[NSDate dateWithNaturalLanguageString:string];
	if (date){
		if (VERBOSE)	NSLog(@"at > %@ %@ %@",command,string,date);
		
	}else{
		//	NSLog(@"at %@ %@ baddate!",command,string,nil);
		NSBeep();
		return nil;
	}
	
	NSTimer *timer=[[NSTimer alloc]initWithFireDate:date interval:0 target:self selector:@selector(runCommand:)
										   userInfo:command repeats:NO];
	//[timer autorelease];
	[[NSRunLoop currentRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
	
	return nil;
}

- (void)runCommand:(NSTimer *)timer{
	QSCommand *command=[timer userInfo];
	[command execute];
	[timer release];
}

- (void)setQuickIconForObject:(QSObject *)object{
    [object setIcon:[NSImage imageNamed:@"defaultAction"]];
}

- (BOOL)loadIconForObject:(QSObject *)object{
	QSCommand *command=(QSCommand *)[object objectForType:@"qs.command"];
	QSAction *action=(QSAction *)[command dObject];
	[action loadIcon];
	[object setIcon:[action icon]];
	return YES;
}	

- (NSString *)detailsOfObject:(id <QSObject>)object{
	return nil;	
}

// CommandsAsActionsHandling
- (QSObject *) performAction:(QSAction *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	NSDictionary *dict=[action objectForType:QSActionType];
	QSCommand *command=[QSCommand commandWithInfo:[dict objectForKey:@"command"]];
	[command execute];
	return nil;
}
@end


@implementation QSCommand

- (QSObject *)objectValue{
	QSObject *commandObject=[QSObject objectWithName:[self description]];
	[commandObject setObject:self forType:QSCommandType];
	[commandObject setPrimaryType:QSCommandType];
	return commandObject;
}
- (NSArray *)types{return [NSArray arrayWithObject:QSCommandType];}


-(id)init{
    if (self=[super init]){
        oDict=[[NSMutableDictionary alloc]initWithCapacity:2]; 
    }
    return self;
}
+(id)commandWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject{
    if (dObject && aObject)
        return [[[self alloc]initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject]autorelease];  
    return nil;
}
-(id)initWithDirectObject:(QSBasicObject *)dObject actionObject:(QSBasicObject *)aObject indirectObject:(QSBasicObject *)iObject{
    if (self=[self init]){
        if (dObject)[oDict setObject:dObject forKey:@"directObject"];
        if (aObject)[oDict setObject:aObject  forKey:@"actionObject"];
        if (iObject)[oDict setObject:iObject forKey:@"indirectObject"];
        if ([dObject identifier])[oDict setObject:[dObject identifier] forKey:@"directID"];
        if ([aObject identifier])[oDict setObject:[aObject identifier] forKey:@"actionID"];
        if ([iObject identifier])[oDict setObject:[iObject identifier] forKey:@"indirectID"];
    }
    return self;
}

+ (QSCommand *)commandWithInfo:(id)command{
	if ([command isKindOfClass:[NSDictionary class]]){
		command=[QSCommand commandWithDictionary:command];
	}else if([command isKindOfClass:[NSString class]]){
		NSDictionary *commandInfo=[QSReg valueForKey:command inTable:@"QSCommands"];
		command=[QSCommand commandWithDictionary:[commandInfo objectForKey:@"command"]];
	}
	return command;
}
+(id)commandWithDictionary:(NSDictionary *)newDict{
	return [[(QSCommand *)[self alloc]initWithDictionary:newDict]autorelease];
}

+(id)commandWithFile:(NSString *)path{
	NSDictionary *dict=[NSDictionary dictionaryWithContentsOfFile:path];
	return [self commandWithDictionary:[dict objectForKey:@"command"]];
}
- (void)writeToFile:(NSString *)path{
	[[NSDictionary dictionaryWithObject:[self dictionaryRepresentation] forKey:@"command"]
		writeToFile:path atomically:NO];
}
- (void)setDObject:(id)dObject{
	if (dObject)[oDict setObject:dObject forKey:@"directObject"];
	if ([dObject identifier])[oDict setObject:[dObject identifier] forKey:@"directID"];
}
-(id)initWithDictionary:(NSDictionary *)newDict{
    if (self=[self init]){
        [oDict addEntriesFromDictionary:newDict];
    }
    return self;
}
- (void)dealloc{
    [oDict release];
    oDict=nil;
    [super dealloc];
}
- (NSComparisonResult)compare:(id)compareObject{
    return [[self description] compare:[compareObject description]];
}
- (NSDictionary *)dictionaryRepresentation{
    NSMutableDictionary *sDict=[[oDict mutableCopy]autorelease];
    QSObject *dObject=[oDict objectForKey:@"directObject"];
    QSObject *iObject=[oDict objectForKey:@"indirectObject"];
	if (dObject && ![oDict objectForKey:@"directArchive"]) [sDict setObject:[dObject archiveDictionary] forKey:@"directArchive"];
	if (iObject &&  ![oDict objectForKey:@"indirectArchive"]) [sDict setObject:[iObject archiveDictionary] forKey:@"indirectArchive"];
    [sDict removeObjectsForKeys:[NSArray arrayWithObjects:@"directObject",@"indirectObject",@"actionObject",nil]];
    return sDict;
}


- (QSObject *)executeIgnoringModifiers{
	[QSAction setModifiersAreIgnored:YES];
	QSObject *result=[self execute];
	[QSAction setModifiersAreIgnored:NO];
	return result;
}

- (QSObject *)execute{

	QSAction *aObject=[self aObject];
    QSObject *dObject=[self dObject];
    QSObject *iObject=[self iObject];
    
	if (VERBOSE) NSLog(@"Execute Command: %@",[self description]);
    int argumentCount=[(QSAction *)aObject argumentCount];
	if (argumentCount<2){
		return [aObject performOnDirectObject:dObject indirectObject:iObject];
	}else if (argumentCount==2){
		if ([iObject objectForType:QSTextProxyType]){
			[[(QSController *)[NSApp delegate]interfaceController]executePartialCommand:[NSArray arrayWithObjects:dObject,aObject,iObject,nil]];
		}else if (iObject){
			return [aObject performOnDirectObject:dObject indirectObject:iObject];
		}else{
			if (!iObject){
				NSString *selectClass=[[NSUserDefaults standardUserDefaults]stringForKey:@"QSUnidentifiedObjectSelector"];
				id handler=[QSReg getClassInstance:selectClass];
				NSLog(@"handler %@ %@",selectClass, handler);
				if (handler && [handler respondsToSelector:@selector(completeAndExecuteCommand:)]){
					[handler completeAndExecuteCommand:self];
					return nil;
				}
			}
			[[(QSController *)[NSApp delegate]interfaceController]executePartialCommand:[NSArray arrayWithObjects:dObject,aObject,iObject,nil]];
		}
		return nil;
	}
	return nil;
//		NS_DURING
//	NS_HANDLER
//		;
//	NS_ENDHANDLER
}
- (void)executeFromMenu:(id)sender{	
	//NSLog(@"sender %@",NSStringFromClass([sender class]));	
	QSObject *object=[self execute];
	if (object){
		[[(QSController *)[NSApp delegate]interfaceController]selectObject:object];
		[[(QSController *)[NSApp delegate]interfaceController]actionActivate:nil];		
	}	
}

- (void)executeFromMenuWithIndirect:(id)sender{
	QSObject *object=[sender representedObject];
	[oDict setObject:object forKey:@"indirectObject"];
	[self executeFromMenu:sender];
}
- (void)executeWithIndirect:(id)iObject{
	QSObject *object=(QSObject *)[iObject resolvedObject];
	[oDict setObject:object forKey:@"indirectObject"];
	[self executeFromMenu:nil];
}
- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[QSCommand alloc]initWithDictionary:[[oDict mutableCopy]autorelease]];
    return copy;
}
- (NSArray *)validIndirects{
	   NSArray *indirects=[[[self aObject] provider]validIndirectObjectsForAction:[[self aObject]identifier] directObject:[self dObject]];
	   if ([indirects count]>1 && [[indirects objectAtIndex:1]isKindOfClass:[NSArray class]])indirects=[indirects objectAtIndex:1];
	   if ([indirects count]==1 && [[indirects objectAtIndex:0]containsType:QSTextProxyType]){
		   indirects=nil;
	   }
	   return indirects;  
}
- (void)menuNeedsUpdate:(NSMenu *)menu{
	
	//	NSLog(@"command %@",self);
	
	   NSArray *indirects=[self validIndirects];	   
	   NSMenuItem *item;
	   if ([indirects count]){
		   int i;			   
		   for (i=0;i<[indirects count] && i<10;i++){
			   QSBasicObject *indirect=[indirects objectAtIndex:i];
			   if ([indirect isKindOfClass:[NSNull class]])continue;
			   item=[indirect menuItem];
			   [menu addItem:item];
			   [item setAction:@selector(executeFromMenuWithIndirect:)];
			   [item setTarget:self];
			   [item setRepresentedObject:indirect];
		   }	
	   }else{
		   item=[menu addItemWithTitle:@"Choose..." action:@selector(executeFromMenu:) keyEquivalent:@""];
		   
		   [item setImage:[[NSImage imageNamed:@"Quicksilver"]duplicateOfSize:QSSize16]];
		   [[item image]setFlipped:NO];
		   [item setTarget:self];		   
	   }
	   [menu setDelegate:nil];
}

- (QSAction *)aObject{
    QSAction *aObject=[oDict objectForKey:@"actionObject"];
	if (!aObject) aObject=[QSExec actionForIdentifier:[oDict objectForKey:@"actionID"]];
	return aObject;  
}
- (QSObject *)dObject{
	QSObject *dObject=[oDict objectForKey:@"directObject"];
	if (!dObject) dObject=[QSObject objectWithIdentifier:[oDict objectForKey:@"directID"]];
	if (!dObject){
		dObject=[QSObject objectWithDictionary:[oDict objectForKey:@"directArchive"]];
		if (dObject)[oDict setObject:dObject forKey:@"directObject"];
	}
	if (!dObject){
		id resource=[oDict objectForKey:@"directResource"];
		dObject=[QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:resource]];
		if (dObject)[oDict setObject:dObject forKey:@"directObject"];
		//		NSLog(@"rez %@ %@",resource,[QSRez pathWithLocatorInformation:resource]);
	}
	
	return dObject;
}
- (QSObject *)iObject{
	QSObject *iObject=[oDict objectForKey:@"indirectObject"];
	if (!iObject) iObject=[QSObject objectWithIdentifier:[oDict objectForKey:@"indirectID"]];
	if (!iObject){
		iObject=[QSObject objectWithDictionary:[oDict objectForKey:@"indirectArchive"]];
		if (iObject)[oDict setObject:iObject forKey:@"indirectObject"];
	}
	if (!iObject){
		id resource=[oDict objectForKey:@"indirectResource"];
		iObject=[QSObject fileObjectWithPath:[QSRez pathWithLocatorInformation:resource]];
		if (iObject)[oDict setObject:iObject forKey:@"indirectObject"];
	}
	return iObject;
}



- (NSString *)description{
	if (![self aObject]) return [NSString stringWithFormat:@"[Action Missing: %@]",[oDict objectForKey:@"actionID"]];
    return [[self aObject] commandDescriptionWithDirectObject:[self dObject] indirectObject:[self iObject]];
}

- (NSImage *)icon{
	QSObject *direct=[self dObject];
	[direct loadIcon];
	return [direct icon];
}	

- (NSString *)text{return [self description];}
- (NSImage *)image{return [self icon];}


@end
