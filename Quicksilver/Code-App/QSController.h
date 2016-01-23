@class QSObject;
@class QSInterfaceController;

@protocol QSDropletHandling
- (void)handlePasteboardDrop:(NSPasteboard *)pb commandPath:(NSString *)path;
@end

@interface QSController : NSWindowController <QSDropletHandling, QSProxyObjectProvider> {
	QSInterfaceController *interfaceController;
	NSWindowController *aboutWindowController, *quitWindowController;
	NSWindow *splashWindow;
	NSStatusItem *statusItem;
	IBOutlet NSMenu *statusMenu;
	NSConnection *controllerConnection, *dropletConnection;
	BOOL versionChanged, runningSetupAssistant;
	NSObject *dropletProxy;
    NSString *crashReportPath;
}

@property (strong) NSString* crashReportPath;

+ (id)sharedInstance;
- (IBAction)runSetupAssistant:(id)sender;
- (NSProgressIndicator *)progressIndicator;
- (IBAction)showPreferences:(id)sender;
- (IBAction)showGuide:(id)sender;
- (IBAction)showPlugins:(id)sender;
- (IBAction)showSettings:(id)sender;
- (IBAction)showCatalog:(id)sender;
- (IBAction)showTriggers:(id)sender;
- (IBAction)showAbout:(id)sender;
- (IBAction)showForums:(id)sender;
- (IBAction)openIRCChannel:(id)sender;
- (IBAction)showTaskViewer:(id)sender;
- (IBAction)showReleaseNotes:(id)sender;

- (IBAction)showHelp:(id)sender;
- (IBAction)getMorePlugIns:(id)sender;

- (void)openURL:(NSURL *)url;
- (void)showSplash:sender;

#ifdef DEBUG
- (void)activateDebugMenu;
#endif

- (NSMenu *)statusMenuWithQuit;
- (void)activateInterface:(id)sender;
- (void)checkForFirstRun;
- (IBAction)rescanItems:sender;
- (IBAction)forceRescanItems:sender;
- (void)receiveObject:(QSObject *)object;
- (IBAction)unsureQuit:(id)sender;
- (QSInterfaceController *)interfaceController;
- (void)setInterfaceController:(QSInterfaceController *)newInterfaceController;

- (void)startMenuExtraConnection;
- (void)setupAssistantCompleted:(id)sender;

- (IBAction)reportABug:(id)sender;

- (NSObject *)dropletProxy;
- (void)setDropletProxy:(NSObject *)newDropletProxy;

- (void)executeCommandAtPath:(NSString *)path;

- (NSString *)crashReportPath;
- (void)showDockIcon;
- (void)clearHistory;

@end

#define QSCon [QSController sharedInstance]
