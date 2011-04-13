#define pTriggerSettings	QSApplicationSupportSubPath(@"Triggers.plist", NO)
#define pCatalogSettings	QSApplicationSupportSubPath(@"Catalog.plist", NO)
#define pCatalogPresetsDebugLocation QSApplicationSupportSubPath(@"Presets.plist", NO)
#define pMnemonicStorage	QSApplicationSupportSubPath(@"Mnemonics.plist", NO)
#define pCacheLocation		QSApplicationSupportSubPath(@"Caches/", NO)
#define pIndexLocation		[@"~/Library/Caches/Quicksilver/Indexes/" stringByStandardizingPath]
#define pShelfLocation		QSApplicationSupportSubPath(@"Shelves/", NO)

#define psMainPlugInsLocation QSApplicationSupportSubPath(@"PlugIns/", NO)
#define psMainPlugInsToInstallLocation QSApplicationSupportSubPath(@"PlugIns/Incoming/", NO)

#define kCheckUpdateURL         @"http://qs0.qsapp.com/versioncheck.php"
#define kDownloadUpdateURL      @"http://qs0.qsapp.com/download.php"
#define kPluginInfoURL          @"http://qs0.blacktree.com/quicksilver/plugins/plugininfo.php"
#define kPluginDownloadURL      @"http://qs0.blacktree.com/quicksilver/plugins/download.php"

#define kForumsURL				@"http://groups.google.com/group/blacktree-quicksilver"
#define kBugsURL				@"https://github.com/quicksilver/Quicksilver/issues"
#define kWebSiteURL             @"http://qsapp.com/"
#define kHelpURL				@"http://qsapp.com/wiki/"
#define kHelpSearchURL			@"http://qsapp.com/w/index.php?title=Special:Search&search=%@&go=Go"

extern NSString *QSApplicationSupportPath;
NSString *QSApplicationSupportSubPath(NSString *subpath, BOOL create);
