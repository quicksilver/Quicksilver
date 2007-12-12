#import "QSActionsPrefPane.h"
#import "QSExecutor.h"
#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSLibrarian.h"
#import "QSTableView.h"

#import <Carbon/Carbon.h>
#define QSTableRowsType @"QSTableRowsType"

#import "NSSortDescriptor+BLTRExtensions.h"
#import "NSIndexSet+Extensions.h"
#import "QSPlugInManager.h"
#import "QSPlugIn.h"

@implementation QSActionsPrefPane

- (NSString *)mainNibName { return @"QSActionsPrefPane"; }

#define kQSAllActionsCategory @"QSAllActions"

- (id)init {
	if (self = [super initWithBundle:[NSBundle bundleForClass:[QSActionsPrefPane class]]]) {
		displayMode = 0;
	}
	return self;
}

- (void)awakeFromNib {
	[self updateGroups];
	[groupController addObserver:self forKeyPath:@"selectedObjects" options:0 context:@"test"];
	[actionController setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"userRank" ascending:YES]];
	[groupController setSelectionIndex:0];
	[self selectCategories:[groupController selectedObjects]];
}

- (void)selectCategories:(NSArray *)categories {
	NSMutableSet *newActions = [NSMutableSet set];
	switch (displayMode) {
		case 0: {
			foreach(category, categories) {
				NSString *type = [category objectForKey:@"group"];
				[newActions addObjectsFromArray: ([type isEqual:kQSAllActionsCategory])?[QSExec actions]:[QSExec actionsArrayForType:type] ];
			}
			break;
		}
		case 1: {
			foreach(category, categories) {
				NSString *plugin = [category objectForKey:@"group"];
				[newActions addObjectsFromArray: ([plugin isEqual:kQSAllActionsCategory])?[QSExec actions]:[QSExec getArrayForSource:plugin] ];
			}
			break;
		}
		default: break;
	}
	[self setActions:[[[newActions allObjects] mutableCopy] autorelease]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self selectCategories:[groupController selectedObjects]];
}

- (NSMutableArray *)actions { return actions;  }
- (void)setActions:(NSMutableArray *)newActions {
	if(newActions != actions){
		[actions release];
		actions = [newActions retain];
	}
}
- (NSMutableArray *)groups { return groups; }
- (void)setGroups:(NSMutableArray *)newGroups {
	if(newGroups != groups){
		[groups release];
		groups = [newGroups retain];
	}
}

- (int) displayMode { return displayMode;  }
- (void)setDisplayMode:(int)newDisplayMode {
	displayMode = newDisplayMode;
	[self updateGroups];
	[groupController setSelectionIndex:0];
}

- (void)updateGroups {
	NSMutableArray *array = [NSMutableArray array];
	switch (displayMode) {
		case 0: {
			NSDictionary *infoTable = [QSReg tableNamed:@"QSTypeDefinitions"];
			NSArray *newGroups = [infoTable allKeys];
			foreach(group, newGroups) {
				NSDictionary *info = [infoTable objectForKey:group];
				if (!info) continue;
				NSString *name = [info objectForKey:@"name"];
				if (!name) name = group;
				[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					group, @"group", name, @"name", [QSResourceManager imageNamed:[info objectForKey:@"icon"]], @"icon", nil]];
			}
			NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
			[array sortUsingDescriptors:[NSArray arrayWithObject:desc]];
			[desc release];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:kQSAllActionsCategory, @"group", @"All Actions", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:0];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:@"*", @"group", @"Any Type", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:1];
			break;
		}
		case 1: {
			foreach(plugin, [[QSPlugInManager sharedInstance] loadedPlugIns]) {
				NSString *name = [plugin shortName];
				if (!name) name = [plugin identifier];
				NSArray *actionsArray = [QSExec getArrayForSource:[plugin identifier]];
				if ([actionsArray count]) {
					name = [name stringByAppendingFormat:@" - %d", [actionsArray count]];
					[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						[plugin identifier] , @"group", name, @"name", [plugin icon] , @"icon", nil]];
				}
			}
			NSSortDescriptor *desc = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
			[array sortUsingDescriptors:[NSArray arrayWithObject:desc]];
			[desc release];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:kQSAllActionsCategory, @"group", @"All Plug-ins", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:0];
			break;
		}
		default:
			break;
	}
	[self setGroups:array];
}

- (NSDragOperation)tableView:(NSTableView *)view validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)operation {
	NSArray *data = [[info draggingPasteboard] propertyListForType:QSTableRowsType];
	NSIndexSet *indexes = [NSIndexSet indexSetFromArray:data];
	if ([indexes containsIndex:row] || [indexes containsIndex:row-1])
		return  NSDragOperationNone;
	else
		return operation == NSTableViewDropAbove ? NSDragOperationMove : NSDragOperationNone;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:@"enabled"] && mOptionKeyIsDown)
		[[actionController arrangedObjects] setValue:object forKey:@"enabled"];
	if ([[tableColumn identifier] isEqualToString:@"rank"]) {
		NSArray *currentActions = [actionController arrangedObjects];
		int newRow = [object intValue] -1;
		if (row != newRow && row >= 0 && row<[currentActions count] && newRow >= 0 && newRow<[currentActions count]) {
			[QSExec orderActions:[NSArray arrayWithObject:[currentActions objectAtIndex:row]] aboveActions:[NSArray arrayWithObject:[currentActions objectAtIndex:newRow]]];
		}
		[actionController rearrangeObjects];
	}
}

- (BOOL)tableView:(NSTableView *)view acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation {
	[view registerForDraggedTypes:nil];
	NSArray *data = [[info draggingPasteboard] propertyListForType:QSTableRowsType];
	NSIndexSet *indexes = [NSIndexSet indexSetFromArray:data];

	NSArray *currentActions = [actionController arrangedObjects];
	NSArray *draggedActions = [[actionController arrangedObjects] objectsAtIndexes:indexes];

	BOOL ascending = [[[view sortDescriptors] objectAtIndex:0] ascending];
	if ((ascending ? [indexes lastIndex] > row : [indexes lastIndex] < row))
		// An upward or mixed drag (promotion for the most part)
		[QSExec orderActions:draggedActions aboveActions:[NSArray arrayWithObject:[currentActions objectAtIndex:ascending?row:row-1]]];
	else // A downward drag (demotion)
		[QSExec orderActions:draggedActions belowActions:[NSArray arrayWithObject:[currentActions objectAtIndex:ascending?row-1:row]]];
	[actionController setSelectedObjects:draggedActions];
	[actionController rearrangeObjects];
	return YES;
}
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard {
	if (![[[[tv sortDescriptors] objectAtIndex:0] key] isEqualToString:@"userRank"])
		return NO;
	[tv registerForDraggedTypes:[NSArray arrayWithObject:QSTableRowsType]];
	[pboard declareTypes:[NSArray arrayWithObject:QSTableRowsType] owner:self];
	[pboard setPropertyList:rows forType:QSTableRowsType];
	return YES;
}

- (IBAction)setFilterText:(id)sender {
	NSString *string = [sender stringValue];
	[actionController setFilterPredicate:([string length])?[NSPredicate predicateWithFormat:@"name contains[cd] %@", string]:nil];
}

- (void)dealloc {
	[actions release];
	[groups release];
	[super dealloc];
}

@end
