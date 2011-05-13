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

/*!
 * @drawIconForObject
 * @abstract   Special handler for drawing the objects image on screen
 * @discussion Currently does not handle any drawing operations and retruns NO.
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
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
	// Need a list of TLDs to compare
	static NSArray *tldArray = nil;
	if(tldArray == nil) {
		tldArray = [[NSArray arrayWithObjects:@"AC",@"AD",@"AE",@"AERO",@"AF",@"AG",@"AI",@"AL",@"AM",@"AN",@"AO",@"AQ",@"AR",@"ARPA",@"AS",@"ASIA",@"AT",@"AU",@"AW",@"AX",@"AZ",@"BA",@"BB",@"BD",@"BE",@"BF",@"BG",@"BH",@"BI",@"BIZ",
					 @"BJ",@"BM",@"BN",@"BO",@"BR",@"BS",@"BT",@"BV",@"BW",@"BY",@"BZ",@"CA",@"CAT",@"CC",@"CD",@"CF",@"CG",@"CH",@"CI",@"CK",@"CL",@"CM",@"CN",@"CO",@"COM",@"COOP",@"CR",@"CU",@"CV",@"CX",@"CY",@"CZ",@"DE",@"DJ",@"DK",
					 @"DM",@"DO",@"DZ",@"EC",@"EDU",@"EE",@"EG",@"ER",@"ES",@"ET",@"EU",@"FI",@"FJ",@"FK",@"FM",@"FO",@"FR",@"GA",@"GB",@"GD",@"GE",@"GF",@"GG",@"GH",@"GI",@"GL",@"GM",@"GN",@"GOV",@"GP",@"GQ",@"GR",@"GS",@"GT",@"GU",
					 @"GW",@"GY",@"HK",@"HM",@"HN",@"HR",@"HT",@"HU",@"ID",@"IE",@"IL",@"IM",@"IN",@"INFO",@"INT",@"IO",@"IQ",@"IR",@"IS",@"IT",@"JE",@"JM",@"JO",@"JOBS",@"JP",@"KE",@"KG",@"KH",@"KI",@"KM",@"KN",@"KP",@"KR",@"KW",@"KY",
					 @"KZ",@"LA",@"LB",@"LC",@"LI",@"LK",@"LR",@"LS",@"LT",@"LU",@"LV",@"LY",@"MA",@"MC",@"MD",@"ME",@"MG",@"MH",@"MIL",@"MK",@"ML",@"MM",@"MN",@"MO",@"MOBI",@"MP",@"MQ",@"MR",@"MS",@"MT",@"MU",@"MUSEUM",@"MV",@"MW",@"MX",
					 @"MY",@"MZ",@"NA",@"NAME",@"NC",@"NE",@"NET",@"NF",@"NG",@"NI",@"NL",@"NO",@"NP",@"NR",@"NU",@"NZ",@"OM",@"ORG",@"PA",@"PE",@"PF",@"PG",@"PH",@"PK",@"PL",@"PM",@"PN",@"PR",@"PRO",@"PS",@"PT",@"PW",@"PY",@"QA",@"RE",@"RO",
					 @"RS",@"RU",@"RW",@"SA",@"SB",@"SC",@"SD",@"SE",@"SG",@"SH",@"SI",@"SJ",@"SK",@"SL",@"SM",@"SN",@"SO",@"SR",@"ST",@"SU",@"SV",@"SY",@"SZ",@"TC",@"TD",@"TEL",@"TF",@"TG",@"TH",@"TJ",@"TK",@"TL",@"TM",@"TN",@"TO",@"TP",@"TR",
					 @"TRAVEL",@"TT",@"TV",@"TW",@"TZ",@"UA",@"UG",@"UK",@"US",@"UY",@"UZ",@"VA",@"VC",@"VE",@"VG",@"VI",@"VN",@"VU",@"WF",@"WS",@"XXX",@"YE",@"YT",@"ZA",@"ZM",@"ZW",nil] retain];
	}
	NSString *urlString = [object objectForType:QSURLType];
	// Make sure the URL type is a domain or .html/htm type
	NSString *type = [urlString pathExtension];
	// Check if the URL is a tld
	if(type.length > 0 && [tldArray containsObject:[type uppercaseString]]) {
		type = @"tld";
	}
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

