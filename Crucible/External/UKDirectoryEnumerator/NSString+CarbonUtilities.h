/* =============================================================================
    PROJECT:    Filie
    FILE:       NSString+CarbonUtilities.h
    
    COPYRIGHT:  (c) 2002 by Nathan Day, all rights reserved.
    
    AUTHORS:    Nathan Day - ND
    
    LICENSES:   GNU GPL, Modified BSD
    
    REVISIONS:
        2002-08-03  ND  Created.
   ========================================================================== */

// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


// -----------------------------------------------------------------------------
//  Headers:
// -----------------------------------------------------------------------------

@interface NSString (CarbonUtilities)

+(NSString*)    stringWithFSRef:(const FSRef *)aFSRef;
-(BOOL)         getFSRef:(FSRef *)aFSRef;

-(NSString*)    resolveAliasFile;

@end
