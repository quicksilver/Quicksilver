//
//  QSAdvancedPrefPane.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSAdvancedPrefPane.h"
#import "NSString_BLTRExtensions.h"
#import "NSSortDescriptor+BLTRExtensions.h"
#import "QSImageAndTextCell.h"

@implementation QSAdvancedPrefPane

- (void)awakeFromNib {
	[prefSetsTable setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"title" ascending:YES]];
	[(QSImageAndTextCell *)[[prefSetsTable tableColumnWithIdentifier:@"title"] dataCell] setImageSize:QSSize16];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(columnResized:) name:NSTableViewColumnDidResizeNotification object:nil];
}

- (void)columnResized:(id)sender {
	[prefSetsTable noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [(NSArray *)[prefSetsController arrangedObjects] count] )]]; // was calling self
}

- (IBAction)setValue:(id)sender {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[sender objectValue] forKey:[currentInfo objectForKey:@"default"]];
	[defaults synchronize];
}

#if 0
- (IBAction)setValueFromMenu:(id)sender {
	NSLog(@"setvalue %@ %@", sender, [sender representedObject]);
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[sender representedObject] forKey:[currentInfo objectForKey:@"default"]];
	[defaults synchronize];
}
#endif

- (NSArray *)prefSets {
    NSString *defaultsMapPath = [[NSBundle mainBundle] pathForResource:@"DefaultsMap" ofType:@"plist"];
	return [NSArray arrayWithContentsOfFile:defaultsMapPath];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[self prefSets] count];
}

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	NSTableColumn *column = [tableView tableColumnWithIdentifier:@"title"];
	NSCell *cell = [column dataCell];
    NSString *titleKey = [[[[prefSetsController arrangedObjects] objectAtIndex:row] objectForKey:@"default"] stringByAppendingString:@":title"];
    NSString *title = NSLocalizedStringFromTable(titleKey, NSStringFromClass([self class]), nil);
	[cell setStringValue:title];
	NSSize size = [cell cellSizeForBounds:NSMakeRect(0, 0, [column width], MAXFLOAT)];
	return MAX(24, size.height+6);
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation {
   return [[aCell objectValue] description];
}

