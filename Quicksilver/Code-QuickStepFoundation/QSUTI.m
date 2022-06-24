/*
 * QSUTI.c
 * Quicksilver
 *
 * Created by Alcor on 4/5/05.
 * Copyright 2005 Blacktree. All rights reserved.
 *
 */

#include "QSUTI.h"
static NSArray *QSFixedUTITypes = nil;
static NSArray *QSFixedNonUTITypes = nil;
/**
 *  Determines if a given string is an existing UTI or not
 *
 *  @param UTIString a string to test whether or not it is a UTI (as defined by Apple's launch service database)
 *
 *  @return Boolean value specifying if UTIString is a valid UTI
 */
BOOL QSIsUTI(NSString *UTIString) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		// 'fixed uti types' are typically Quicksilver internally defined strings, that don't have a corresponding reverse dot formatted UTI (like real UTIs). We know these types won't resolve to an actual UTI, so for performance gains, we consider them to already be 'UTIs'. See https://github.com/quicksilver/Quicksilver/issues/2356 for more info
		QSFixedUTITypes = @[@"public.utf8-plain-text", @"ABPeopleUIDsPboardType", @"AppActions", @"AttributedString", @"CalculatorActionProvider", @"ClipboardActions", @"CorePasteboardFlavorType 0x7374796C", @"CorePasteboardFlavorType 0x7573746C", @"CorePasteboardFlavorType 0x75743136", @"FSActions", @"FSDiskActions", @"mkdn", @"NSColorPboardType", @"NSFileContentsPboardType", @"NSFilesPromisePboardType", @"NSFontPboardType", @"NSHTMLPboardType", @"NSPDFPboardType", @"NSRulerPboardType", @"NSTabularTextPboardType", @"NSURLPboardType", @"NSVCardPboardType", @"OakPasteboardOptionsPboardType", @"OnePasswordAction", @"QS1PasswordForm", @"QSABContactActions", @"QSABMimicActionProvider", @"QSAdvancedProcessActionProvider", @"QSAirPortItemType", @"QSAirPortNetworkActionProvider", @"QSAppleMailPlugIn_Action", @"QSAppleScriptActions", @"QSCatalogEntrySource", @"QSChat_SupportType", @"QSCLExecutableProvider", @"QSCompressionActionProvider", @"QSDashDocsetType", @"QSDashPluginActionProvider", @"QSDisplayIDType", @"QSDisplayParametersType", @"QSDisplaysActionProvider", @"QSEmailActions", @"QSFileTag", @"QSFileTagsPlugInAction", @"QSFileTemplateManager", @"QSFormulaType", @"QSGoogleChromeActions", @"QSGoogleChromeCanaryActions", @"QSGoogleChromeProxies", @"QSHFSAttributeActions", @"QSImageManipulationPlugInAction", @"QSiPhotoActionProvider", @"QSiTerm2ActionProvider", @"QSiTunesActionProvider", @"QSKeychainActionProvider", @"QSKeychainItemType", @"QSKeychainType", @"QSLineReferenceActions", @"QSLineReferenceType", @"QSNetworkingActionProvider", @"QSNetworkingType", @"QSNetworkLocationActionProvider", @"QSObjCMessageSource", @"QSObjectActions", @"QSObjectName", @"QSPDQuicksilverPluginActionProvider", @"QSProcessActionProvider", @"QSQRCodeAction", @"QSQSFacetimeActionProvider", @"QSRemoteHostsAction", @"QSRemoteHostsGroupType", @"QSRemoteHostsType", @"QSRemovableVolumesParentType", @"QSSafariActionProvider", @"QSShelfSource", @"QSSpotlightPlugIn_Action", @"QSSpotlightSavedSearchSource", @"QSTextActions", @"QSTextManipulationPlugIn", @"QSTransmitSiteType", @"QSUIAccessPlugIn_Action", @"QSUnreadMailParent", @"QSURLSearchActions", @"QSViscosityAction", @"QSViscosityType", @"QSViscosityVPNAction", @"QSWirelessNetworkType", @"QSYojimboPlugInAction", @"URLActions", @"WindowsType", @"qs.action", @"qs.command", @"qs.proxy", @"qs.process", @"QSEmojisPluginType", @"QSTextProxyType"];
		// NOTE: The compiler gives a warning that these are deprecated, but don't change them, they must be these specific types
		// e.g. NSStringPboardType != NSPasteboardTypeString
		QSFixedNonUTITypes = @[NSStringPboardType, NSURLPboardType, NSRTFPboardType];
	});
	if ([QSFixedUTITypes containsObject:UTIString]) {
		return YES;
	}
	if ([QSFixedNonUTITypes containsObject:UTIString]) {
		return NO;
	}
	if ([UTIString rangeOfString:@"public."].location == 0) {
		return YES;
	}
 
	if (UTTypeIsDeclared((__bridge CFStringRef)UTIString)) {
        // UTIString has a declaration dictionary - it must be a UTI
        return YES;
    }
    if (UTTypeConformsTo((__bridge CFStringRef)UTIString, kUTTypeItem)) {
        // UTIString conforms to public.item - it must be a UTI
        return YES;
    }
    
    NSUInteger dotLocation = [UTIString rangeOfString:@"."].location;
    if (dotLocation > 0 && dotLocation < [UTIString length] -1) {
        // UTIString contains a . somewhere in the middle. Since UTIs use reverse DNS we can guess it is a UTI
        return YES;
    }

    return NO;
}

