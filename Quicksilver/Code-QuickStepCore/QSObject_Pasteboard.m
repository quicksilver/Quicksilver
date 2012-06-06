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
	else if ([NSColorPboardType isEqualToString:type])
		return [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorFromPasteboard:pasteboard]];
	else if ([NSFileContentsPboardType isEqualToString:type]);
	else
		return [pasteboard dataForType:type];
	return nil;
}

// writes the selected data to the general pasteboard
bool writeObjectToPasteboard(NSPasteboard *pasteboard, NSString *type, id data) {
	if ([NSURLPboardType isEqualToString:type]) {
		[[NSURL URLWithString:data] writeToPasteboard:pasteboard];
		[pasteboard addTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
		[pasteboard setString:([data hasPrefix:@"mailto:"]) ?[data substringFromIndex:7] :data forType:NSStringPboardType];
	} else if ([PLISTTYPES containsObject:type] || [data isKindOfClass:[NSDictionary class]] || [data isKindOfClass:[NSArray class]])
		[pasteboard setPropertyList:data forType:type];
	else if ([data isKindOfClass:[NSString class]])
		[pasteboard setString:data forType:type];
	else if ([NSColorPboardType isEqualToString:type])
		[data writeToPasteboard:pasteboard];
	else if ([NSFileContentsPboardType isEqualToString:type]);
	else
		[pasteboard setData:data forType:type];
	return YES;
}

@implementation QSObject (Pasteboard)
+ (id)objectWithPasteboard:(NSPasteboard *)pasteboard {
	id theObject = nil;

	if ([[pasteboard types] containsObject:QSPrivatePboardType] || [[pasteboard types] containsObject:@"de.petermaurer.TransientPasteboardType"])
		return nil;

	if ([[pasteboard types] containsObject:@"QSObjectID"])
		theObject = [QSObject objectWithIdentifier:[pasteboard stringForType:@"QSObjectID"]];

	if (!theObject && [[pasteboard types] containsObject:@"QSObjectAddress"]) {
		NSArray *objectIdentifier = [[pasteboard stringForType:@"QSObjectAddress"] componentsSeparatedByString:@":"];
		if ([[objectIdentifier objectAtIndex:0] intValue] == [[NSProcessInfo processInfo] processIdentifier])
			return [QSObject objectWithIdentifier:[objectIdentifier lastObject]];
#ifdef DEBUG
		else if (VERBOSE)
			NSLog(@"Ignored old object: %@", objectIdentifier);
#endif
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
	NSMutableArray *typeArray = [NSMutableArray arrayWithCapacity:1];
	NSArray *ignoreTypes = [NSArray arrayWithObjects:@"QSObjectAddress", @"CorePasteboardFlavorType 0x4D555246", @"CorePasteboardFlavorType 0x54455854", nil];
	for(NSString *thisType in (types?types:[pasteboard types])) {
		if ([[pasteboard types] containsObject:thisType] && ![ignoreTypes containsObject:thisType]) {
			id theObject = objectForPasteboardType(pasteboard, thisType);
			if (theObject && thisType)
				[self setObject:theObject forType:thisType];
			else
				NSLog(@"bad data for %@", thisType);
			[typeArray addObject:[thisType decodedPasteboardType]];
		}
	}
	// NSLog(@"data:%@", [self dataDictionary]);
	/*
	 if (![[data allKeys] containsObject:NSURLPboardType]) {
		 NSURL *getURL = [[NSURL URLFromPasteboard:pasteboard] absoluteString];
		 if (getURL) {
			 [data setObject:getURL forType:NSURLPboardType];
			 NSLog(@"addingURL");
		 }
	 }
	 */
}

- (id)initWithPasteboard:(NSPasteboard *)pasteboard types:(NSArray *)types {
	if (self = [self init]) {
		if (!types) types = [pasteboard types];

		NSString *source = @"Clipboard";
		if (pasteboard == [NSPasteboard generalPasteboard])
			source = [[[NSWorkspace sharedWorkspace] activeApplication] objectForKey:@"NSApplicationBundleIdentifier"];
		if ([source isEqualToString: @"com.microsoft.RDC"]) {
			NSLog(@"Ignoring RDC Clipboard");
			[self release];
			return nil;
		}

		[self setDataDictionary:[NSMutableDictionary dictionaryWithCapacity:[[pasteboard types] count]]];
		[self addContentsOfPasteboard:pasteboard types:types];

		[self setObject:source forMeta:kQSObjectSource];
		[self setObject:[NSDate date] forMeta:kQSObjectCreationDate];

		id value;
		if (value = [self objectForType:NSRTFPboardType]) {
			value = [[NSAttributedString alloc] initWithRTF:value documentAttributes:nil];
			[self setObject:[value string] forType:QSTextType];
            [value release];
		}
		if ([self objectForType:QSTextType])
			[self sniffString];
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
	if (self = [self initWithPasteboard:pasteboard]) {
		[self setLabel:[clippingFile lastPathComponent]];
	}
	[pasteboard releaseGlobally];
	return self;
}

- (void)guessName {
	if (itemForKey(NSFilenamesPboardType) ) {
		[self setPrimaryType:NSFilenamesPboardType];
		[self getNameFromFiles];
	} else {
		NSDictionary *namesAndKeys = [NSDictionary dictionaryWithObjects:
                                      [NSArray arrayWithObjects:[itemForKey(NSStringPboardType) stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]], @"PDF Image", @"Finder Icon", @"PICT Image", @"PostScript Image", @"TIFF Image", @"Color Data", @"File Contents", @"Font Information", @"HTML Data", @"Paragraph Formatting", @"Tabular Text", @"VCard Data", @"Promised Files",nil]
                                    forKeys:[NSArray arrayWithObjects:NSStringPboardType, NSPDFPboardType, [@"'icns'" encodedPasteboardType] , NSPICTPboardType, NSPostScriptPboardType, NSTIFFPboardType, NSColorPboardType, NSFileContentsPboardType, NSFontPboardType, NSHTMLPboardType, NSRulerPboardType, NSTabularTextPboardType, NSVCardPboardType, NSFilesPromisePboardType,nil]];
        for (NSString *key in [namesAndKeys allKeys]) {
			if (itemForKey(key) ) {
				[self setName:[namesAndKeys objectForKey:key]];
                break;
            }
		}
	}
}

- (BOOL)putOnPasteboardAsPlainTextOnly:(NSPasteboard *)pboard {
	NSArray *types = [NSArray arrayWithObject:NSStringPboardType];
	[pboard declareTypes:types owner:nil];
	NSString *string = [self stringValue];
	[pboard setString:string forType:NSStringPboardType];
	return YES;
}

// Declares the types that should be put on the pasteboard
- (BOOL)putOnPasteboard:(NSPasteboard *)pboard declareTypes:(NSArray *)types includeDataForTypes:(NSArray *)includeTypes {
	if (!types) {
		// get the different pboard types from the object's data dictionary -- they're all stored here
		types = [[[[self dataDictionary] allKeys] mutableCopy] autorelease];
		if ([types containsObject:QSProxyType])
			[(NSMutableArray *)types addObjectsFromArray:[[(QSObject *)[self resolvedObject] dataDictionary] allKeys]];
	}
	else {
		NSMutableSet *typeSet = [NSMutableSet setWithArray:types];
		[typeSet intersectSet:[NSSet setWithArray:[[self dataDictionary] allKeys]]];
		types = [[[typeSet allObjects] mutableCopy] autorelease];
	}
	// If there are no types for the object, we need to set one (using stringValue)
	if (![types count]) {
		[(NSMutableArray *)types addObject:NSStringPboardType];
		[[self dataDictionary] setObject:[self stringValue] forKey:NSStringPboardType];
	}
	
	// define the types to be included on the pasteboard
	if (!includeTypes) {
		if ([types containsObject:NSFilenamesPboardType])
			includeTypes = [NSArray arrayWithObject:NSFilenamesPboardType];
		//			[pboard declareTypes:includeTypes owner:self];
		else if ([types containsObject:NSURLPboardType])
			// for urls, define plain text, rtf and html
			includeTypes = [NSArray arrayWithObjects:NSURLPboardType,NSHTMLPboardType,NSRTFPboardType,NSStringPboardType,nil];
		else if ([types containsObject:NSColorPboardType])
			includeTypes = [NSArray arrayWithObject:NSColorPboardType];
	}
	// last case: no other useful types: return a basic string
	if (!includeTypes) {
		includeTypes = [NSArray arrayWithObject:NSStringPboardType];
	}

	[pboard declareTypes:types owner:self];
	/*
	 // ***warning  ** Should add additional information for file items	 if ([paths count] == 1) {
	 [[self data] setObject:[[NSURL fileURLWithPath:[paths lastObject]]absoluteString] forKey:NSURLPboardType];
	 [[self data] setObject:[paths lastObject] forKey:NSStringPboardType];
	 }
	 */
	//  NSLog(@"declareTypes: %@", [types componentsJoinedByString:@", "]);
	
	// For URLs, create the RTF and HTML data to be stored in the clipboard
	if ([types containsObject:NSURLPboardType]) {
		// add the RTF and HTML types to the list of types
		types = [types arrayByAddingObjectsFromArray:[NSArray arrayWithObjects:NSHTMLPboardType,NSRTFPboardType,nil]];
		// Create the HTML and RTF data
		NSData *htmlData = [NSString dataForObject:self forType:NSHTMLPboardType];
		NSData *rtfData = [NSString dataForObject:self forType:NSRTFPboardType];
		// Add the HTML and RTF data to the object's data dictionary
		[[self dataDictionary] setObject:htmlData forKey:NSHTMLPboardType];	
		[[self dataDictionary] setObject:rtfData forKey:NSRTFPboardType];
	}
	
	for (NSString *thisType in includeTypes) {
		if ([types containsObject:thisType]) {
			// NSLog(@"includedata, %@", thisType);
			[self pasteboard:pboard provideDataForType:thisType];
		}
	}
	if ([self identifier]) {
		[pboard addTypes:[NSArray arrayWithObject:@"QSObjectID"] owner:self];
		writeObjectToPasteboard(pboard, @"QSObjectID", [self stringValue]);
	}
	
	[pboard addTypes:[NSArray arrayWithObject:@"QSObjectAddress"] owner:self];
	//  NSLog(@"types %@", [pboard types]);
	return YES;
}

- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type {
	//if (VERBOSE) NSLog(@"Provide: %@", [type decodedPasteboardType]);
	if ([type isEqualToString:@"QSObjectAddress"]) {
		writeObjectToPasteboard(sender, type, [NSString stringWithFormat:@"%d:%@", [[NSProcessInfo processInfo] processIdentifier] , [self identifier]]);
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
	//  NSLog(@"%@ Lost the Pasteboard: %@", self, sender);
}

- (NSData *)dataForType:(NSString *)dataType {
	id theData = [data objectForKey:dataType];
	if ([theData isKindOfClass:[NSData class]]) return theData;
	return nil;
}
@end