- (NSCell *)tableView:(NSTableView *)aTableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    
    id thisInfo = nil;
    @try {
       thisInfo = [[prefSetsController arrangedObjects] objectAtIndex:rowIndex];
    }
    @catch (NSException * e) {
#ifdef DEBUG
		NSLog(@"*** Unhandled Exception:%@ with reason: %@, in %@", [e name], [e reason], NSStringFromSelector(_cmd));
#endif
    }
	NSCell *cell = nil;
    
    if ([[aTableColumn identifier] isEqualToString:@"title"]) {
        cell = [[NSTextFieldCell alloc] init];
        NSString *titleKey = [[thisInfo objectForKey:@"default"] stringByAppendingString:@":title"];
        NSString *title = NSLocalizedStringFromTable(titleKey, NSStringFromClass([self class]), nil);
        [cell setStringValue:title];
        [cell setFont:[NSFont systemFontOfSize:11]];
        [cell setControlSize:NSSmallControlSize];
    } else if ([[aTableColumn identifier] isEqualToString:@"value"]) {
        NSString *type = [thisInfo objectForKey:@"type"];
        
        if ([type isEqualToString:@"checkbox"]) {
            cell = [[NSButtonCell alloc] init];
			[(NSButtonCell*)cell setButtonType:NSButtonTypeSwitch];
            [cell setTitle:@""];
        } else if ([type hasPrefix:@"popup"]) {
            cell = [[NSPopUpButtonCell alloc] init];
            
            [(NSPopUpButtonCell *)cell setBordered:YES];
            [(NSPopUpButtonCell *)cell removeAllItems];
            
            NSDictionary *items = [thisInfo objectForKey:@"items"];
            NSMutableDictionary *localizedOptions = [NSMutableDictionary dictionaryWithCapacity:[items count]];
            for (NSString *key in [items allKeys]) {
                NSString *option = [items objectForKey:key];
                NSString *optionKey = [[thisInfo objectForKey:@"default"] stringByAppendingFormat:@":%@", option];
                NSString *optionName = NSLocalizedStringFromTable(optionKey, NSStringFromClass([self class]), nil);
                [localizedOptions setObject:optionName forKey:key];
            }
            NSArray *allKeys = [[localizedOptions allKeys] sortedArrayUsingSelector:@selector(compare:)];
            for (NSString *key in allKeys) {
                NSString *option = [localizedOptions objectForKey:key];
                id item = [[cell menu] addItemWithTitle:option action:nil keyEquivalent:@""];
                [item setRepresentedObject:key];
            }
            
        } else if ([type isEqualToString:@"text"]) {
            cell = [[NSTextFieldCell alloc] init];
            [(NSTextFieldCell *)cell setPlaceholderString:@"text"];
        }
        [cell setControlSize:NSSmallControlSize];
        [cell setFont:[NSFont systemFontOfSize:11]];
        [cell setEditable:YES];
    } else {
        // Special case for cells that span a whole row. Return nil for normal behavior.
        cell = nil;
    }
    
    return cell;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"value"]) {
		id defaultKey = [[[prefSetsController arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"default"];
		return defaultKey ? [[NSUserDefaults standardUserDefaults] objectForKey:defaultKey] : nil;
	} else if ([[aTableColumn identifier] isEqualToString:@"title"]) {
        NSString *titleKey = [[[[prefSetsController arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"default"] stringByAppendingString:@":title"];
        return NSLocalizedStringFromTable(titleKey, NSStringFromClass([self class]), nil);
    }
	return nil;
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	if ([[aTableColumn identifier] isEqualToString:@"value"]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:anObject forKey:[[[prefSetsController arrangedObjects] objectAtIndex:rowIndex] objectForKey:@"default"]];
		[defaults synchronize];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return NO; //[[tableColumn identifier] isEqualToString:@"value"];
}

#if 0
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	if ([[tableColumn identifier] isEqualToString:@"value"]) {
	//	id thisInfo = [[prefSetsController arrangedObjects] objectAtIndex:row];
		//NSString *type = [thisInfo objectForKey:@"type"];
	}
}
#endif

#if 0
- (NSView *)viewForPref:(NSDictionary *)pref {
	return [[[NSView alloc] init] autorelease];
	//float topLeft = NSHeight([view frame]);
	//	if ([[pref objectForKey:@"type"] isEqualToString:@"checkbox"]) {
	//		NSButton *checkbox = [[[NSButton alloc] initWithFrame:[view frame]]autorelease];
	//		[checkbox setButtonType:NSSwitchButton];
	//		[checkbox setTitle:[pref objectForKey:@"title"]];
	//		[view addSubview:checkbox];
	//	}
	//
	// return [[[NSButton alloc] init] autorelease];
}
#endif

#if 0
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self refreshView];
}
- (void)refreshView {
	return;
//	NSArray *selection = [prefSetsController selectedObjects];
//
//	NSLog(@"pref %@", selection);
//	[self setCurrentInfo:[selection lastObject]];
//	//NSView * prefView = [self viewForPref:[selection lastObject]];
//	//[settingsBox setContentView:prefView];
//
//	NSArray *array = [NSArray arrayWithObjects:valueSlider, valuePopUp, valueSwitch, valueField, nil];
//
//	[array setValue:[NSNumber numberWithBool:YES] forKey:@"hidden"];
//
//	id defaultKey = [currentInfo objectForKey:@"default"];
//	id value = defaultKey?[[NSUserDefaults standardUserDefaults] objectForKey:defaultKey] :nil;
//	//NSLog(@"value", value);
//	NSString *type = [currentInfo objectForKey:@"type"];
//
//	NSView *valueView = nil;
//	if ([type isEqualToString:@"checkbox"]) {
//		valueView = valueSwitch;
//
//	}
//	if ([type hasPrefix:@"popup"]) {
//		valueView = valuePopUp;
//
//		[valuePopUp removeAllItems];
//		foreachkey(key, option, [currentInfo objectForKey:@"items"]) {
//		id item = [[valuePopUp menu] addItemWithTitle:option
//									action:nil
//							 keyEquivalent:@""];
//			[item setRepresentedObject:value];
//		}
//
//
//
//
//	}
//	if ([type isEqualToString:@"slider"])
//		valueView = valueSlider;
//	[valueView setObjectValue:value];
//	[valueView setHidden:NO];
//	[valueView setValuesForKeysWithDictionary:[currentInfo objectForKey:@"viewProperties"]];
//
//
//
//	//int i;
//	float top = 0;
//	float spacer = 8;
//	top = NSHeight([[settingsBox contentView] frame]);
//
//	NSView *view = [settingsBox nextKeyView];
//	while(view) {
//		if (![view isHidden]) {
//			[view sizeToFit];
//			top -= NSHeight([view frame]) +spacer;
//			NSRect rect = [view frame];
//
//			NSLog(@"view %@ %f %f", view, rect.origin.y, top);
//			rect.origin.y = top;
//			[view setFrame:rect];
//		}
//		view = [view nextKeyView];
//	}
//	[settingsBox display];
}
#endif


- (NSMutableDictionary *)currentInfo { return currentInfo;  }
- (void)setCurrentInfo:(NSMutableDictionary *)newCurrentInfo {
	if (currentInfo != newCurrentInfo) {
		currentInfo = newCurrentInfo;
	}
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTableViewColumnDidResizeNotification object:nil];
}

@end
