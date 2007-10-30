/*
 *  NDAppleScriptObject.m
 *  NDAppleScriptObjectProject
 *
 *  Created by nathan on Thu Nov 29 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

#import "NDAppleScriptObject.h"
#import "NSURL+NDCarbonUtilities.h"
#import "NDResourceFork.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#import "NDComponentInstance.h"

const	short				kScriptResourceID = 128;
static const OSType	kScriptEditorCreatorCode = 'ToyS',
							kCompiledAppleScriptTypeCode = 'osas';

const NSString			* NDAppleScriptOffendingObject = @"Error Offending Object";
const NSString			* NDAppleScriptPartialResult = @"Error Partial Result";

/*
 * class interface NDAppleScriptObject (Private)
 */
@interface NDAppleScriptObject (Private)
- (OSAID)compileString:(NSString *)aString modeFlags:(long)aModeFlags scriptID:(OSAID)aCompiledScript;
- (OSAID)loadCompiledScriptData:(NSData *)aData;

- (OSAID)compiledScriptID;
- (ComponentInstance)scriptingComponent;
@end

/*
 * class interface NDComponentInstance (Private)
 */
@interface NDComponentInstance (Private)
- (ComponentInstance)scriptingComponent;
@end

/*
 * class implementation NDAppleScriptObject
 */
@implementation NDAppleScriptObject

/*
 * + compileExecuteString:
 */
+ (id)compileExecuteString:(NSString *)aString
{
	return [self compileExecuteString:aString componentInstance:[NDComponentInstance sharedComponentInstance]];
}


/*
 * + compileExecuteString:componentInstance:
 */
+ (id)compileExecuteString:(NSString *)aString componentInstance:(NDComponentInstance *)aComponentInstance
{
	OSAID							theResultID;
	AEDesc						theResultDesc = { typeNull, NULL };
	NSAppleEventDescriptor	* theDescString,
									* theResult = nil;

	theDescString = [NSAppleEventDescriptor descriptorWithString:aString];

	if( theDescString && OSACompileExecute( [aComponentInstance scriptingComponent], [theDescString aeDesc], kOSANullScript, kOSAModeNull, &theResultID) ==  noErr )
	{
		if( OSACoerceToDesc( [aComponentInstance scriptingComponent], theResultID, typeWildCard, kOSAModeNull, &theResultDesc ) == noErr )
		{
			theResult = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theResultDesc];

			OSADispose( [aComponentInstance scriptingComponent], theResultID );
		}
		else
		{
			NSLog(@"Could not coerc result");
		}
	}

	return [theResult objectValue];
}

/*
 * + appleScriptObjectWithString:
 */
+ (id)appleScriptObjectWithString:(NSString *)aString
{
	return [[[self alloc] initWithString:aString modeFlags:kOSAModeCompileIntoContext] autorelease];
}

/*
 * + appleScriptObjectWithString:componentInstance:
 */
+ (id)appleScriptObjectWithString:(NSString *)aString componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithString:aString modeFlags:kOSAModeCompileIntoContext componentInstance:aComponentInstance] autorelease];
}

/*
 * + appleScriptObjectWithData:
 */
+ (id)appleScriptObjectWithData:(NSData *)aData
{
	return [[[self alloc] initWithData:aData] autorelease];
}

/*
 * + appleScriptObjectWithData:componentInstance:
 */
+ (id)appleScriptObjectWithData:(NSData *)aData componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithData:aData componentInstance:(NDComponentInstance *)aComponentInstance] autorelease];
}

/*
 * + appleScriptObjectWithPath:
 */
+ (id)appleScriptObjectWithContentsOfFile:(NSString *)aPath
{
	return [[[self alloc] initWithContentsOfFile:aPath] autorelease];
}

/*
 * + appleScriptObjectWithPath:componentInstance:
 */
