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

@synthesize currentLargeTypeWindow;

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
	[self typeString:[dObject objectForType:QSTextType]];
	return nil;
}

- (void)typeString:(NSString *)string {
    UniChar buffer;
    CGEventRef keyEvent = CGEventCreateKeyboardEvent(NULL, 0, true);
    CFRelease(keyEvent);
    for (NSUInteger i = 0; i < [string length]; i++) {
        buffer = [string characterAtIndex:i];
        keyEvent = CGEventCreateKeyboardEvent(NULL, 1, true);
        CGEventKeyboardSetUnicodeString(keyEvent, 1, &buffer);
        CGEventPost(kCGHIDEventTap, keyEvent);
        CFRelease(keyEvent);
    }
}

@end
