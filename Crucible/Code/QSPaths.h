#define pTriggerSettings	QSApplicationSupportSubPath(@"Triggers.plist",NO)
#define pCatalogSettings	QSApplicationSupportSubPath(@"Catalog.plist",NO)
#define pCatalogPresetsDebugLocation QSApplicationSupportSubPath(@"Presets.plist",NO)
#define pMnemonicStorage	QSApplicationSupportSubPath(@"Mnemonics.plist",NO)
#define pCacheLocation		QSApplicationSupportSubPath(@"Caches/",NO)
#define pIndexLocation		[@"~/Library/Caches/com.blacktree.Quicksilver/Catalog Indexes/" stringByStandardizingPath]
//QSApplicationSupportSubPath(@"Indexes",NO)
//[ stringByStandardizingPath]
//
#define pShelfLocation		QSApplicationSupportSubPath(@"Shelves/",NO)

#define psMainPlugInsLocation QSApplicationSupportSubPath(@"PlugIns/",NO)
#define psMainPlugInsToInstallLocation QSApplicationSupportSubPath(@"PlugIns/Incoming/",NO)

#define kCurrentVersionURL		@"http://quicksilver.blacktree.com/versioncheck.php?type=rel"
#define kCurrentDevVersionURL	@"http://quicksilver.blacktree.com/versioncheck.php?type=dev"
#define kCurrentPreVersionURL	@"http://quicksilver.blacktree.com/versioncheck.php?type=pre"
#define kDownloadUpdateExactURL @"http://quicksilver.blacktree.com/versiondownloadurl.txt"
#define kDownloadUpdateURL      @"http://quicksilver.blacktree.com/"
#define kForumsURL              @"http://forums.blacktree.com/index.php?c=2"
#define kBugsURL                @"http://bugs.blacktree.com/"
#define kHelpURL                @"http://docs.blacktree.com/"
#define kIRCURL                 @"irc://irc.freenode.net/quicksilver"

NSString *QSApplicationSupportPath( void );
NSString *QSApplicationSupportSubPath( NSString *subpath, BOOL create );