+ (id)appleScriptObjectWithContentsOfFile:(NSString *)aPath componentInstance:(NDComponentInstance *)aComponentInstance
{
	return [[[self alloc] initWithContentsOfFile:aPath componentInstance:aComponentInstance] autorelease];
}

/*
 * + appleScriptObjectWithURL:
 */
+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)aURL
{
	return [[[self alloc] initWithContentsOfURL:aURL] autorelease];
}

/*
 * + appleScriptObjectWithURL:componentInstance:
 */
+ (id)appleScriptObjectWithContentsOfURL:(NSURL *)aURL componentInstance:(NDComponentInstance *)aComponentInstance;
{
	return [[[self alloc] initWithContentsOfURL:aURL componentInstance:aComponentInstance] autorelease];
}

/*
 * -init
 */
- (id)init
{
	if( self = [super init] )
	{
		componentInstance = nil;
		scriptSource = nil;
		compiledScriptID = kOSAModeNull;
		resultingValueID = kOSANullScript;
		executionModeFlags = kOSAModeNull;
	}

	return self;
}
/*
 * - initWithString:modeFlags:
 */
- (id)initWithString:(NSString *)aString
{
	return [self initWithString:aString modeFlags:kOSAModeCompileIntoContext componentInstance:nil];
}

/*
 * - initWithString:modeFlags:
 */
- (id)initWithString:(NSString *)aString modeFlags:(long)aModeFlags
{
	return [self initWithString:aString modeFlags:aModeFlags componentInstance:nil];
}

/*
 * - initWithContentsOfFile:
 */
- (id)initWithContentsOfFile:(NSString *)aPath
{
	return [self initWithContentsOfFile:aPath componentInstance:nil];
}

/*
 * - initWithContentsOfFile:componentInstance:
 */
