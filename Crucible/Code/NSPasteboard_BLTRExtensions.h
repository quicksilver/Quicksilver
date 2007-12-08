//
//  NSPasteboard_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Sun Nov 09 2003.

//

void QSForcePaste();

@interface NSPasteboard (Clippings)
+ (NSPasteboard *)pasteboardByFilteringClipping:(NSString *)pacg;
@end
