/*
 *  NDProcess.m
 *  ProcessesObjectTest
 *
 *  Created by Nathan Day on Mon May 27 2002.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDProcess.h"
#import "NSURL+NDCarbonUtilities.h"

NDProcess		* reusedInstance = nil;
NSString		* kBundleExecutableKey = @"CFBundleExecutable";

/*
 * category interface NDProcess (Private)
 */
@interface NDProcess (Private)
- (void)setProcessSerialNumber:(ProcessSerialNumber)aProcessSerialNumber;
- (BOOL)fillProcessInfoRec;
@end

/*
 * class interface NDProcessesEnumerater
 */
@interface NDProcessesEnumerater : NSEnumerator
{
	ProcessSerialNumber	currentProcessSerialNumber;
}
+ (NDProcessesEnumerater *)processesEnumerater;
@end

/*
 * class implementation NDProcess
 */
@implementation NDProcess

/*
 * -initWithProcessSerialNumber:
 */
- (id)initWithProcessSerialNumber:(ProcessSerialNumber)aProcessSerialNumber
{
	if( (self = [self init]) != nil )
	{
		[self setProcessSerialNumber:aProcessSerialNumber];
	}

	return self;
}

/*
 * -dealloc
 */
- (void)dealloc
{
	[name release];
	[url release];
	[super dealloc];
}

/*
 * -processSerialNumber
 */
- (ProcessSerialNumber)processSerialNumber
{
	return processSerialNumber;
}

/*
 * -isFrontProcess
 */
- (BOOL)isFrontProcess
{
	Boolean					theResult = FALSE;
	ProcessSerialNumber		theProcessSerialNumber;

	if( GetFrontProcess( &theProcessSerialNumber ) == noErr )
	{
		if( SameProcess( &theProcessSerialNumber, &processSerialNumber, &theResult ) != noErr )
		{
			theResult = FALSE;
		}
	}

	return theResult != FALSE;
}

/*
 * -isCurrentProcess
 */
- (BOOL)isCurrentProcess
{
	Boolean						theResult = FALSE;
	ProcessSerialNumber		theProcessSerialNumber;

	if( GetCurrentProcess( &theProcessSerialNumber ) == noErr )
	{
		if( SameProcess( &theProcessSerialNumber, &processSerialNumber, &theResult ) != noErr )
		{
			theResult = FALSE;
		}
	}

	return theResult != FALSE;
}

/*
 * -makeFrontProcessFrontWindowOnly:
 */
- (BOOL)makeFrontProcessFrontWindowOnly:(BOOL)aFlag
{
	return SetFrontProcessWithOptions( &processSerialNumber, aFlag ? kSetFrontProcessFrontWindowOnly : 0 ) == noErr;
}

/*
 * -makeFrontProcess
 */
- (BOOL)makeFrontProcess
{
	return SetFrontProcess( &processSerialNumber ) == noErr;
}


/*
 * -wakeUpProcess
 */
- (BOOL)wakeUpProcess
{
	return WakeUpProcess( &processSerialNumber ) == noErr;
}

/*
 * -isEqual:
 */
- (BOOL)isEqual:(id)anObject
{
	Boolean						theResult = FALSE;
	if( [anObject isKindOfClass:[self class]] )
	{
		ProcessSerialNumber		theProcessSerialNumber;
		
		theProcessSerialNumber = [anObject processSerialNumber];

		if( SameProcess( &processSerialNumber, &theProcessSerialNumber, &theResult ) != noErr )
			theResult = FALSE;
	}

	return theResult != FALSE;
}

/*
 * -description
 */
- (NSString *)description
{
	OSType			theOSType;
	UInt32			theSignature;
	NSString			* theOSTypeString,
						* theSignatureString;
	NSTimeInterval	theLaunchTime;

	if( [self isNoProcess] )
	{
		return [self name];
	}
	else
	{
		theOSType = [self type];
		theSignature = [self signature];

		theOSTypeString = (theOSType) ? [NSString stringWithCString:(char*)&theOSType length:4] : @"NULL";
		theSignatureString = (theSignature) ? [NSString stringWithCString:(char*)&theSignature length:4] : @"NULL";

		theLaunchTime = [self launchTime];
		return [NSString stringWithFormat:@"name:\"%@\",\tprocces ID: %i,\ttime:[%ih %im %.1fs],\ttype:'%@',\tsignature:'%@'", [self name], [self processID], (int)theLaunchTime/3600,((int)theLaunchTime/60)%60,fmod(theLaunchTime, 60), theOSTypeString, theSignatureString];
	}
}

