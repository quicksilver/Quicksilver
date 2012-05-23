#import <AppKit/AppKit.h>

enum QSFileConflictResolutionMethod {
	QSCancelReplaceResolution, QSReplaceFilesResolution, QSDontReplaceFilesResolution, QSSmartReplaceFilesResolution
};
#if !defined(__cplusplus)
typedef NSInteger QSFileConflictResolutionMethod;
#endif

@interface QSFileConflictPanel : NSPanel {
	IBOutlet NSTableView *nameTable;
	NSArray *conflictNames;
	NSInteger method;

	IBOutlet NSButton *smartReplaceButton;
	IBOutlet NSButton *dontReplaceButton;
	IBOutlet NSButton *replaceButton;
}
+ (QSFileConflictPanel *)conflictPanel;
- (QSFileConflictResolutionMethod) runModal;
- (IBAction)cancel:(id)sender;
- (IBAction)replace:(id)sender;

- (NSArray *)conflictNames;
- (void)setConflictNames:(NSArray *)newConflictNames;
- (QSFileConflictResolutionMethod) runModalAsSheetOnWindow:(NSWindow *)window;

@end
