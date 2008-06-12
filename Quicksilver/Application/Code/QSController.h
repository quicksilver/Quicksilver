/* QSController */


//#import <Cocoa/Cocoa.h>

@class QSObjectView;
@class QSActionMatrix;

@class QSWindow;
@class QSMenuWindow;
//@class QSPrefsController;
@class QSObject;

@class QSInterfaceController;
@class QSCatalogController;
//@class QSProcessSwitcher;

extern NSString * QSWindowsShouldHideNotification;


@interface QSController : NSWindowController {
    QSInterfaceController *interfaceController;
   // QSProcessSwitcher *switcherController;
    //QSPrefsController *prefsController;
    QSCatalogController *catalogController;
    NSWindowController *aboutWindowController;
    NSWindowController *quitWindowController;
    NSWindowController *triggerEditor;
    
    NSStatusItem *statusItem;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSMenuItem *preferencesMenu;
    IBOutlet NSWindow *aboutWindow;
    IBOutlet NSTextField *versionField;
    
    NSConnection *controllerConnection; 
    NSConnection *contextConnection;
    NSWindow *splashWindow;
	
    BOOL newVersion;
    BOOL runningSetupAssistant;
    
    NSColor *iconColor;
	NSImage *activatedImage;
	NSImage *runningImage;
	NSConnection *dropletConnection;
	
	NSObject *dropletProxy;
}

- (NSProgressIndicator *)progressIndicator;

- (void)openURL:(NSURL *)url;
- (void)showSplash:sender;

- (void)recompositeIconImages;

- (NSImage *)daedalusImage;

- (void)activateDebugMenu;

- (NSMenu *)statusMenu;
- (NSMenu *)statusMenuWithQuit;

- (void) activateInterface:(id)sender;
- (void) checkForFirstRun;


- (void) receiveObject:(QSObject *)object;
- (QSInterfaceController *) interfaceController;
- (void)setInterfaceController:(QSInterfaceController *) newInterfaceController;


- (NSMenu *)statusMenu;
- (NSColor *)iconColor;
- (void)setIconColor:(NSColor *)newIconColor;

- (void)setupAssistantCompleted:(id)sender;
- (NSImage *)activatedImage;
- (void)setActivatedImage:(NSImage *)newActivatedImage;
- (NSImage *)runningImage;
- (void)setRunningImage:(NSImage *)newRunningImage;
- (NSObject *)dropletProxy;
- (void)setDropletProxy:(NSObject *)newDropletProxy;

@end

@interface QSController (IBActions)
- (IBAction) showAgreement:(id)sender;
- (IBAction) runSetupAssistant:(id)sender;
- (IBAction) reportABug:(id)sender;
- (IBAction) unsureQuit:(id)sender;
- (IBAction) rescanItems:sender;
- (IBAction) forceRescanItems:sender;
- (IBAction) showElementsViewer:(id)sender;
- (IBAction) runSetupAssistant:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (IBAction) showGuide:(id)sender;
- (IBAction) showSettings:(id)sender;
- (IBAction) showCatalog:(id)sender;
- (IBAction) showTriggers:(id)sender;
- (IBAction) showAbout:(id)sender;
- (IBAction) showForums:(id)sender;
- (IBAction) showTaskViewer:(id)sender;
- (IBAction) showReleaseNotes:(id)sender;
- (IBAction) showHelp:(id)sender;
- (IBAction) openIRCChannel:(id)sender;
- (IBAction) donate:(id)sender;
- (IBAction) getMorePlugIns:(id)sender;
@end

@interface QSController (ErrorHandling)
- (void)registerForErrors;
@end



extern QSController *QSCon;