

#import "QSObject_URLHandling.h"
#import "QSObject_FileHandling.h"
//#import "QSFaviconManager.h"

#import "QSTypes.h"
#import "QSResourceManager.h"

#import "QSParser.h"
#import "QSTaskController.h"

#import "NSGeometry_BLTRExtensions.h"

@implementation QSObject (URLHandling)

+ (QSObject *)URLObjectWithURL:(NSString *)url title:(NSString *)title {
    if ([url hasPrefix:@"file://"] || [url hasPrefix:@"/"]) {
        return [QSObject fileObjectWithPath:[[NSURL URLWithString:url] path]];
    }
    return [[[QSObject alloc] initWithURL:url title:title] autorelease];
}

- (id)initWithURL:(NSString *)url title:(NSString *)title {
    if (!url) {
		[self release];
		return nil;
	}
	if ((self = [self init])) {
		url = [self cleanQueryURL:url];
		[self setName:(title ? title : url)];
		[[self dataDictionary] setObject:url forKey:QSURLType];
		if ([url hasPrefix:@"mailto:"])
			[self setObject:[NSArray arrayWithObject:[url substringWithRange:NSMakeRange(7, [url length] -7)]] forType:QSEmailAddressType];
		[self setPrimaryType:QSURLType];
	}
    return self;
}

- (NSString *)cleanQueryURL:(NSString *)query {
	//QSLog(@"query %@", query);
	if ([query rangeOfString:@"\%s"] .location != NSNotFound) {
		//QSLog(@"%@ > %@", query, [query stringByReplacing:@"\%s" with:@"***"]);
		return [query stringByReplacing:@"\%s" with:@"***"]; 	
	}
	return query;
}

@end


