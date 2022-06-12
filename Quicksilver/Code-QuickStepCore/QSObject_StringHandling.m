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

+ (id)objectWithString:(NSString *)string shouldSniff:(BOOL)shouldSniff {
    return [(QSObject *)[QSObject alloc] initWithString:string shouldSniff:shouldSniff];
}

+ (id)objectWithString:(NSString *)string {
	return [(QSObject *)[QSObject alloc] initWithString:string shouldSniff:YES];
}

- (id)initWithString:(NSString *)string {
	return [(QSObject *)[QSObject alloc] initWithString:string shouldSniff:YES];
}

- (id)initWithString:(NSString *)string shouldSniff:(BOOL)shouldSniff {
    if (![string length]) {
        return nil;
    }
	if (self = [self init]) {
		[data setObject:string forKey:QSTextType];
		[self setName:string];
		[self setPrimaryType:QSTextType];
		if (shouldSniff) {
			[self sniffString];
		}
	}
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
			tldArray = @[@"LOCAL", @"AAA", @"AARP", @"ABARTH", @"ABB", @"ABBOTT", @"ABBVIE", @"ABC", @"ABLE", @"ABOGADO", @"ABUDHABI", @"AC", @"ACADEMY", @"ACCENTURE", @"ACCOUNTANT", @"ACCOUNTANTS", @"ACO", @"ACTOR", @"AD", @"ADAC", @"ADS", @"ADULT", @"AE", @"AEG", @"AERO", @"AETNA", @"AF", @"AFAMILYCOMPANY", @"AFL", @"AFRICA", @"AG", @"AGAKHAN", @"AGENCY", @"AI", @"AIG", @"AIGO", @"AIRBUS", @"AIRFORCE", @"AIRTEL", @"AKDN", @"AL", @"ALFAROMEO", @"ALIBABA", @"ALIPAY", @"ALLFINANZ", @"ALLSTATE", @"ALLY", @"ALSACE", @"ALSTOM", @"AM", @"AMERICANEXPRESS", @"AMERICANFAMILY", @"AMEX", @"AMFAM", @"AMICA", @"AMSTERDAM", @"ANALYTICS", @"ANDROID", @"ANQUAN", @"ANZ", @"AO", @"AOL", @"APARTMENTS", @"APP", @"APPLE", @"AQ", @"AQUARELLE", @"AR", @"ARAB", @"ARAMCO", @"ARCHI", @"ARMY", @"ARPA", @"ART", @"ARTE", @"AS", @"ASDA", @"ASIA", @"ASSOCIATES", @"AT", @"ATHLETA", @"ATTORNEY", @"AU", @"AUCTION", @"AUDI", @"AUDIBLE", @"AUDIO", @"AUSPOST", @"AUTHOR", @"AUTO", @"AUTOS", @"AVIANCA", @"AW", @"AWS", @"AX", @"AXA", @"AZ", @"AZURE", @"BA", @"BABY", @"BAIDU", @"BANAMEX", @"BANANAREPUBLIC", @"BAND", @"BANK", @"BAR", @"BARCELONA", @"BARCLAYCARD", @"BARCLAYS", @"BAREFOOT", @"BARGAINS", @"BASEBALL", @"BASKETBALL", @"BAUHAUS", @"BAYERN", @"BB", @"BBC", @"BBT", @"BBVA", @"BCG", @"BCN", @"BD", @"BE", @"BEATS", @"BEAUTY", @"BEER", @"BENTLEY", @"BERLIN", @"BEST", @"BESTBUY", @"BET", @"BF", @"BG", @"BH", @"BHARTI", @"BI", @"BIBLE", @"BID", @"BIKE", @"BING", @"BINGO", @"BIO", @"BIZ", @"BJ", @"BLACK", @"BLACKFRIDAY", @"BLOCKBUSTER", @"BLOG", @"BLOOMBERG", @"BLUE", @"BM", @"BMS", @"BMW", @"BN", @"BNL", @"BNPPARIBAS", @"BO", @"BOATS", @"BOEHRINGER", @"BOFA", @"BOM", @"BOND", @"BOO", @"BOOK", @"BOOKING", @"BOSCH", @"BOSTIK", @"BOSTON", @"BOT", @"BOUTIQUE", @"BOX", @"BR", @"BRADESCO", @"BRIDGESTONE", @"BROADWAY", @"BROKER", @"BROTHER", @"BRUSSELS", @"BS", @"BT", @"BUDAPEST", @"BUGATTI", @"BUILD", @"BUILDERS", @"BUSINESS", @"BUY", @"BUZZ", @"BV", @"BW", @"BY", @"BZ", @"BZH", @"CA", @"CAB", @"CAFE", @"CAL", @"CALL", @"CALVINKLEIN", @"CAM", @"CAMERA", @"CAMP", @"CANCERRESEARCH", @"CANON", @"CAPETOWN", @"CAPITAL", @"CAPITALONE", @"CAR", @"CARAVAN", @"CARDS", @"CARE", @"CAREER", @"CAREERS", @"CARS", @"CARTIER", @"CASA", @"CASE", @"CASEIH", @"CASH", @"CASINO", @"CAT", @"CATERING", @"CATHOLIC", @"CBA", @"CBN", @"CBRE", @"CBS", @"CC", @"CD", @"CEB", @"CENTER", @"CEO", @"CERN", @"CF", @"CFA", @"CFD", @"CG", @"CH", @"CHANEL", @"CHANNEL", @"CHARITY", @"CHASE", @"CHAT", @"CHEAP", @"CHINTAI", @"CHRISTMAS", @"CHROME", @"CHRYSLER", @"CHURCH", @"CI", @"CIPRIANI", @"CIRCLE", @"CISCO", @"CITADEL", @"CITI", @"CITIC", @"CITY", @"CITYEATS", @"CK", @"CL", @"CLAIMS", @"CLEANING", @"CLICK", @"CLINIC", @"CLINIQUE", @"CLOTHING", @"CLOUD", @"CLUB", @"CLUBMED", @"CM", @"CN", @"CO", @"COACH", @"CODES", @"COFFEE", @"COLLEGE", @"COLOGNE", @"COM", @"COMCAST", @"COMMBANK", @"COMMUNITY", @"COMPANY", @"COMPARE", @"COMPUTER", @"COMSEC", @"CONDOS", @"CONSTRUCTION", @"CONSULTING", @"CONTACT", @"CONTRACTORS", @"COOKING", @"COOKINGCHANNEL", @"COOL", @"COOP", @"CORSICA", @"COUNTRY", @"COUPON", @"COUPONS", @"COURSES", @"CR", @"CREDIT", @"CREDITCARD", @"CREDITUNION", @"CRICKET", @"CROWN", @"CRS", @"CRUISE", @"CRUISES", @"CSC", @"CU", @"CUISINELLA", @"CV", @"CW", @"CX", @"CY", @"CYMRU", @"CYOU", @"CZ", @"DABUR", @"DAD", @"DANCE", @"DATA", @"DATE", @"DATING", @"DATSUN", @"DAY", @"DCLK", @"DDS", @"DE", @"DEAL", @"DEALER", @"DEALS", @"DEGREE", @"DELIVERY", @"DELL", @"DELOITTE", @"DELTA", @"DEMOCRAT", @"DENTAL", @"DENTIST", @"DESI", @"DESIGN", @"DEV", @"DHL", @"DIAMONDS", @"DIET", @"DIGITAL", @"DIRECT", @"DIRECTORY", @"DISCOUNT", @"DISCOVER", @"DISH", @"DIY", @"DJ", @"DK", @"DM", @"DNP", @"DO", @"DOCS", @"DOCTOR", @"DODGE", @"DOG", @"DOMAINS", @"DOT", @"DOWNLOAD", @"DRIVE", @"DTV", @"DUBAI", @"DUCK", @"DUNLOP", @"DUNS", @"DUPONT", @"DURBAN", @"DVAG", @"DVR", @"DZ", @"EARTH", @"EAT", @"EC", @"ECO", @"EDEKA", @"EDU", @"EDUCATION", @"EE", @"EG", @"EMAIL", @"EMERCK", @"ENERGY", @"ENGINEER", @"ENGINEERING", @"ENTERPRISES", @"EPSON", @"EQUIPMENT", @"ER", @"ERICSSON", @"ERNI", @"ES", @"ESQ", @"ESTATE", @"ESURANCE", @"ET", @"ETISALAT", @"EU", @"EUROVISION", @"EUS", @"EVENTS", @"EVERBANK", @"EXCHANGE", @"EXPERT", @"EXPOSED", @"EXPRESS", @"EXTRASPACE", @"FAGE", @"FAIL", @"FAIRWINDS", @"FAITH", @"FAMILY", @"FAN", @"FANS", @"FARM", @"FARMERS", @"FASHION", @"FAST", @"FEDEX", @"FEEDBACK", @"FERRARI", @"FERRERO", @"FI", @"FIAT", @"FIDELITY", @"FIDO", @"FILM", @"FINAL", @"FINANCE", @"FINANCIAL", @"FIRE", @"FIRESTONE", @"FIRMDALE", @"FISH", @"FISHING", @"FIT", @"FITNESS", @"FJ", @"FK", @"FLICKR", @"FLIGHTS", @"FLIR", @"FLORIST", @"FLOWERS", @"FLY", @"FM", @"FO", @"FOO", @"FOOD", @"FOODNETWORK", @"FOOTBALL", @"FORD", @"FOREX", @"FORSALE", @"FORUM", @"FOUNDATION", @"FOX", @"FR", @"FREE", @"FRESENIUS", @"FRL", @"FROGANS", @"FRONTDOOR", @"FRONTIER", @"FTR", @"FUJITSU", @"FUJIXEROX", @"FUN", @"FUND", @"FURNITURE", @"FUTBOL", @"FYI", @"GA", @"GAL", @"GALLERY", @"GALLO", @"GALLUP", @"GAME", @"GAMES", @"GAP", @"GARDEN", @"GB", @"GBIZ", @"GD", @"GDN", @"GE", @"GEA", @"GENT", @"GENTING", @"GEORGE", @"GF", @"GG", @"GGEE", @"GH", @"GI", @"GIFT", @"GIFTS", @"GIVES", @"GIVING", @"GL", @"GLADE", @"GLASS", @"GLE", @"GLOBAL", @"GLOBO", @"GM", @"GMAIL", @"GMBH", @"GMO", @"GMX", @"GN", @"GODADDY", @"GOLD", @"GOLDPOINT", @"GOLF", @"GOO", @"GOODYEAR", @"GOOG", @"GOOGLE", @"GOP", @"GOT", @"GOV", @"GP", @"GQ", @"GR", @"GRAINGER", @"GRAPHICS", @"GRATIS", @"GREEN", @"GRIPE", @"GROCERY", @"GROUP", @"GS", @"GT", @"GU", @"GUARDIAN", @"GUCCI", @"GUGE", @"GUIDE", @"GUITARS", @"GURU", @"GW", @"GY", @"HAIR", @"HAMBURG", @"HANGOUT", @"HAUS", @"HBO", @"HDFC", @"HDFCBANK", @"HEALTH", @"HEALTHCARE", @"HELP", @"HELSINKI", @"HERE", @"HERMES", @"HGTV", @"HIPHOP", @"HISAMITSU", @"HITACHI", @"HIV", @"HK", @"HKT", @"HM", @"HN", @"HOCKEY", @"HOLDINGS", @"HOLIDAY", @"HOMEDEPOT", @"HOMEGOODS", @"HOMES", @"HOMESENSE", @"HONDA", @"HONEYWELL", @"HORSE", @"HOSPITAL", @"HOST", @"HOSTING", @"HOT", @"HOTELES", @"HOTELS", @"HOTMAIL", @"HOUSE", @"HOW", @"HR", @"HSBC", @"HT", @"HU", @"HUGHES", @"HYATT", @"HYUNDAI", @"IBM", @"ICBC", @"ICE", @"ICU", @"ID", @"IE", @"IEEE", @"IFM", @"IKANO", @"IL", @"IM", @"IMAMAT", @"IMDB", @"IMMO", @"IMMOBILIEN", @"IN", @"INC", @"INDUSTRIES", @"INFINITI", @"INFO", @"ING", @"INK", @"INSTITUTE", @"INSURANCE", @"INSURE", @"INT", @"INTEL", @"INTERNATIONAL", @"INTUIT", @"INVESTMENTS", @"IO", @"IPIRANGA", @"IQ", @"IR", @"IRISH", @"IS", @"ISELECT", @"ISMAILI", @"IST", @"ISTANBUL", @"IT", @"ITAU", @"ITV", @"IVECO", @"JAGUAR", @"JAVA", @"JCB", @"JCP", @"JE", @"JEEP", @"JETZT", @"JEWELRY", @"JIO", @"JLL", @"JM", @"JMP", @"JNJ", @"JO", @"JOBS", @"JOBURG", @"JOT", @"JOY", @"JP", @"JPMORGAN", @"JPRS", @"JUEGOS", @"JUNIPER", @"KAUFEN", @"KDDI", @"KE", @"KERRYHOTELS", @"KERRYLOGISTICS", @"KERRYPROPERTIES", @"KFH", @"KG", @"KH", @"KI", @"KIA", @"KIM", @"KINDER", @"KINDLE", @"KITCHEN", @"KIWI", @"KM", @"KN", @"KOELN", @"KOMATSU", @"KOSHER", @"KP", @"KPMG", @"KPN", @"KR", @"KRD", @"KRED", @"KUOKGROUP", @"KW", @"KY", @"KYOTO", @"KZ", @"LA", @"LACAIXA", @"LADBROKES", @"LAMBORGHINI", @"LAMER", @"LANCASTER", @"LANCIA", @"LANCOME", @"LAND", @"LANDROVER", @"LANXESS", @"LASALLE", @"LAT", @"LATINO", @"LATROBE", @"LAW", @"LAWYER", @"LB", @"LC", @"LDS", @"LEASE", @"LECLERC", @"LEFRAK", @"LEGAL", @"LEGO", @"LEXUS", @"LGBT", @"LI", @"LIAISON", @"LIDL", @"LIFE", @"LIFEINSURANCE", @"LIFESTYLE", @"LIGHTING", @"LIKE", @"LILLY", @"LIMITED", @"LIMO", @"LINCOLN", @"LINDE", @"LINK", @"LIPSY", @"LIVE", @"LIVING", @"LIXIL", @"LK", @"LLC", @"LOAN", @"LOANS", @"LOCKER", @"LOCUS", @"LOFT", @"LOL", @"LONDON", @"LOTTE", @"LOTTO", @"LOVE", @"LPL", @"LPLFINANCIAL", @"LR", @"LS", @"LT", @"LTD", @"LTDA", @"LU", @"LUNDBECK", @"LUPIN", @"LUXE", @"LUXURY", @"LV", @"LY", @"MA", @"MACYS", @"MADRID", @"MAIF", @"MAISON", @"MAKEUP", @"MAN", @"MANAGEMENT", @"MANGO", @"MAP", @"MARKET", @"MARKETING", @"MARKETS", @"MARRIOTT", @"MARSHALLS", @"MASERATI", @"MATTEL", @"MBA", @"MC", @"MCKINSEY", @"MD", @"ME", @"MED", @"MEDIA", @"MEET", @"MELBOURNE", @"MEME", @"MEMORIAL", @"MEN", @"MENU", @"MERCKMSD", @"METLIFE", @"MG", @"MH", @"MIAMI", @"MICROSOFT", @"MIL", @"MINI", @"MINT", @"MIT", @"MITSUBISHI", @"MK", @"ML", @"MLB", @"MLS", @"MM", @"MMA", @"MN", @"MO", @"MOBI", @"MOBILE", @"MOBILY", @"MODA", @"MOE", @"MOI", @"MOM", @"MONASH", @"MONEY", @"MONSTER", @"MOPAR", @"MORMON", @"MORTGAGE", @"MOSCOW", @"MOTO", @"MOTORCYCLES", @"MOV", @"MOVIE", @"MOVISTAR", @"MP", @"MQ", @"MR", @"MS", @"MSD", @"MT", @"MTN", @"MTR", @"MU", @"MUSEUM", @"MUTUAL", @"MV", @"MW", @"MX", @"MY", @"MZ", @"NA", @"NAB", @"NADEX", @"NAGOYA", @"NAME", @"NATIONWIDE", @"NATURA", @"NAVY", @"NBA", @"NC", @"NE", @"NEC", @"NET", @"NETBANK", @"NETFLIX", @"NETWORK", @"NEUSTAR", @"NEW", @"NEWHOLLAND", @"NEWS", @"NEXT", @"NEXTDIRECT", @"NEXUS", @"NF", @"NFL", @"NG", @"NGO", @"NHK", @"NI", @"NICO", @"NIKE", @"NIKON", @"NINJA", @"NISSAN", @"NISSAY", @"NL", @"NO", @"NOKIA", @"NORTHWESTERNMUTUAL", @"NORTON", @"NOW", @"NOWRUZ", @"NOWTV", @"NP", @"NR", @"NRA", @"NRW", @"NTT", @"NU", @"NYC", @"NZ", @"OBI", @"OBSERVER", @"OFF", @"OFFICE", @"OKINAWA", @"OLAYAN", @"OLAYANGROUP", @"OLDNAVY", @"OLLO", @"OM", @"OMEGA", @"ONE", @"ONG", @"ONL", @"ONLINE", @"ONYOURSIDE", @"OOO", @"OPEN", @"ORACLE", @"ORANGE", @"ORG", @"ORGANIC", @"ORIGINS", @"OSAKA", @"OTSUKA", @"OTT", @"OVH", @"PA", @"PAGE", @"PANASONIC", @"PARIS", @"PARS", @"PARTNERS", @"PARTS", @"PARTY", @"PASSAGENS", @"PAY", @"PCCW", @"PE", @"PET", @"PF", @"PFIZER", @"PG", @"PH", @"PHARMACY", @"PHD", @"PHILIPS", @"PHONE", @"PHOTO", @"PHOTOGRAPHY", @"PHOTOS", @"PHYSIO", @"PIAGET", @"PICS", @"PICTET", @"PICTURES", @"PID", @"PIN", @"PING", @"PINK", @"PIONEER", @"PIZZA", @"PK", @"PL", @"PLACE", @"PLAY", @"PLAYSTATION", @"PLUMBING", @"PLUS", @"PM", @"PN", @"PNC", @"POHL", @"POKER", @"POLITIE", @"PORN", @"POST", @"PR", @"PRAMERICA", @"PRAXI", @"PRESS", @"PRIME", @"PRO", @"PROD", @"PRODUCTIONS", @"PROF", @"PROGRESSIVE", @"PROMO", @"PROPERTIES", @"PROPERTY", @"PROTECTION", @"PRU", @"PRUDENTIAL", @"PS", @"PT", @"PUB", @"PW", @"PWC", @"PY", @"QA", @"QPON", @"QUEBEC", @"QUEST", @"QVC", @"RACING", @"RADIO", @"RAID", @"RE", @"READ", @"REALESTATE", @"REALTOR", @"REALTY", @"RECIPES", @"RED", @"REDSTONE", @"REDUMBRELLA", @"REHAB", @"REISE", @"REISEN", @"REIT", @"RELIANCE", @"REN", @"RENT", @"RENTALS", @"REPAIR", @"REPORT", @"REPUBLICAN", @"REST", @"RESTAURANT", @"REVIEW", @"REVIEWS", @"REXROTH", @"RICH", @"RICHARDLI", @"RICOH", @"RIGHTATHOME", @"RIL", @"RIO", @"RIP", @"RMIT", @"RO", @"ROCHER", @"ROCKS", @"RODEO", @"ROGERS", @"ROOM", @"RS", @"RSVP", @"RU", @"RUGBY", @"RUHR", @"RUN", @"RW", @"RWE", @"RYUKYU", @"SA", @"SAARLAND", @"SAFE", @"SAFETY", @"SAKURA", @"SALE", @"SALON", @"SAMSCLUB", @"SAMSUNG", @"SANDVIK", @"SANDVIKCOROMANT", @"SANOFI", @"SAP", @"SARL", @"SAS", @"SAVE", @"SAXO", @"SB", @"SBI", @"SBS", @"SC", @"SCA", @"SCB", @"SCHAEFFLER", @"SCHMIDT", @"SCHOLARSHIPS", @"SCHOOL", @"SCHULE", @"SCHWARZ", @"SCIENCE", @"SCJOHNSON", @"SCOR", @"SCOT", @"SD", @"SE", @"SEARCH", @"SEAT", @"SECURE", @"SECURITY", @"SEEK", @"SELECT", @"SENER", @"SERVICES", @"SES", @"SEVEN", @"SEW", @"SEX", @"SEXY", @"SFR", @"SG", @"SH", @"SHANGRILA", @"SHARP", @"SHAW", @"SHELL", @"SHIA", @"SHIKSHA", @"SHOES", @"SHOP", @"SHOPPING", @"SHOUJI", @"SHOW", @"SHOWTIME", @"SHRIRAM", @"SI", @"SILK", @"SINA", @"SINGLES", @"SITE", @"SJ", @"SK", @"SKI", @"SKIN", @"SKY", @"SKYPE", @"SL", @"SLING", @"SM", @"SMART", @"SMILE", @"SN", @"SNCF", @"SO", @"SOCCER", @"SOCIAL", @"SOFTBANK", @"SOFTWARE", @"SOHU", @"SOLAR", @"SOLUTIONS", @"SONG", @"SONY", @"SOY", @"SPACE", @"SPORT", @"SPOT", @"SPREADBETTING", @"SR", @"SRL", @"SRT", @"SS", @"ST", @"STADA", @"STAPLES", @"STAR", @"STARHUB", @"STATEBANK", @"STATEFARM", @"STC", @"STCGROUP", @"STOCKHOLM", @"STORAGE", @"STORE", @"STREAM", @"STUDIO", @"STUDY", @"STYLE", @"SU", @"SUCKS", @"SUPPLIES", @"SUPPLY", @"SUPPORT", @"SURF", @"SURGERY", @"SUZUKI", @"SV", @"SWATCH", @"SWIFTCOVER", @"SWISS", @"SX", @"SY", @"SYDNEY", @"SYMANTEC", @"SYSTEMS", @"SZ", @"TAB", @"TAIPEI", @"TALK", @"TAOBAO", @"TARGET", @"TATAMOTORS", @"TATAR", @"TATTOO", @"TAX", @"TAXI", @"TC", @"TCI", @"TD", @"TDK", @"TEAM", @"TECH", @"TECHNOLOGY", @"TEL", @"TELEFONICA", @"TEMASEK", @"TENNIS", @"TEVA", @"TF", @"TG", @"TH", @"THD", @"THEATER", @"THEATRE", @"TIAA", @"TICKETS", @"TIENDA", @"TIFFANY", @"TIPS", @"TIRES", @"TIROL", @"TJ", @"TJMAXX", @"TJX", @"TK", @"TKMAXX", @"TL", @"TM", @"TMALL", @"TN", @"TO", @"TODAY", @"TOKYO", @"TOOLS", @"TOP", @"TORAY", @"TOSHIBA", @"TOTAL", @"TOURS", @"TOWN", @"TOYOTA", @"TOYS", @"TR", @"TRADE", @"TRADING", @"TRAINING", @"TRAVEL", @"TRAVELCHANNEL", @"TRAVELERS", @"TRAVELERSINSURANCE", @"TRUST", @"TRV", @"TT", @"TUBE", @"TUI", @"TUNES", @"TUSHU", @"TV", @"TVS", @"TW", @"TZ", @"UA", @"UBANK", @"UBS", @"UCONNECT", @"UG", @"UK", @"UNICOM", @"UNIVERSITY", @"UNO", @"UOL", @"UPS", @"US", @"UY", @"UZ", @"VA", @"VACATIONS", @"VANA", @"VANGUARD", @"VC", @"VE", @"VEGAS", @"VENTURES", @"VERISIGN", @"VERSICHERUNG", @"VET", @"VG", @"VI", @"VIAJES", @"VIDEO", @"VIG", @"VIKING", @"VILLAS", @"VIN", @"VIP", @"VIRGIN", @"VISA", @"VISION", @"VISTAPRINT", @"VIVA", @"VIVO", @"VLAANDEREN", @"VN", @"VODKA", @"VOLKSWAGEN", @"VOLVO", @"VOTE", @"VOTING", @"VOTO", @"VOYAGE", @"VU", @"VUELOS", @"WALES", @"WALMART", @"WALTER", @"WANG", @"WANGGOU", @"WARMAN", @"WATCH", @"WATCHES", @"WEATHER", @"WEATHERCHANNEL", @"WEBCAM", @"WEBER", @"WEBSITE", @"WED", @"WEDDING", @"WEIBO", @"WEIR", @"WF", @"WHOSWHO", @"WIEN", @"WIKI", @"WILLIAMHILL", @"WIN", @"WINDOWS", @"WINE", @"WINNERS", @"WME", @"WOLTERSKLUWER", @"WOODSIDE", @"WORK", @"WORKS", @"WORLD", @"WOW", @"WS", @"WTC", @"WTF", @"XBOX", @"XEROX", @"XFINITY", @"XIHUAN", @"XIN", @"XN--11B4C3D", @"XN--1CK2E1B", @"XN--1QQW23A", @"XN--2SCRJ9C", @"XN--30RR7Y", @"XN--3BST00M", @"XN--3DS443G", @"XN--3E0B707E", @"XN--3HCRJ9C", @"XN--3OQ18VL8PN36A", @"XN--3PXU8K", @"XN--42C2D9A", @"XN--45BR5CYL", @"XN--45BRJ9C", @"XN--45Q11C", @"XN--4GBRIM", @"XN--54B7FTA0CC", @"XN--55QW42G", @"XN--55QX5D", @"XN--5SU34J936BGSG", @"XN--5TZM5G", @"XN--6FRZ82G", @"XN--6QQ986B3XL", @"XN--80ADXHKS", @"XN--80AO21A", @"XN--80AQECDR1A", @"XN--80ASEHDB", @"XN--80ASWG", @"XN--8Y0A063A", @"XN--90A3AC", @"XN--90AE", @"XN--90AIS", @"XN--9DBQ2A", @"XN--9ET52U", @"XN--9KRT00A", @"XN--B4W605FERD", @"XN--BCK1B9A5DRE4C", @"XN--C1AVG", @"XN--C2BR7G", @"XN--CCK2B3B", @"XN--CG4BKI", @"XN--CLCHC0EA0B2G2A9GCD", @"XN--CZR694B", @"XN--CZRS0T", @"XN--CZRU2D", @"XN--D1ACJ3B", @"XN--D1ALF", @"XN--E1A4C", @"XN--ECKVDTC9D", @"XN--EFVY88H", @"XN--ESTV75G", @"XN--FCT429K", @"XN--FHBEI", @"XN--FIQ228C5HS", @"XN--FIQ64B", @"XN--FIQS8S", @"XN--FIQZ9S", @"XN--FJQ720A", @"XN--FLW351E", @"XN--FPCRJ9C3D", @"XN--FZC2C9E2C", @"XN--FZYS8D69UVGM", @"XN--G2XX48C", @"XN--GCKR3F0F", @"XN--GECRJ9C", @"XN--GK3AT1E", @"XN--H2BREG3EVE", @"XN--H2BRJ9C", @"XN--H2BRJ9C8C", @"XN--HXT814E", @"XN--I1B6B1A6A2E", @"XN--IMR513N", @"XN--IO0A7I", @"XN--J1AEF", @"XN--J1AMH", @"XN--J6W193G", @"XN--JLQ61U9W7B", @"XN--JVR189M", @"XN--KCRX77D1X4A", @"XN--KPRW13D", @"XN--KPRY57D", @"XN--KPU716F", @"XN--KPUT3I", @"XN--L1ACC", @"XN--LGBBAT1AD8J", @"XN--MGB9AWBF", @"XN--MGBA3A3EJT", @"XN--MGBA3A4F16A", @"XN--MGBA7C0BBN0A", @"XN--MGBAAKC7DVF", @"XN--MGBAAM7A8H", @"XN--MGBAB2BD", @"XN--MGBAH1A3HJKRD", @"XN--MGBAI9AZGQP6J", @"XN--MGBAYH7GPA", @"XN--MGBB9FBPOB", @"XN--MGBBH1A", @"XN--MGBBH1A71E", @"XN--MGBC0A9AZCG", @"XN--MGBCA7DZDO", @"XN--MGBERP4A5D4AR", @"XN--MGBGU82A", @"XN--MGBI4ECEXP", @"XN--MGBPL2FH", @"XN--MGBT3DHD", @"XN--MGBTX2B", @"XN--MGBX4CD0AB", @"XN--MIX891F", @"XN--MK1BU44C", @"XN--MXTQ1M", @"XN--NGBC5AZD", @"XN--NGBE9E0A", @"XN--NGBRX", @"XN--NODE", @"XN--NQV7F", @"XN--NQV7FS00EMA", @"XN--NYQY26A", @"XN--O3CW4H", @"XN--OGBPF8FL", @"XN--OTU796D", @"XN--P1ACF", @"XN--P1AI", @"XN--PBT977C", @"XN--PGBS0DH", @"XN--PSSY2U", @"XN--Q9JYB4C", @"XN--QCKA1PMC", @"XN--QXAM", @"XN--RHQV96G", @"XN--ROVU88B", @"XN--RVC1E0AM3E", @"XN--S9BRJ9C", @"XN--SES554G", @"XN--T60B56A", @"XN--TCKWE", @"XN--TIQ49XQYJ", @"XN--UNUP4Y", @"XN--VERMGENSBERATER-CTB", @"XN--VERMGENSBERATUNG-PWB", @"XN--VHQUV", @"XN--VUQ861B", @"XN--W4R85EL8FHU5DNRA", @"XN--W4RS40L", @"XN--WGBH1C", @"XN--WGBL6A", @"XN--XHQ521B", @"XN--XKC2AL3HYE2A", @"XN--XKC2DL3A5EE0H", @"XN--Y9A3AQ", @"XN--YFRO4I67O", @"XN--YGBI2AMMX", @"XN--ZFR164B", @"XXX", @"XYZ", @"YACHTS", @"YAHOO", @"YAMAXUN", @"YANDEX", @"YE", @"YODOBASHI", @"YOGA", @"YOKOHAMA", @"YOU", @"YOUTUBE", @"YT", @"YUN", @"ZA", @"ZAPPOS", @"ZARA", @"ZERO", @"ZIP", @"ZM", @"ZONE", @"ZUERICH", @"ZW"];

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
