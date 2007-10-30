/*
 *  QSUTI.c
 *  Quicksilver
 *
 *  Created by Alcor on 4/5/05.
 *  Copyright 2005 Blacktree. All rights reserved.
 *
 */

#include "QSUTI.h"


NSString *QSUTIForAnyTypeString(NSString *type){
	NSString *itemUTI = NULL;
	
	OSType filetype=0;
	NSString *extension=nil;

	if ([type hasPrefix:@"'"] && [type length]==6)
		filetype=NSHFSTypeCodeFromFileType(type);
	else
		extension=type;
	itemUTI=QSUTIForExtensionOrType(extension,filetype);
	if ([itemUTI hasPrefix:@"dyn"])itemUTI=nil;
	return itemUTI;
}

NSString *QSUTIForExtensionOrType(NSString *extension,OSType filetype){
	NSString *itemUTI = NULL;
	//QSLog(@"type %@ %@",extension,UTCreateStringForOSType(filetype));
	if ( extension != NULL ){
		itemUTI = (NSString *)UTTypeCreatePreferredIdentifierForTag (kUTTagClassFilenameExtension,
														 (CFStringRef)extension, 
														 NULL );
	}else{
		if (filetype=='fold') return @"public.folder";
		itemUTI = (NSString *)UTTypeCreatePreferredIdentifierForTag (kUTTagClassOSType, 
														 (CFStringRef)[(NSString *)UTCreateStringForOSType(filetype) autorelease], 
														 NULL );
	}
				
	return [itemUTI autorelease];
}

NSString *QSUTIForInfoRec(NSString *extension,OSType filetype){
	NSString *itemUTI = NULL;
	//QSLog(@"type %@ %@",extension,UTCreateStringForOSType(filetype));
	if ( extension != NULL ){
		itemUTI = (NSString *) UTTypeCreatePreferredIdentifierForTag (kUTTagClassFilenameExtension,
														 (CFStringRef)extension, 
														 NULL );
	}else{
		itemUTI = (NSString *) UTTypeCreatePreferredIdentifierForTag (kUTTagClassOSType, 
														 (CFStringRef)[(NSString *)UTCreateStringForOSType(filetype) autorelease], 
														 NULL );
	}
				
	return [itemUTI autorelease];
}