- (id)initWithContentsOfFile:(NSString *)aPath componentInstance:(NDComponentInstance *)aComponent
{
	NSData		* theData;
	
	if( (theData = [[NDResourceFork resourceForkForReadingAtPath:aPath] dataForType:kOSAScriptResourceType Id:kScriptResourceID]) != nil )
	{
		self = [self initWithData:theData componentInstance:aComponent];
	}
	else if( (theData = [NSData dataWithContentsOfFile:aPath]) != nil )
	{
		self = [self initWithData:theData componentInstance:aComponent];
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
}

/*
 * initWithContentsOfURL:
 */
- (id)initWithContentsOfURL:(NSURL *)aURL
{
	return [self initWithContentsOfURL:aURL componentInstance:nil];
}

/*
 * - initWithContentsOfURL:
 */
- (id)initWithContentsOfURL:(NSURL *)aURL componentInstance:(NDComponentInstance *)aComponent
{
	NSData		* theData;
	
	if( (theData = [[NDResourceFork resourceForkForReadingAtURL:aURL] dataForType:kOSAScriptResourceType Id:kScriptResourceID]) != nil )
	{
		self = [self initWithData:theData componentInstance:aComponent];
	}
	else if( (theData = [NSData dataWithContentsOfURL:aURL]) != nil )
	{
		self = [self initWithData:theData componentInstance:aComponent];
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
}

/*
 * - initWithAppleEventDescriptor:
 */
- (id)initWithAppleEventDescriptor:(NSAppleEventDescriptor *)aDescriptor
{
	if( [aDescriptor descriptorType] == cScript )
	{
		self = [self initWithData:[aDescriptor data]];
	}
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
}

/*
 * - initWithData:
 */
- (id)initWithData:(NSData *)aData
{
	return [self initWithData:aData componentInstance:nil];
}

/*
 * - initWithString:modeFlags:componentInstance:
 */
- (id)initWithString:(NSString *)aString modeFlags:(long)aModeFlags componentInstance:(NDComponentInstance *)aComponent
{
	if( ( self = [self init] )  )
	{
		if( aComponent == nil )		// use the shared ComponentInstance if not given one
			aComponent = [NDComponentInstance sharedComponentInstance];

		componentInstance = [aComponent retain];
		compiledScriptID = [self compileString:aString modeFlags:aModeFlags scriptID:kOSANullScript];
		resultingValueID = kOSANullScript;
		executionModeFlags = kOSAModeNull;
		
		if( compiledScriptID == kOSANullScript )
			scriptSource = [aString retain];	// can't get source from compiled script so we need to keep it
	}

	return self;
}

/*
 * - initWithData:componet:
 */
- (id)initWithData:(NSData *)aData componentInstance:(NDComponentInstance *)aComponent
{
	if( (self = [self init]) != nil )
	{
		if( aComponent == nil )		// use the shared ComponentInstance if not given one
			aComponent = [NDComponentInstance sharedComponentInstance];

		componentInstance = [aComponent retain];
		compiledScriptID = [self loadCompiledScriptData:aData];
		resultingValueID = kOSANullScript;
		executionModeFlags = kOSAModeNull;

		if( compiledScriptID == kOSANullScript )
		{
			[self release];
			self = nil;
		}
	}

	return self;
}

/*
 * - dealloc
 */
-(void)dealloc
{
	if( compiledScriptID != kOSANullScript )
	{
		OSADispose( [self scriptingComponent], compiledScriptID );
	}
	
	if( resultingValueID != kOSANullScript )
	{
		OSADispose( [self scriptingComponent], resultingValueID );
	}
	
	[componentInstance release];
	[scriptSource release];
	
	[super dealloc];
}

/*
 * - data
 */
- (NSData *)data
{
	AEDesc				theDesc = { typeNull, NULL };
	NSData				* theData = nil;

	if( [self isCompiled] && (noErr == OSAStore( [self scriptingComponent], compiledScriptID, typeOSAGenericStorage, kOSAModeNull, &theDesc ) ) )
	{
		theData = [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] data];
	}
	return theData;
}

/*
 * - execute
 */
- (BOOL)execute
{
	if( resultingValueID != kOSANullScript )
	{
		OSADispose( [self scriptingComponent], resultingValueID );
		resultingValueID = kOSANullScript;
	}
	return [self isCompiled] && OSAExecute([self scriptingComponent], compiledScriptID, kOSANullScript, [self executionModeFlags], &resultingValueID) == noErr;
}

/*
 * - executeOpen:
 */
- (BOOL)executeOpen:(NSArray *)aParameters
{
	NSAppleEventDescriptor	* theEvent = nil;
	theEvent = [NSAppleEventDescriptor openEventDescriptorWithTargetDescriptor:[self appleEventTarget] array:aParameters];

	return (theEvent != nil) ? [self executeEvent:theEvent] : NO;
}

/*
 * - executeEvent:
 */
- (BOOL)executeEvent:(NSAppleEventDescriptor *)anEvent
{
	if( resultingValueID != kOSANullScript )
	{
		OSADispose( [self scriptingComponent], resultingValueID );
		resultingValueID = kOSANullScript;
	}
	return [self isCompiled] && OSAExecuteEvent([self scriptingComponent], [anEvent aeDesc], [self compiledScriptID], [self executionModeFlags], &resultingValueID) == noErr;
}

/*
 * -executeSubroutineNamed:withArgumentsArray:
 */
- (BOOL)executeSubroutineNamed:(NSString *)aName argumentsArray:(NSArray *)anArray
{
	return [self executeEvent:[NSAppleEventDescriptor descriptorWithSubroutineName:aName argumentsArray:anArray]];
}

/*
 * -executeSubroutineNamed:arguments:...
 */
- (BOOL)executeSubroutineNamed:(NSString *)aName arguments:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [NSAppleEventDescriptor listDescriptorWithObjects:anObject arguments:theArgList];
	va_end( theArgList );

	return [self executeEvent:[NSAppleEventDescriptor descriptorWithSubroutineName:aName argumentsListDescriptor:theDescriptor]];
}

