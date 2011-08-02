//
// NSAppleScript_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on Thu Aug 28 2003.
// Copyright (c) 2003 Blacktree. All rights reserved.
//

#import "NSAppleScript_BLTRExtensions.h"
#import "NSData_RangeExtensions.h"
#import "NDAppleScriptObject.h"
#import "NDResourceFork.h"

#import <Carbon/Carbon.h>

#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

@interface NSAppleScript (NSPrivate)
+ (struct ComponentInstanceRecord *)_defaultScriptingComponent;
- (OSAID) _compiledScriptID;
@end

@interface NSScriptObjectSpecifier (NSScriptObjectSpecifierPrivate) // Private Foundation Methods
+ (id)_objectSpecifierFromDescriptor:(NSAppleEventDescriptor *)descriptor inCommandConstructionContext:(id)context;
- (NSAppleEventDescriptor *)_asDescriptor;
@end

@interface NSAEDescriptorTranslator : NSObject // Private Foundation Class
+ (id)sharedAEDescriptorTranslator;
- (NSAppleEventDescriptor *)descriptorByTranslatingObject:(id)object ofType:(id)type inSuite:(id)suite;
- (id)objectByTranslatingDescriptor:(NSAppleEventDescriptor *)descriptor toType:(id)type inSuite:(id)suite;
- (void)registerTranslator:(id)translator selector:(SEL) selector toTranslateFromClass:(Class) class;
- (void)registerTranslator:(id)translator selector:(SEL) selector toTranslateFromDescriptorType:(unsigned int) type;
@end

@implementation NSAppleScript (Constructors)
+ (NSAppleScript *)scriptWithContentsOfFile:(NSString *)path {
	return [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil] autorelease];
}
+ (NSAppleScript *)scriptWithContentsOfResource:(NSString *)path inBundle:(NSBundle *)bundle {
	return [[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[bundle pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]]] error:nil] autorelease];
}
@end

@implementation NSAppleScript (Subroutine)

- (NSAppleEventDescriptor *)executeSubroutine:(NSString *)name arguments:(id)arguments error:(NSDictionary **)errorInfo {
	// NSLog(@"Handlers: %@", [self handlers]);
	NSAppleEventDescriptor* event;
	NSAppleEventDescriptor* targetAddress;
	NSAppleEventDescriptor* subroutineDescriptor;
	// NSAppleEventDescriptor* arguments;
	if (arguments && ![arguments isKindOfClass:[NSAppleEventDescriptor class]])
		arguments = [NSAppleEventDescriptor descriptorWithObjectAPPLE:arguments];
	if (arguments && [arguments descriptorType] != cAEList) {
		NSAppleEventDescriptor *argumentList = [NSAppleEventDescriptor listDescriptor];
		[argumentList insertDescriptor:arguments atIndex:[arguments numberOfItems] +1];
		arguments = argumentList;
	}
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
	event = [[NSAppleEventDescriptor alloc] initWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:name];
	[event setParamDescriptor:subroutineDescriptor forKeyword:keyASSubroutineName];
	if (arguments) [event setParamDescriptor:arguments forKeyword:keyDirectObject];
	NSAppleEventDescriptor *desc = [self executeAppleEvent:event error:errorInfo];
    [event release];
    [targetAddress release];
    return desc;
}

- (NSAppleEventDescriptor *)executeAppleEventWithEventClass:(AEEventClass)aEventClass eventID:(AEEventID)aEventID arguments:(id)arguments error:(NSDictionary **)errorInfo {
	return nil;
}

- (NSData *)data {
	AEDesc				theDesc = { typeNull, NULL } ;
	NSData				* theData = nil;

	 {	if ( [self isCompiled] && (noErr == OSAStore( [NSAppleScript _defaultScriptingComponent] , [self _compiledScriptID] , typeOSAGenericStorage, kOSAModeNull, &theDesc ) ) )

		theData = [[NSAppleEventDescriptor descriptorWithAEDescNoCpy:&theDesc] data];
	}
	return theData;
}


- (BOOL)storeInFile:(NSString *)path {
	FSRef ref;
	FSPathMakeRef((const UInt8 *)[path UTF8String] , &ref, NULL );

	OSAStoreFile([NSAppleScript _defaultScriptingComponent] , [self _compiledScriptID] , typeOSAGenericStorage, kOSAModeNull,
				 &ref);

	//	[[self data] writeToFile:(NSString *)path atomically:flag];
	return YES;
}


- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)flag {
	[[self data] writeToFile:path atomically:flag];
	return YES;
}

/*
 -(NSArray *)handlers {
	 NSLog(@"id %d", _compiledScriptID);

	 NSArray			* theNamesArray = nil;
	 AEDescList		theNamesDescList;
	 if ( OSAGetHandlerNames (OpenDefaultComponent( kOSAComponentType, kAppleScriptSubtype ), kOSAModeNull, _compiledScriptID, &theNamesDescList ) == noErr ) {


		 theNamesArray = [NDAppleScriptObject objectForAEDesc: &theNamesDescList];
		 AEDisposeDesc( &theNamesDescList );
	 }

	 return theNamesArray;
 }
 */
@end

@implementation NSAppleEventDescriptor (CocoaConversion)

+ (NSAppleEventDescriptor *)descriptorWithObjectAPPLE:(id)object {
	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] descriptorByTranslatingObject:object ofType:nil inSuite:nil];
}

- (id)objectValueAPPLE {
	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] objectByTranslatingDescriptor:self toType:nil inSuite:nil];
}

+ (NSAppleEventDescriptor *)descriptorWithPath:(NSString *)path {
	if (!path) return 0;
	// AppleEvent event, reply;
	OSErr err;
	FSRef fileRef;
	AliasHandle fileAlias;
	err = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation] , &fileRef, NULL);
	if (err != noErr) return nil;
	err = FSNewAliasMinimal(&fileRef, &fileAlias);
	if (err != noErr) return nil;
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeAlias bytes:fileAlias length:sizeof(*fileAlias)];

}

@end

@implementation NSAppleScript (FilePeeking)
+ (NSArray *)validHandlersFromArray:(NSArray *)array inScriptFile:(NSString *)path; {
	NSData *scriptData = [NSData dataWithContentsOfMappedFile:path];
	if (![scriptData length]) {
		NDResourceFork *resource = [NDResourceFork resourceForkForReadingAtPath:path];
		scriptData = [resource dataForType:'scpt' Id:128];
        [resource closeFile];
	}
	NSMutableArray *validHandlers = [NSMutableArray array];
	for (NSString *handler in array) {
		if ([scriptData offsetOfData:[handler dataUsingEncoding:NSASCIIStringEncoding]] != NSNotFound)
			[validHandlers addObject:handler];
	}
	return validHandlers;
}
@end
