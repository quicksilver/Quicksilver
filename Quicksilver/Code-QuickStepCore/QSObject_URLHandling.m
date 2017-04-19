#import "QSObject_URLHandling.h"
#import "QSObject_FileHandling.h"

#import "QSTypes.h"
#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSParser.h"
#import "QSTaskController.h"
#import <QSFoundation/QSFoundation.h>

#define QSURLTypeParsersTableKey @"QSURLTypeParsersTableKey"

@implementation QSURLObjectHandler
// Object Handler Methods

- (NSString *)identifierForObject:(QSObject *)object {
	return [object objectForType:QSURLType];
}
- (NSString *)detailsOfObject:(QSObject *)object {
	return [object objectForType:QSURLType];
}


#pragma mark Search URL Images

- (NSImage *)getFavIcon:(NSString *)urlString { 
	NSURL *favIconURL = [NSURL URLWithString:[urlString URLEncoding]];
	// URLs without a scheme, NSURL's 'host' method returns nil
	if (![favIconURL host]) {
		return nil;
	}
    NSString *faviconScheme = [favIconURL scheme];
    if ([faviconScheme hasPrefix:@"qss-"]) {
        faviconScheme = [faviconScheme substringFromIndex:4];
    } else if ([faviconScheme hasPrefix:@"qssp-"]) {
        faviconScheme = [faviconScheme substringFromIndex:5];
    }
    if (!faviconScheme) {
        faviconScheme = @"http";
    }
    
	NSString *favIconString = [NSString stringWithFormat:@"http://grabicon.com/icon?domain=%@://%@&origin=quicksilverosx", faviconScheme, [favIconURL host]];
	NSImage *favicon = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:favIconString]];
	return favicon;
}

- (void)buildWebSearchIconForObject:(QSObject *)object {
    
	NSImage *webSearchImage = nil;
	NSImage *image = [QSResourceManager imageNamed:@"DefaultBookmarkIcon"];
	if(!image) {
        return;
    }
    NSRect rect = NSMakeRect(0, 0, QSMaxIconSize.width, QSMaxIconSize.height);
    [image setSize:[[image bestRepresentationForSize:rect.size] size]];
    NSSize imageSize = [image size];
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                        pixelsWide:imageSize.width
                                                                        pixelsHigh:imageSize.height
                                                                     bitsPerSample:8
                                                                   samplesPerPixel:4
                                                                          hasAlpha:YES
                                                                          isPlanar:NO
                                                                    colorSpaceName:NSCalibratedRGBColorSpace
                                                                      bitmapFormat:0
                                                                       bytesPerRow:0
                                                                      bitsPerPixel:0];
    if(!bitmap) {
        return;
    }
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:bitmap];
    
    if(!graphicsContext){
        return;
    }
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:graphicsContext];
    rect = NSMakeRect(0, 0, imageSize.width, imageSize.height);
    [image setSize:rect.size];
    [image drawInRect:rect fromRect:rectFromSize([image size]) operation:NSCompositeSourceOver fraction:1.0];
    NSImage *findImage = [[QSResourceManager imageNamed:@"Find"] copy];
    NSImage *favIcon = nil;
    if(findImage) {
        [findImage setSize:rect.size];
        // Try and load the site's favicon
        favIcon = [self getFavIcon:[object objectForType:QSURLType]];
        if(favIcon) {
            [favIcon setSize:rect.size];
            [favIcon drawInRect:NSMakeRect(rect.origin.x+NSWidth(rect)*0.48, rect.origin.y+NSWidth(rect)*0.32, 30, 30) fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
        }
        [findImage drawInRect:NSMakeRect(rect.origin.x+NSWidth(rect) *1/3, rect.origin.y, NSWidth(rect)*2/3, NSHeight(rect)*2/3) fromRect:rect operation:NSCompositeSourceOver fraction:1.0];
    }
    [NSGraphicsContext restoreGraphicsState];
    webSearchImage = [[NSImage alloc] initWithData:[bitmap TIFFRepresentation]];
    NSImageRep *fav16 = [favIcon bestRepresentationForSize:(NSSize){16.0f, 16.0f}];
    if (fav16) [webSearchImage addRepresentation:fav16];
    
    [webSearchImage setName:@"Web Search Icon"];

    [object setIcon:webSearchImage];
    [object setRetainsIcon:YES];
}

#pragma mark image handling

