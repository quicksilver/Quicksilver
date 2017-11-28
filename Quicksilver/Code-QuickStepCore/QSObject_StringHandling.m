//
// QSObject_StringHandling.m
// Quicksilver
//
// Created by Alcor on 8/5/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSObject_StringHandling.h"
#import "QSTypes.h"
#import "QSObject_URLHandling.h"
//#import "NSString+CarbonUtilities.h"



@implementation NSString (Trimming)
- (NSString *)trimWhitespace {
	CFMutableStringRef 		theString;

	theString = CFStringCreateMutableCopy( kCFAllocatorDefault, 0, (CFStringRef) self);
	CFStringTrimWhitespace( theString );
    
    NSString * retString = (NSString*)CFBridgingRelease(CFStringCreateCopy( kCFAllocatorDefault, theString ));
    CFRelease( theString );
    
	return retString;
}
@end

@implementation QSStringObjectHandler

- (NSData *)fileRepresentationForObject:(QSObject *)object { return [[object stringValue] dataUsingEncoding:NSUTF8StringEncoding];  }

- (NSString *)filenameForObject:(QSObject *)object {
	NSString *name = [[[object stringValue] lines] objectAtIndex:0];
	return [name stringByAppendingPathExtension:@"txt"];
}
- (BOOL)objectHasChildren:(QSObject *)object {
    NSString *str = [object stringValue];
    return [[str componentsSeparatedByLineSeparators] count] > 1;
}

- (BOOL)loadChildrenForObject:(QSObject *)object {
    NSArray *lines = [[object stringValue] componentsSeparatedByLineSeparators];
    [object setChildren:[lines arrayByEnumeratingArrayUsingBlock:^id(NSString *str) {
        QSObject *obj = [QSObject objectWithString:str];
        [obj setParentID:[object identifier]];
        return obj;
    }]];
    return YES;
}

- (void)setQuickIconForObject:(QSObject *)object { [object setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:@"'clpt'"]];  }
- (BOOL)loadIconForObject:(QSObject *)object { return NO;  }

 - (NSString *)detailsOfObject:(QSObject *)object { return nil;  }
@end

@implementation QSObject (StringHandling)

+ (id)objectWithString:(NSString *)string {
    return [(QSObject *)[QSObject alloc] initWithString:string];
}

- (id)initWithString:(NSString *)string {
    if (![string length]) {
        return nil;
    }

	self = [self init];
	if (!self) return nil;

	[self setObject:string forType:QSTextType];
	[self setName:string];
	[self setPrimaryType:QSTextType];
	[self sniffString];

	return self;
}

- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type {
    return [object objectForType:type];
}

- (void)sniffString {
	NSString *stringValue = [self objectForType:QSTextType];

	// A string for the calculator
	if ([stringValue hasPrefix:@"="]) {
		[self setObject:stringValue forType:QSFormulaType];
		[self setObject:nil forType:QSTextType];
		[self setPrimaryType:QSFormulaType];
		return;
	}
	
	// It's an AppleScript
	if ([stringValue hasPrefix:@"tell app"]) {
		//NSLog(@"Script!");
		[self setObject:@"AppleScriptRunTextAction" forMeta:kQSObjectDefaultAction];
		return;
	}
	
	// It's a file path
	if ([stringValue hasPrefix:@"/"] || [stringValue hasPrefix:@"~"]) {
		NSMutableArray *files = [[stringValue componentsSeparatedByString:@"\n"] mutableCopy];
		[files removeObject:@""];
		files = [files arrayByPerformingSelector:@selector(stringByStandardizingPath)];
		//NSString *path = [stringValue stringByStandardizingPath];
		//NSLog(@"%@", files);
		NSInteger line = -1;
		if ([files count]) {
			NSString *path = [files objectAtIndex:0];
			NSArray *extComp = [[path pathExtension] componentsSeparatedByString:@":"];
			if ([extComp count] == 2) {
				line = [[extComp lastObject] integerValue];
				files = [NSMutableArray arrayWithObject:[path substringToIndex:[path length] -1-[[extComp lastObject] length]]];
				//NSLog(@"files %@", files);
			}
		}
		if ([[NSFileManager defaultManager] filesExistAtPaths:files]) {
			if (line >= 0) {
				[self setObject:[NSDictionary dictionaryWithObjectsAndKeys:[files lastObject] , @"path", [NSNumber numberWithInteger:line] , @"line", nil] forType:@"QSLineReferenceType"];
			}
            // wipe existing types and set this up as a file
			/* FIXME: Just after doing a bunch of QSLineReferenceType things above ? */
            [[self dataDictionary] removeAllObjects];
			[self setObject:files forType:QSFilePathType];
			[self setPrimaryType:QSFilePathType];
			// set an appropriate name based on the files
			[self getNameFromFiles];
		}
		return;
	}
	// It's a file URL
	if ([stringValue hasPrefix:@"file://"]) {
		NSURL *fileURL = [NSURL URLWithString:stringValue];
		if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            // wipe existing types and set this up as a file
            [[self dataDictionary] removeAllObjects];
			[self setObject:[fileURL path] forType:QSFilePathType];
			[self setPrimaryType:QSFilePathType];
			[self getNameFromFiles];
			return;
		}
	}
	
	// trimWhitespace calls a CFStringTrimWhitespace to remove whitespace from start and end of string
	stringValue = [stringValue trimWhitespace];
	

    // JavaScript
	if ([stringValue hasPrefix:@"javascript:"]) {
		[self assignURLTypesWithURL:stringValue];
		return;
	}
    // returns YES if a valid URL is assigned to the object
    if ([self sniffURL:stringValue]) {
        return;
    }
	return;
}

