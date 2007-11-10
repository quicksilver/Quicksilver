//
//  QSFileSystemMonitor.h
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 9/19/05.

//

#import <Cocoa/Cocoa.h>


@interface QSFileSystemMonitor : NSObject {
	NSTask *logger;
	NSFileHandle *output;
}

@end
