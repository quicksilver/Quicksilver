//
//  QSPasteboardMirror.h
//  KeystrokeRecorder
//
//  Created by Nicholas Jitkoff on 5/6/06.

//

#import <Cocoa/Cocoa.h>


@interface QSPasteboardMirror : NSObject {
	NSPasteboard *pboard;
}
- (NSPasteboard *)pboard;
- (void)setPboard:(NSPasteboard *)newPboard;
- (void)supplyPboard:(NSPasteboard *)newPboard;
@end
