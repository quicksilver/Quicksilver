#import <QSCrucible/QSLocalization.h>

#import "QSFileSystemObjectSource.h"

@implementation QSEncapsulatedTextCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView{
    BOOL isFirstResponder=[[controlView window]firstResponder]==controlView && ![controlView isKindOfClass:[NSTableView class]];
    BOOL isKey=[[controlView window]isKeyWindow];
    
    if (isFirstResponder)
        [[[NSColor selectedTextBackgroundColor]colorWithAlphaComponent:(isKey?0.5:0.25)]set];
    else
        [[[NSColor blackColor]colorWithAlphaComponent:(isKey?0.10:0.05)]set];
    NSBezierPath *roundRect=[NSBezierPath bezierPath];
    [roundRect appendBezierPathWithRoundedRectangle:NSInsetRect(cellFrame,0.5,0.5) withRadius:NSHeight(cellFrame)/2];
    [roundRect fill];  
    
    if (isFirstResponder)
        [[NSColor alternateSelectedControlColor]set];
    else
        [[NSColor grayColor]set];
    
    [roundRect stroke];
    
    
    
    [super drawWithFrame:cellFrame inView:controlView];
}
- (NSPoint)cellBaselineOffset{
    return NSZeroPoint;
}
- (BOOL)wantsToTrackMouse{
    
    return NO;
}
/*
 - (NSSize)cellSize{
     return NSMakeSize(32,32);
     return [[self stringValue]sizeWithAttributes:nil];
 }
 */
@end

static NSMutableDictionary *typeSets;

@implementation QSFileSystemObjectSource

+ (void)initialize{
    
	typeSets=[[NSMutableDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle]pathForResource:@"FileTypeGroups" ofType:@"plist"]]retain];
	[typeSets setObject:[NSImage imageUnfilteredFileTypes] forKey:@"QSImageFileTypes"];
	[typeSets setObject:[NSMovie movieUnfilteredFileTypes] forKey:@"QSMovieFileTypes"];
	[typeSets setObject:[NSSound soundUnfilteredFileTypes] forKey:@"QSSoundFileTypes"];
}



+ (NSMenu *)parserMenuForPath:(NSString *)path{
	NSMenu *_parserMenu = [[[NSMenu alloc]initWithTitle:kQSFSParsers]autorelease];
    
    [_parserMenu addItemWithTitle:@"None" action:nil keyEquivalent:@""];
    [_parserMenu addItem:[NSMenuItem separatorItem]];
    NSDictionary *parsers=[QSReg loadedInstancesByIDForPointID:kQSFSParsers];
	
    NSMenuItem *item;
    NSEnumerator *keyEnum=[parsers keyEnumerator];
    NSString *key;
    while((key=[keyEnum nextObject])){
        if (![[parsers objectForKey:key] validParserForPath:path]) continue;
		
		NSString *title=[[NSBundle bundleForClass:NSClassFromString(key)]safeLocalizedStringForKey:key value:key table:@"QSParser.name"];
		if ([title isEqualToString:key])title=[[NSBundle mainBundle]safeLocalizedStringForKey:key value:key table:@"QSParser.name"];
		
		
		
        item=(NSMenuItem *)[_parserMenu addItemWithTitle:title action:nil keyEquivalent:@""];
        [item setRepresentedObject:key];
    }
    
    return _parserMenu;
}

+ (NSMenu *)typeSetsMenu{
    
    NSMenu *typeSetsMenu = [[NSMenu alloc]initWithTitle:@"Types"];
    
    NSEnumerator *keyEnumerator=[typeSets keyEnumerator];
    NSString *key;
    [typeSetsMenu addItemWithTitle:@"Add Set" action:nil keyEquivalent:@""];
    
    NSMenuItem *item;
    while((key=[keyEnumerator nextObject])){
        //   [[NSBundle mainBundle]localizedStringForKey:theID value:theID table:@"QSCatalogPreset.name"];
        
        item=(NSMenuItem *)[typeSetsMenu addItemWithTitle:[[NSBundle mainBundle]safeLocalizedStringForKey:key value:key table:@"FileTypeGroupNames"] action:nil keyEquivalent:@""];
        [item setRepresentedObject:key];
    }
    
    item=(NSMenuItem *)[typeSetsMenu addItemWithTitle:@"Edit..." action:@selector(editSets:) keyEquivalent:@""];
    [item setTarget:self];
    
    
    return typeSetsMenu;
}    