-(BOOL)sniffURL:(NSString*)stringValue {
    // array used to store list of TLDs
	static NSArray *tldArray = nil;
    // replace \%s with *** for Query URLs
	NSString *urlString = [self cleanQueryURL:stringValue];
    
    // @ sign but NO /, -> email address
    if (([stringValue rangeOfString:@"@"] .location != NSNotFound && [stringValue rangeOfString:@"/"].location == NSNotFound)) {
        // no spaces are allowed anywhere in email addresses
        if ([stringValue rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
            return NO;
        }
        NSArray *components = [stringValue componentsSeparatedByString:@"@"];
        if ([components count] > 2 || ![[components objectAtIndex:0] length] || ![[components lastObject] length]) {
            // only one @ symbol allowed in email addresses, and both parts must have a length
            return NO;
        }
        NSArray *hostParts = [[components lastObject] componentsSeparatedByString:@"."];
        NSIndexSet *emptyHostParts = [hostParts indexesOfObjectsWithOptions:NSEnumerationConcurrent passingTest:^BOOL(NSString *part, NSUInteger idx, BOOL *stop) {
            return [part length] == 0;
        }];
        if ([emptyHostParts count]) {
            return NO;
        }
        NSString *preAtString = [components objectAtIndex:0];
        if ([stringValue hasPrefix:@"mailto:"]) {
            stringValue = [stringValue substringFromIndex:@"mailto:".length];
            preAtString = [[components objectAtIndex:0] substringFromIndex:@"mailto:".length];
        }
        if (![preAtString length]) {
            return NO;
        }
        [self assignURLTypesWithURL:[@"mailto:" stringByAppendingString:stringValue]];
        return YES;
    } else {
        // FQDN and URL checks
        NSRange schemeRange = [stringValue rangeOfString:@"://"];
        NSString *scheme = nil;
        if (schemeRange.location != NSNotFound) {
            scheme = [stringValue substringToIndex:schemeRange.location];
            if ([scheme rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
                // spaces are not allowed in a valid URL scheme
                return NO;
            }
            // remove the scheme from the URL. Makes deciphering the URL easier (less colons)
            stringValue = [stringValue substringFromIndex:schemeRange.location +schemeRange.length];
        }
        
        // allow "qsapp/" to turn into "http://www.qsapp.com/" as in Safari's address bar
        if ([stringValue hasSuffix:@"/"]) {
            NSString *withoutSlash = [stringValue substringToIndex:[stringValue length] - 1];
            if (![withoutSlash hasPrefix:@"-"] && ![withoutSlash hasSuffix:@"-"]) {
                // can't begin or end with '-', but can contain it
                NSString *dehyphenated = [withoutSlash stringByReplacingOccurrencesOfString:@"-" withString:@""];
                if ([dehyphenated containsOnlyCharactersFromSet:[NSCharacterSet alphanumericCharacterSet]]) {
                    // valid domain name
                    NSString *urlTemplate = NSLocalizedString(@"http://www.%@.com/", @"Typical URL for this locale");
                    NSString *urlValue = [NSString stringWithFormat:urlTemplate, withoutSlash];
                    [self assignURLTypesWithURL:urlValue];
                    // preserve the original text
                    [self setObject:stringValue forType:QSTextType];
                }
            }
        }
        
        NSArray *colonComponents = [[[stringValue componentsSeparatedByString:@"/"] objectAtIndex:0] componentsSeparatedByString:@":"];
        // Charset containing everything but decimal digits
        NSCharacterSet *nonNumbersSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
        
        if ([colonComponents count] > 2) {
            // only host:port should be valid
            return NO;
        }
        if ([colonComponents count] == 2) {
            // Check the port (if it exists). URLs may contain multiple colons, so we take the first occurance of it. e.g. http://google.com:80/?q=this_is_a_:
            NSString *port = [colonComponents objectAtIndex:1];
            if ([port length] == 0 || [port rangeOfCharacterFromSet:nonNumbersSet].location != NSNotFound) {
                return NO;
            }
        }
        NSString *host = [colonComponents objectAtIndex:0];

        NSArray *components = [host componentsSeparatedByString:@"."];
        if ([host rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound || ![[components objectAtIndex:0] length]) {
            // Valid hosts must have no spaces, and must not be empty
            return NO;
        }
        if (([components count] == 1 && scheme) || [host isEqualToString:@"localhost"]) {
            // the string is a hostname URL. e.g. http://hostname, or the special case 'localhost'
            [self assignURLTypesWithURL:urlString];
            [self setObject:host forType:QSRemoteHostsType];
            return YES;
        }
        if ([components count] == 1) {
            return NO;
        }
        // initialise a static array of TLDs
        if(tldArray == nil) {
            tldArray = @[@"LOCAL", @"AC", @"AD", @"AE", @"AERO", @"AF", @"AG", @"AI", @"AL", @"AM", @"AN", @"AO", @"AQ", @"AR", @"ARPA", @"AS", @"ASIA", @"AT", @"AU", @"AW", @"AX", @"AZ", @"BA", @"BB", @"BD", @"BE", @"BF", @"BG", @"BH", @"BI", @"BIZ", @"BJ", @"BM", @"BN", @"BO", @"BR", @"BS", @"BT", @"BV", @"BW", @"BY", @"BZ", @"CA", @"CAT", @"CC", @"CD", @"CF", @"CG", @"CH", @"CI", @"CK", @"CL", @"CM", @"CN", @"CO", @"COM", @"COOP", @"CR", @"CU", @"CV", @"CW", @"CX", @"CY", @"CZ", @"DE", @"DJ", @"DK", @"DM", @"DO", @"DZ", @"EC", @"EDU", @"EE", @"EG", @"ER", @"ES", @"ET", @"EU", @"FI", @"FJ", @"FK", @"FM", @"FO", @"FR", @"GA", @"GB", @"GD", @"GE", @"GF", @"GG", @"GH", @"GI", @"GL", @"GM", @"GN", @"GOV", @"GP", @"GQ", @"GR", @"GS", @"GT", @"GU", @"GW", @"GY", @"HK", @"HM", @"HN", @"HR", @"HT", @"HU", @"ID", @"IE", @"IL", @"IM", @"IN", @"INFO", @"INT", @"IO", @"IQ", @"IR", @"IS", @"IT", @"JE", @"JM", @"JO", @"JOBS", @"JP", @"KE", @"KG", @"KH", @"KI", @"KM", @"KN", @"KP", @"KR", @"KW", @"KY", @"KZ", @"LA", @"LB", @"LC", @"LI", @"LK", @"LR", @"LS", @"LT", @"LU", @"LV", @"LY", @"MA", @"MC", @"MD", @"ME", @"MG", @"MH", @"MIL", @"MK", @"ML", @"MM", @"MN", @"MO", @"MOBI", @"MP", @"MQ", @"MR", @"MS", @"MT", @"MU", @"MUSEUM", @"MV", @"MW", @"MX", @"MY", @"MZ", @"NA", @"NAME", @"NC", @"NE", @"NET", @"NF", @"NG", @"NI", @"NL", @"NO", @"NP", @"NR", @"NU", @"NZ", @"OM", @"ORG", @"PA", @"PE", @"PF", @"PG", @"PH", @"PK", @"PL", @"PM", @"PN", @"POST", @"PR", @"PRO", @"PS", @"PT", @"PW", @"PY", @"QA", @"RE", @"RO", @"RS", @"RU", @"RW", @"SA", @"SB", @"SC", @"SD", @"SE", @"SG", @"SH", @"SI", @"SJ", @"SK", @"SL", @"SM", @"SN", @"SO", @"SR", @"ST", @"SU", @"SV", @"SX", @"SY", @"SZ", @"TC", @"TD", @"TEL", @"TF", @"TG", @"TH", @"TJ", @"TK", @"TL", @"TM", @"TN", @"TO", @"TP", @"TR", @"TRAVEL", @"TT", @"TV", @"TW", @"TZ", @"UA", @"UG", @"UK", @"US", @"UY", @"UZ", @"VA", @"VC", @"VE", @"VG", @"VI", @"VN", @"VU", @"WF", @"WS", @"XN--0ZWM56D", @"XN--11B5BS3A9AJ6G", @"XN--3E0B707E", @"XN--45BRJ9C", @"XN--80AKHBYKNJ4F", @"XN--80AO21A", @"XN--90A3AC", @"XN--9T4B11YI5A", @"XN--CLCHC0EA0B2G2A9GCD", @"XN--DEBA0AD", @"XN--FIQS8S", @"XN--FIQZ9S", @"XN--FPCRJ9C3D", @"XN--FZC2C9E2C", @"XN--G6W251D", @"XN--GECRJ9C", @"XN--H2BRJ9C", @"XN--HGBK6AJ7F53BBA", @"XN--HLCJ6AYA9ESC7A", @"XN--J1AMH", @"XN--J6W193G", @"XN--JXALPDLP", @"XN--KGBECHTV", @"XN--KPRW13D", @"XN--KPRY57D", @"XN--LGBBAT1AD8J", @"XN--MGB9AWBF", @"XN--MGBAAM7A8H", @"XN--MGBAYH7GPA", @"XN--MGBBH1A71E", @"XN--MGBC0A9AZCG", @"XN--MGBERP4A5D4AR", @"XN--MGBX4CD0AB", @"XN--O3CW4H", @"XN--OGBPF8FL", @"XN--P1AI", @"XN--PGBS0DH", @"XN--S9BRJ9C", @"XN--WGBH1C", @"XN--WGBL6A", @"XN--XKC2AL3HYE2A", @"XN--XKC2DL3A5EE0H", @"XN--YFRO4I67O", @"XN--YGBI2AMMX", @"XN--ZCKZAH", @"XXX", @"YE", @"YT", @"ZA", @"ZM", @"ZW"];
        }
        // check if the last component of the string is a tld
        if([tldArray containsObject:[[components lastObject] uppercaseString]]) {
            [self assignURLTypesWithURL:urlString];
            [self setObject:host forType:QSRemoteHostsType];
            return YES;
        }
        // Check if the string is an IP address (e.g. 192.168.1.1)
        if ([components count] == 4) {
            BOOL isValidIPAddress = TRUE;
            // more efficient to enumerate backwards - last components is often empty when user types '192.168.1.'
            for (NSString *subPart in [components reverseObjectEnumerator]) {
                // Ensure each part (Separated by '.' is only 3 or less digits
                if (![subPart length] || [subPart length] > 3 || [subPart  rangeOfCharacterFromSet:nonNumbersSet].location != NSNotFound) {
                    isValidIPAddress = FALSE;
                    break;
                }
            }
            if (isValidIPAddress) {
                [self assignURLTypesWithURL:urlString];
                [self setObject:host forType:QSRemoteHostsType];
                return YES;
            }
        }
    }
    return NO;
}

- (NSString *)stringValue {
    id stringValue = [self objectForType:QSTextType];
    if ([stringValue isKindOfClass:[NSData class]]) {
        stringValue = [[NSString alloc] initWithData:stringValue encoding:NSUTF8StringEncoding];
    }
	if ([self count] > 1) {
		QSObject *obj = [self resolvedObject];
		// get the string value for each object in the collection
		/* NOTE: getting the splti objects directly from cache may return `nil` in some instances
				 This avoids an infinite loop as exhibited in #2242, but it may cause unexpected behaviour in certain cases
		 */
		stringValue = [[[obj objectForCache:kQSObjectComponents] arrayByPerformingSelector:@selector(stringValue)] componentsJoinedByString:@"\n"];
	}
    if (!stringValue) {
        // Backwards compatibility
        stringValue = [self objectForType:NSStringPboardType];
    }
    if (!stringValue && [self containsType:QSURLType]) {
        stringValue = [self objectForType:QSURLType];
    }
    if (!stringValue) {
        stringValue = [self displayName];
    }
    if (!stringValue) {
        QSCatalogEntry *theEntry = [[QSLibrarian sharedInstance] firstEntryContainingObject:self];
        NSString *entryName = [theEntry name];
        if (!entryName) {
            entryName = NSLocalizedString(@"Unknown Source", @"The entry that created this object is unknown");
        }
        NSString *localizedStringFormat = NSLocalizedString(@"Unnamed Item from %@", @"Unable to dtermine a name for this object");
        stringValue = [NSString stringWithFormat:localizedStringFormat, entryName];
        NSLog(@"No string value could be determined for object with ID %@ from %@", [self identifier], entryName);
    }
    return stringValue;
}

@end
