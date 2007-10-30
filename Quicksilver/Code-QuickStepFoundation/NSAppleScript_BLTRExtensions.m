//
//  NSAppleScript_BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.
//  Copyright (c) 2003 Blacktree. All rights reserved.
//

#import "NSAppleScript_BLTRExtensions.h"
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

#pragma mark -

@interface NSAEDescriptorTranslator : NSObject // Private Foundation Class
+ (id) sharedAEDescriptorTranslator;
- (NSAppleEventDescriptor *) descriptorByTranslatingObject:(id) object ofType:(id) type inSuite:(id) suite;
- (id) objectByTranslatingDescriptor:(NSAppleEventDescriptor *) descriptor toType:(id) type inSuite:(id) suite;
- (void) registerTranslator:(id) translator selector:(SEL) selector toTranslateFromClass:(Class) class;
- (void) registerTranslator:(id) translator selector:(SEL) selector toTranslateFromDescriptorType:(unsigned int) type;
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

@implementation NSAppleScript (Subroutine)

- (NSAppleEventDescriptor *)executeSubroutine:(NSString *)name arguments:(id)arguments error:(NSDictionary **)errorInfo{
	//   NSLog(@"Handlers: %@",[self handlers]);
    NSAppleEventDescriptor* event;
    NSAppleEventDescriptor* targetAddress;
    NSAppleEventDescriptor* subroutineDescriptor;
    // NSAppleEventDescriptor* arguments;
    if (arguments && ![arguments isKindOfClass:[NSAppleEventDescriptor class]])
        arguments=[NSAppleEventDescriptor descriptorWithObjectAPPLE:arguments];
    if (arguments && [arguments descriptorType]!=cAEList){
        NSAppleEventDescriptor *argumentList=[NSAppleEventDescriptor listDescriptor];
        [argumentList insertDescriptor:arguments atIndex:[arguments numberOfItems]+1];
        arguments=argumentList;
    }
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    targetAddress = [[[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)]autorelease];
    event = [[[NSAppleEventDescriptor alloc] initWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID]autorelease];
    subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:name];
    [event setParamDescriptor:subroutineDescriptor forKeyword:keyASSubroutineName];
    if (arguments) [event setParamDescriptor:arguments forKeyword:keyDirectObject];
    return [self executeAppleEvent:event error:errorInfo];
}

- (NSAppleEventDescriptor *)executeAppleEventWithEventClass:(AEEventClass)aEventClass eventID:(AEEventID)aEventID  arguments:(id)arguments error:(NSDictionary **)errorInfo{
    return nil;
} 


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