/*
 * -executeSubroutineNamed:labelsAndArguments:...
 */
- (BOOL)executeSubroutineNamed:(NSString *)aName labelsAndArguments:(AEKeyword)aKeyWord, ...
{
	NSAppleEventDescriptor	* theDescriptor;
	va_list	theArgList;
	va_start( theArgList, aKeyWord );
	theDescriptor = [[[NSAppleEventDescriptor alloc] initWithSubroutineName:aName labelsAndArguments:aKeyWord arguments:theArgList] autorelease];
	va_end( theArgList );

	return [self executeEvent:theDescriptor];
}

/*
 * - arrayOfEventIdentifier
 */
- (NSArray *)arrayOfEventIdentifier
{
	AEDescList		theEventIdentifierList;
	NSArray			* theArray = nil;
	
	if( [self isCompiled] && OSAGetHandlerNames ( [self scriptingComponent], kOSAModeNull, [self compiledScriptID], &theEventIdentifierList ) == noErr )
	{
		theArray = [[[[NSAppleEventDescriptor  alloc] initWithAEDescNoCopy:&theEventIdentifierList] autorelease] arrayValue];
	}
	return theArray;
}

/*
 * - respondsToEventClass:eventID:
 */
- (BOOL)respondsToEventClass:(AEEventClass)aEventClass eventID:(AEEventID)aEventID 
{
	NSDictionary		* theEventIdentifier;
	
	theEventIdentifier = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:aEventClass], @"EventClass", [NSNumber numberWithUnsignedInt:aEventID], @"EventID", nil];
	return [[self arrayOfEventIdentifier] containsObject:theEventIdentifier];
}

/*
 * - respondsToSubroutine:
 */
- (BOOL)respondsToSubroutine:(NSString *)aName
{
	return [[self arrayOfEventIdentifier] containsObject:[aName lowercaseString]];
}

- (NSArray *)arrayOfPropertyNames
{
	AEDescList		thePropertyNamesList;
	NSArray			* theArray = nil;

	if( [self isCompiled] && OSAGetPropertyNames ( [self scriptingComponent], kOSAModeNull, [self compiledScriptID], &thePropertyNamesList ) == noErr )
	{
		theArray = [[[[NSAppleEventDescriptor  alloc] initWithAEDescNoCopy:&thePropertyNamesList] autorelease] arrayValue];
	}
	return theArray;
}

- (NSAppleEventDescriptor *)descriptorForPropertyNamed:(NSString *)aVariableName
{
	AEDesc						theDesc = { typeNull, NULL };
	OSAID							theResultID = 0;
	NSAppleEventDescriptor	* theResultDesc = nil,
									* theNameDescriptor = [NSAppleEventDescriptor descriptorWithString:aVariableName];
	OSAError						theErr;

	if( OSAGetProperty( [self scriptingComponent], kOSAModeNull, [self compiledScriptID], [theNameDescriptor aeDesc], &theResultID ) == noErr )
	{
		if( (theErr = OSACoerceToDesc ( [self scriptingComponent], theResultID, typeWildCard, kOSAModeNull, &theDesc )) == noErr )
			theResultDesc = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc];
	}

	return theResultDesc;
}

- (id)valueForPropertyNamed:(NSString *)aVariableName
{
	return [[self descriptorForPropertyNamed:aVariableName] objectValue];
}

- (BOOL)setPropertyNamed:(NSString *)aVariableName toDescriptor:(NSAppleEventDescriptor *)aDescriptor  define:(BOOL)aFlag
{
	OSAID		theScriptValue = kOSANullScript;
	NSAppleEventDescriptor	* theNameDescriptor = [NSAppleEventDescriptor descriptorWithString:aVariableName];
	return OSACoerceFromDesc( [self scriptingComponent], [aDescriptor aeDesc], kOSAModeNull, &theScriptValue) == noErr
		&& OSASetProperty ( [self scriptingComponent], aFlag ? kOSAModeNull : kOSAModeDontDefine, compiledScriptID, [theNameDescriptor aeDesc], theScriptValue ) == noErr;
	
}

