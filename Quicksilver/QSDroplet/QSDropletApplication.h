//
//  QSDropletApplication.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 2/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface QSDropletApplication : NSApplication 
#if MAC_OS_X_VERSION_MAX_ALLOWED >= 1060
   <NSApplicationDelegate>
#endif
{}
- (BOOL)executeCommandWithPasteboard:(NSPasteboard *)pb;
- (void)resetTerminateDelay;
@end
