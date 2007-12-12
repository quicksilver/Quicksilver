
#import "QSFileConflictPanel.h"
#import "QSApp.h"
#import "QSImageAndTextCell.h"

@implementation QSFileConflictPanel

+ (QSFileConflictPanel *)conflictPanel {
	return (QSFileConflictPanel *)[[[[NSWindowController alloc] initWithWindowNibName:@"QSFileConflictPanel"] autorelease] window];
}

- (void)awakeFromNib {
	[nameTable setRowHeight:17];
	QSImageAndTextCell *imageAndTextCell = [[QSImageAndTextCell alloc] init];
	[imageAndTextCell setEditable:YES];
	[imageAndTextCell setWraps:NO];
	if ([(QSApp*)NSApp devLevel])
		[smartReplaceButton setHidden:0];
	[[[nameTable tableColumns] objectAtIndex:0] setDataCell:imageAndTextCell];
	[imageAndTextCell release];
}

- (int)runModal {
//	[self makeKeyAndOrderFront:self];
	[NSApp runModalForWindow:self];
	[self orderOut:nil];
	return method;
}

- (int)runModalAsSheetOnWindow:(NSWindow *)window {
	[NSApp beginSheet:self modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
	[NSApp runModalForWindow:self];
	[NSApp endSheet:self];
	[self orderOut:nil];
	return method;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)theReturnCode contextInfo:(void *)contextInfo {
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

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	return [[conflictNames objectAtIndex:rowIndex] lastPathComponent];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	[(QSImageAndTextCell*)aCell setImage:[[NSWorkspace sharedWorkspace] iconForFile:[conflictNames objectAtIndex:rowIndex]]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [conflictNames count];
}

- (NSArray *)conflictNames { return conflictNames;  }
- (void)setConflictNames:(NSArray *)newConflictNames {
	[conflictNames release];
	conflictNames = [newConflictNames retain];
	[nameTable reloadData];
}

- (void)dealloc {
	[conflictNames release];
	[super dealloc];
}

@end
