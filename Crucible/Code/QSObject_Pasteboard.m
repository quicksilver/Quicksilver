

#import "QSObject_Pasteboard.h"
#import "QSTypes.h"

#import "QSObject_FileHandling.h"


#import "QSObject_StringHandling.h"

id objectForPasteboardType(NSPasteboard *pasteboard, NSString *type) {
    if ([PLISTTYPES containsObject:type])
        return [pasteboard propertyListForType:type];
    else if ([NSStringPboardType isEqualToString:type] || [type hasPrefix:@"QSObject"])
        return [pasteboard stringForType:type];
    else if ([NSURLPboardType isEqualToString:type])
        return [[NSURL URLFromPasteboard:pasteboard] absoluteString];
	//else if ([NSColorPboardType isEqualToString:type]);
    else if ([NSFileContentsPboardType isEqualToString:type]);
    else
        return [pasteboard dataForType:type];
    return nil;
}

BOOL writeObjectToPasteboard(NSPasteboard *pasteboard, NSString *type, id data) {
    //NSArray *plistTypes = [NSArray arrayWithObjects:NSFilenamesPboardType, @"ABPeopleUIDsPboardType", @"WebURLsWithTitlesPboardType", nil];
    if ([NSURLPboardType isEqualToString:type]) {
        //if (VERBOSE) QSLog(@"URL Data: %@", data);
        [[NSURL URLWithString:data] writeToPasteboard:pasteboard];
		[pasteboard addTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		
		if ([data hasPrefix:@"mailto:"])
			data = [data substringFromIndex:7];
        [pasteboard setString:data forType:NSStringPboardType];
    }
    else if ([PLISTTYPES containsObject:type] || [data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]]) {
        [pasteboard setPropertyList:data forType:type];
    } else if ([data isKindOfClass:[NSString class]]) {
        [pasteboard setString:data forType:type];
    } else if ([NSColorPboardType isEqualToString:type]);
    else if ([NSFileContentsPboardType isEqualToString:type]);
    else {
		//QSLog(@"setting data, %@, %@", data, type);
        [pasteboard setData:data forType:type];
    }
    
    //QSLog(@"Added to pasteboard:%@\r%@", type, data);
    return YES;
}


