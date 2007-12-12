//
//  QSWebSource.m
//  Quicksilver
//
//  Created by Alcor on 7/9/04.

//
#import "QSHTMLLinkParser.h"

#import "QSWebSource.h"

@implementation QSWebSource

- (NSImage *) iconForEntry:(NSDictionary *)entry{
//	NSMutableDictionary *settings=[entry objectForKey:kItemSettings];
	
	NSImage *image=nil;
//	NSString *location=[settings objectForKey:kItemPath];
	//if (location) image=[[QSFaviconManager sharedInstance]faviconForURL:[NSURL URLWithString:location]];
	
	if (!image)
		image=[NSImage imageNamed:@"DefaultBookmarkIcon"];
	[image createIconRepresentations];
	return image;
}

- (NSArray *) objectsForEntry:(NSDictionary *)theEntry{
    NSMutableDictionary *settings=[theEntry objectForKey:kItemSettings];
	NSString *location=[settings objectForKey:kItemPath];
	if (location){
		id instance=[QSReg getClassInstance:@"QSHTMLLinkParser"];
		return [(QSHTMLLinkParser *)instance objectsFromURL:[NSURL URLWithString:location] withSettings:settings];
		
	}
	return nil;
}

- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
	return YES;
}

@end