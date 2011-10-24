
#define kQSUserAgent [NSString stringWithFormat:@"Quicksilver/%@ OSX/%@ (%@)",\
					 (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey),\
					 [NSApplication macOSXFullVersion], @"x86"]

#define QUERY_KEY @"***"

// Name of the faulty plugin that caused Quicksilver to crash (for user alert)
#define kQSPluginCausedCrashAtLaunch @"QSFaultyPluginName"
// Path of faulty plugin (for deletion purposes)
#define kQSFaultPluginPath @"QSFaultyPluginPath"
