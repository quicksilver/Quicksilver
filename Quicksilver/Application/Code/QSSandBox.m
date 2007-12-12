/*
 *  QSSandBox.c
 *  Quicksilver
 *
 *  Created by Alcor on 7/10/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#import <Carbon/Carbon.h>

#import "QSTooltip.h"
#import "QSUpdateController.h"

#import "QSSimpleWebWindowController.h"

#import "QSSandBox.h"

void listEncodings() {
	//  int i = 0;
    const CFStringEncoding *encodings;
    encodings = CFStringGetListOfAvailableEncodings();
	for (int i = 0; encodings[i] != kCFStringEncodingInvalidId; i++) {
		NSString *encodingName = (NSString *)CFStringGetNameOfEncoding(encodings[i]);
		
		if (i && encodings[i] -encodings[i-1] >16) QSLog(@"-");
		QSLog(@"Enc: %x %@", encodings[i] , encodingName);
    }
}

NSString *QSGetPrimaryMACAddress();
UInt64 QSGetPrimaryMACAddressInt();


void QSSandBoxMain() {
	//	int i;
//	for(i = 0; i<10; i++) {
//	QSTask *task = [QSTask taskWithIdentifier:[NSString stringWithFormat:@"testid %d", i]];
//		
//		[task setName:[NSString stringWithFormat:@"Name %d", i]];
//		
//		[task startTask:nil];
//		[task setProgress:(float) i/10];
//		[task setStatus:@"Status"];
//		[task performSelector:@selector(stopTask:)
//				   withObject:nil
//				   afterDelay:i+10];
//	}
//	float size = 512;
//	CGRect windowFrame = CGRectMake(512-size/2, 384-size/2, size, size);
//	QSCIEffectOverlay *overlay = [[QSCIEffectOverlay alloc] initWithRect:windowFrame];
//	[overlay setFilter:@"CIHoleDistortion"];
//    
//    NSString *inputPoint0 = [NSString stringWithFormat: @"[%d %d] ",  
//        (int) CGRectGetMidX(windowFrame),  
//        (int) CGRectGetMidY(windowFrame)];
//    NSNumber *inputCornerRadius = [NSNumber numberWithFloat: size/2];
//    
//    NSDictionary *filterValues = [NSDictionary dictionaryWithObjectsAndKeys: 
//        inputPoint0, @"inputCenter",  
//        inputCornerRadius, @"inputRadius",  
//        nil, nil];
//	
//	[overlay setFilterValues:filterValues];
//	float f;
//	for(f = 0; f<1; f += 0.04)
//	 {
//		usleep(100000);
//		
//		filterValues = [NSDictionary dictionaryWithObjectsAndKeys: 
//			[NSNumber numberWithFloat: -f] , @"inputScale",  
//			nil, nil];
//		
//		filterValues = [NSDictionary dictionaryWithObjectsAndKeys: 
//			[NSNumber numberWithFloat: f*size/4] , @"inputRadius",  
//			nil, nil];
//		
//		[overlay setFilterValues:filterValues];
//		
//	} 	
//	[overlay release];
	//inputScale
//	NSString *uniqueID = [NSString stringWithFormat:@"%@/%@", QSGetPrimaryMACAddress(), NSUserName()];
//QSGetPrimaryMACAddressInt()
///	QSLog(@"%@ %qu", uniqueID, QSGetPrimaryMACAddressInt() );
//	//id monitor = [[QSFileSystemMonitor alloc] init];
//	id parser = [QSReg getClassInstance:@"QSDirectoryParser"];
//	
//	QSLog(@"X scanning with %@", parser);
//	
//	usleep(5);
//	//for(int i = 0; i<5; i++) {
//		QSLog(@"start scanning with %@", parser);
//		for(int i = 0; i<1000000; i++) {
//			
//			NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//			NSArray *objects = [parser objectsFromPath:@"/Volumes/Lore/" depth:-1 types:[NSArray arrayWithObject:@"com.apple.xcode.project"]];
//			QSLog(@"done %d items", [objects count]); //, [objects count]);
//				
//			[pool release];
//		}
//		//	[pool release];
//			usleep(5);
//	
//	
//		while (1) {
//		usleep(5);
//	}
	
	//NSString *string = @" >> \rnick jitkoff\rkathy ho\r >> \rbilly moron\rjo shmo\r >> \rJessica rabbit\r";
	//QSLog(@"screen %@", [string componentsSeparatedByStrings:[NSArray arrayWithObjects:@" >> \r", @"\r", @" ", nil]]);
				//[[QSUpdateController sharedInstance] installAppFromDiskImage:@"/Volumes/Lore/Forge/Build/Release/QS.2D40.dmg"];
//int i = 4;
	//for (i = 5; i<20; i++) {
//	[[NSClassFromString(@"QSPowerManager") sharedInstance] scheduleEvent:@"wakeorpoweron" date:[NSDate dateWithTimeIntervalSinceNow:i*60] owner:@"Quicksilver"];
//	[[NSClassFromString(@"QSPowerManager") sharedInstance] listEvents];

	//}
	//QSShowTextViewerWithString(@"test");
				//		NSRect frame = [[NSScreen mainScreen] frame];
				
	//[[NSWorkspace sharedWorkspace] commentForFile:@"/Volumes/Lore/Desktop/QSTODO"];
	//[[NSWorkspace sharedWorkspace] setComment:@"venrock" forFile:@"/Volumes/Lore/Desktop/QSTODO"];
	
	//options:NSExcludeQuickDrawElementsIconCreationOption];
	
	//	[[NSWorkspace sharedWorkspace] setIcon:[NSImage imageNamed:@"NSApplicationIcon"] forFile:@"/Volumes/Lore/Desktop/test2" options:NSExclude10_4ElementsIconCreationOption];
	//	QSLog(@"image %@", [[NSWorkspace sharedWorkspace] iconForFile:@"/Volumes/Lore/Desktop/test1"]);
	
	
 	//[[NSScreen mainScreen] deviceName];
	//QSIdleWatcher *idler = [[QSIdleWatcher alloc] init];
	//[idler performSelector:@selector(test:) withObject:@"hi" afterIdleFor:5.0 repeat:NO];
	//[idler performSelector:@selector(test:) withObject:@"there" afterIdleFor:10.0 repeat:NO];
	//[idler performSelector:@selector(test:) withObject:@"me!" afterIdleFor:20.0 repeat:NO];
	
	//	if (DEBUG) QSLog(@"Dict %@", [[NSApp parentProcessInformation]);
	//	listEncodings();
	
	//QSTooltipWindow *tip = [QSTooltipWindow tipWithString:@"flat feet" frame:NSMakeRect(0, 0, 200, 200) display:YES];
	
	
	//	NSAppleScript *script = [[[NSAppleScript alloc] initWithSource:@"tell application \"Finder\" to return selection"] autorelease];
	
	
	//	NSAppleEventDescriptor *result = [script executeAndReturnError:nil];
	//QSLog(@"", result);
	return; 	
	//QSLog(@"code %d", [[[[QSKeyCodeTranslator alloc] init] autorelease] keyCodeForCharacter:@"c"]);
	//QSLog(@"code %d", [[[[QSKeyCodeTranslator alloc] init] autorelease] AsciiToKeyCode:118]);
	
		  //[[BTConnection sharedConnection] setDevice:@"00-80-37-3e-8d-2d"];
		  //[[BTConnection sharedConnection] setDelegate:
		  //[[BTConnection sharedConnection] connect];
	/*
	 while(![[BTConnection sharedConnection] isConnected]) {
		 sleep(1);
		 QSLog(@"Waiting");
	 }
	 */
	
	//	id dialer = [[BTDialer alloc] init];
	//	[dialer dialerWillStartDialing];
	//	[dialer dial:@"16504753755"]; 	
	//	NSRect frame = [[NSScreen mainScreen] frame];
	//	NSRect windowRect = NSMakeRect(NSMinX(frame), NSMinY(frame), NSWidth(frame) /2, NSHeight(frame));
	//    NSWindow *window = [[NSWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	//    [window setBackgroundColor: [NSColor darkGrayColor]];
	//    [window setOpaque:NO];
	//	[window setAlphaValue:1.0];
	//	[window setLevel:kCGDesktopIconWindowLevel];
	//    [window setHidesOnDeactivate:NO]; [window setCanHide:NO];
	//    
	//    [window setMovableByWindowBackground:NO];
	//    [window orderFront:nil];
	//    [window setHasShadow:NO];
	//[window setContentView:[[[QSShelfView alloc] init] autorelease]];
}
