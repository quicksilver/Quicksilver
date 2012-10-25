#import "QSTextSource.h"
#import "QSTypes.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"
#import "QSObject_PropertyList.h"

#import "NSUserDefaults_BLTRExtensions.h"
#import "QSLargeTypeDisplay.h"
#import "QSFoundation.h"

#import "QSTextProxy.h"

#import "QSObject_PropertyList.h"
#define textTypes [NSArray arrayWithObjects:@"'TEXT'", @"txt", @"html", @"htm", nil]

#define kQSTextTypeAction @"QSTextTypeAction"

#define kQSTextDiffAction @"QSTextDiffAction"
#define kQSLargeTypeAction @"QSLargeTypeAction"

@implementation QSTextActions

- (QSObject *)showLargeType:(QSObject *)dObject {
    NSString *display = nil;
    if ([dObject singleFilePath]) {
        NSError *err = nil;
        display = [[[NSString alloc] initWithContentsOfFile:[dObject singleFilePath] usedEncoding:nil error:&err] autorelease];
        if (err) {
            NSLog(@"Error: %@",[err description]);
        }
    } else {
        display = [dObject stringValue];
    }
	QSShowLargeType(display);
	return nil;
}

- (QSObject *)showDialog:(QSObject *)dObject {
	[NSApp activateIgnoringOtherApps:YES];
	NSRunInformationalAlertPanel(@"Quicksilver", [dObject stringValue] , @"OK", nil, nil);
	return nil;
}

- (QSObject *)speakText:(QSObject *)dObject {
	NSString *string = [dObject stringValue];
	string = [string stringByReplacing:@"\"" with:@"\\\""];
	string = [NSString stringWithFormat:@"say \"%@\"", string];
	[[[[NSAppleScript alloc] initWithSource:string] autorelease] executeAndReturnError:nil];
	return nil;
}

- (QSObject *)typeObject:(QSObject *)dObject {
	// NSLog( AsciiToKeyCode(&ttable, "m") {
	// short AsciiToKeyCode(Ascii2KeyCodeTable *ttable, short asciiCode) {
	[self typeString2:[dObject objectForType:QSTextType]];
	return nil;
}

- (void)typeString:(NSString *)string {
    NSUInteger length = [string length];
    UniChar s[length];
    [string getCharacters:s range:NSMakeRange(0, length)];
	CGEventRef keyEvent = CGEventCreateKeyboardEvent(NULL, 0, true);
    CGEventKeyboardSetUnicodeString(keyEvent, (UniCharCount)length, s);
    CGEventPost(kCGSessionEventTap, keyEvent);
	CFRelease(keyEvent);
}

- (void)typeString2:(NSString *)string {
	string = [string stringByReplacing:@"\n" with:@"\r"];
	NSAppleScript *sysEventsScript = [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"System Events" ofType:@"scpt"]] error:nil];
	NSDictionary *errorDict = nil;
	[sysEventsScript executeSubroutine:@"type_text" arguments:string error:&errorDict];
	if (errorDict) NSLog(@"Execute Error: %@", errorDict);
    [sysEventsScript release];
}
@end