- (void)setQuickIconForObject:(QSObject *)object {
	if ([[object types] containsObject:QSEmailAddressType])
		[object setIcon:[QSResourceManager imageNamed:@"ContactEmail"]];
	else if ([[object objectForType:QSURLType] hasPrefix:@"ftp:"])
		[object setIcon:[QSResourceManager imageNamed:@"InternetLocationFTP"]];
	else
		[object setIcon:[QSResourceManager imageNamed:@"DefaultBookmarkIcon"]];
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
    
	// For search URLs
	if([object containsType:QSSearchURLType]) {
        [self buildWebSearchIconForObject:object];
		return YES;
	}
	
	// For images that are links on web pages
	NSString *imageURL = [object objectForMeta:kQSObjectIconName];
	if (imageURL) {	
		// initWithContentsOfURL accounts for the URL being dynamic
		NSImage *image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:imageURL]];
		if (image) {
			[object setIcon:image];
			return YES;
		}
	}
    [object setRetainsIcon:YES];
	return NO;
}

#pragma mark children

- (BOOL)objectHasChildren:(QSObject *)object { 
    // Need a list of TLDs to compare
	static NSArray *tldArray = nil;
	if(tldArray == nil) {
		tldArray = [NSArray arrayWithObjects:@"AC",@"AD",@"AE",@"AERO",@"AF",@"AG",@"AI",@"AL",@"AM",@"AN",@"AO",@"AQ",@"AR",@"ARPA",@"AS",@"ASIA",@"AT",@"AU",@"AW",@"AX",@"AZ",@"BA",@"BB",@"BD",@"BE",@"BF",@"BG",@"BH",@"BI",@"BIZ",
					 @"BJ",@"BM",@"BN",@"BO",@"BR",@"BS",@"BT",@"BV",@"BW",@"BY",@"BZ",@"CA",@"CAT",@"CC",@"CD",@"CF",@"CG",@"CH",@"CI",@"CK",@"CL",@"CM",@"CN",@"CO",@"COM",@"COOP",@"CR",@"CU",@"CV",@"CX",@"CY",@"CZ",@"DE",@"DJ",@"DK",
					 @"DM",@"DO",@"DZ",@"EC",@"EDU",@"EE",@"EG",@"ER",@"ES",@"ET",@"EU",@"FI",@"FJ",@"FK",@"FM",@"FO",@"FR",@"GA",@"GB",@"GD",@"GE",@"GF",@"GG",@"GH",@"GI",@"GL",@"GM",@"GN",@"GOV",@"GP",@"GQ",@"GR",@"GS",@"GT",@"GU",
					 @"GW",@"GY",@"HK",@"HM",@"HN",@"HR",@"HT",@"HU",@"ID",@"IE",@"IL",@"IM",@"IN",@"INFO",@"INT",@"IO",@"IQ",@"IR",@"IS",@"IT",@"JE",@"JM",@"JO",@"JOBS",@"JP",@"KE",@"KG",@"KH",@"KI",@"KM",@"KN",@"KP",@"KR",@"KW",@"KY",
					 @"KZ",@"LA",@"LB",@"LC",@"LI",@"LK",@"LR",@"LS",@"LT",@"LU",@"LV",@"LY",@"MA",@"MC",@"MD",@"ME",@"MG",@"MH",@"MIL",@"MK",@"ML",@"MM",@"MN",@"MO",@"MOBI",@"MP",@"MQ",@"MR",@"MS",@"MT",@"MU",@"MUSEUM",@"MV",@"MW",@"MX",
					 @"MY",@"MZ",@"NA",@"NAME",@"NC",@"NE",@"NET",@"NF",@"NG",@"NI",@"NL",@"NO",@"NP",@"NR",@"NU",@"NZ",@"OM",@"ORG",@"PA",@"PE",@"PF",@"PG",@"PH",@"PK",@"PL",@"PM",@"PN",@"PR",@"PRO",@"PS",@"PT",@"PW",@"PY",@"QA",@"RE",@"RO",
					 @"RS",@"RU",@"RW",@"SA",@"SB",@"SC",@"SD",@"SE",@"SG",@"SH",@"SI",@"SJ",@"SK",@"SL",@"SM",@"SN",@"SO",@"SR",@"ST",@"SU",@"SV",@"SY",@"SZ",@"TC",@"TD",@"TEL",@"TF",@"TG",@"TH",@"TJ",@"TK",@"TL",@"TM",@"TN",@"TO",@"TP",@"TR",
					 @"TRAVEL",@"TT",@"TV",@"TW",@"TZ",@"UA",@"UG",@"UK",@"US",@"UY",@"UZ",@"VA",@"VC",@"VE",@"VG",@"VI",@"VN",@"VU",@"WF",@"WS",@"XXX",@"YE",@"YT",@"ZA",@"ZM",@"ZW",nil];
	}
	NSString *urlString = [object objectForType:QSURLType];
	// Check the extension of the URL. We're looking for a tld, .php, .html or .htm (set in QSCorePlugin-Info.plist)
	NSString *URLExtension = [[[urlString pathExtension] componentsSeparatedByString:@"?"] objectAtIndex:0];
	// Check if the URL is a tld
	if(URLExtension.length > 0 && [tldArray containsObject:[URLExtension uppercaseString]]) {
		URLExtension = @"tld";
	}
	id <QSParser> parser = [QSReg instanceForKey:URLExtension inTable:@"QSURLTypeParsers"];
    
    if (parser) {
        // Store the key for the QSURLTypeParsers table (see QSReg) to save having to load the URL extension again
        [object setObject:URLExtension forMeta:QSURLTypeParsersTableKey];
        return YES;
    }
    
    return NO;
}