- (BOOL)setPropertyNamed:(NSString *)aVariableName toValue:(id)aValue define:(BOOL)aFlag
{
	return [self setPropertyNamed:aVariableName toDescriptor:[NSAppleEventDescriptor descriptorWithObject:aValue] define:aFlag];
}

/*
 * resultDescriptor
 */
- (NSAppleEventDescriptor *)resultAppleEventDescriptor
{
	AEDesc							theResultDesc = { typeNull, NULL };
	NSAppleEventDescriptor		* theDescriptor = nil;
	
	if( [self isCompiled] && OSACoerceToDesc( [self scriptingComponent], resultingValueID, typeWildCard, kOSAModeNull, &theResultDesc ) == noErr )
	{
		theDescriptor = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theResultDesc];
	}
	return theDescriptor;
}

/*
 * resultObject
 */
- (id)resultObject
{
	return [[self resultAppleEventDescriptor] objectValue];
}

/*
 * resultData
 */
- (id)resultData
{
	return [[self resultAppleEventDescriptor] data];
}

/*
 * - resultAsString
 */
- (NSString *)resultAsString
{
	AEDesc					theResultDesc = { typeNull, NULL };
	NSString					* theString = nil;
	if( [self isCompiled] && OSADisplay( [self scriptingComponent], resultingValueID, typeChar, kOSAModeNull, &theResultDesc ) == noErr )
	{
		theString = [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theResultDesc] stringValue];
	}
	return theString;
}

/*
 * -componentInstance
 */
- (NDComponentInstance *)componentInstance
{
	return componentInstance;
}

/*
 * - executionModeFlags
 */
- (long)executionModeFlags
{
	return executionModeFlags;
}

/*
 * -setExecutionModeFlags:
 */
- (void)setExecutionModeFlags:(long)aModeFlags
{
	executionModeFlags = aModeFlags;
}

/*
 * appleEventTarget
 */
- (NSAppleEventDescriptor *)appleEventTarget
{
	unsigned int				theCurrentProcess = kCurrentProcess;

	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber data:[NSData dataWithBytes:&theCurrentProcess length:sizeof(theCurrentProcess)]];
}

/*
 * -error
 */
- (NSDictionary *)error
{
	AEDesc					aDescriptor;
	unsigned int			theIndex;
	ComponentInstance		theComponentInstance = [self scriptingComponent];
	NSMutableDictionary	* theDictionary = [NSMutableDictionary dictionaryWithCapacity:7];

	struct { const NSString * key; const DescType desiredType; const OSType selector; }
			theResults[] = {
				{ NSAppleScriptErrorMessage, typeText, kOSAErrorMessage },
				{ NSAppleScriptErrorNumber, typeShortInteger, kOSAErrorNumber },
				{ NSAppleScriptErrorAppName, typeText, kOSAErrorApp },
				{ NSAppleScriptErrorBriefMessage, typeText, kOSAErrorBriefMessage },
				{ NSAppleScriptErrorRange, typeOSAErrorRange, kOSAErrorRange },
				{ NDAppleScriptOffendingObject, typeObjectSpecifier, kOSAErrorOffendingObject, },
				{ NDAppleScriptPartialResult, typeBest, kOSAErrorPartialResult },
				{ nil, 0, 0 }
			};
	for( theIndex = 0; theResults[theIndex].key != nil; theIndex++ )
	{
		if( OSAScriptError(theComponentInstance, theResults[theIndex].selector, theResults[theIndex].desiredType, &aDescriptor ) == noErr )
		{
			[theDictionary setObject:(id)[[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&aDescriptor] objectValue] forKey:(id)theResults[theIndex].key];
		}
	}

	return theDictionary;
}