@implementation QSObject (Pasteboard)
+ (id)objectWithPasteboard:(NSPasteboard *)pasteboard {
    id theObject = nil;
	
    if ([[pasteboard types] containsObject:QSPrivatePboardType]) return nil;
    if ([[pasteboard types] containsObject:@"de.petermaurer.TransientPasteboardType"]) return nil;
	
    if ([[pasteboard types] containsObject:@"QSObjectID"])
        theObject = [QSObject objectWithIdentifier:[pasteboard stringForType:@"QSObjectID"]];
    
    if (!theObject && [[pasteboard types] containsObject:@"QSObjectAddress"]) {
        NSArray *objectIdentifier = [[pasteboard stringForType:@"QSObjectAddress"] componentsSeparatedByString:@":"];
        if ([[objectIdentifier objectAtIndex:0] intValue] == [[NSProcessInfo processInfo] processIdentifier])
            return (QSObject *)[[objectIdentifier lastObject] intValue];
        else if (VERBOSE)
            QSLog(@"Ignored old object: %@", objectIdentifier);
    }
    
    return [[[QSObject alloc] initWithPasteboard:pasteboard] autorelease];
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard {
    return [self initWithPasteboard:pasteboard types:nil];
}

- (void)addContentsOfClipping:(NSString *)path { // Not thread safe?
	NSPasteboard *pasteboard = [NSPasteboard pasteboardByFilteringClipping:path];
	[self addContentsOfPasteboard:pasteboard types:nil];
	[pasteboard releaseGlobally];
}

- (void)addContentsOfPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types {
    NSEnumerator *typesEnumerator = [(types?types:[pasteboard types]) objectEnumerator];
    NSString *thisType;
    NSMutableArray *typeArray = [NSMutableArray arrayWithCapacity:1];
    NSArray *ignoreTypes = [NSArray arrayWithObjects:@"QSObjectAddress", @"CorePasteboardFlavorType 0x4D555246", @"CorePasteboardFlavorType 0x54455854", nil];
    while ((thisType = [typesEnumerator nextObject])) {
        if ([[pasteboard types] containsObject:thisType] && ![ignoreTypes containsObject:thisType]) {
            id theObject = objectForPasteboardType(pasteboard, thisType);
            if (theObject && thisType) [self setObject:theObject forType:thisType];  
			// ***warning   * change these to use decodedPasteboardType
            else QSLog(@"bad data for %@", thisType);
            [typeArray addObject:[thisType decodedPasteboardType]];
        }
    }
	// QSLog(@"data:%@", [self dataDictionary]);
}


- (id)initWithPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types {
    if ((self = [self init])) {
        //QSLog(@"new pasteboard object:%d", self);
        if (!types)
            types = [pasteboard types];
        //pasteboard = [NSPasteboard pasteboardByFilteringTypesInPasteboard:pasteboard];
        
		NSString *source = @"Clipboard";
		if (pasteboard == [NSPasteboard generalPasteboard])
			source = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationBundleIdentifier"];
		
		if ([source isEqualToString: @"com.microsoft.RDC"]) {
			QSLog(@"Ignoring RDC Clipboard");
			[self release];
			return nil;
		} else if (VERBOSE) {
			//QSLog(@"Clipsource:%@", source);
		}
		
        [self setDataDictionary:[NSMutableDictionary dictionaryWithCapacity:[[pasteboard types] count]]];
        [self addContentsOfPasteboard:pasteboard types:types];
		
		[self setObject:source forMeta:kQSObjectSource];
        [self setObject:[NSDate date] forMeta:kQSObjectCreationDate];
        
        // if (VERBOSE) QSLog(@"Created object with types:\r%@", [typeArray componentsJoinedByString:@", "]);
        id value;
		if ((value = [self objectForType:NSRTFPboardType])) {
			value = [[[NSAttributedString alloc] initWithRTF:value documentAttributes:nil] string];
			[self setObject:value forType:QSTextType];
		}
        if ([self objectForType:QSTextType]) {
			[self sniffString]; 	
		}
        NSString *clippingPath = [self singleFilePath];
        if (clippingPath) {
            NSString *type = [[NSFileManager defaultManager] typeOfFile:clippingPath];
            if ([clippingTypes containsObject:type])
                [self addContentsOfClipping:clippingPath];
        }
        
        if ([self objectForType:kQSObjectPrimaryName])
            [self setName:[self objectForType:kQSObjectPrimaryName]];
        else {
            [self setName:@"Unknown Clipboard Object"];
            [self guessName];
        }
        [self loadIcon];
    }
    return self;
}

+ (id)objectWithClipping:(NSString *)clippingFile {
    return [[[QSObject alloc] initWithClipping:clippingFile] autorelease];
}

- (id)initWithClipping:(NSString *)clippingFile {
	NSPasteboard *pasteboard = [NSPasteboard pasteboardByFilteringClipping:clippingFile];
    if ((self = [self initWithPasteboard:pasteboard])) {
		[self setLabel:[clippingFile lastPathComponent]];
    }
	[pasteboard releaseGlobally];
    return self;
}

- (void)guessName {
    NSString * newName = nil;
    //QSLog(@"webtitl %@", [pasteboard propertyListForType:@"WebURLsWithTitlesPboardType"]);
    if ([self objectForType:NSFilenamesPboardType]) {
        [self setPrimaryType:NSFilenamesPboardType];
        [self getNameFromFiles];
    }
    else if ([self objectForType:NSStringPboardType]) {
        newName = [[self objectForType:NSStringPboardType] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self setName:newName];
    } else {
        if ([self objectForType:NSPDFPboardType])
            newName = @"PDF Image";
        else if ([self objectForType:[@"'icns'" encodedPasteboardType]])
            newName = @"Finder Icon";
        else if ([self objectForType:NSPICTPboardType])
            newName = @"PICT Image";
        else if ([self objectForType:NSPostScriptPboardType])
            newName = @"PostScript Image";
        else if ([self objectForType:NSTIFFPboardType])
            newName = @"TIFF Image";  
        else if ([self objectForType:NSColorPboardType])
            newName = @"Color Data";
        else if ([self objectForType:NSFileContentsPboardType])
            newName = @"File Contents";
        else if ([self objectForType:NSFontPboardType])
            newName = @"Font Information";
        else if ([self objectForType:NSHTMLPboardType])
            newName = @"HTML Data";
        else if ([self objectForType:NSRulerPboardType])
            newName = @"Paragraph formatting";
        else if ([self objectForType:NSHTMLPboardType])
            newName = @"HTML Data";
        else if ([self objectForType:NSTabularTextPboardType])
            newName = @"Tabular Text";
        else if ([self objectForType:NSVCardPboardType])
            newName = @"VCard data";
        else if ([self objectForType:NSFilesPromisePboardType])
            newName = @"Promised Files";  
        
        NSString *source = [self objectForMeta:kQSObjectSource];
        if (source) {
            NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:source];
            NSString *appName = [[NSFileManager defaultManager] displayNameAtPath:path];
            if (!appName)
                appName = source;
            newName = [newName stringByAppendingFormat: @" - %@", appName];
        }
        [self setName:newName];
    }
    
    /*
     also
     
     NSRTFPboardType
     Rich Text Format (RTF)
     
     NSRTFDPboardType
     RTFD formatted file contents
     
     NSStringPboardType
     NSString data
     */
}

- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes {
    if (!types)
        types = [[[[self dataDictionary] allKeys] mutableCopy] autorelease];
    
	// ***warning   * should only include available types
    else {
        NSMutableSet *typeSet = [NSMutableSet setWithArray:types];
        [typeSet intersectSet:[NSSet setWithArray:[[self dataDictionary] allKeys]]];
        types = [[[typeSet allObjects] mutableCopy] autorelease];
    }
    
    if (!includeTypes && [types containsObject:NSFilenamesPboardType]) {
		includeTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
		[pboard declareTypes:includeTypes owner:self];
		
		//		QSLog(@"declare types: %@", [pboard types]);
		//	QSLog(@"declare types: %@", types);
		
	} else {
		if (!includeTypes && [types containsObject:NSURLPboardType])
            includeTypes = [NSArray arrayWithObject:NSURLPboardType];
    }
	[pboard declareTypes:types owner:self];
    /*
     
	 // ***warning   ** Should add additional information for file items     if ([paths count] == 1) {
     [[self data] setObject:[[NSURL fileURLWithPath:[paths lastObject]]absoluteString] forKey:NSURLPboardType];  
     [[self data] setObject:[paths lastObject] forKey:NSStringPboardType];  
     }
     
     */
    //   QSLog(@"declareTypes: %@", [types componentsJoinedByString:@", "]);
    for (NSString *thisType in includeTypes) {
        if ([types containsObject:thisType]) {
			// QSLog(@"includedata, %@", thisType);
            [self pasteboard:pboard provideDataForType:thisType];
        }
    }
    if ([self identifier]) {
        [pboard addTypes:[NSArray arrayWithObject:@"QSObjectID"] owner:self];
        writeObjectToPasteboard(pboard, @"QSObjectID", [self identifier]);
    }
	
    [pboard addTypes:[NSArray arrayWithObject:@"QSObjectAddress"] owner:self];
	//   QSLog(@"types %@", [pboard types]);
    return YES;
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type {
    //if (VERBOSE) QSLog(@"Provide: %@", [type decodedPasteboardType]);
    if ([type isEqualToString:@"QSObjectAddress"]) {
        writeObjectToPasteboard(sender, type, [NSString stringWithFormat:@"%d:%d", [[NSProcessInfo processInfo] processIdentifier] , self]);
	} else {
		id theData = nil;
		id handler = [self handlerForType:type selector:@selector(dataForObject:pasteboardType:)];
		if (handler)
			theData = [handler dataForObject:self pasteboardType:type];
		if (!theData)
			theData = [self objectForType:type];
		if (theData) writeObjectToPasteboard(sender, type, theData);
	} 	
}

- (void)pasteboardChangedOwner:(NSPasteboard *)sender {
    //if (sender == [NSPasteboard generalPasteboard] && VERBOSE)
	//   QSLog(@"%@ Lost the Pasteboard: %@", self, sender);
}

- (NSData *)dataForType:(NSString *)dataType {
    id theData = [data objectForKey:dataType];
    if ([theData isKindOfClass:[NSData class]])
        return theData;
    return nil;
}
@end
