#import <Carbon/Carbon.h>

#import <QSCrucible/QSPlugInManager.h>

#import "QSActionsPrefPane.h"

#define QSTableRowsType @"QSTableRowsType"

@implementation QSActionsPrefPane

- (NSString *)mainNibName {
	return @"QSActionsPrefPane";
}


#define kQSAllActionsCategory @"QSAllActions"
- (id)init {
    self = [super initWithBundle:[NSBundle bundleForClass:[QSActionsPrefPane class]]];
    if (self) {
		displayMode = 0;
    }
    return self;
}

- (void)awakeFromNib {
	//	[self setActions:[[[QSExec actions] mutableCopy] autorelease]];
	
	//[self bind:@"currentGroup" toObject:groupController withKeyPath:@"selectedObject" options:nil];
	
	[self updateGroups];
	
  [groupController addObserver:self
					  forKeyPath:@"selectedObjects"
						 options:0
						 context:@"test"];
	
	[actionController setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"userRank" ascending:YES]];

	[groupController setSelectionIndex:0];
	[self selectCategories:[groupController selectedObjects]];
}



- (void)selectCategories:(NSArray *)categories {
	NSMutableSet *newActions = [NSMutableSet set];
	
	switch (displayMode) {
		case 0:
		 {
			foreach(category, categories) {
				NSString *type = [category objectForKey:@"group"];
				if ([type isEqual:kQSAllActionsCategory])
					[newActions addObjectsFromArray:[QSExec actions]];
				else
					[newActions addObjectsFromArray:[QSExec actionsArrayForType:type]];
			} 	
			break;
		}
			
		case 1:
		 {
			foreach(category, categories) {
				NSString *plugin = [category objectForKey:@"group"];
				if ([plugin isEqual:kQSAllActionsCategory])
					[newActions addObjectsFromArray:[QSExec actions]];
				else
					[newActions addObjectsFromArray:[QSExec getArrayForSource:plugin]];
			} 		
			break;
		}
		default: break;
	}
	[self setActions:[[[newActions allObjects] mutableCopy] autorelease]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	NSArray *selection = [groupController selectedObjects];
	
	//QSLog(@"change %@", selection);
	[self selectCategories:selection];
}
- (NSMutableArray *)actions { return [[actions retain] autorelease];  }
- (void)setActions:(NSMutableArray *)newActions
{
    [actions autorelease];
    actions = [newActions retain];
}



- (NSMutableArray *)groups { return [[groups retain] autorelease];  }
- (void)setGroups:(NSMutableArray *)newGroups
{
    [groups autorelease];
    groups = [newGroups retain];
}


- (int) displayMode { return displayMode;  }
- (void)setDisplayMode:(int)newDisplayMode
{
    displayMode = newDisplayMode;
	[self updateGroups];
	[groupController setSelectionIndex:0];
}

- (void)updateGroups {
	NSMutableArray *array = [NSMutableArray array];
	
	switch (displayMode) {
		case 0:
        {
			NSDictionary *infoTable = [QSReg elementsByIDForPointID:@"QSTypeDefinitions"];
			QSLog(@"infoTable %@", infoTable);
			NSArray *newGroups = [infoTable allKeys];
			
			foreach(group, newGroups) {
				NSDictionary *info = [[infoTable objectForKey:group] plistContent];
				if (!info) continue;
				NSString *name = [info objectForKey:@"name"];
				if (!name) name = group;
				[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  group, @"group", name, @"name", [QSResourceManager imageNamed:[info objectForKey:@"icon"]], @"icon", nil]]; 	
			}
			NSSortDescriptor *desc = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
			[array sortUsingDescriptors:[NSArray arrayWithObject:desc]];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 kQSAllActionsCategory, @"group", @"All Actions", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:0]; 	
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 @"*", @"group", @"Any Type", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:1]; 	
			break;
		}
		case 1:
        {
            
			foreach ( plugin, [QSReg plugins] ) {// [[QSPlugInManager sharedInstance] loadedPlugIns] ) {
                QSPlugIn *qsPlugin = [QSPlugIn plugInWithBundle:[plugin bundle]];
				NSString *name = [qsPlugin name];
				if (!name) name = [qsPlugin identifier];
				NSArray *actionsArray = [QSExec getArrayForSource:[qsPlugin identifier]];
				if ([actionsArray count]) {
					name = [name stringByAppendingFormat:@" - %d", [actionsArray count]];
					[array addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [qsPlugin identifier] , @"group", name, @"name", [qsPlugin icon] , @"icon", nil]];
				}
			}
			NSSortDescriptor *desc = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
			[array sortUsingDescriptors:[NSArray arrayWithObject:desc]];
			[array insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                 kQSAllActionsCategory, @"group", @"All Plug-ins", @"name", [QSResourceManager imageNamed:@"Quicksilver"] , @"icon", nil] atIndex:0]; 	
			break;
		}
		case 2:
        {
			break; 	
		}
		default:
			break;
			
	}
	[self setGroups:array];
}

