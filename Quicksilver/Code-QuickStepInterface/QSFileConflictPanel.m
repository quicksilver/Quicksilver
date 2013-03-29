
#import "QSFileConflictPanel.h"
#import "QSApp.h"
#import "QSImageAndTextCell.h"

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
//	[self makeKeyAndOrderFront:self];
	[NSApp runModalForWindow:self];
	[self orderOut:nil];
	return method;
}

- (QSFileConflictResolutionMethod)runModalAsSheetOnWindow:(NSWindow *)window {
//    [self makeKeyAndOrderFront:window];
	[NSApp beginSheet:self modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[NSApp runModalForWindow:self];
	[NSApp endSheet:self];
	[self orderOut:nil];
	return method;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)theReturnCode contextInfo:(void *)contextInfo {
	[NSApp stopModal];
}
- (void)cancel:(id)sender {
	[NSApp stopModal];
}
- (void)replace:(id)sender {
	if (sender == smartReplaceButton)
		method = QSSmartReplaceFilesResolution;
	else if (sender == dontReplaceButton)
		method = QSDontReplaceFilesResolution;
	else if (sender == replaceButton)
		method = QSReplaceFilesResolution;

	[NSApp stopModal];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return [[conflictNames objectAtIndex:rowIndex] lastPathComponent];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	[(QSImageAndTextCell*)aCell setImage:[[NSWorkspace sharedWorkspace] iconForFile:[conflictNames objectAtIndex:rowIndex]]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [conflictNames count];
}

- (NSArray *)conflictNames { return conflictNames;  }
- (void)setConflictNames:(NSArray *)newConflictNames {
	conflictNames = newConflictNames;
	[nameTable reloadData];
}


@end