/**
 *  Returns whether a uniform type identifier conforms to another uniform type identifier. It's better than the UTType function. See discussion
 *
 *  @param inUTI           A uniform type identifier to compare.
 *  @param inConformsToUTI The uniform type identifier to compare it to.
 *
 *  @return Returns true if the uniform type identifier is equal to or conforms to the second type.
 *
 *  @discussion The UTTypeConformsTo() function isn't great in all cases. If a UTI for an unknown file extension has been created (e.g. "dyn-xxxxx" was created for the extension "myextension"), and subsequently an application regisers the extension "myextension" with the UTI "com.me.myextension", the OS will not say that "dyn-xxxxx" conforms to "com.me.myextension" (or vice-versa) when, in fact, they do. This function first resolves the extensions for the two UTIs, then attempts to convert them back to UTIs in order to check for UTI conformance
 */
BOOL QSTypeConformsTo(NSString *inUTI, NSString *inConformsToUTI) {
    if (UTTypeConformsTo((__bridge CFStringRef)inUTI, (__bridge CFStringRef)inConformsToUTI)) {
        return YES;
    }
    CFStringRef inUTIExtension = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)inUTI, kUTTagClassFilenameExtension);
    NSString *resolvedInUTI = nil;
    if (inUTIExtension) {
        resolvedInUTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, inUTIExtension, NULL);
        CFRelease(inUTIExtension);
    }
    CFStringRef inConformsToUTIExtension = UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)inConformsToUTI, kUTTagClassFilenameExtension);
    NSString *resolvedInConformsToUTI = nil;
    if (inConformsToUTIExtension) {
        resolvedInConformsToUTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, inConformsToUTIExtension, NULL);
        CFRelease(inConformsToUTIExtension);
    }
    return UTTypeConformsTo((__bridge CFStringRef)(resolvedInUTI ? resolvedInUTI : inUTI), (__bridge CFStringRef)(resolvedInConformsToUTI ? resolvedInConformsToUTI : inConformsToUTI));
}

NSString *QSUTIOfURL(NSURL *fileURL) {
    LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((__bridge CFURLRef)fileURL, kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	return QSUTIWithLSInfoRec([fileURL path], &infoRec);
}

NSString *QSUTIOfFile(NSString *path) {
    LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], kLSRequestTypeCreator|kLSRequestBasicFlagsOnly, &infoRec);
	return QSUTIWithLSInfoRec(path, &infoRec);
}

NSString *QSUTIWithLSInfoRec(NSString *path, LSItemInfoRecord *infoRec) {
	NSString *extension = [path pathExtension];
	if (![extension length])
		extension = nil;
	BOOL isDirectory;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory])
		return nil;

	if (infoRec->flags & kLSItemInfoIsAliasFile)
		return (NSString *)kUTTypeAliasFile;
	if (infoRec->flags & kLSItemInfoIsVolume)
		return (NSString *)kUTTypeVolume;

    // the order with which we try to resolve the UTI is important. First we use the OSType, *then* the file extension. This is wise since it's possible to give (possible misleading) extensions to folders - like myfolder.js (it is of type public.folder, not com.netscape.javascript-source)
	NSString *hfsType = (NSString *)CFBridgingRelease(UTCreateStringForOSType(infoRec->filetype));
	if (![hfsType length] && isDirectory && !(infoRec->flags & kLSItemInfoIsPackage))
		return (NSString *)kUTTypeFolder;

	NSString *hfsUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, (__bridge CFStringRef)hfsType, NULL));
	if (![hfsUTI hasPrefix:@"dyn"])
		return hfsUTI;
    
    NSString *extensionUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL));
	if (extensionUTI && ![extensionUTI hasPrefix:@"dyn"])
		return extensionUTI;

	if ([[NSFileManager defaultManager] isExecutableFileAtPath:path])
		return @"public.executable";

	return (extensionUTI ? extensionUTI : hfsUTI);
}

NSString *QSUTIForAnyTypeString(NSString *type) {
    if ([type isEqualToString:NSFilenamesPboardType]) {
        return (__bridge NSString *)kUTTypeData; // QSFilePathType
    }
    if ([type isEqualToString:NSStringPboardType]) {
        return (__bridge NSString *)kUTTypeUTF8PlainText; // QSTextType;
    }
	if ([type isEqualToString:NSURLPboardType]) {
		return NSURLPboardType; // technically this should be kUTTypeURL, but it seems we're still using NSURLPboardType as an URL all round atm.
	}
    if (!type || [type isEqualToString:@"*"] || QSIsUTI(type)) {
        return type;
    }
    
    NSString *uti = nil;
    NSString *cleanType = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'."]];
    for (NSString * UTTagClass in @[(__bridge NSString*)kUTTagClassFilenameExtension, (__bridge NSString *)kUTTagClassOSType, (__bridge NSString *)kUTTagClassNSPboardType, (__bridge NSString*)kUTTagClassMIMEType]) {
        NSString *utiFromOtherType = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag((__bridge CFStringRef)UTTagClass, (__bridge CFStringRef)(cleanType), NULL);
        if (![utiFromOtherType hasPrefix:@"dyn."]) {
            // we can assume that this is the correct UTI converted from 'UTTagClass'
            uti = utiFromOtherType;
            break;
        }
    }
	
    return uti ? uti : type;
}


// WARNING: This does not necessarily return the correct UTI. QSUTIWithLSInfoRec() is more reliable
NSString *QSUTIForExtensionOrType(NSString *extension, OSType filetype) {
	NSString *itemUTI = nil;

	if (extension != nil) {
		itemUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL));
	} else {
		CFStringRef fileTypeUTI = UTCreateStringForOSType(filetype);
		itemUTI = (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType, fileTypeUTI, NULL));
		CFRelease(fileTypeUTI);
	}
	return itemUTI;
}

/* Deprecated */
NSString *QSUTIForInfoRec(NSString *extension, OSType filetype) {
	return QSUTIForExtensionOrType(extension, filetype);
}

