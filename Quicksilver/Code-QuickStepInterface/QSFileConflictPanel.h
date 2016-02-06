#import <AppKit/AppKit.h>

typedef NS_ENUM(NSUInteger, QSFileConflictResolutionMethod) {
	QSCancelReplaceResolution,
	QSReplaceFilesResolution,
	QSDontReplaceFilesResolution,
	QSSmartReplaceFilesResolution
};

@interface QSFileConflictPanel : NSPanel

+ (QSFileConflictPanel *)conflictPanel;
- (QSFileConflictResolutionMethod)runModal;
- (QSFileConflictResolutionMethod)runModalAsSheetOnWindow:(NSWindow *)window;

@property (retain) NSArray *conflictNames;
@property (assign) BOOL allowsRenames;

@end
