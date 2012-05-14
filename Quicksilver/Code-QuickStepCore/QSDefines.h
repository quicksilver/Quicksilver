
#define kQSUserAgent [NSString stringWithFormat:@"Quicksilver/%@ OSX/%@ (%@)",\
					 (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey),\
					 [NSApplication macOSXFullVersion], @"x86"]

#define QUERY_KEY @"***"
#define kQSResultArrayKey @"resultArray"
