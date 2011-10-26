
#define kQSUserAgent [NSString stringWithFormat:@"Quicksilver %@ (Mac OS X %@)",\
					 (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey),\
					 [NSApplication macOSXFullVersion]]

#define QUERY_KEY @"***"