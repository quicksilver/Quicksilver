

#import <AppKit/AppKit.h>

enum QSFileConflictResolutionMethod {
    QSCancelReplaceResolution, QSReplaceFilesResolution, QSDontReplaceFilesResolution, QSSmartReplaceFilesResolution
};

@interface QSFileConflictPanel : NSPanel {
    IBOutlet NSTableView *nameTable;
    NSArray *conflictNames;
    int method;
    
    IBOutlet NSButton *smartReplaceButton;
    IBOutlet NSButton *dontReplaceButton;
    IBOutlet NSButton *replaceButton;
}
+ (QSFileConflictPanel *)conflictPanel;
- (int)runModal;
- (IBAction)cancel:(id)sender;
- (IBAction)replace:(id)sender;

- (NSArray *)conflictNames;
- (void)setConflictNames:(NSArray *)newConflictNames;
- (int)runModalAsSheetOnWindow:(NSWindow *)window;

@end
