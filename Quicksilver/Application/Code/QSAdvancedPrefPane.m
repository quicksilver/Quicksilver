//
//  QSAdvancedPrefPane.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/28/06.

//

#import "QSAdvancedPrefPane.h"

@implementation QSAdvancedPrefPane
- (void)awakeFromNib {
    
	[prefSetsTable setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"title"
																	 ascending:YES]];
    
    NSTableColumn *titleColumn = [prefSetsTable tableColumnWithIdentifier:@"title"];
    [[titleColumn dataCell] setImageSize:QSSize16];
		
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(columnResized)
                                                 name:NSTableViewColumnDidResizeNotification
                                               object:titleColumn];
}

- (void)dealloc
{
    [currentInfo release];
	
    currentInfo = nil;
    [super dealloc];
}

- (void)columnResized {
	[prefSetsTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[prefSetsController arrangedObjects] count] )]];
}

- (NSArray *)prefSets {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultsMap" ofType:@"plist"];
	NSArray *array = [NSArray arrayWithContentsOfFile:path];
    
	return array;
}

- (NSMutableDictionary *)currentInfo { return [[currentInfo retain] autorelease];  }
- (void)setCurrentInfo:(NSMutableDictionary *)newCurrentInfo
{
    if (currentInfo != newCurrentInfo) {
        [currentInfo release];
        currentInfo = [newCurrentInfo retain];
    }
}

#pragma mark -
#pragma mark NSTableView DataSource
/* FIXME: It seems aTableColumn is always nil in ALL those methods, which gives the result you see
 * (no title, and a value spanning both columns.
 * I tried switching to a NSValueTransformer, but you can't output NSCells :(
 */
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"value"]) {
		id thisInfo = [[prefSetsController arrangedObjects] objectAtIndex:rowIndex]; 	
		id defaultKey = [thisInfo objectForKey:@"default"];
		id value = defaultKey ? [[NSUserDefaults standardUserDefaults] objectForKey:defaultKey] : nil;
		return value;
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"value"]) {
        
		id thisInfo = [[prefSetsController arrangedObjects] objectAtIndex:rowIndex]; 	
		QSLog(@"%@ -> %@", [thisInfo objectForKey:@"default"] , anObject); 	
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:anObject  forKey:[thisInfo objectForKey:@"default"]];
		[defaults synchronize];
	}
}

#pragma mark -
#pragma mark NSTableView Delegate
- (float) tableView:(NSTableView *)tableView heightOfRow:(int)row {
    id thisInfo = [[prefSetsController arrangedObjects] objectAtIndex:row];
    if (!thisInfo) return 24;
	NSTableColumn *column = [tableView tableColumnWithIdentifier:@"title"];
	NSCell *cell = [column dataCell];
	NSString *title = [thisInfo objectForKey:@"title"];
	[cell setStringValue:title];
	NSSize size = [cell cellSizeForBounds:NSMakeRect(0, 0, [column width], MAXFLOAT)]; 		
	return MAX(24, size.height+4);
}

- (NSCell *)tableView:(NSTableView *)aTableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    NSCell *cell;
    id thisInfo = [[prefSetsController arrangedObjects] objectAtIndex:rowIndex];
    
    if ([[aTableColumn identifier] isEqualToString:@"title"]) {
        cell = [[[NSTextFieldCell alloc] init] autorelease];
        [cell setStringValue:[thisInfo objectForKey:@"title"]];
        [cell setFont:[NSFont systemFontOfSize:11]];
        [cell setControlSize:NSSmallControlSize];
    } else if ([[aTableColumn identifier] isEqualToString:@"value"]) {
        NSString *type = [thisInfo objectForKey:@"type"];
        
        if ([type isEqualToString:@"checkbox"]) {
            cell = [[[NSButtonCell alloc] init] autorelease];
            [(NSButtonCell*)cell setButtonType:NSSwitchButton];
            [cell setTitle:@""];
        } else if ([type hasPrefix:@"popup"]) {
            cell = [[[NSPopUpButtonCell alloc] init] autorelease];
            
            [(NSPopUpButtonCell *)cell setBordered:YES];
            
            [(NSPopUpButtonCell *)cell removeAllItems];
            NSDictionary *items = [thisInfo objectForKey:@"items"];
            NSArray *keys = [[items allKeys] sortedArrayUsingSelector:@selector(compare:)];
            
            foreach(key, keys) {
                id option = [items objectForKey:key];
                id item = [[cell menu] addItemWithTitle:option
                                                 action:nil
                                          keyEquivalent:@""];
                [item setRepresentedObject:key];
            }
            
        } else if ([type isEqualToString:@"slider"]) {
            cell = [[[QSSliderTextCell alloc] init] autorelease];
            [cell setTitle:@"0.0"];
        } else if ([type isEqualToString:@"text"]) {
            cell = [[[NSTextFieldCell alloc] init] autorelease];
            [(NSTextFieldCell *)cell setPlaceholderString:@"text"];
        }
        //	QSLog(@"cell %@", cell);
        [cell setControlSize:NSSmallControlSize];
        [cell setFont:[NSFont systemFontOfSize:11]];
        [cell setEditable:YES];
    } else {
        // Special case for cells that span a whole row. Return nil for normal behavior.
        cell = nil;
    }
    return cell;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row {
	return [[tableColumn identifier] isEqualToString:@"value"]; 	
}

@end
