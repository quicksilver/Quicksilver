#import "QSObject_URLHandling.h"
#import "QSObject_FileHandling.h"

#import "QSTypes.h"
#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSParser.h"
#import "QSTaskController.h"
#import <QSFoundation/QSFoundation.h>

@implementation QSURLObjectHandler
// Object Handler Methods

- (NSString *)identifierForObject:(id <QSObject>)object {
	return [object objectForType:QSURLType];
}
- (NSString *)detailsOfObject:(id <QSObject>)object {
	//NSString *url = [object objectForType:QSURLType];
	return [object objectForType:QSURLType];
}

- (void)setQuickIconForObject:(QSObject *)object {
	NSString *url = [object objectForType:QSURLType];
	if ([url hasPrefix:@"mailto:"])
		[object setIcon:[NSImage imageNamed:@"ContactEmail"]];
	else if ([url hasPrefix:@"ftp:"])
		[object setIcon:[QSResourceManager imageNamed:@"AFPClient"]];
	else
		[object setIcon:[NSImage imageNamed:@"DefaultBookmarkIcon"]];

}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	//	NSImage *icon = [object icon];
	NSString *url = [object objectForType:QSURLType];
	//NSLog(@"drawurl %@", url);
	if (NSWidth(rect) <= 32 ) return NO;

	NSImage *image = [NSImage imageNamed:@"DefaultBookmarkIcon"];

	BOOL isQuery = [url rangeOfString:QUERY_KEY] .location != NSNotFound;
	if (![url hasPrefix:@"http:"] && !isQuery) return NO;

	[image setSize:[[image bestRepresentationForSize:rect.size] size]];
	//[image adjustSizeToDrawAtSize:rect.size];
	[image setFlipped:flipped];
	[image drawInRect:rect fromRect:rectFromSize([image size]) operation:NSCompositeSourceOver fraction:1.0];

	if ([object iconLoaded]) {
		NSImage *cornerBadge = [object icon];
		if (cornerBadge != image) {
			[cornerBadge setFlipped:flipped];
			NSImageRep *bestBadgeRep = [cornerBadge bestRepresentationForSize:rect.size];
			[cornerBadge setSize:[bestBadgeRep size]];
			NSRect badgeRect = rectFromSize([cornerBadge size]);

			//NSPoint offset = rectOffset(badgeRect, rect, 2);
			badgeRect = centerRectInRect(badgeRect, rect);
			badgeRect = NSOffsetRect(badgeRect, 0, -NSHeight(rect) /6);

			[[NSColor colorWithDeviceWhite:1.0 alpha:0.8] set];
			NSRectFillUsingOperation(NSInsetRect(badgeRect, -3, -3), NSCompositeSourceOver);
			[[NSColor colorWithDeviceWhite:0.75 alpha:1.0] set];
			NSFrameRectWithWidth(NSInsetRect(badgeRect, -5, -5), 2);
			[cornerBadge drawInRect:badgeRect fromRect:rectFromSize([cornerBadge size]) operation:NSCompositeSourceOver fraction:1.0];
		}
	}
	if (isQuery) {
		NSImage *findImage = [NSImage imageNamed:@"Find"];
		[findImage setSize:NSMakeSize(128, 128)];
		[findImage drawInRect:NSMakeRect(rect.origin.x+NSWidth(rect) *1/3, rect.origin.y, NSWidth(rect)*2/3, NSHeight(rect)*2/3) fromRect:NSMakeRect(0, 0, 128, 128)
					operation:NSCompositeSourceOver fraction:1.0];
		return YES;

	}
	return YES;

}
- (BOOL)loadIconForObject:(QSObject *)object {
	NSString *urlString = [object objectForType:QSURLType];
	if (!urlString) return NO;

	NSString *imageURL = [object objectForMeta:kQSObjectIconName];
	if (imageURL) {
	NSImage *image = [[NSImage alloc] initByReferencingURL:[NSURL URLWithString:imageURL]];
	if (image) {
		[object setIcon:image];
        [image release];
		return YES;
		}
	}
	NSURL *url = [NSURL URLWithString:urlString];
	NSImage *favicon = nil; //[[QSFaviconManager sharedInstance] faviconForURL:url];

	NSEnumerator *e = [[QSReg instancesForTable:@"QSFaviconSources"] objectEnumerator];
	id <QSFaviconSource> source;

	//NSLog(@"favisource", source);
	while (!favicon && (source = [e nextObject]) ) {
	//	NSLog(@"favisource %@", source);
		favicon = [source faviconForURL:url];
	}

	if (!favicon) return NO;

	if (![favicon representationOfSize:NSMakeSize(16, 16)])
		[favicon createRepresentationOfSize:NSMakeSize(16, 16)];

	[object setIcon:(favicon)];

	return YES;

}

- (BOOL)loadChildrenForObject:(QSObject *)object {
	//if (!fBETA) return NO;
	NSString *urlString = [object objectForType:QSURLType];

	NSString *type = [urlString pathExtension];

	id <QSParser> parser = [QSReg instanceForKey:type inTable:@"QSURLTypeParsers"];

	[QSTasks updateTask:@"DownloadPage" status:@"Downloading Page" progress:0];

	NSArray *children = [parser objectsFromURL:[NSURL URLWithString:urlString] withSettings:nil];

	[QSTasks removeTask:@"DownloadPage"];

	if (children) {
		[object setChildren:children];
		return YES;
	}

	return NO;
}
@end

@implementation QSObject (URLHandling)

+ (QSObject *)URLObjectWithURL:(NSString *)url title:(NSString *)title {
	if ([url hasPrefix:@"file://"] || [url hasPrefix:@"/"]) {
		return [QSObject fileObjectWithPath:[[NSURL URLWithString:url] path]];

	}
	return [[[QSObject alloc] initWithURL:url title:title] autorelease];
}
- (NSString *)cleanQueryURL:(NSString *)query {
	//NSLog(@"query %@", query);
	if ([query rangeOfString:@"\%s"] .location != NSNotFound) {
		//NSLog(@"%@ > %@", query, [query stringByReplacing:@"\%s" with:@"***"]);
		return [query stringByReplacing:@"\%s" with:@"***"];

	}
	return query;
}
- (id)initWithURL:(NSString *)url title:(NSString *)title {

	if (!url) {
		[self release];
		return nil;
	}
	if (self = [self init]) {

		url = [self cleanQueryURL:url];
		[self setName:(title?title:url)];
		[[self dataDictionary] setObject:url forKey:QSURLType];
		if ([url hasPrefix:@"mailto:"])
			[self setObject:[NSArray arrayWithObject:[url substringWithRange:NSMakeRange(7, [url length] -7)]] forType:QSEmailAddressType];
		[self setPrimaryType:QSURLType];
	}
	return self;
}

@end