- (BOOL)loadChildrenForObject:(QSObject *)object {
	QSTask *task = [QSTask taskWithIdentifier:@"DownloadPage"];
	task.status = NSLocalizedString(@"Downloading Page", @"");
	task.showProgress = NO;
	[task start];

    if (![object objectForMeta:QSURLTypeParsersTableKey]) {
        // it's possible `objectHasChildren:` was never called to populate this
        [self objectHasChildren:object];
    }
    
    id <QSParser> parser = [QSReg instanceForKey:[object objectForMeta:QSURLTypeParsersTableKey] inTable:@"QSURLTypeParsers"];
    
	NSArray *children = [parser objectsFromURL:[NSURL URLWithString:[object objectForType:QSURLType]] withSettings:nil];

	[task stop];
    
	if (children) {
		[object setChildren:children];
		return YES;
	}
    
	return NO;
}
@end

@implementation QSObject (URLHandling)

+ (QSObject *)URLObjectWithURL:(NSString *)urlString title:(NSString *)title {
	if ([urlString hasPrefix:@"file://"] || [urlString hasPrefix:@"/"]) {
		return [QSObject fileObjectWithPath:[[NSURL URLWithString:urlString] path]];
        
	}
	return [[QSObject alloc] initWithURL:urlString title:title];
}
- (NSString *)cleanQueryURL:(NSString *)query {
	//NSLog(@"query %@", query);
	if ([query rangeOfString:@"\%s"] .location != NSNotFound) {
		//NSLog(@"%@ > %@", query, [query stringByReplacing:@"\%s" with:QUERY_KEY]);
		return [query stringByReplacingOccurrencesOfString:@"\%s" withString:QUERY_KEY];
	}
	return query;
}
- (id)initWithURL:(NSString *)urlString title:(NSString *)title {
    
	if (!urlString) {
		return nil;
	}
	if (self = [self init]) {
        
		urlString = [self cleanQueryURL:urlString];
		[self setName:(title?title:urlString)];
		[self assignURLTypesWithURL:urlString];
	}
	return self;
}

- (void)assignURLTypesWithURL:(NSString *)urlString
{
    [[self dataDictionary] setObject:urlString forKey:QSURLType];
    // Apple's 'URLWithString' method incorrectly deals with IP addresses, check for "://" and "mailto:" in the string as well
    if (([urlString rangeOfString:@"://"].location != NSNotFound || [urlString hasPrefix:@"mailto:"] || [urlString hasPrefix:@"javascript:"]) && [[NSURL URLWithString:[urlString URLEncoding]] scheme])
    {
        [self setObject:urlString forType:QSURLType];
    } else {
        // a plain string (host or FQDN?) was passed - add a scheme prefix
        [self setObject:[@"http://" stringByAppendingString:urlString] forType:QSURLType];
    }
    if ([urlString hasPrefix:@"mailto:"]) {
        NSString *email = [urlString substringWithRange:NSMakeRange(7, [urlString length] -7)];
        [self setObject:email forType:QSEmailAddressType];
        [self setObject:email forType:QSTextType];
        [self setPrimaryType:QSEmailAddressType];
    } else {
        [self setObject:urlString forType:QSTextType];
        [self setPrimaryType:QSURLType];
    }
	// search URLs
	if ([urlString rangeOfString:QUERY_KEY].location != NSNotFound) {
		[self setObject:urlString forType:QSSearchURLType];
		[self setPrimaryType:QSSearchURLType];
	}
}

@end