/*
 * -retain
 */
- (id)retain
{
	if( self == reusedInstance )
	{
		reusedInstance = nil;
		[self autorelease];		// autorelease since not kept with reusedInstance
	}

	return [super retain];
}

/*
 * -copy
 */
- (id)copy
{
	[self retain];
	return self;
}

@end

/*
 * category implementation NDProcess (Private)
 */
@implementation NDProcess (Private)

/*
 * -setProcessSerialNumber:
 */
- (void)setProcessSerialNumber:(ProcessSerialNumber)aProcessSerialNumber
{
	processSerialNumber = aProcessSerialNumber;
	infoRec.processInfoLength = 0;
	[name release];
	name = nil;
	[url release];
	url = nil;
}

/*
 * -fillProcessInfoRec
 */
- (BOOL)fillProcessInfoRec
{
	if( infoRec.processInfoLength == 0 )
	{
		infoRec.processInfoLength = sizeof(ProcessInfoRec);

		if( GetProcessInformation( &processSerialNumber, &infoRec ) != noErr)
		{
			infoRec.processInfoLength = 0;
		}
	}

	return infoRec.processInfoLength != 0;
}

@end

/*
 * category implementation NDProcess (Construction)
 */
@implementation NDProcess (Constructors)

static NDProcess * reusableInstance();

/*
 * +processWithProcessSerialNumber:
 */
+ (NDProcess *)processWithProcessSerialNumber: (ProcessSerialNumber)aProcessSerialNumber
{
	NDProcess  * theInstance = reusableInstance();
	[theInstance setProcessSerialNumber:aProcessSerialNumber];
	return theInstance;
}

/*
 * +currentProcess
 */
+ (NDProcess *)currentProcess
{
	NDProcess					* theInstance = nil;
	ProcessSerialNumber		theProcessSerialNumber;

	if( GetCurrentProcess( &theProcessSerialNumber ) == noErr )
	{
		theInstance = reusableInstance();
		[theInstance setProcessSerialNumber:theProcessSerialNumber];
	}

	return theInstance;
}

/*
 * +frontProcess
 */
+ (NDProcess *)frontProcess
{
	NDProcess					* theInstance = nil;
	ProcessSerialNumber		theProcessSerialNumber;

	if( GetFrontProcess( &theProcessSerialNumber ) == noErr )
	{
		theInstance = reusableInstance();
		[theInstance setProcessSerialNumber:theProcessSerialNumber];
	}

	return theInstance;
}

/*
 * +processWithProcessID:
 */
+ (NDProcess *)processWithProcessID:(pid_t)aPid
{
	NDProcess					* theInstance = nil;
	ProcessSerialNumber		theProcessSerialNumber;
	
	if( GetProcessForPID( aPid, &theProcessSerialNumber) == noErr )
	{
		theInstance = reusableInstance();
		[theInstance setProcessSerialNumber:theProcessSerialNumber];
	}
	
	return theInstance;
}

/*
 * -initWithCurrentProcess
 */
- (id)initWithCurrentProcess;
{
	ProcessSerialNumber		theProcessSerialNumber;

	if( GetCurrentProcess( &theProcessSerialNumber ) == noErr )
		self = [self initWithProcessSerialNumber:theProcessSerialNumber];
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
}

/*
 * -initWithFrontProcess
 */
- (id)initWithFrontProcess
{
	ProcessSerialNumber		theProcessSerialNumber;

	if( GetFrontProcess( &theProcessSerialNumber ) == noErr )
		self = [self initWithProcessSerialNumber:theProcessSerialNumber];
	else
	{
		[self release];
		self = nil;
	}
	
	return self;
}

/*
 * -initWithProcessID:
 */
- (id)initWithProcessID:(pid_t)aPid
{
	ProcessSerialNumber		theProcessSerialNumber;

	if( GetProcessForPID( aPid, &theProcessSerialNumber) == noErr )
		self = [self initWithProcessSerialNumber:theProcessSerialNumber];
	else
	{
		[self release];
		self = nil;
	}

	return self;
}

/*
 * +processesEnumerater
 */
+ (NSEnumerator *)processesEnumerater
{
	return [NDProcessesEnumerater processesEnumerater];
}

/*
 * +everyProcess
 */
