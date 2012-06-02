#import "QSAlertManager.h"

@implementation QSAlertManager
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)theReturnCode contextInfo:(void *)contextInfo {
	returnCode = theReturnCode;
	[NSApp stopModal];
}
- (NSInteger) returnCode { return returnCode; }
@end

NSInteger QSRunSheet(id panel, NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
	QSAlertManager *obj = [[QSAlertManager alloc] init];
	[NSApp beginSheet:panel modalForWindow:attachToWin modalDelegate:obj didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[NSApp runModalForWindow:panel];
	[NSApp endSheet:panel];
	[panel orderOut:nil];
	NSReleaseAlertPanel(panel);
	NSInteger result = [obj returnCode];
	[obj release];
	return result;
}

NSLock *onlyOneAlertSheetAtATimeLock = nil;

NSInteger QSRunAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
	if (onlyOneAlertSheetAtATimeLock == nil)
		onlyOneAlertSheetAtATimeLock = [[NSLock alloc] init];
	[onlyOneAlertSheetAtATimeLock lock];

	NSInteger returnVal = -1;
	if (attachToWin == nil)
		returnVal = NSRunAlertPanel(title, msg, defaultButton, alternateButton, otherButton);
	else {
		returnVal = QSRunSheet(NSGetAlertPanel(title, msg, defaultButton, alternateButton, otherButton), attachToWin, title, msg, defaultButton, alternateButton, otherButton);
	}

	[onlyOneAlertSheetAtATimeLock unlock];
	return returnVal;
}

NSInteger QSRunInformationalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
	if (onlyOneAlertSheetAtATimeLock == nil)
		onlyOneAlertSheetAtATimeLock = [[NSLock alloc] init];
	[onlyOneAlertSheetAtATimeLock lock];

	NSInteger returnVal = -1;
	if (attachToWin == nil)
		returnVal = NSRunInformationalAlertPanel(title, msg, defaultButton, alternateButton, otherButton);
	else
		returnVal = QSRunSheet(NSGetInformationalAlertPanel(title, msg, defaultButton, alternateButton, otherButton), attachToWin, title, msg, defaultButton, alternateButton, otherButton);

	[onlyOneAlertSheetAtATimeLock unlock];
	return returnVal;
}

NSInteger QSRunCriticalAlertSheet(NSWindow *attachToWin, NSString *title, NSString *msg, NSString *defaultButton, NSString *alternateButton, NSString *otherButton) {
	if (onlyOneAlertSheetAtATimeLock == nil)
		onlyOneAlertSheetAtATimeLock = [[NSLock alloc] init];
	[onlyOneAlertSheetAtATimeLock lock];
	NSInteger returnVal = -1;
	if (attachToWin == nil)
		returnVal = NSRunCriticalAlertPanel(title, msg, defaultButton, alternateButton, otherButton);
	else
		returnVal = QSRunSheet(NSGetCriticalAlertPanel(title, msg, defaultButton, alternateButton, otherButton), attachToWin, title, msg, defaultButton, alternateButton, otherButton);

	[onlyOneAlertSheetAtATimeLock unlock];
	return returnVal;
}