- (IBAction)selectType:(id)sender {
	
}


- (NSDragOperation) tableView: (NSTableView *)view
				 validateDrop: (id <NSDraggingInfo>) info
				  proposedRow: (int) row
		proposedDropOperation: (NSTableViewDropOperation) operation
{
	
	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *data = [pboard propertyListForType: QSTableRowsType];
	NSIndexSet *indexes = [NSIndexSet indexSetFromArray:data];
	if ([indexes containsIndex:row]) return  NSDragOperationNone;
	if ([indexes containsIndex:row-1]) return  NSDragOperationNone;
	return operation == NSTableViewDropAbove?NSDragOperationMove:NSDragOperationNone;
}


- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	if ([[tableColumn identifier] isEqualToString:@"enabled"] && mOptionKeyIsDown) {
		[[actionController arrangedObjects] setValue:object forKey:@"enabled"];
	}
	if ([[tableColumn identifier] isEqualToString:@"rank"]) {
		
		NSArray *currentActions = [actionController arrangedObjects];
		int newRow = [object intValue] -1;
		if (row != newRow && row >= 0 && row<[currentActions count] && newRow >= 0 && newRow<[currentActions count]) {
			[QSExec orderActions:[NSArray arrayWithObject:[currentActions objectAtIndex:row]]
					aboveActions:[NSArray arrayWithObject:[currentActions objectAtIndex:newRow]]];
		}
		[actionController rearrangeObjects];
	}
}

- (BOOL)tableView: (NSTableView *)view
		acceptDrop: (id <NSDraggingInfo>) info
			   row: (int) row
	 dropOperation: (NSTableViewDropOperation) operation
{
	
	[view registerForDraggedTypes:nil];
	NSPasteboard *pboard = [info draggingPasteboard];
	NSArray *data = [pboard propertyListForType: QSTableRowsType];
	NSIndexSet *indexes = [NSIndexSet indexSetFromArray:data];
	
	NSArray *currentActions = [actionController arrangedObjects];
	NSArray *draggedActions = [[actionController arrangedObjects] objectsAtIndexes:indexes];
	
	
	BOOL ascending = [[[view sortDescriptors] objectAtIndex:0] ascending];
	
	
	BOOL promotion = ascending?[indexes lastIndex] >row:[indexes lastIndex] <row;
	
	if (promotion) { // An upward or mixed drag (promotion for the most part)
		[QSExec orderActions:draggedActions
				aboveActions:[NSArray arrayWithObject:[currentActions objectAtIndex:ascending?row:row-1]]];
	} else { // A downward drag (demotion)
		
		[QSExec orderActions:draggedActions
				belowActions:[NSArray arrayWithObject:[currentActions objectAtIndex:ascending?row-1:row]]];
	} 	
	[actionController setSelectedObjects:draggedActions];
	[actionController rearrangeObjects];  
	
	return YES;
}
- (BOOL)tableView:(NSTableView *)tv
		writeRows:(NSArray*)rows
	 toPasteboard:(NSPasteboard*)pboard {
	
	if (![[[[tv sortDescriptors] objectAtIndex:0] key] isEqualToString:@"userRank"])
		return NO;
	
	[tv registerForDraggedTypes:[NSArray arrayWithObject:QSTableRowsType]];
	[pboard declareTypes:[NSArray arrayWithObject:QSTableRowsType] owner:self];
    [pboard setPropertyList:rows forType:QSTableRowsType];
    return YES;
}

- (IBAction)setFilterText:(id)sender {
	NSString *string = [sender stringValue];
	if (![string length]) {
		[actionController setFilterPredicate:nil];
	} else {
		
		NSPredicate *bPredicate = [NSPredicate predicateWithFormat:@"name contains[cd] %@", string];
	//	QSLog(@"pred %@", bPredicate);
	//	NSPredicate *predicate = [NSComparisonPredicate
//    predicateWithLeftExpression:[NSExpression expressionForKeyPath:@"name"]
//				rightExpression:[NSExpression expressionForConstantValue:string]
//					   modifier:NSDirectPredicateModifier
//						   type:NSLikePredicateOperatorType
//						options:NSCaseInsensitivePredicateOption];
	//	QSLog(@"pred %@", predicate);
		[actionController setFilterPredicate:bPredicate];
	}
}
@end
