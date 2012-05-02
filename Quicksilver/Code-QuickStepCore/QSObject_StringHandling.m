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
    
    NSString * retString = (NSString*)CFStringCreateCopy( kCFAllocatorDefault, theString );
    CFRelease( theString );
    
	return [retString autorelease];
}
@end

@implementation QSStringObjectHandler

- (NSData *)fileRepresentationForObject:(QSObject *)object { return [[object stringValue] dataUsingEncoding:NSUTF8StringEncoding];  }
- (NSString *)filenameForObject:(QSObject *)object {
	NSString *name = [[[object stringValue] lines] objectAtIndex:0];
	return [name stringByAppendingPathExtension:@"txt"];
}
- (BOOL)objectHasChildren:(QSObject *)object { return NO;  }
- (void)setQuickIconForObject:(QSObject *)object { [object setIcon:[[NSWorkspace sharedWorkspace] iconForFileType:@"'clpt'"]];  }
- (BOOL)loadIconForObject:(QSObject *)object { return NO;  }
- (NSString *)identifierForObject:(QSObject *)object { return nil;  }
- (BOOL)loadChildrenForObject:(QSObject *)object { return NO;  }
- (NSString *)detailsOfObject:(QSObject *)object { return nil;  }
@end

@implementation QSObject (StringHandling)

+ (id)objectWithString:(NSString *)string { return [[(QSObject *)[QSObject alloc] initWithString:string] autorelease];  }
- (id)initWithString:(NSString *)string {
    if (![string length]) {
        return nil;
    }
	if (self = [self init]) {
		[data setObject:string forKey:QSTextType];
		[self setName:string];
		[self setPrimaryType:QSTextType];
		[self sniffString];
		[self loadIcon];
	}
	return self;
}

- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type { return [object objectForType:type];  }

- (void)sniffString {
	// array used to store list of TLDs
	static NSArray *tldArray = nil;

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
		NSMutableArray *files = [[[stringValue componentsSeparatedByString:@"\n"] mutableCopy] autorelease];
		[files removeObject:@""];
		files = [files arrayByPerformingSelector:@selector(stringByStandardizingPath)];
		//NSString *path = [stringValue stringByStandardizingPath];
		//NSLog(@"%@", files);
		int line = -1;
		if ([files count]) {
			NSString *path = [files objectAtIndex:0];
			NSArray *extComp = [[path pathExtension] componentsSeparatedByString:@":"];
			if ([extComp count] == 2) {
				line = [[extComp lastObject] intValue];
				files = [NSArray arrayWithObject:[path substringToIndex:[path length] -1-[[extComp lastObject] length]]];
				//NSLog(@"files %@", files);
			}
		}
		if ([[NSFileManager defaultManager] filesExistAtPaths:files]) {
			if (line >= 0) {
				[self setObject:[NSDictionary dictionaryWithObjectsAndKeys:[files lastObject] , @"path", [NSNumber numberWithInt:line] , @"line", nil] forType:@"QSLineReferenceType"];
			}
			[self setObject:files forType:QSFilePathType];
			[self setPrimaryType:QSFilePathType];
			// set an appropriate name based on the files
			[self getNameFromFiles];
		}
		return;
	}
	
	// trimWhitespace calls a CFStringTrimWhitespace to remove whitespace from start and end of string
	stringValue = [stringValue trimWhitespace];
	// Any whitespaces means it's still a string
	if ([stringValue rangeOfString:@" "] .location != NSNotFound) return;
	// replace \%s with *** for Query URLs
	NSString *urlString = [self cleanQueryURL:stringValue];
	// replace all \r with \n
	if ([urlString rangeOfString:@"\n"] .location != NSNotFound || [urlString rangeOfString:@"\r"] .location != NSNotFound) {
		urlString = [[urlString lines] componentsJoinedByString:@""];
	}
	
	// Create a URL with the string make sure to encode any |%<> chars
	NSURL *url = [NSURL URLWithString:[urlString URLEncoding]];

	if ([url scheme] && [url host] && [urlString rangeOfString:@":"].location != 1) {
		[self assignURLTypesWithURL:urlString];
		return;
	}
	
	// Email address
	if ([stringValue hasPrefix:@"mailto:"]) {
		[self assignURLTypesWithURL:stringValue];
		return;
	}	
	
	
	// Text with a '.' (most likely a URL or email address)
	if ([stringValue rangeOfString:@"."] .location != NSNotFound) {
		// @ sign but NO /, -> email address
		if (([stringValue rangeOfString:@"@"] .location != NSNotFound && [stringValue rangeOfString:@"/"] .location == NSNotFound)) {
			[self assignURLTypesWithURL:[@"mailto:" stringByAppendingString:stringValue]];
			return;
		} else {
			// @ sign AND /, -> a URL?
			NSString *host = [[stringValue componentsSeparatedByString:@"/"] objectAtIndex:0];
			NSArray *components = [host componentsSeparatedByString:@"."];
			// Make sure the URL host exists, with no spaces
			if ([host length] && [host rangeOfString:@" "] .location == NSNotFound && [components count]) {
				// initialise a static array of TLDs
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
				// check if the last component of the string is a tld 
				if([tldArray containsObject:[[components lastObject] uppercaseString]]) {
					[self assignURLTypesWithURL:urlString];
					[self setObject:host forType:QSRemoteHostsType];
					return;
				}
				// Check if the string is an IP address (e.g. 192.168.1.1)
				if ([components count] == 4) {
					BOOL isValidIPAddress = TRUE;				
					// Charset containing everything but decimal digits
					NSCharacterSet *nonNumbersSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
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
						return;
					}
				}
			}
		}
	}
	return;
}
	
	
- (NSString *)stringValue {
	if ([self containsType:QSTextType]) {
		return [self objectForType:QSTextType];
	}
	if ([self containsType:QSURLType]) {
		return [self objectForType:QSURLType];
	}
	return [self displayName];
}

@end
