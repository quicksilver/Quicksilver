//
//  QSPasteboardMirror.m
//  KeystrokeRecorder
//
//  Created by Nicholas Jitkoff on 5/6/06.

//

#import "QSPasteboardMirror.h"


@implementation QSPasteboardMirror
+(QSPasteboardMirror *)mirrorWithPasteboard:(NSPasteboard *)newPboard{
	QSPasteboardMirror *mirror=[[[self alloc]init]autorelease];
	[mirror setPboard:newPboard];
	return mirror;
}					 
- (void)supplyPboard:(NSPasteboard *)newPboard{
	[self retain];
	[newPboard declareTypes:[pboard types] owner:self];
	
}

- (void)pasteboardChangedOwner:(NSPasteboard *)sender{
	[self autorelease];
}
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type{
	[sender setData:[pboard dataForType:type] forType:type];
}

- (NSPasteboard *)pboard { return [[pboard retain] autorelease]; }
- (void)setPboard:(NSPasteboard *)newPboard
{
	if (pboard != newPboard) {
		[pboard release];
		pboard = [[NSPasteboard pasteboardByFilteringTypesInPasteboard:newPboard] retain];
	}
}



- (void)dealloc
{
	[pboard release];
	
	pboard = nil;
	[super dealloc];
}


@end
