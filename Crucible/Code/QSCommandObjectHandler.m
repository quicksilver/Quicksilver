/*
 Copyright 2007 Blacktree, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "QSCommandObjectHandler.h"

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
			//QSLog(@"string %@",string);
		}
	}
	//QSLog(@"%f %f %f",h,m,s);
	return h * 60 * 60 + m * 60 + s;
}

@implementation QSCommandObjectHandler
- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	if ([action isEqualToString:@"QSCommandSaveAction"]) {
		return nil;
	} 
    QSObject *textObject = [QSObject textProxyObjectWithDefaultValue:@""];
    return [NSArray arrayWithObject:textObject];
}

- (QSObject *)executeCommand:(QSObject *)dObject {
	QSCommand *command = [dObject objectForType:QSCommandType];
	QSLog(@"command %@", command);
	return [command execute];
}

- (QSObject *)saveCommand:(QSObject *)dObject toPath:(QSObject *)iObject {
	QSCommand *command = [dObject objectForType:QSCommandType];
	
	NSString *destination = [iObject singleFilePath];
	
	destination = [destination stringByAppendingPathComponent:[dObject name]];
	
	BOOL asDroplet = [[[command dObject] identifier] isEqualToString:@"QSDropletItemProxy"];
	
	QSLog(@"droplet %d", asDroplet);
	destination = [destination stringByAppendingPathExtension:(asDroplet ? @"app" : @"qscommand")];
	destination = [destination firstUnusedFilePath];
	
	if (asDroplet) {
		NSString *dropletTemplate = [[NSBundle mainBundle] pathForResource:@"QSDroplet" ofType:@"app"];
		NSFileManager *fm = [NSFileManager defaultManager];
		[fm copyPath:dropletTemplate toPath:destination handler:nil];
		
		NSString *commandFile = [destination stringByAppendingPathComponent:@"Contents/Command.qscommand"];
		[command writeToFile:commandFile];
		
		//[[NSWorkspace sharedWorkspace] setIcon:[[command aObject] icon]
		//                               forFile:destination
		//                               options:NSExcludeQuickDrawElementsIconCreationOption];
	} else {
		[command writeToFile:destination];
		[[command dObject] loadIcon];
		NSImage *image = [[command dObject] icon];
		[image setFlipped:NO];
		[image setSize:QSSize128];
		[[NSWorkspace sharedWorkspace] setIcon:image
									   forFile:destination
									   options:NSExcludeQuickDrawElementsIconCreationOption];
	}
    
	return [QSObject fileObjectWithPath:destination];
}



- (QSObject *)addTrigger:(QSObject *)dObject {
	QSLogError(@"Not currently implemented");
	//FIXME
    //	QSCommand *command=[dObject objectForType:QSCommandType];
    //	
    //	NSMutableDictionary *info=[NSMutableDictionary dictionaryWithCapacity:5];
    //	[info setObject:@"QSHotKeyTrigger" forKey:@"type"];
    //	[info setObject:[NSNumber numberWithBool:YES] forKey:kItemEnabled];
    //	
    //	if (command){
    //		[info setObject:command forKey:@"command"];
    //	}
    //	[info setObject:[NSString uniqueString] forKey:kItemID];
    //	
    //	
    //	QSTrigger *trigger=[QSTrigger triggerWithInfo:info];
    //	[trigger initializeTrigger];
    //	[[QSTriggerCenter sharedInstance]addTrigger:trigger];
    //	[[NSClassFromString(@"QSPreferencesController") sharedInstance]showPaneWithIdentifier:@"QSTriggersPrefPane"];
    //	[[NSClassFromString(@"QSTriggersPrefPane") sharedInstance]showTrigger:trigger];
	return nil;
}

- (QSObject *)executeCommand:(QSObject *)dObject afterDelay:(QSObject *)iObject {
	//QSLog(@"delay");
	QSCommand *command = [dObject objectForType:QSCommandType];
	
	NSString *string = [iObject stringValue];
	float delay = QSTimeIntervalForString(string);
	//QSLog(@"delay %@ %@ %f",command,string,delay);
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:delay]
                                              interval:0
                                                target:self
                                              selector:@selector(runCommand:)
                                              userInfo:command
                                               repeats:NO];
	//[timer autorelease];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    
	// tiennou: Return the timer ?
	return nil;//[command execute];
}

- (QSObject *)executeCommand:(QSObject *)dObject atTime:(QSObject *)iObject {
	QSCommand *command = [dObject objectForType:QSCommandType];
	NSString *string = [iObject stringValue];
	
	//NSDateFormatter *dateFormat = [[[NSDateFormatter alloc] initWithDateFormat:@"%X" allowNaturalLanguage:YES] autorelease];
	NSDate *date = [NSDate dateWithNaturalLanguageString:string];
	if (date) {
		if (VERBOSE) QSLog(@"at > %@ %@ %@",command,string,date);
		
	} else {
		//QSLog(@"at %@ %@ baddate!", command, string, nil);
		NSBeep();
		return nil;
	}
	
	NSTimer *timer = [[NSTimer alloc] initWithFireDate:date
                                              interval:0
                                                target:self
                                              selector:@selector(runCommand:)
                                              userInfo:command
                                               repeats:NO];
	//[timer autorelease];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	
	return nil;
}

- (void)runCommand:(NSTimer *)timer {
	QSCommand *command = [timer userInfo];
	[command execute];
	[timer release];
}

- (void)setQuickIconForObject:(QSObject *)object {
    [object setIcon:[NSImage imageNamed:@"defaultAction"]];
}

- (BOOL)loadIconForObject:(QSObject *)object {
	QSCommand *command = (QSCommand *)[object objectForType:QSCommandType];
	QSAction *action = (QSAction *)[command dObject];
	[action loadIcon];
	[object setIcon:[action icon]];
	return YES;
}	

- (NSString *)detailsOfObject:(id <QSObject>)object {
	return nil;	
}

// CommandsAsActionsHandling
- (QSObject *)performAction:(QSAction *)action directObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {
	NSDictionary *dict = [action objectForType:QSActionType];
	QSCommand *command = [QSCommand commandWithInfo:[dict objectForKey:@"command"]];
	[command execute];
	return nil;
}
@end