+ (NSArray *)everyProcess
{
	return [[self processesEnumerater] allObjects];
}

/*
 * +everyProcessNamed:
 */
+ (NSArray *)everyProcessNamed:(NSString *)aName
{
	NSEnumerator		* theEnumerator;
	NSMutableArray		* theProcessesArray;
	NDProcess			* theProcess;

	theProcessesArray = [NSMutableArray array];
	theEnumerator = [self processesEnumerater];
	while( theProcessesArray != nil && (theProcess = [theEnumerator nextObject]) != nil )
	{
		if( [[theProcess name] isEqualToString:aName] )
			[theProcessesArray addObject:theProcess];
	}

	return theProcessesArray;
}

/*
 * +firstProcessNamed:
 */
+ (NDProcess *)firstProcessNamed:(NSString *)aName
{
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess = nil;

	theEnumerator = [self processesEnumerater];
	while( (theProcess = [theEnumerator nextObject]) != nil )
	{
		if( [[theProcess name] isEqualToString:aName] )
			break;							// FOUND
	}

	return theProcess;
}

/*
 * +processForURL:
 */
+ (NDProcess *)processForURL:(NSURL *)aURL
{
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess;

	theEnumerator = [self processesEnumerater];
	while( (theProcess = [theEnumerator nextObject]) != nil )
	{
		if( [[theProcess url] isEqual:aURL] )
			return theProcess;						// RETURN found process
	}

	return nil;
}

/*
 * +processForPath:
 */
+ (NDProcess *)processForPath:(NSString *)aPath
{
	return [self processForURL:[NSURL fileURLWithPath:aPath]];
}

/*
 * +processForApplicationURL:
 */
+ (NDProcess *)processForApplicationURL:(NSURL *)aURL
{
	return [self processForApplicationPath:[aURL path]];
}

/*
 * +processForApplicationPath:
 */
+ (NDProcess *)processForApplicationPath:(NSString *)aPath
{
	BOOL				theIsDir;
	NDProcess		* theProcess = nil;
	if([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&theIsDir])
	{
		if( theIsDir )
		{
			NSDictionary		* theDictionary;

			theDictionary = [NSDictionary dictionaryWithContentsOfFile:[aPath stringByAppendingString:@"/Contents/Info.plist"]];

			aPath = [aPath stringByAppendingFormat:@"/Contents/MacOS/%@", [theDictionary objectForKey:kBundleExecutableKey]];
		}


		theProcess = [self processForPath:aPath];
	}

	return theProcess;
}

/*
 * +everyProcessBeginingWithURL:
 */
+ (NSArray *)everyProcessBeginingWithURL:(NSURL *)aURL
{
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess;
	NSMutableArray		* theFoundProcesses;

	theFoundProcesses = [NSMutableArray array];
	theEnumerator = [self processesEnumerater];

	while( (theProcess = [theEnumerator nextObject]) != nil )
	{
		if( [[[theProcess url] absoluteString] isEqualToString:[aURL absoluteString]] )
			[theFoundProcesses addObject:theProcess];
	}

	return theFoundProcesses;
}

/*
 * +everyProcessBeginingWithPath:
 */
+ (NSArray *)everyProcessBeginingWithPath:(NSString *)aPath
{
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess;
	NSMutableArray		* theFoundProcesses;

	theFoundProcesses = [NSMutableArray array];
	theEnumerator = [self processesEnumerater];

	while( (theProcess = [theEnumerator nextObject]) != nil)
	{
		if( [[theProcess path] isEqualToString:aPath] )
			[theFoundProcesses addObject:theProcess];
	}

	return theFoundProcesses;
}

/*
 * getReusedInstance()
 */
static NDProcess * reusableInstance()
{
	if( reusedInstance == nil)
	{
		reusedInstance = [[NDProcess alloc] init];
	}

	return reusedInstance;
}

/*
 * -isNoProcess
 */
- (BOOL)isNoProcess
{
	Boolean						theResult = FALSE;
	ProcessSerialNumber		theProcessSerialNumber;

	theProcessSerialNumber.highLongOfPSN = 0;
	theProcessSerialNumber.lowLongOfPSN = kNoProcess;

	if( SameProcess( &processSerialNumber, &theProcessSerialNumber, &theResult ) != noErr )
		theResult = FALSE;

	return theResult != FALSE;
}

/*
 * -isSystemProcess
 */
