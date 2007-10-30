//
//  QSAdvancedPrefPane.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 4/28/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QSAdvancedPrefPane.h"
#import "QSSliderTextCell.h"
#import "NSString_BLTRExtensions.h"
//#import "QSTextAndImageCell.h"

@implementation QSAdvancedPrefPane
- (void)awakeFromNib{
	[prefSetsController addObserver:self
						 forKeyPath:@"selectedObjects"
							options:nil
							context:nil];
	
	[prefSetsTable setSortDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"title"
																	 ascending:YES]];
		[self refreshView];
		
		NSTableColumn *titleColumn=[prefSetsTable tableColumnWithIdentifier:@"title"];
		[[titleColumn dataCell]setImageSize:QSSize16];
		
		[[NSNotificationCenter defaultCenter]addObserver:self
												selector:@selector(columnResized)
													name:NSTableViewColumnDidResizeNotification
												  object:titleColumn];
				
}
- (void)columnResized{
	[self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[prefSetsController arrangedObjects]count] )]];
}

- (IBAction)setValue:(id)sender{
	NSLog(@"setvalue %@",[sender objectValue]);
	[[NSUserDefaults standardUserDefaults]setObject:[sender objectValue]
											 forKey:[currentInfo objectForKey:@"default"]];
	[[NSUserDefaults standardUserDefaults]synchronize];
}

- (IBAction)setValueFromMenu:(id)sender{
	NSLog(@"setvalue %@ %@",sender,[sender representedObject]);
	[[NSUserDefaults standardUserDefaults]setObject:[sender representedObject]
											 forKey:[currentInfo objectForKey:@"default"]];
	[[NSUserDefaults standardUserDefaults]synchronize];
}


- (NSArray *)prefSets{
	NSString *path=[[NSBundle mainBundle]pathForResource:@"DefaultsMap" ofType:@"plist"];
	NSArray *array=[NSArray arrayWithContentsOfFile:path];
	return array;
}
- (float)tableView:(NSTableView *)tableView heightOfRow:(int)row{
		id thisInfo=[[prefSetsController arrangedObjects]objectAtIndex:row];
	NSTableColumn *column=[tableView tableColumnWithIdentifier:@"title"];
	NSCell *cell=[column dataCell];
	NSString *title=[thisInfo objectForKey:@"title"];
	[cell setStringValue:title];
	NSSize size=[cell cellSizeForBounds:NSMakeRect(0,0,[column width],MAXFLOAT)];		
	return MAX(24,size.height+4);
}
//- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation{
////	return [[aCell objectValue]description];
//}
- (NSCell *)tableView:(NSTableView *)aTableView dataCellForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	id thisInfo=[[prefSetsController arrangedObjects]objectAtIndex:rowIndex];
	NSString *type=[thisInfo objectForKey:@"type"];
	NSCell *cell;
	if ([type isEqualToString:@"checkbox"]){
		 cell=[[[NSButtonCell alloc]init]autorelease];
		[cell setButtonType:NSSwitchButton];
		[cell setTitle:@""];
	}
	if ([type hasPrefix:@"popup"]){
		 cell=[[[NSPopUpButtonCell alloc]init]autorelease];
		
		[(NSPopUpButtonCell *)cell setBordered:YES];
		
		[(NSPopUpButtonCell *)cell removeAllItems];
		NSDictionary *items=[thisInfo objectForKey:@"items"];
		NSArray *keys=[[items allKeys]sortedArrayUsingSelector:@selector(compare:)];
		
		foreach(key,keys){
			id option=[items objectForKey:key];
			id item=[[cell menu]addItemWithTitle:option
										  action:nil
								   keyEquivalent:@""];
				[item setRepresentedObject:key];
		//		[item setTarget:self];
		//		[item setAction:@selector(setValueFromMenu:)];
		}
		
	}
	if ([type isEqualToString:@"slider"]){
		 cell=[[[QSSliderTextCell alloc]init]autorelease];
		[cell setTitle:@"0.0"];
	}	
	if ([type isEqualToString:@"text"]){
		 cell=[[[NSTextFieldCell alloc]init]autorelease];
		[(NSTextFieldCell *)cell setPlaceholderString:@"text"];
	}
