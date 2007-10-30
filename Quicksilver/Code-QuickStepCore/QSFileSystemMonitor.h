//
//  QSFileSystemMonitor.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 9/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface QSFileSystemMonitor : NSObject {
	NSTask *logger;
	NSFileHandle *output;
}

@end