/*
 * -compile
 */
- (BOOL)compile
{
	return [self compileWithModeFlags:kOSAModeCompileIntoContext];
}

/*
 * -compileWithModeFlags:
 */
- (BOOL)compileWithModeFlags:(long)aModeFlags
{
	if( ![self isCompiled] && scriptSource != nil )
	{
		compiledScriptID = [self compileString:scriptSource modeFlags:aModeFlags scriptID:kOSANullScript];

		if( compiledScriptID != kOSANullScript )
		{
			[scriptSource release];
			scriptSource = nil;
		}
	}

	return [self isCompiled];
}

/*
 * -isCompiled
 */
- (BOOL)isCompiled
{
	return compiledScriptID != kOSANullScript;
}

/*
 * -source
 */
- (NSString *)source
{
	AEDesc		theDesc = { typeNull, NULL };
	NSString		* theSource = scriptSource;
	OSAError		theErr = noErr;

	if( theSource == nil && (theErr = OSAGetSource( [self scriptingComponent], compiledScriptID, typeChar, &theDesc)) == noErr )
	{
		theSource = [[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] stringValue];
	}
	
	return theSource;
}

/*
 * -description
 */
- (NSString *)description
{
	NSString		* theScriptSource = [self source];

	return theScriptSource ? [NSString stringWithFormat:@"\"%@\"",[[theScriptSource componentsSeparatedByString:@"\""] componentsJoinedByString:@"\\\""]] : @"NDAppleScriptObject: source not available";
}

/*
 * -writeToURL:
 */
- (BOOL)writeToURL:(NSURL *)aURL
{
	return [self writeToURL:aURL Id:kScriptResourceID];
}

- (BOOL)writeToURL:(NSURL *)aURL inDataFork:(BOOL)aFlag atomically:(BOOL)anAtomically
{
	return aFlag
			? [[self data] writeToURL:aURL atomically:anAtomically]
			: [self writeToURL:aURL Id:kScriptResourceID];
}
/*
 * -writeToURL:Id:
 */
- (BOOL)writeToURL:(NSURL *)aURL Id:(short)anID
{
	NSData				* theData;
	NDResourceFork		* theResourceFork;
	BOOL					theResult = NO,
							theCanNotWriteTo = NO;

	if( [self isCompiled] && (theData = [self data]) )
	{
		if( ![[NSFileManager defaultManager] fileExistsAtPath:[aURL path] isDirectory:&theCanNotWriteTo] )
		{
			theCanNotWriteTo = ![[NSFileManager defaultManager] createFileAtPath:[aURL path] contents:nil attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedLong:kScriptEditorCreatorCode], NSFileHFSCreatorCode, [NSNumber numberWithUnsignedLong:kCompiledAppleScriptTypeCode], NSFileHFSTypeCode, nil]];
		}

		if( !theCanNotWriteTo && (theResourceFork = [NDResourceFork resourceForkForWritingAtURL:aURL]) )
			theResult = [theResourceFork addData:theData type:kOSAScriptResourceType Id:anID name:@"script"];
	}

	return theResult;
}

/*
 * -writeToFile:
 */
- (BOOL)writeToFile:(NSString *)aPath
{
	return [self writeToURL:[NSURL fileURLWithPath:aPath] Id:kScriptResourceID];
}

- (BOOL)writeToFile:(NSString *)aPath inDataFork:(BOOL)aFlag atomically:(BOOL)anAtomically
{
	return aFlag
		? [[self data] writeToFile:aPath atomically:anAtomically]
		: [self writeToURL:[NSURL fileURLWithPath:aPath] Id:kScriptResourceID];
}

/*
 * -writeToFile:
 */
- (BOOL)writeToFile:(NSString *)aPath Id:(short)anID
{
	return [self writeToURL:[NSURL fileURLWithPath:aPath] Id:anID];
}

