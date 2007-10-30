

#import <AppKit/AppKit.h>

@class WebView;
@interface QSSetupAssistant : NSWindowController {
    IBOutlet NSTabView *setupTabView;

    IBOutlet NSButton *continueButton;
    IBOutlet NSButton *backButton;
    
	IBOutlet NSView *agreementView;
    IBOutlet NSProgressIndicator *scanProgress;
    
    IBOutlet NSTextField *scanTextField;
    IBOutlet NSTextField *scanStatusField;
    IBOutlet NSTextField *hotKeyField;
	int plugInInfoStatus;
    int step;
    BOOL scanComplete;
    BOOL setupComplete;
	NSDictionary *identifiers;
    IBOutlet NSProgressIndicator *installProgress;
    IBOutlet NSTextField *installTextField;
	BOOL downloadComplete;
	NSMutableDictionary *plugInsToInstall;
	NSMutableDictionary *installedPlugIns;
	NSArray *recommendedPlugIns;
	
    IBOutlet NSArrayController *plugInsController;
	IBOutlet NSPanel *pluginStatusPanel;
	IBOutlet NSProgressIndicator *pluginStatusProgress;
	IBOutlet NSTextField *pluginStatusField;
	
	IBOutlet WebView *gettingStartedView;
	IBOutlet WebView *gettingSupportView;
	
	IBOutlet NSTabView *plugInLoadTabView;
	IBOutlet NSProgressIndicator *plugInLoadProgress;
}
+ (id)sharedInstance;
- (BOOL)run:(id)sender;

- (IBAction)setHotKey:(id)sender;
- (IBAction)downloadPlugIns:(id)sender;
- (IBAction)nextSection:(id)sender;
- (IBAction)prevSection:(id)sender;

- (IBAction)cancelPlugInInstall:(id)sender;

- (IBAction)finish:(id)sender;
- (BOOL)downloadComplete;
- (void)setDownloadComplete:(BOOL)flag;
- (NSArray *)recommendedPlugIns;
- (void)setRecommendedPlugIns:(NSArray *)newRecommendedPlugIns;

- (void)selectedItem:(NSTabViewItem *)item;
- (void)deselectedItem:(NSTabViewItem *)item;

@end