- (id) init {
	self = [super init];
	if (self != nil) {
	}
	return self;
}

- (NSImage *) iconForEntry:(NSDictionary *)entry{
    NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    
    NSMutableDictionary *settings=[entry objectForKey:kItemSettings];
    
    if (!settings) return [workspace iconForFile:@"/volumes"];
    
    NSFileManager *manager=[NSFileManager defaultManager];
	
	NSString *path=[self fullPathForSettings:settings];
    
    BOOL isDirectory, exists;
    exists=[manager fileExistsAtPath:path isDirectory:&isDirectory];
    
    NSImage *theImage=(exists?[workspace iconForFile:path]:[NSImage imageNamed:@"Question"]);
    [theImage setSize:NSMakeSize(16,16)];
    return theImage;
    
    //  [aCell setTextColor:(exists?[NSColor blackColor]:[NSColor grayColor])];
}


- (BOOL)isVisibleSource{return YES;}
- (BOOL)usesGlobalSettings{return NO;}


- (NSString *)tokenField:(NSTokenField *)tokenField editingStringForRepresentedObject:(id)representedObject{
	return representedObject;	
}
-(id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString{
	//NSString *osstype=nil;
	NSString *type=QSUTIForAnyTypeString(editingString);
	if (!type){
		if ([editingString hasPrefix:@"'"])return editingString;
		if ([editingString hasPrefix:@"."])return [editingString substringFromIndex:1];
		type=editingString;
	}
	return type;
}
//-(NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject{
//	
//	if ([representedObject hasPrefix:@"."])return NSPlainTextTokenStyle;
//	return NSRoundedTokenStyle;
//}
-(BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject{
	if ([representedObject hasPrefix:@"'"] || [representedObject hasPrefix:@"."])return NO;
	return YES;
}
-(NSMenu *)tokenField:(NSTokenField *)tokenField menuForRepresentedObject:(id)representedObject{
	NSMenu *menu=[[[NSMenu alloc]initWithTitle:@""]autorelease];
	//	[menu addItemWithTitle:[UTTypeCopyDescription(representedObject) autorelease]  action:nil keyEquivalent:@""];
	
	NSArray *conforms=[[(NSString *)UTTypeCopyDeclaration((CFStringRef)representedObject) autorelease]objectForKey:(NSString *)kUTTypeConformsToKey];
	if (conforms){
		if (![conforms isKindOfClass:[NSArray class]])conforms=[NSArray arrayWithObject:conforms];
		foreach(type,conforms)	
			[menu addItemWithTitle:[(NSString *)UTTypeCopyDescription((CFStringRef)type) autorelease] action:nil keyEquivalent:@""];
	}
	return menu;
	
}


-(NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject{
	NSString *description=[(NSString *)UTTypeCopyDescription((CFStringRef)representedObject) autorelease];
	if (!description){
		if ([representedObject hasPrefix:@"'"]){
			return [@"Type: " stringByAppendingString:representedObject];
		}else if ([representedObject rangeOfString:@"."].location==NSNotFound){
			return [@"." stringByAppendingString:representedObject];
		}
		description=representedObject;
	}
	return description;
}

- (NSView *) settingsView{
    if (![super settingsView]){
        [NSBundle loadNibNamed:NSStringFromClass([self class]) owner:self];
        
        [typeSetsPopUp setTitle:@"Type Sets"];
        [typeSetsPopUp setMenu:[QSFileSystemObjectSource typeSetsMenu]];
        
        [typeSetsPopUp setHidden:!fDEV];
    }
    return [super settingsView];
}

- (BOOL)selectionIsEditable{
    QSLog(@"editable?");
    return ![[self selection]isPreset];
}

- (void)populateFields{
    NSFileManager *manager=[NSFileManager defaultManager];
	//   QSLog(@"Populate With %@",[self currentEntry]);
    NSMutableDictionary *settings=[[self currentEntry] objectForKey:kItemSettings];
    
    NSString *path=[settings objectForKey:kItemPath];
    [itemLocationField setStringValue:(path?path:@"")];
    NSString *fullPath=[self fullPathForSettings:settings];
    
    NSString *parser=[settings objectForKey:kItemParser];
	
    [itemParserPopUp setMenu:[QSFileSystemObjectSource parserMenuForPath:fullPath]];
    
    int parserEntry=[itemParserPopUp indexOfItemWithRepresentedObject:parser];
    [itemParserPopUp selectItemAtIndex:(parserEntry==-1?0:parserEntry)];
    
    
    // NSWorkspace *workspace=[NSWorkspace sharedWorkspace];
    BOOL isDirectory, exists;
    exists=fullPath&&[manager fileExistsAtPath:fullPath isDirectory:&isDirectory];
    
    if ([[settings objectForKey:kItemParser]isEqualToString:@"QSDirectoryParser"] && (exists)){
        [itemOptionsView setContentView:itemFolderOptions];
        NSArray *types=[settings objectForKey:kItemFolderTypes];
        
		//  [typesTextView setString:(types?[types componentsJoinedByString:@","]:@"")];
        [typesTextField setObjectValue:types];
        
        NSNumber *depth=[settings objectForKey:kItemFolderDepth];
        int depthInt=(depth?[depth intValue]:1);
        if (depthInt==-1 || depthInt>8) depthInt=8;
        [itemFolderDepthSlider setFloatValue:9-depthInt];
    }else{
        [itemOptionsView setContentView:nil];
    }
    
    //   NSString *ID=[settings objectForKey:kItemID];
    bool validItem=(settings!=nil);
    
    //[itemLocationChooseButton setEnabled:]
    [itemLocationShowButton setEnabled:exists];
    
    [itemSkipItemSwitch setState:([[settings objectForKey:kItemSkipItem]boolValue])];
    [itemSkipItemSwitch setEnabled:parserEntry>=0];
    [itemParserPopUp setEnabled:validItem];
    //   [itemNameField setEnabled:validItem && !isPreset];
    [itemLocationField setEnabled:YES];
    
    //   [typesTextView setEnabled:validItem];
    
}


//Item Fields

- (IBAction)setValueForSender:(id)sender{
    NSMutableDictionary *settings=[[self currentEntry] objectForKey:kItemSettings];
    if (!settings){
        settings=[NSMutableDictionary dictionaryWithCapacity:1];
        [[self currentEntry] setObject:settings forKey:kItemSettings];
    }
    
    if (sender==typeSetsPopUp){
        QSLog([[sender selectedItem]representedObject]);
        
        //      QSObjectCell *attachmentCell = [[QSObjectCell alloc]initTextCell:@""];
        //       [attachmentCell setRepresentedObject:[QSObject fileObjectWithPath:@"/Volumes/Lore/"]];
        //   [[attachmentCell representedObject]loadIcon];
        
        // NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        // [attachment setAttachmentCell: attachmentCell ];
        
        
        // NSTextAttachment *attachment=[[NSTextAttachment alloc]initWithFileWrapper:nil];
        //[attachment setAttachmentCell:;
        //   [[attachment attachmentCell]setImage:[NSImage imageNamed:@"Dot"]];
        
		/*    
        NSString *set=[[sender selectedItem]representedObject];
        //NSImage *image = [NSImage imageNamed:@"Dot"];
        QSEncapsulatedTextCell *attachmentCell = [[QSEncapsulatedTextCell alloc]init];
        [attachmentCell setRepresentedObject:set];
        
        [attachmentCell setStringValue:[[NSBundle mainBundle]localizedStringForKey:set value:set table:@"FileTypeGroupNames"]];
        
        
        
        
        
        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
        [attachment setAttachmentCell: attachmentCell ];
        
        NSAttributedString *attributedString = [NSAttributedString attributedStringWithAttachment: attachment];
        
		*/  
        NSAttributedString *attributedString = [[[NSAttributedString alloc]initWithString:[NSString stringWithFormat:@"[%@]",[[sender selectedItem]representedObject]]]autorelease];
        
        [[typesTextView textStorage] appendAttributedString:attributedString];
		
        
        // [typesTextView display];
        
        
        // [currentEntry setObject:[sender stringValue] forKey:kItemName];
    }
    else if (sender==itemLocationField){
        [settings setObject:[sender stringValue] forKey:kItemPath];
    }
    
    else if (sender==itemSkipItemSwitch){
        [settings setObject:[NSNumber numberWithBool:[sender state]] forKey:kItemSkipItem];
    }
    
    else if (sender==typesTextView){
        //QSLog(@"%@",[[sender string]componentsSeparatedByString:@","]);
        if ([[sender string]length])
            [settings setObject:[[sender string]componentsSeparatedByString:@","] forKey:kItemFolderTypes];
        else [settings removeObjectForKey:kItemFolderTypes];
    }    
    else if (sender==typesTextField){
        QSLog(@"%@",[sender objectValue]);
        if ([[sender objectValue]count])
            [settings setObject:[sender objectValue] forKey:kItemFolderTypes];
        else [settings removeObjectForKey:kItemFolderTypes];
    }
    else if (sender==itemFolderDepthSlider){
        int depth=(9-[itemFolderDepthSlider intValue]);
        if (depth>7) depth=-1;
        [settings setObject:[NSNumber numberWithInt:depth] forKey:kItemFolderDepth];
    }
    else if (sender==itemParserPopUp){
        NSString *parserName=[[sender selectedItem]representedObject];
        if (parserName)
            [settings setObject:[[sender selectedItem]representedObject] forKey:kItemParser];
        else
            [settings removeObjectForKey:kItemParser];
    }
    [currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
    
    [self populateFields];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
}

- (BOOL)textShouldEndEditing:(NSText *)aTextObject{
//    QSLog(@"ended editing");
    [self setValueForSender:typesTextView];
    return YES;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView{
    return [typeSets count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row{
    if ([[tableColumn identifier]isEqualToString:@"Set"]){
        return [[typeSets allKeys]objectAtIndex:row];
        return @"name"; 
    }
    else if ([[tableColumn identifier]isEqualToString:@"Types"]){
        return  [[typeSets objectForKey:[[typeSets allKeys]objectAtIndex:row]]componentsJoinedByString:@", "];
    }
    return nil;
}



- (IBAction)editSets:(id)sender{
	[NSApp beginSheet: typeSetsPanel
	   modalForWindow: [sender window]
		modalDelegate: nil
	   didEndSelector: nil
		  contextInfo: nil];
    
}

- (IBAction)endContainingSheet:(id)sender{
    [[sender window] makeFirstResponder:[sender window]];
    [NSApp endSheet: [sender window]];
    [[sender window] orderOut: self];
}


- (IBAction)addSet:(id)sender{
    
}
- (IBAction)removeSet:(id)sender{
    
}



//- (void)pathChanged:(NSNotification *)notif{
//	
//	
//}
//

- (void)enableEntry:(QSCatalogEntry *)entry{
	if (!fALPHA) return;
	NSMutableDictionary *settings=[[entry info] objectForKey:kItemSettings];
	NSString *path=[self fullPathForSettings:settings];
	
	if ([[settings objectForKey:@"watchTarget"]boolValue]){
		[[QSVoyeur sharedInstance]addPathToQueue:path notifyingAbout:UKKQueueNotifyAboutDelete|UKKQueueNotifyAboutWrite];
		if (VERBOSE)QSLog(@"Watching Path %@",path);
		[[[NSWorkspace sharedWorkspace] notificationCenter]addObserver:entry 
												selector:@selector(invalidateIndex:)
													name:nil
												  object:path];
	}
	NSArray *paths=[settings objectForKey:@"watchPaths"];
	foreach (p,paths){
		[[QSVoyeur sharedInstance]addPathToQueue:p];
		if (VERBOSE)QSLog(@"Watching Path %@",p);
		[[[NSWorkspace sharedWorkspace] notificationCenter]addObserver:entry 
															  selector:@selector(invalidateIndex:)
																  name:UKFileWatcherWriteNotification
																object:p];
	}
}

- (void)disableEntry:(QSCatalogEntry *)entry{
	if (!fALPHA) return;
	NSMutableDictionary *settings=[[entry info] objectForKey:kItemSettings];
	NSString *path=[self fullPathForSettings:settings];
	if ([[settings objectForKey:@"watchTarget"]boolValue]){
		[[QSVoyeur sharedInstance]removePathFromQueue:path];
		[[NSNotificationCenter defaultCenter]removeObserver:entry];
	}
}

- (NSArray *) objectsForEntry:(NSMutableDictionary *)theEntry{
    NSMutableDictionary *settings=[theEntry objectForKey:kItemSettings];
    NSFileManager *manager=[NSFileManager defaultManager];
    BOOL isDirectory; //,scanContents;
	NSString *path=nil;
	NSMutableArray *containedItems=[NSMutableArray arrayWithCapacity:1];
	
	path=[self fullPathForSettings:settings];

	if (![manager fileExistsAtPath:path isDirectory:&isDirectory]) return [NSArray array];
	if ([[settings objectForKey:@"watchTarget"]boolValue]){
		[[QSVoyeur sharedInstance]addPathToQueue:path];
	
	}
		
	NSString *parser=[settings objectForKey:kItemParser];
	

	if (parser){
		id instance=[QSReg instanceForPointID:kQSFSParsers withID:parser];
		[containedItems setArray:[instance objectsFromPath:path withSettings:settings]];
	}
	
	if (!parser || ![[settings objectForKey:kItemSkipItem]boolValue]){
		QSObject *mainObject=[QSObject fileObjectWithPath:path];
		NSString *name=[theEntry objectForKey:kItemName];
		if (!QSIsLocalized && !name){ 
			NSString *theID=[theEntry objectForKey:kItemID];
			if ([theID hasPrefix:@"QSPreset"])
				name=[[NSBundle mainBundle]safeLocalizedStringForKey:theID value:theID table:@"QSCatalogPreset.name"];
		}
		if (name) [mainObject setLabel:name];
		
		[containedItems addObject:mainObject];
	}
	return containedItems;
}

- (IBAction)showFile:(id)sender{
	NSMutableDictionary *settings=[[self currentEntry] objectForKey:kItemSettings];
	NSString *fullPath=[self fullPathForSettings:settings];
    [[NSWorkspace sharedWorkspace]selectFile:fullPath inFileViewerRootedAtPath:@""];
}

- (IBAction)chooseFile:(id)sender{
    [self chooseFile];
}



- (BOOL)chooseFile{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    NSString *oldFile=[[itemLocationField stringValue]stringByStandardizingPath];
    
    [openPanel setCanChooseDirectories:YES];
    
    if (![openPanel runModalForDirectory:[oldFile stringByDeletingLastPathComponent] file:[oldFile lastPathComponent] types:nil])return NO;
    [itemLocationField setStringValue:[[openPanel filename]stringByAbbreviatingWithTildeInPath]];
    [self setValueForSender:itemLocationField];
    
    [[self selection] setName:[[openPanel filename] lastPathComponent]];
    
    [currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
    return YES;
}

/*
 
 - (IBAction)chooseFile:(id)sender{
	 NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	 
	 NSString *oldFile=[[itemLocationField stringValue]stringByStandardizingPath];
	 
	 [openPanel setCanChooseDirectories:YES];
	 NSView *content=[openPanel contentView];
	 // QSLog(@"sub %@",[content subviews]);
	 if  (![content isKindOfClass:[QSBackgroundView class]]){
		 NSView *newBackground=[[QSBackgroundView alloc]init];
		 [openPanel setContentView:newBackground];
		 [newBackground addSubview:content];
	 }
	 
	 [openPanel beginSheetForDirectory:[oldFile stringByDeletingLastPathComponent]
								  file:[oldFile lastPathComponent]
								 types:nil
						modalForWindow:[[self settingsView] window]
						 modalDelegate:self
						didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						   contextInfo:sender];
 }
 
 
 - (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{ 
	 if (returnCode==NSCancelButton) return;
	 
	 [itemLocationField setStringValue:[[sheet filename]stringByAbbreviatingWithTildeInPath]];
	 [self setValueForSender:itemLocationField];
	 
	 [[self currentEntry] setObject:[[sheet filename] lastPathComponent] forKey:kItemName];
	 
	 [currentEntry setObject:[NSNumber numberWithFloat:[NSDate timeIntervalSinceReferenceDate]] forKey:kItemModificationDate];
	 
	 [[NSNotificationCenter defaultCenter] postNotificationName:QSCatalogEntryChanged object:[self currentEntry]];
 }
 */


/*
 NSString *indexPath=[[[pIndexLocation stringByStandardizingPath] stringByAppendingPathComponent:[theItem objectForKey:kItemID]]stringByAppendingPathExtension:@"qsindex"];
 if (![manager fileExistsAtPath:indexPath isDirectory:nil]) return YES;
 NSDate *indexDate=[[manager fileAttributesAtPath:indexPath traverseLink:NO]fileModificationDate]; 
 */ 

- (NSString *)fullPathForSettings:(NSDictionary *)settings{
    if (![settings objectForKey:kItemPath]) return nil;
    NSString *itemPath=[[settings objectForKey:kItemPath]stringByResolvingWildcardsInPath];
    if (![itemPath isAbsolutePath]){
		//QSLog(@"base %@",[settings objectForKey:kItemBaseBundle]);
		NSString *bundlePath=[[QSReg bundleWithIdentifier:[settings objectForKey:kItemBaseBundle]]bundlePath];
		if (!bundlePath) bundlePath=[[NSBundle mainBundle]bundlePath];
        itemPath=[bundlePath stringByAppendingPathComponent:itemPath];
    }
	
	return itemPath;
}


- (BOOL)indexIsValidFromDate:(NSDate *)indexDate forEntry:(NSDictionary *)theEntry{
	
    NSMutableDictionary *settings=[theEntry objectForKey:kItemSettings];
	
    NSString *itemPath= [self fullPathForSettings:settings];
	if (!itemPath) return YES;
	
    NSFileManager *manager=[NSFileManager defaultManager];
	if (![manager fileExistsAtPath:itemPath isDirectory:nil]) return YES;
    
    NSDate *specDate=[NSDate dateWithTimeIntervalSinceReferenceDate:[[settings objectForKey:kItemModificationDate]floatValue]];
	
	if ([specDate compare:indexDate]==NSOrderedDescending) return NO; //Catalog Specification is more recent than index
    
    NSNumber *depth=[settings objectForKey:kItemFolderDepth];
    
		//QSLog(@"depth of %@ %@",itemPath, indexDate);
		//NSDate *date=[NSDate date];
		  NSDate *modDate=[manager path:itemPath wasModifiedAfter:indexDate depth:[depth intValue]];
		//  QSLog(@"nepth %@ - %f",modDate,[date timeIntervalSinceNow]);
		  //date=[NSDate date];
		  //modDate=[manager bulkPath:itemPath wasModifiedAfter:indexDate depth:[depth intValue]];
		 // QSLog(@"d`epth %@ - %f",modDate,[date timeIntervalSinceNow]);
		  return modDate==nil;
		  // //  QSLog(@"depth %@ %d",modDate,[modDate compare:indexDate]!=NSOrderedDescending);
		  
		  //		  NSDate *modDate=[manager modifiedDate:itemPath depth:[depth intValue]];
		  
		  //return [modDate compare:indexDate]!=NSOrderedDescending; //FS item modification is more recent than index
}

@end