//	NSLog(@"cell %@",cell);
	[cell setControlSize:NSSmallControlSize];
	[cell setFont:[NSFont systemFontOfSize:11]];
	[cell setEditable:YES];
	return cell;
}
//- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex{
//	return NO;	
//	
//}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	if ([[aTableColumn identifier]isEqualToString:@"value"]){
		id thisInfo=[[prefSetsController arrangedObjects]objectAtIndex:rowIndex];	
		id defaultKey=[thisInfo objectForKey:@"default"];
		id value=defaultKey?[[NSUserDefaults standardUserDefaults]objectForKey:defaultKey]:nil;
		return value;
	}
	return nil;
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex{
	if ([[aTableColumn identifier]isEqualToString:@"value"]){
		
		id thisInfo=[[prefSetsController arrangedObjects]objectAtIndex:rowIndex];	
		NSLog(@"%@ -> %@",[thisInfo objectForKey:@"default"],anObject);	
		NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
		[defaults setObject:anObject  forKey:[thisInfo objectForKey:@"default"]];
		[defaults synchronize];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	return NO;//[[tableColumn identifier]isEqualToString:@"value"];	
}
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(int)row{
	if ([[tableColumn identifier]isEqualToString:@"value"]){
	//	id thisInfo=[[prefSetsController arrangedObjects]objectAtIndex:row];	
		//NSString *type=[thisInfo objectForKey:@"type"];

	}
}
- (NSView *)viewForPref:(NSDictionary *)pref{
	NSView *view=[[[NSView alloc]init]autorelease];
	//float topLeft=NSHeight([view frame]);
	//	if ([[pref objectForKey:@"type"]isEqualToString:@"checkbox"]){
	//		NSButton *checkbox=[[[NSButton alloc]initWithFrame:[view frame]]autorelease];
	//		[checkbox setButtonType:NSSwitchButton];
	//		[checkbox setTitle:[pref objectForKey:@"title"]];
	//		[view addSubview:checkbox];
	//	}
	//	
	return view;//[[[NSButton alloc]init]autorelease];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	[self refreshView];
}
	
- (void)refreshView{
	return;
//	NSArray *selection=[prefSetsController selectedObjects];
//
//	NSLog(@"pref %@",selection);
//	[self setCurrentInfo:[selection lastObject]];
//	//NSView * prefView=[self viewForPref:[selection lastObject]];
//	//[settingsBox setContentView:prefView];
//	
//	NSArray *array=[NSArray arrayWithObjects:valueSlider,valuePopUp,valueSwitch,valueField,nil];
//
//	[array setValue:[NSNumber numberWithBool:YES] forKey:@"hidden"];
//	
//	id defaultKey=[currentInfo objectForKey:@"default"];
//	id value=defaultKey?[[NSUserDefaults standardUserDefaults]objectForKey:defaultKey]:nil;
//	//NSLog(@"value",value);
//	NSString *type=[currentInfo objectForKey:@"type"];
//	
//	NSView *valueView=nil;
//	if ([type isEqualToString:@"checkbox"]){
//		valueView=valueSwitch;
//		
//	}
//	if ([type hasPrefix:@"popup"]){
//		valueView=valuePopUp;	
//		
//		[valuePopUp removeAllItems];
//		foreachkey(key,option,[currentInfo objectForKey:@"items"]){
//		id item=[[valuePopUp menu]addItemWithTitle:option
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
//		valueView=valueSlider;	
//	[valueView setObjectValue:value];
//	[valueView setHidden:NO];
//	[valueView setValuesForKeysWithDictionary:[currentInfo objectForKey:@"viewProperties"]];
//	
//	
//	
//	//int i;
//	float top=0;
//	float spacer=8;
//	top=NSHeight([[settingsBox contentView]frame]);
//	
//	NSView *view=[settingsBox nextKeyView];
//	while(view){
//		if (![view isHidden]){
//			[view sizeToFit];
//			top-=NSHeight([view frame])+spacer;
//			NSRect rect=[view frame];
//			
//			NSLog(@"view %@ %f %f",view,rect.origin.y,top);
//			rect.origin.y=top;
//			[view setFrame:rect];
//		}
//		view=[view nextKeyView];
//	}
//	[settingsBox display];
}



- (NSMutableDictionary *)currentInfo { return [[currentInfo retain] autorelease]; }
- (void)setCurrentInfo:(NSMutableDictionary *)newCurrentInfo
{
    if (currentInfo != newCurrentInfo) {
        [currentInfo release];
        currentInfo = [newCurrentInfo retain];
    }
}



- (void)dealloc
{
    [currentInfo release];
	
    currentInfo = nil;
    [super dealloc];
}



@end
