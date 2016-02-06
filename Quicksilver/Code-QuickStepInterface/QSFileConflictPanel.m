
#import "QSFileConflictPanel.h"
#import "QSApp.h"
#import "QSImageAndTextCell.h"

@interface QSFileConflictPanel () <NSTableViewDataSource, NSTableViewDelegate> {
	IBOutlet NSTableView *nameTable;

	IBOutlet NSButton *smartReplaceButton;
	IBOutlet NSButton *dontReplaceButton;
	IBOutlet NSButton *replaceButton;

	NSInteger _method;
}

- (IBAction)cancel:(id)sender;
- (IBAction)replace:(id)sender;

@property (retain) NSMutableArray *mutableConflictNames;

@end

@implementation QSFileConflictPanel

+ (QSFileConflictPanel *)conflictPanel {
	return (QSFileConflictPanel *)[[[NSWindowController alloc] initWithWindowNibName:@"QSFileConflictPanel"] window];
}

- (void)awakeFromNib {
	[nameTable setRowHeight:17];
	QSImageAndTextCell *imageAndTextCell = [[QSImageAndTextCell alloc] init];
	[imageAndTextCell setEditable:YES];
	[imageAndTextCell setWraps:NO];
	[smartReplaceButton setHidden:0];
	[[[nameTable tableColumns] objectAtIndex:0] setDataCell:imageAndTextCell];
}

- (QSFileConflictResolutionMethod)runModal {
	[NSApp runModalForWindow:self];
	[self orderOut:nil];
	return _method;
}

- (QSFileConflictResolutionMethod)runModalAsSheetOnWindow:(NSWindow *)window {
	[NSApp beginSheet:self modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[NSApp runModalForWindow:self];
	[NSApp endSheet:self];
	[self orderOut:nil];
	return _method;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)theReturnCode contextInfo:(void *)contextInfo {
	[NSApp stopModal];
}

- (void)cancel:(id)sender {
	[NSApp stopModal];
}

- (void)replace:(id)sender {
	if (sender == smartReplaceButton)
		_method = QSSmartReplaceFilesResolution;
	else if (sender == dontReplaceButton)
		_method = QSDontReplaceFilesResolution;
	else if (sender == replaceButton)
		_method = QSReplaceFilesResolution;

	[NSApp stopModal];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [self.mutableConflictNames[rowIndex] lastPathComponent];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	[(QSImageAndTextCell*)aCell setImage:[[NSWorkspace sharedWorkspace] iconForFile:self.mutableConflictNames[rowIndex]]];
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return self.allowsRenames;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if (!self.allowsRenames) return;
	NSString *parent = [self.mutableConflictNames[row] stringByDeletingLastPathComponent];
	NSString *path = [parent stringByAppendingPathComponent:object];
	if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[self.mutableConflictNames replaceObjectAtIndex:row withObject:path];
	} else {
		NSBeep();
		[nameTable reloadData];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [self.mutableConflictNames count];
}

- (NSArray *)conflictNames { return [self.mutableConflictNames copy];  }
- (void)setConflictNames:(NSArray *)newConflictNames {
	self.mutableConflictNames = [newConflictNames mutableCopy];
	[nameTable reloadData];
}


@end