@end

/*
 * class implementation NDAppleScriptObject (Private)
 */
@implementation NDAppleScriptObject (Private)

/*
 * - compileString:
 */
- (OSAID)compileString:(NSString *)aString modeFlags:(long)aModeFlags scriptID:(OSAID)aCompiledScript
{
	NSAppleEventDescriptor		* theStringDesc;

	if ( theStringDesc = [NSAppleEventDescriptor descriptorWithString:aString] )
	{				
		OSACompile([self scriptingComponent], [theStringDesc aeDesc], aModeFlags, &aCompiledScript);
	}
	
	return aCompiledScript;
}

/*
 * - loadCompiledScriptData:
 */
- (OSAID)loadCompiledScriptData:(NSData *)aData
{
	OSAID								theCompiledScript = kOSANullScript;
	NSAppleEventDescriptor		* theDataDesc;

	if( theDataDesc = [NSAppleEventDescriptor descriptorWithDescriptorType:typeOSAGenericStorage data:aData] )
	{
		OSALoad([self scriptingComponent], [theDataDesc aeDesc], kOSAModeCompileIntoContext, &theCompiledScript);
	}
	
	return theCompiledScript;
}

/*
 * - compiledScriptID
 */
- (OSAID)compiledScriptID
{
	return compiledScriptID;
}

/*
 * - scriptingComponent
 */
- (ComponentInstance)scriptingComponent
{
	return [componentInstance scriptingComponent];
}

@end

/*
 * class implementation NSAppleEventDescriptor (NDAppleScriptValueExtension)
 */
@implementation NSAppleEventDescriptor (NDAppleScriptValueExtension)

/*
 * -appleScriptValue
 */
- (NDAppleScriptObject *)appleScriptValue
{
	return [NDAppleScriptObject appleScriptObjectWithData:[self data]];
}

/*
 * +descriptorWithAppleScript:
 */
+ (NSAppleEventDescriptor *)descriptorWithAppleScript:(NDAppleScriptObject *)anAppleScript
{
	return [NSAppleEventDescriptor descriptorWithDescriptorType:cScript data:[anAppleScript data]];
}

@end

/*
 * class interface NDAppleScriptObject (NSAppleScriptCompatibility)
 */
@implementation NDAppleScriptObject (NSAppleScriptCompatibility)

/*
 * -initWithContentsOfURL:error:
 */
- (id)initWithContentsOfURL:(NSURL *)aURL error:(NSDictionary **)anErrorInfo
{
	self = [self initWithContentsOfURL:aURL];
	*anErrorInfo = self ? [self error] : nil;
	return self;
}

/*
 * -initWithSource:
 */
- (id)initWithSource:(NSString *)aSource
{
	if( self = [self init] )
	{
		componentInstance = [[NDComponentInstance sharedComponentInstance] retain];
		scriptSource = [aSource retain];
	}
	return self;
}

/*
 * -compileAndReturnError:
 */
- (BOOL)compileAndReturnError:(NSDictionary **)anErrorInfo
{
	BOOL		theResult = [self compile];
	*anErrorInfo = theResult ? [self error] : nil;
	return theResult;
}

/*
 * -executeAndReturnError:
 */
- (NSAppleEventDescriptor *)executeAndReturnError:(NSDictionary **)anErrorInfo
{
	BOOL		theResult = [self execute];
	*anErrorInfo = theResult ? [self error] : nil;
	return theResult ? [self resultAppleEventDescriptor] : nil;
}

/*
 * -executeAppleEvent:error:
 */
- (NSAppleEventDescriptor *)executeAppleEvent:(NSAppleEventDescriptor *)anEvent error:(NSDictionary **)anErrorInfo
{
	BOOL		theResult = [self executeEvent:anEvent];
	*anErrorInfo = theResult ? [self error] : nil;
	return theResult ? [self resultAppleEventDescriptor] : nil;
}

@end
