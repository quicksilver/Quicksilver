/*
 * QSUTI.c
 * Quicksilver
 *
 * Created by Alcor on 4/5/05.
 * Copyright 2005 Blacktree. All rights reserved.
 *
 */

#include "QSUTI.h"

/**
 *  Determines if a given string is an existing UTI or not
 *
 *  @param UTIString a string to test whether or not it is a UTI (as defined by Apple's launch service database)
 *
 *  @return Boolean value specifying if UTIString is a valid UTI
 */
BOOL QSIsUTI(NSString *UTIString) {
    if (UTTypeConformsTo((__bridge CFStringRef)UTIString, kUTTypeItem)) {
        // UTIString conforms to public.item - it must be a UTI
        return YES;
    }
    CFDictionaryRef dict = UTTypeCopyDeclaration((__bridge CFStringRef)UTIString);
    if (dict != NULL) {
        // UTIString has a declaration dictionary - it must be a UTI
        CFRelease(dict);
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
    if (!type || [type isEqualToString:@"*"] || QSIsUTI(type)) {
        return type;
    }
    
    NSString *uti = nil;
    NSString *cleanType = [type stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'."]];
    for (NSString * UTTagClass in @[(__bridge NSString *)kUTTagClassOSType, (__bridge NSString*)kUTTagClassFilenameExtension, (__bridge NSString*)kUTTagClassMIMEType, (__bridge NSString *)kUTTagClassNSPboardType]) {
        NSString *utiFromOtherType = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag((__bridge CFStringRef)UTTagClass, (__bridge CFStringRef)(cleanType), NULL);
        if (![utiFromOtherType hasPrefix:@"dyn."]) {
            // we can assume that this is the correct UTI converted from 'UTTagClass'
            uti = utiFromOtherType;
            break;
        }
    }
    if ([cleanType isEqualToString:NSPasteboardTypeString]) {
        return (__bridge NSString *)kUTTypeUTF8PlainText; // QSTextType;
    }
    if ([cleanType isEqualToString:NSFilenamesPboardType]) {
        return (__bridge NSString *)kUTTypeData; // QSFilePathType
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

