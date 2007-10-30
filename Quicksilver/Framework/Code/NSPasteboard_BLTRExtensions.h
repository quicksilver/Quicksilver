//
//  NSPasteboard_BLTRExtensions.h
//  Quicksilver
//
//  Created by Alcor on Sun Nov 09 2003.
//  Copyright (c) 2003 Blacktree, Inc.. All rights reserved.
//

void QSForcePaste();

@interface NSPasteboard (Clippings)
+ (NSPasteboard *)pasteboardByFilteringClipping:(NSString *)pacg;
@end
