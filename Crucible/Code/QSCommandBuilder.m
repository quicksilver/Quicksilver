

#import "QSSearchObjectView.h"
#import "QSCommandBuilder.h"
//#import "QSCommand.h"


#import "QSExecutor.h"
@implementation QSCommandBuilder


- (id)init {
    self = [self initWithWindowNibName:@"CommandBuilder"];
    if (self) {
		
    }
    return self;
}
- (void) windowDidLoad{
	[super windowDidLoad];
	
    [dSelector setDropMode:QSSelectDropMode];
	[aSelector setDropMode:QSRejectDropMode];
	[iSelector setDropMode:QSSelectDropMode];
	
}

- (IBAction)hideWindows:(id)sender{
	[NSApp endSheet:[self window]];
}
- (void)searchObjectChanged:(NSNotification*)notif{
	[super searchObjectChanged:notif];
	NSString *description=[[self currentCommand]description];
	[commandView setStringValue:description?description:@""];
	[self setRepresentedCommand:[self currentCommand]];
}
- (NSMutableArray *)rankedActions{
	
	return [QSExec rankedActionsForDirectObject:[dSelector objectValue] indirectObject:[iSelector objectValue] shouldBypass:YES];


//		return [super rankedActions];
}


- (void)updateActions{
	[aSelector setResultArray:nil];
	[aSelector clearObjectValue];
	[self updateActionsNow];
}

- (void)setClearTimer{};
- (void)hideIndirectSelector:(id)sender{
	//[iSelector setHidden:YES];
	[super hideIndirectSelector:sender];
	[iFrame setEnabled:NO];
}
- (void)showIndirectSelector:(id)sender{
	
	[super showIndirectSelector:sender];
	//[iSelector setHidden:NO];
	[iFrame setEnabled:YES];
}

- (IBAction)executeCommand:(id)sender{
	[self save:sender];	
}
- (IBAction)cancel:(id)sender{
	[self setRepresentedCommand:nil];
	[NSApp endSheet:[self window]];
}

- (IBAction)save:(id)sender{	
	[NSApp endSheet:[self window]];
}


- (QSCommand *)representedCommand { return [[representedCommand retain] autorelease]; }

- (void)setRepresentedCommand:(QSCommand *)aRepresentedCommand {
    if (representedCommand != aRepresentedCommand) {
        [representedCommand release];
        representedCommand = [aRepresentedCommand retain];
    }
}

- (void)windowDidResignKey:(NSNotification *)aNotification{
	return;
}
@end
