#define pTriggerSettings	QSApplicationSupportSubPath(@"Triggers.plist", NO)
#define pCatalogSettings	QSApplicationSupportSubPath(@"Catalog.plist", NO)
#define pCatalogPresetsDebugLocation QSApplicationSupportSubPath(@"Presets.plist", NO)
#define pMnemonicStorage	QSApplicationSupportSubPath(@"Mnemonics.plist", NO)
#define pCacheLocation		QSApplicationSupportSubPath(@"Caches/", NO)
#define pUpdatePath         QSApplicationSupportSubPath(@"QSAppUpdateFolder", NO)
#define pIndexLocation		[@"~/Library/Caches/Quicksilver/Indexes/" stringByStandardizingPath]
#define pStateLocation		[@"~/Library/Caches/Quicksilver/QuicksilverState.plist" stringByStandardizingPath]
#define pCrashReporterFolder [@"~/Library/Logs/DiagnosticReports" stringByStandardizingPath]
#define pShelfLocation		QSApplicationSupportSubPath(@"Shelves/", NO)
#define pICloudDocumentsPrefix [@"~/Library/Mobile Documents/" stringByStandardizingPath]
#define appSupportSubpath @"Application Support/Quicksilver/PlugIns"

#define psMainPlugInsLocation QSApplicationSupportSubPath(@"PlugIns/", NO)
#define psMainPlugInsToInstallLocation QSApplicationSupportSubPath(@"PlugIns/Incoming/", NO)

#define kCheckUpdateURL         @"http://cdn.qsapp.com/plugins/check.php"
#define kDownloadUpdateURL      @"http://cdn.qsapp.com/plugins/download.php"
#define kPluginInfoURL          @"http://cdn.qsapp.com/plugins/info.php"
#define kPluginDownloadURL      @"http://cdn.qsapp.com/plugins/download.php"

#define kForumsURL				@"http://groups.google.com/group/blacktree-quicksilver"
#define kBugsURL				@"https://github.com/quicksilver/Quicksilver/issues"
#define kWebSiteURL             @"http://qsapp.com/"
#define kHelpURL				@"http://qsapp.com/wiki/"
#define kHelpSearchURL			@"http://qsapp.com/w/index.php?title=Special:Search&search=%@&go=Go"
// URL to crash reporter server/script
#define kCrashReporterURL       @"http://qs0.qsapp.com/crashreports/reporter.php"
// Wiki page detailing why we collect crash reports
#define kCrashReportsWikiURL     @"http://qsapp.com/wiki/Crash_Reports"
#define kReleaseNotesURL        @"http://qsapp.com/changelog.php"

extern NSString *QSApplicationSupportPath;
NSString *QSApplicationSupportSubPath(NSString *subpath, BOOL create);
