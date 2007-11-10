//
//  NSAppleScript_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.

//

#import "NSAppleScript+QSStorage.h"
#import "NSData_RangeExtensions.h"
#import "NDAppleScriptObject.h"
#import "NDResourceFork.h"

#import <Carbon/Carbon.h>


#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

@interface NSAppleScript (NSPrivate)
+ (struct ComponentInstanceRecord *)_defaultScriptingComponent;
- (OSAID)_compiledScriptID;
@end



@interface NSScriptObjectSpecifier (NSScriptObjectSpecifierPrivate) // Private Foundation Methods
+ (id) _objectSpecifierFromDescriptor:(NSAppleEventDescriptor *) descriptor inCommandConstructionContext:(id) context;
- (NSAppleEventDescriptor *) _asDescriptor;
@end





@implementation NSAppleScript (Constructors)
+ (NSAppleScript *)scriptWithContentsOfFile:(NSString *)path{
	return [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
}
+ (NSAppleScript *)scriptWithContentsOfResource:(NSString *)path inBundle:(NSBundle *)bundle{
	path=[bundle pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]];
	return [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
}
@end

@implementation NSAppleScript (QSStorage)

- (NSData *)data
{
	AEDesc				theDesc = { typeNull, NULL };
	NSData				* theData = nil;
	
	{	if( [self isCompiled] && (noErr == OSAStore( [NSAppleScript _defaultScriptingComponent], [self _compiledScriptID], typeOSAGenericStorage, kOSAModeNull, &theDesc ) ) )

		theData = [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] data];
	}
	return theData;
}


- (BOOL)storeInFile:(NSString *)path{
	FSRef ref;
	FSPathMakeRef((const UInt8 *)[path UTF8String], &ref, NULL );
	
	OSAStoreFile([NSAppleScript _defaultScriptingComponent], [self _compiledScriptID], typeOSAGenericStorage, kOSAModeNull,
				 &ref);
	
	//	[[self data]writeToFile:(NSString *)path atomically:flag];
	return YES;
}


- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag{
	[[self data]writeToFile:(NSString *)path atomically:flag];
	return YES;
}


@end