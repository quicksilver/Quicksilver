//
//  NSAppleScript+QSSubroutine.m
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.

//

#import "NSAppleScript+QSSubroutine.h"
#import "NSAppleEventDescriptor+QSTranslation.h"
#import <Carbon/Carbon.h>

@implementation NSAppleScript (QSSubroutine)

- (NSAppleEventDescriptor *)executeSubroutine:(NSString *)name arguments:(id)arguments error:(NSDictionary **)errorInfo {
    NSAppleEventDescriptor* event;
    NSAppleEventDescriptor* targetAddress;
    NSAppleEventDescriptor* subroutineDescriptor;
  
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