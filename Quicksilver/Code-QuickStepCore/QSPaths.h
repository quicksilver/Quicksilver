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
#define pSharedFileListPathTemplate @"~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/%@.sfl"
#define appSupportSubpath @"Application Support/Quicksilver/PlugIns"

#define psMainPlugInsLocation QSApplicationSupportSubPath(@"PlugIns/", NO)
#define psMainPlugInsToInstallLocation QSApplicationSupportSubPath(@"PlugIns/Incoming/", NO)

#define kCheckUpdateURL         @"https://qs0.qsapp.com/plugins/check.php"
#define kDownloadUpdateURL      @"https://qs0.qsapp.com/plugins/download.php"
#define kPluginInfoURL          @"https://qs0.qsapp.com/plugins/info.php"
#define kPluginDownloadURL      @"https://qs0.qsapp.com/plugins/download.php"

#define kForumsURL				@"http://groups.google.com/group/blacktree-quicksilver"
#define kBugsURL				@"https://github.com/quicksilver/Quicksilver/issues"
#define kWebSiteURL             @"https://qsapp.com/"
#define kHelpURL				@"https://qsapp.com/wiki/"
#define kHelpSearchURL			@"https://qsapp.com/w/index.php?title=Special:Search&search=%@&go=Go"
// URL to crash reporter server/script
#define kCrashReporterURL       @"https://qs0.qsapp.com/crashreports/reporter.php"
// Wiki page detailing why we collect crash reports
#define kCrashReportsWikiURL     @"https://qsapp.com/wiki/Crash_Reports"


NSString *QSApplicationSupportSubPath(NSString *subpath, BOOL create);
NSString *QSGetApplicationSupportFolder();