

#import "QSFileConflictPanel.h"
#import "QSImageAndTextCell.h"


@implementation QSFileConflictPanel

+ (QSFileConflictPanel *)conflictPanel{
    NSWindowController *wc=[[[NSWindowController alloc] initWithWindowNibName:@"QSFileConflictPanel"]autorelease];
    //QSLog(@"wc %@ %@",wc,[wc window]);
    return (QSFileConflictPanel *)[wc window];

}

- (void)awakeFromNib{
    QSImageAndTextCell *imageAndTextCell = nil;
    [nameTable setRowHeight:17];
    imageAndTextCell = [[[QSImageAndTextCell alloc] init] autorelease];
    [imageAndTextCell setEditable: YES];
    [imageAndTextCell setWraps:NO];
    
    [[[nameTable tableColumns]objectAtIndex:0] setDataCell:imageAndTextCell];   
}

- (int)runModal{
    [self makeKeyAndOrderFront:self];
    [NSApp runModalForWindow:self];
    [self orderOut:nil];
    return method;
}
- (int)runModalAsSheetOnWindow:(NSWindow *)window{
    [NSApp beginSheet:self
        modalForWindow:window
         modalDelegate:self
        didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
           contextInfo:nil];
    [NSApp runModalForWindow:self];
    [NSApp endSheet:self];
    [self orderOut:nil];
    // QSLog(@"Result: %d",method);
    return method;
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)theReturnCode contextInfo:(void *)contextInfo{
    [NSApp stopModal];
}


- (void)cancel:(id)sender{
    [NSApp stopModal];
}
- (void)replace:(id)sender{
    if (sender==smartReplaceButton)
        method=QSSmartReplaceFilesResolution;
    else if (sender==dontReplaceButton)
        method=QSDontReplaceFilesResolution;
    else if (sender==replaceButton)
        method=QSReplaceFilesResolution;
    
    [NSApp stopModal];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
    return [[conflictNames objectAtIndex:rowIndex]lastPathComponent];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
    NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    NSString *file=[conflictNames objectAtIndex:rowIndex];
    //QSLog(@"x %@ %@",file,aCell);
    [(QSImageAndTextCell*)aCell setImage: [workspace iconForFile:file]];        
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView{
    return [conflictNames count];
}

- (NSArray *)conflictNames { return [[conflictNames retain] autorelease]; }

- (void)setConflictNames:(NSArray *)newConflictNames {
    [conflictNames release];
    conflictNames = [newConflictNames retain];
    [nameTable reloadData];
}

@end
