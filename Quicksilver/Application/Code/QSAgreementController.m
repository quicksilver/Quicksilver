//
//  QSAgreementController.m
//  Quicksilver
//
//  Created by Alcor on 10/13/04.

//

#import "QSAgreementController.h"

@implementation QSAgreementController
+ (void)showAgreement:(id)sender {
	
	[[[[QSAgreementController alloc] init] autorelease] showAgreement:sender];
	
}
- (id)init {
    self = [self initWithWindowNibName:@"QSAgreement"];
    if (self) {
		
		//	QSLog(@"plugs %@", installedPlugIns);  
	}
    return self;
}

- (void)dealloc {
	[super dealloc];
}
- (void)showAgreement:(id)sender {
	[[self window] center];  
	// ***warning   ** finish me!
	
	NSString *path = [[NSBundle bundleForClass:[self class]]pathForResource:@"License"
																   ofType:@"rtf"];
	
	[[agreement documentView] replaceCharactersInRange:NSMakeRange(0, 0) withRTF:[NSData dataWithContentsOfFile:path]];
	
	
	[NSApp activateIgnoringOtherApps:YES];
	[self showWindow:self];
	[NSApp runModalForWindow:[self window]];
	
	[[self window] close];
	//   [aboutWindow center];
	//   [aboutWindow makeKeyAndOrderFront:self];
}
- (void)accept:(id)sender {
	
	[(QSWindow *)[self window] setHideOffset:NSMakePoint(0, 400)];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"QSAgreementAccepted"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[NSApp stopModal];
}
- (void)quit:(id)sender {
	
	[(QSWindow *)[self window] setHideOffset:NSMakePoint(0, -400)];
	[NSApp terminate:sender];
	
}


@end
