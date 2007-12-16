//
//  QSHistoryObjectSource.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 8/18/05.

//

#import "QSHistoryObjectSource.h"

@implementation QSHistoryObjectSource

- (id) init{
    if ((self=[super init])){
		[QSHistoryController sharedInstance];
	}
	return self;
}

- (BOOL)entryCanBeIndexed:(NSDictionary *)theEntry{return NO;}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
    return NO;
}

- (NSImage *) iconForEntry:(NSDictionary *)dict{return [QSResourceManager imageNamed:@"Quicksilver"];}

- (NSArray *) objectsForEntry:(NSDictionary *)dict{
	if ([[dict objectForKey:@"userInfo"]isEqualToString:@"commands"])
		return [QSHist recentCommands];
	else
		return [QSHist recentObjects];

}


-(id)resolveProxyObject:(id)proxy{	
	if ([[proxy identifier]isEqualToString:@"QSLastCommandProxy"]){
		return [[QSHist recentCommands]objectAtIndex:0];
	}
	if ([[proxy identifier]isEqualToString:@"QSLastObjectProxy"]){
		return [[QSHist recentCommands]objectAtIndex:0];	
	}
	return nil;
	
}



@end
