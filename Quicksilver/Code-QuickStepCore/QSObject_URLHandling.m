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

- (NSString *)identifierForObject:(QSObject *)object {
	return [object objectForType:QSURLType];
}
- (NSString *)detailsOfObject:(QSObject *)object {
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


#if defined(USE_ORIGINAL_URL_ICON_DRAWING_CODE)
// Original drawIconForObject code
- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	//      NSImage *icon = [object icon];
	NSString *url = [object objectForType:QSURLType];
	//NSLog(@"drawurl %@", url);
	if (NSWidth(rect) <= 32 ) return NO;

	NSImage *image = [NSImage imageNamed:@"DefaultBookmarkIcon"];

	BOOL isQuery = [url rangeOfString:QUERY_KEY] .location != NSNotFound;
	if (![url hasPrefix:@"http:"] && !isQuery) return NO;

	[image setSize:[[image bestRepresentationForSize:rect.size] size]];
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

	NSLog(@"%@", url);
	if (isQuery) {
		NSImage *findImage = [NSImage imageNamed:@"Find"];
		[findImage setSize:NSMakeSize(128, 128)];
		[findImage drawInRect:NSMakeRect(rect.origin.x+NSWidth(rect) *1/3, rect.origin.y, NSWidth(rect)*2/3, NSHeight(rect)*2/3) fromRect:NSMakeRect(0, 0, 128, 128)
					operation:NSCompositeSourceOver fraction:1.0];
		return YES;

	}
	return YES;

}
#endif

#if defined(USE_NEW_URL_ICON_DRAWING_CODE) || defined(USE_NEW_URL_ICON_DRAWING_CODE_WITH_FAVICONS)
/*!
 *    favIcon
 *    @abstract   Matches a URL string with a favIcon NSImage
 *    @discussion For this function to work the favIcon dictionary must
 *                by populated.  Currently that is done through Safari (need the
 *                updated plugin).
 *    @param      url The input URL string to match
 *    @result     An NSImage if there was a match, otherwise nil
 */
- (NSImage *)favIcon:(NSString *)url {
	id <QSFaviconSource> source;
	NSImage *favicon = nil;

	for(source in [[QSReg instancesForTable:@"QSFaviconSources"] objectEnumerator]) {
		favicon = [source faviconForURL:[NSURL URLWithString:url]];
		if(favicon)
			break;
	}
	return favicon;
}
#endif

#if defined(USE_NEW_URL_ICON_DRAWING_CODE_WITH_FAVICONS)
/*!
 * @drawIconForObject
 * @abstract   Experimental (w/flavicon): Special handler for drawing the objects image on screen
 * @discussion This function handles the drawing of object of URL search and query types.
 *             Currently it looks for URL strings starting with "http", "https",
 *             URL strings that contain "***", or end with "web_search_list". If any of these
 *             conditions are met then the function will handle object drawing.
 *
 *             First, the icon "DefaultBookmarkIcon" is loaded and drawn on screen.
 *             Second, a Favicon is looked up based on the URL and drawn over the first image.
 *             Third, if this is a search query URL then a "Finder" icon is overlay the other images.
 *
 *             When this function handles the drawing operations it will ignore
 *             the NSImage that may be attached to the object.
 *
 *             Search the code base for USE_NEW_URL_ICON_DRAWING_CODE_WITH_FAVICONS to find
 *             where web search and query objects assign a default NSImage.
 *
 * @param      object The object to draw an image of
 * @param      inRect The size of the rectangle drawing area
 * @param      flipped Does the image need to be flipped prior to drawing
 * @result     Returns YES if the function handled drawing of the object, otherwise
 *             returns NO.
 */
- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	if (NSWidth(rect) <= 32 )
		return NO;

	if(![object iconLoaded])
		return NO;

	NSString *url = [object objectForType:QSURLType];
	NSString * imageURL = [object objectForMeta:kQSObjectIconName];

#ifdef _DDEBUG
	NSLog(@"ImageURL = %@", imageURL);
	NSLog(@"URL      = %@", url);
#endif

	// "***" and "web_search_list" are matches
	BOOL isQuery = [url rangeOfString:QUERY_KEY] .location != NSNotFound ||	[imageURL hasSuffix:@"web_search_list"];
	BOOL hasPrefix = [url hasPrefix:@"http:"] || [url hasPrefix:@"https"];
	if (!hasPrefix && !isQuery)
		return NO;

	// draw the DefaultBookmarkIcon
	NSImage *image = [NSImage imageNamed:@"DefaultBookmarkIcon"];
	[image setFlipped:flipped];
	[image setSize:[[image bestRepresentationForSize:rect.size] size]];
	[image drawInRect:rect fromRect:rectFromSize([image size]) operation:NSCompositeSourceOver fraction:1.0];

	// draw the favicon if one is found
	NSImage *favicon = [self favIcon:url];
	if(favicon) {
		NSRect faviconRect = NSMakeRect(0, 0, 16, 16);
		[favicon setSize:[[favicon bestRepresentationForSize:faviconRect.size] size]] ;
		NSRect faviconPos = centerRectInRect(faviconRect, rect);
		faviconPos = centerRectInRect(NSMakeRect(0, 0, 24, 24), rect);
		faviconPos.origin.y -= 16;
		[favicon drawInRect:faviconPos fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}

	if(isQuery) {
		// draw the "Finder" icon
		NSLog(@"%@", url);
		NSImage *findImage = [NSImage imageNamed:@"Find"];
		if(findImage) {
			[findImage setSize:rect.size];
			[findImage drawInRect:NSMakeRect(rect.origin.x+NSWidth(rect) *1/3, rect.origin.y, NSWidth(rect)*2/3, NSHeight(rect)*2/3) fromRect:NSMakeRect(0, 0, 128, 128) operation:NSCompositeSourceOver fraction:1.0];
		}
	}
	return YES;
}
#endif

#ifdef USE_NEW_URL_ICON_DRAWING_CODE
/*!
 * @drawIconForObject
 * @abstract   Special handler for drawing the objects image on screen
 * @discussion Currently does not handle any drawing operations and retruns NO.
 *
 *             Search the code base for USE_NEW_URL_ICON_DRAWING_CODE to find
 *             where web search and query objects assign a default NSImage.
 *
 * @param      object The object to draw an image of
 * @param      inRect The size of the rectangle drawing area
 * @param      flipped Does the image need to be flipped prior to drawing
 * @result     Returns YES if the function handled drawing of the object, otherwise
 *             returns NO.
 */
- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped {
	return NO;
}
#endif

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
	return NO;

/*
//	// removed all this because if there is a favicon available,
//	// we don't want it being used as the objects image, because
//	// the favicon would be upscaled to 32x32, 64x64, or 128x128,
//	// making it really ugly.
//	NSURL *url = [NSURL URLWithString:urlString];
//	NSImage *favicon = nil; //[[QSFaviconManager sharedInstance] faviconForURL:url];

//	NSEnumerator *e = [[QSReg instancesForTable:@"QSFaviconSources"] objectEnumerator];
//	id <QSFaviconSource> source;

//	//NSLog(@"favisource", source);
//	while (!favicon && (source = [e nextObject]) ) {
//	//	NSLog(@"favisource %@", source);
//		favicon = [source faviconForURL:url];
//	}

////
//	for(source in e) {
//		favicon = [source faviconForURL:url];
//		if(favicon)
//			break;
//	}

//	if (!favicon) return NO;

//	if (![favicon representationOfSize:NSMakeSize(16, 16)])
//		[favicon createRepresentationOfSize:NSMakeSize(16, 16)];

//	[object setIcon:(favicon)];

//	return YES;
*/
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