/*
 -(NSArray *)handlers{
	 NSLog(@"id %d",_compiledScriptID);
	 
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

@implementation NSAppleEventDescriptor (CocoaConversion)

+ (NSAppleEventDescriptor *)descriptorWithObjectAPPLE:(id)object{
	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] descriptorByTranslatingObject:object ofType:nil inSuite:nil];
}

- (id)objectValueAPPLE{
	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] objectByTranslatingDescriptor:self toType:nil inSuite:nil];
}

+ (NSAppleEventDescriptor *)XdescriptorWithObject:(id)object{
    NSAppleEventDescriptor *descriptorObject=nil;
    if ([object isKindOfClass:[NSArray class]]){
        descriptorObject=[NSAppleEventDescriptor listDescriptor];
        int i;
        for (i=0;i<[object count];i++){
            [descriptorObject insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:[object objectAtIndex:i]]
                                       atIndex:i+1];
        }
        return descriptorObject; 
    }
    else if ([object isKindOfClass:[NSString class]]){
        return [NSAppleEventDescriptor descriptorWithString:object];
    }else if ([object isKindOfClass:[NSNumber class]]){
        return [NSAppleEventDescriptor descriptorWithInt32:[object intValue]];
    }else if ([object isKindOfClass:[NSAppleEventDescriptor class]]){
        return object;
    }else if ([object isKindOfClass:[NSNull class]]){
        return [NSAppleEventDescriptor nullDescriptor];
    }
    
    return nil;
}
//- (id)newObjectValue;
- (id)xobjectValue{
    // NSLog(@"Convert type: %@",NSFileTypeForHFSTypeCode([self descriptorType]));
    switch ([self descriptorType]){
        case kAENullEvent:
            return nil;
        case cAEList:
        {
            NSMutableArray *array=[NSMutableArray arrayWithCapacity:[self numberOfItems]];
            int i;
            id theItem;
            // NSAppleEventDescriptor *itemDescriptor;
            for (i=0;i<[self numberOfItems];i++){
                theItem=[[self descriptorAtIndex:i+1]objectValue];
                if (theItem)[array addObject:theItem];
            }
			return array;
        }
        case cBoolean:
            return [NSNumber numberWithBool:[self booleanValue]];
            
            //   if (typeAERecord==[self descriptorType]) {
            //      return [NSNumber numberWithBool:[self booleanValue]];
            //    }
        default:
            return [self stringValue];
    }
    return nil;
}

+ (NSAppleEventDescriptor *)descriptorWithPath:(NSString *)path{
    if (!path)return 0;
	//  AppleEvent event, reply;
    OSErr err;
    FSRef fileRef;
    AliasHandle fileAlias;
    err = FSPathMakeRef((const UInt8 *)[path fileSystemRepresentation], &fileRef, NULL);
    if (err != noErr) return nil;
    err = FSNewAliasMinimal(&fileRef, &fileAlias);
    if (err != noErr) return nil;
    return [NSAppleEventDescriptor descriptorWithDescriptorType:typeAlias bytes:fileAlias length:sizeof(*fileAlias)];
	
}

@end




@implementation NSAppleScript (FilePeeking)
+ (NSArray *)validHandlersFromArray:(NSArray *)array inScriptFile:(NSString *)path;{
	NSData *scriptData=[NSData dataWithContentsOfMappedFile:path];
	if (![scriptData length]){
		NDResourceFork *resource=[NDResourceFork resourceForkForReadingAtPath:path];
		scriptData=[resource dataForType:'scpt' Id:128];
	}
	NSMutableArray *validHandlers=[NSMutableArray array];
	int i;
	for (i=0;i<[array count];i++){
		NSString *handler=[array objectAtIndex:i];
		if ([scriptData offsetOfData:[handler dataUsingEncoding:NSASCIIStringEncoding]]!=NSNotFound)
			[validHandlers addObject:handler];
	}
	return validHandlers;
}


@end











//----------------------------

//#import "MVChatPluginManager.h"
//#import "MVChatScriptPlugin.h"
//
//@interface NSScriptObjectSpecifier (NSScriptObjectSpecifierPrivate) // Private Foundation Methods
//+ (id) _objectSpecifierFromDescriptor:(NSAppleEventDescriptor *) descriptor inCommandConstructionContext:(id) context;
//- (NSAppleEventDescriptor *) _asDescriptor;
//@end
//
//#pragma mark -
//
//@interface NSAEDescriptorTranslator : NSObject // Private Foundation Class
//+ (id) sharedAEDescriptorTranslator;
//- (NSAppleEventDescriptor *) descriptorByTranslatingObject:(id) object ofType:(id) type inSuite:(id) suite;
//- (id) objectByTranslatingDescriptor:(NSAppleEventDescriptor *) descriptor toType:(id) type inSuite:(id) suite;
//- (void) registerTranslator:(id) translator selector:(SEL) selector toTranslateFromClass:(Class) class;
//- (void) registerTranslator:(id) translator selector:(SEL) selector toTranslateFromDescriptorType:(unsigned int) type;
//@end
//
//#pragma mark -
//
//@interface NSString (NSStringFourCharCode)
//- (unsigned long) fourCharCode;
//@end
//
//#pragma mark -
//
//@implementation NSString (NSStringFourCharCode)
//- (unsigned long) fourCharCode {
//	unsigned long ret = 0, length = [self length];
//	
//	if( length >= 1 ) ret |= ( [self characterAtIndex:0] & 0x00ff ) << 24;
//	else ret |= ' ' << 24;
//	if( length >= 2 ) ret |= ( [self characterAtIndex:1] & 0x00ff ) << 16;
//	else ret |= ' ' << 16;
//	if( length >= 3 ) ret |= ( [self characterAtIndex:2] & 0x00ff ) << 8;
//	else ret |= ' ' << 8;
//	if( length >= 4 ) ret |= ( [self characterAtIndex:3] & 0x00ff );
//	else ret |= ' ';
//	
//	return ret;
//}
//@end
//
//#pragma mark -
//
//@implementation NSAppleScript (NSAppleScriptIdentifier)
//- (NSNumber *) scriptIdentifier {
//	return [NSNumber numberWithUnsignedLong:_compiledScriptID];
//}
//@end
//
//#pragma mark -
//
//@implementation MVChatScriptPlugin
//- (id) initWithManager:(MVChatPluginManager *) manager {
//	if( ( self = [self init] ) ) {
//		_doseNotRespond = [[NSMutableSet set] retain];
//		_script = nil;
//	}
//	return self;
//}
//
//- (id) initWithScript:(NSAppleScript *) script andManager:(MVChatPluginManager *) manager {
//	if( ( self = [self initWithManager:manager] ) )
//		_script = [script retain];
//	return self;
//}
//
//- (void) dealloc {
//	[_script release];
//	[_doseNotRespond release];
//	
//	_script = nil;
//	_doseNotRespond = nil;
//	
//	[super dealloc];
//}
//
//#pragma mark -
//
//- (NSAppleScript *) script {
//	return _script;
//}
//
//- (id) callScriptHandler:(unsigned long) handler withArguments:(NSDictionary *) arguments forSelector:(SEL) selector {
//	if( ! _script ) return nil;
//	
//	int pid = [[NSProcessInfo processInfo] processIdentifier];
//	NSAppleEventDescriptor *targetAddress = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof( pid )];
//	NSAppleEventDescriptor *event = [NSAppleEventDescriptor appleEventWithEventClass:'cplG' eventID:handler targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
//	
//	NSEnumerator *enumerator = [arguments objectEnumerator];
//	NSEnumerator *kenumerator = [arguments keyEnumerator];
//	NSAppleEventDescriptor *descriptor = nil;
//	NSString *key = nil;
//	id value = nil;
//	
//	while( ( key = [kenumerator nextObject] ) && ( value = [enumerator nextObject] ) ) {
//		NSScriptObjectSpecifier *specifier = nil;
//		if( [value isKindOfClass:[NSScriptObjectSpecifier class]] ) specifier = value;
//		else specifier = [value objectSpecifier];
//		
//		if( specifier ) descriptor = [[value objectSpecifier] _asDescriptor]; // custom object, use it's object specitier
//		else descriptor = [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] descriptorByTranslatingObject:value ofType:nil inSuite:nil];
//		
//		if( ! descriptor ) descriptor = [NSAppleEventDescriptor nullDescriptor];
//		[event setDescriptor:descriptor forKeyword:[key fourCharCode]];
//	}
//	
//	NSDictionary *error = nil;
//	NSAppleEventDescriptor *result = [_script executeAppleEvent:event error:&error];
//	if( error && ! result ) { // an error
//		int code = [[error objectForKey:NSAppleScriptErrorNumber] intValue];
//		if( code == errAEEventNotHandled || code == errAEHandlerNotFound )
//			[self doesNotRespondToSelector:selector]; // disable for future calls
//		return [NSError errorWithDomain:NSOSStatusErrorDomain code:code userInfo:error];
//	}
//	
//	if( [result descriptorType] == 'obj ' ) { // an object specifier result, evaluate it to the object
//		NSScriptObjectSpecifier *specifier = [NSScriptObjectSpecifier _objectSpecifierFromDescriptor:result inCommandConstructionContext:nil];
//		return [specifier objectsByEvaluatingSpecifier];
//	}
//	
//	// a static result evaluate it to the proper object
//	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] objectByTranslatingDescriptor:result toType:nil inSuite:nil];
//}
//
//#pragma mark -
//
//- (BOOL) respondsToSelector:(SEL) selector {
//	if( ! _script || [_doseNotRespond containsObject:NSStringFromSelector( selector )] ) return NO;
//	return [super respondsToSelector:selector];
//}
//
//- (void) doesNotRespondToSelector:(SEL) selector {
//	[_doseNotRespond addObject:NSStringFromSelector( selector )];
//}
//@end