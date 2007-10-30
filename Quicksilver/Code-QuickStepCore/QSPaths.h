#define pTriggerSettings	QSApplicationSupportSubPath(@"Triggers.plist",NO)
#define pCatalogSettings	QSApplicationSupportSubPath(@"Catalog.plist",NO)
#define pCatalogPresetsDebugLocation QSApplicationSupportSubPath(@"Presets.plist",NO)
#define pMnemonicStorage	QSApplicationSupportSubPath(@"Mnemonics.plist",NO)
#define pCacheLocation		QSApplicationSupportSubPath(@"Caches/",NO)
#define pIndexLocation		[@"~/Library/Caches/Quicksilver/Indexes/" stringByStandardizingPath]
//QSApplicationSupportSubPath(@"Indexes",NO)
//[ stringByStandardizingPath]
//
#define pShelfLocation		QSApplicationSupportSubPath(@"Shelves/",NO)

#define psMainPlugInsLocation QSApplicationSupportSubPath(@"PlugIns/",NO)
#define psMainPlugInsToInstallLocation QSApplicationSupportSubPath(@"PlugIns/Incoming/",NO)

#define kCurrentVersionURL		@"http://qs0.blacktree.com/quicksilver/versioncheck.php?type=rel"
#define kCurrentDevVersionURL	@"http://qs0.blacktree.com/quicksilver/versioncheck.php?type=dev"
#define kCurrentPreVersionURL	@"http://qs0.blacktree.com/quicksilver/versioncheck.php?type=pre"
#define kDownloadUpdateExactURL @"http://qs0.blacktree.com/quicksilver/versiondownloadurl.txt"
#define kDownloadUpdateURL @"http://qs0.blacktree.com/quicksilver/"
#define kForumsURL @"http://forums.blacktree.com/index.php?c=2"
#define kBugsURL @"http://bugs.blacktree.com/"
#define kHelpURL @"http://docs.blacktree.com/"

extern NSString *QSApplicationSupportPath;
NSString *QSApplicationSupportSubPath(NSString *subpath,BOOL create);