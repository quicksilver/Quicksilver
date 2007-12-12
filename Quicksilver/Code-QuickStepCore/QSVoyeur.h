

#import <Foundation/Foundation.h>

#import "UKKQueue.h"

#import "UKFileWatcher.h"

@interface QSVoyeur : UKKQueue {
	NSMutableArray *watchArray;
}

+ (id)sharedInstance;
//- (void)setDelegate:(id)delegate;
@end
