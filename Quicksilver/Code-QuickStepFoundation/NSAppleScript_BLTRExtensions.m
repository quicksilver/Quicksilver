//
// NSAppleScript_BLTRExtensions.m
// Quicksilver
//
// Created by Alcor on Thu Aug 28 2003.
// Copyright (c) 2003 Blacktree. All rights reserved.
//

#import "NSAppleScript_BLTRExtensions.h"
#import "NSData_RangeExtensions.h"
#import "NDScript.h"
#import "NDResourceFork.h"

#import <Carbon/Carbon.h>

#import "NSAppleEventDescriptor+NDCoercion.h"

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
- (void)registerTranslator:(id)translator selector:(SEL) selector toTranslateFromDescriptorType:(NSUInteger) type;
@end

@implementation NSAppleScript (Constructors)
+ (NSAppleScript *)scriptWithContentsOfFile:(NSString *)path {
	return [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
}
+ (NSAppleScript *)scriptWithContentsOfResource:(NSString *)path inBundle:(NSBundle *)bundle {
	return [[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[bundle pathForResource:[path stringByDeletingPathExtension] ofType:[path pathExtension]]] error:nil];
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
	NSInteger pid = [[NSProcessInfo processInfo] processIdentifier];
	targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
	event = [[NSAppleEventDescriptor alloc] initWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:name];
	[event setParamDescriptor:subroutineDescriptor forKeyword:keyASSubroutineName];
	if (arguments) [event setParamDescriptor:arguments forKeyword:keyDirectObject];
	NSAppleEventDescriptor *desc = [self executeAppleEvent:event error:errorInfo];
    return desc;
}

- (NSAppleEventDescriptor *)executeAppleEventWithEventClass:(AEEventClass)aEventClass eventID:(AEEventID)aEventID arguments:(id)arguments error:(NSDictionary **)errorInfo {
	return nil;
}

- (NSData *)data {
	AEDesc				theDesc = { typeNull, NULL } ;
	NSData				* theData = nil;

	 {	if ( [self isCompiled] && (noErr == OSAStore( [NSAppleScript _defaultScriptingComponent] , [self _compiledScriptID] , typeOSAGenericStorage, kOSAModeNull, &theDesc ) ) )

		theData = [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] data];
	}
	return theData;
}


- (BOOL)storeInFile:(NSString *)path {
	FSRef ref;
	BOOL success = [path getFSRef:&ref];
	if (!success) return NO;

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

+ (NSAppleEventDescriptor *)XdescriptorWithObject:(id)object {
	NSAppleEventDescriptor *descriptorObject = nil;
	if ([object isKindOfClass:[NSArray class]]) {
		descriptorObject = [NSAppleEventDescriptor listDescriptor];
		NSUInteger i;
		for (i = 0; i < [(NSArray *)object count]; i++) {
			[descriptorObject insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:[object objectAtIndex:i]] atIndex:i+1];
		}
		return descriptorObject;
	} else if ([object isKindOfClass:[NSString class]]) {
		return [NSAppleEventDescriptor descriptorWithString:object];
	} else if ([object isKindOfClass:[NSNumber class]]) {
		return [NSAppleEventDescriptor descriptorWithInt32:[object intValue]];
	} else if ([object isKindOfClass:[NSAppleEventDescriptor class]]) {
		return object;
	} else if ([object isKindOfClass:[NSNull class]]) {
		return [NSAppleEventDescriptor nullDescriptor];
	} else {
		return nil;
	}
}

- (id)xobjectValue {
	// NSLog(@"Convert type: %@", NSFileTypeForHFSTypeCode([self descriptorType]) );
	switch ([self descriptorType]) {
		case kAENullEvent:
			return nil;
		case cAEList: {
			NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self numberOfItems]];
			NSInteger i;
			id theItem;
			for (i = 0; i<[self numberOfItems]; i++) {
				theItem = [[self descriptorAtIndex:i+1] objectValue];
				if (theItem) [array addObject:theItem];
			}
			return array;
		}
		case cBoolean:
			return [NSNumber numberWithBool:[self booleanValue]];

			// if (typeAERecord == [self descriptorType]) {
			//	 return [NSNumber numberWithBool:[self booleanValue]];
			//	}
		default:
			return [self stringValue];
	}
	return nil;
}

+ (NSAppleEventDescriptor *)descriptorWithPath:(NSString *)path {
	if (!path) return nil;
	OSErr err;
	FSRef fileRef;
	AliasHandle fileAlias;
	BOOL success = [path getFSRef:&fileRef];
	if (!success) return nil;

	err = FSNewAliasMinimal(&fileRef, &fileAlias);
	if (err != noErr) return nil;

	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeAlias bytes:fileAlias length:sizeof(*fileAlias)];
}

@end

@implementation NSAppleScript (FilePeeking)
+ (NSArray *)validHandlersFromArray:(NSArray *)array inScriptFile:(NSString *)path {
	NSData *scriptData = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path] options:NSDataReadingMappedAlways error:nil];
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
