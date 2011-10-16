
#define kQSUserAgent [NSString stringWithFormat:@"Quicksilver %@ (Mac OS X %@)",\
					 (NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey),\
					 [NSApplication macOSXFullVersion]]

#define QUERY_KEY @"***"

// Name of the faulty plugin that caused Quicksilver to crash (for user alert)
#define kQSPluginCausedCrashAtLaunch @"QSFaultyPluginName"
// Path of faulty plugin (for deletion purposes)
#define kQSFaultPluginPath @"QSFaultyPluginPath"