- (BOOL)isSystemProcess
{
	Boolean						theResult = FALSE;
	ProcessSerialNumber		theProcessSerialNumber;

	theProcessSerialNumber.highLongOfPSN = 0;
	theProcessSerialNumber.lowLongOfPSN = kSystemProcess;

	if( SameProcess( &processSerialNumber, &theProcessSerialNumber, &theResult ) != noErr )
		theResult = FALSE;

	return theResult != FALSE;
}

/*
 * -isValid
 */
- (BOOL)isValid
{
	infoRec.processInfoLength = 0;			// set to zero to force attempt to retireve process info
	return [self fillProcessInfoRec];
}

@end

/*
 * category implementation NDProcess (ProcessInfoRec)
 */
@implementation NDProcess (ProcessInfoRec)

/*
 * -name
 */
- (NSString *)name
{
	if( name == nil )
	{
		if( [self isNoProcess] )
		{
			name = @"no process";
		}
		else if( [self isSystemProcess] )
		{
			name = @"system process";
		}
		else
		{
			unsigned char			theProcessName[32];
		
			infoRec.processInfoLength = 0;			// set to zero to force retireve process info
			infoRec.processName = theProcessName;
		
			if( [self fillProcessInfoRec] && infoRec.processName != NULL )
			{
				name = [[NSString alloc] initWithCString:(const char *)(theProcessName + 1) length:*theProcessName];
				infoRec.processName = NULL;		// not valid after this method call
			}
		}
	}
	
	return name;
}

/*
 * -type
 */
- (OSType)type
{
	return [self fillProcessInfoRec] ? infoRec.processType : 0;
}

/*
 * -signature
 */
- (OSType)signature
{
	return [self fillProcessInfoRec] ? infoRec.processSignature : 0;
}

/*
 * -mode
 */
- (UInt32)mode
{
	return [self fillProcessInfoRec] ? infoRec.processMode : 0;
}

/*
 * -launcher
 */
- (NDProcess *)launcher
{
	return [self fillProcessInfoRec] ? [[[NDProcess alloc] initWithProcessSerialNumber:infoRec.processLauncher] autorelease] : nil;
}

/*
 * -launchTime
 */
- (NSTimeInterval)launchTime
{
	return [self fillProcessInfoRec] ? (NSTimeInterval)TicksToEventTime( infoRec.processLaunchDate )/kEventDurationSecond : 0;
}

/*
 * -url
 */
- (NSURL *)url
{
	if( url == nil )
	{
		FSSpec				theSpec;

		infoRec.processInfoLength = 0;			// set to zero to force retireve process info
		infoRec.processAppSpec = &theSpec;

		if( [self fillProcessInfoRec] && infoRec.processAppSpec != NULL )
		{
			FSRef			theRef;

			if( FSpMakeFSRef ( &theSpec, &theRef ) == noErr )
				url = [[NSURL URLWithFSRef:&theRef] retain];
			else
				NSLog( @"Failed to get file reference from file spec" );
		}
		
		infoRec.processAppSpec = NULL;		// not valid after method call
	}
	
	return url;
}

/*
 * -path
 */
- (NSString *)path
{
	return [[self url] path];
}

/*
 * -processID
 */
- (pid_t)processID
{
	pid_t pid = -1;
	
	return GetProcessPID(&processSerialNumber, &pid) == noErr ? pid : -1;
}

@end

/*
 * class implementation NDProcessesEnumerater
 */
@implementation NDProcessesEnumerater

/*
 * +processesEnumerater
 */
+ (NDProcessesEnumerater *)processesEnumerater
{
	return [[[self alloc] init] autorelease];
}

/*
 * -init
 */
- (id)init
{
	if( (self = [super init]) != nil)
	{
		currentProcessSerialNumber.highLongOfPSN = kNoProcess;
		currentProcessSerialNumber.lowLongOfPSN = 0;
	}

	return self;
}

/*
 * -nextObject
 */
- (id)nextObject
{
	NDProcess		* theNextNDProcess = nil;
	
	if( GetNextProcess ( &currentProcessSerialNumber ) == noErr && !(currentProcessSerialNumber.highLongOfPSN == kNoProcess && currentProcessSerialNumber.lowLongOfPSN == 0) )
	{
		theNextNDProcess = [NDProcess processWithProcessSerialNumber:currentProcessSerialNumber];
	}

	return theNextNDProcess;
}

@end

