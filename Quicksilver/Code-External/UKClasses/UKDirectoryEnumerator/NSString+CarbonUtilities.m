/* == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == ===
	PROJECT:	Filie
	FILE:	  NSString+CarbonUtilities.m

	COPYRIGHT: (c) 2002 by Nathan Day, all rights reserved.

	AUTHORS:	Nathan Day - ND

	LICENSES:  GNU GPL, Modified BSD

	REVISIONS:
		2002-08-03 ND Created.
  = == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == == = */

// -----------------------------------------------------------------------------
// Headers:
// -----------------------------------------------------------------------------

#import "NSString+CarbonUtilities.h"

@implementation NSString (CarbonUtilities)

+ (NSString *)stringWithFSRef:(const FSRef *)aFSRef {
	UInt8 thePath[PATH_MAX + 1]; 		// plus 1 for \0 terminator
	return (FSRefMakePath( aFSRef, thePath, PATH_MAX ) == noErr) ? [NSString stringWithUTF8String:thePath] : nil;
}

- (BOOL)getFSRef:(FSRef *)aFSRef { return FSPathMakeRef( [self UTF8String] , aFSRef, NULL ) == noErr; }

- (NSString *)resolveAliasFile {
	FSRef theRef;
	Boolean theIsTargetFolder, theWasAliased;

	[self getFSRef:&theRef];
	if ( (FSResolveAliasFile ( &theRef, YES, &theIsTargetFolder, &theWasAliased ) == noErr) )
		return (theWasAliased) ? [NSString stringWithFSRef:&theRef] : self;
	else
		return nil;
}

@end


