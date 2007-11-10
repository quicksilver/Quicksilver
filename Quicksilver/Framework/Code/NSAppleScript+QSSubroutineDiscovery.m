//
//  NSAppleScript_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.

//

#import "NSAppleScript+QSSubroutineDiscovery.h"
#import "NSData_RangeExtensions.h"
#import "NDAppleScriptObject.h"
#import "NDResourceFork.h"

#import <Carbon/Carbon.h>


#import "NSAppleEventDescriptor+NDAppleScriptObject.h"


@implementation NSAppleScript (QSSubroutineDiscovery)
+ (NSArray *)validHandlersFromArray:(NSArray *)array inScriptFile:(NSString *)path;{
	NSData *scriptData=[NSData dataWithContentsOfMappedFile:path];
	if (![scriptData length]){
		NDResourceFork *resource=[NDResourceFork resourceForkForReadingAtPath:path];
		scriptData=[resource dataForType:'scpt' Id:128];
	}
	NSMutableArray *validHandlers=[NSMutableArray array];
	for (NSString *handler in array){
		if ([scriptData offsetOfData:[handler dataUsingEncoding:NSASCIIStringEncoding]]!=NSNotFound)
			[validHandlers addObject:handler];
	}
	return validHandlers;
}

/*
 -(NSArray *)handlers{
 QSLog(@"id %d",_compiledScriptID);
 
 NSArray			* theNamesArray = nil;
 AEDescList		theNamesDescList;
 if( OSAGetHandlerNames (OpenDefaultComponent( kOSAComponentType, kAppleScriptSubtype ), kOSAModeNull, _compiledScriptID, &theNamesDescList ) == noErr ){
 
 
 theNamesArray = [NDAppleScriptObject objectForAEDesc: &theNamesDescList];
 AEDisposeDesc( &theNamesDescList );
 }
 
 return theNamesArray;
 }
 */
@end
