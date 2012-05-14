#import "QSCommandBuilder.h"
#import "QSCommand.h"
#import "QSSearchObjectView.h"
#import "QSExecutor.h"

@implementation QSCommandBuilder
- (id)init {
	self = [self initWithWindowNibName:@"CommandBuilder"];
	return self;
}
- (void)windowDidLoad {
	[super windowDidLoad];
	NSArray *theControls = [NSArray arrayWithObjects:dSelector, aSelector, iSelector, nil];
	for(QSSearchObjectView *theControl in theControls) {
		[theControl setDropMode:QSSelectDropMode];
		QSObjectCell *theCell = [theControl cell];
		[theCell setHighlightColor:[NSColor lightGrayColor]];
		[theCell setTextColor:[NSColor blackColor]];
	}
	// don't observe notifications meant for the main interface
	[self ignoreInterfaceNotifications];
}

- (IBAction)hideWindows:(id)sender {
	[NSApp endSheet:[self window]];
}
- (void)searchObjectChanged:(NSNotification*)notif {
	[super searchObjectChanged:notif];
	NSString *description = [[self currentCommand] name];
	[commandView setStringValue:description?description:@""];
	[self setRepresentedCommand:[self currentCommand]];
}
- (NSArray *)rankedActions {
	return [QSExec rankedActionsForDirectObject:[dSelector objectValue] indirectObject:[iSelector objectValue] shouldBypass:YES];
}

- (void)updateActions {
	[aSelector setResultArray:nil];
	[aSelector clearObjectValue];
	[self updateActionsNow];
}

- (void)hideIndirectSelector:(id)sender {
	[super hideIndirectSelector:sender];
	[iFrame setEnabled:NO];
}
- (void)showIndirectSelector:(id)sender {
	[super showIndirectSelector:sender];
	[iFrame setEnabled:YES];
}
- (IBAction)executeCommand:(id)sender { [self save:nil]; }
- (IBAction)cancel:(id)sender {
	[self setRepresentedCommand:nil];
	[NSApp endSheet:[self window]];
}

- (IBAction)save:(id)sender { [NSApp endSheet:[self window]]; }

- (QSCommand *)representedCommand { return representedCommand; }
- (void)setRepresentedCommand:(QSCommand *)aRepresentedCommand {
	if (representedCommand != aRepresentedCommand) {
		[representedCommand release];
		representedCommand = [aRepresentedCommand retain];
	}
}

- (void)windowDidResignKey:(NSNotification *)aNotification {}

- (void)dealloc {
	[representedCommand release];
	[super dealloc];
}
@end
