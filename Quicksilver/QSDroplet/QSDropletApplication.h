//
//  QSDropletApplication.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 2/24/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSDropletApplication : NSApplication {

}
- (BOOL)executeCommandWithPasteboard:(NSPasteboard *)pb;
- (void)resetTerminateDelay;
@end
