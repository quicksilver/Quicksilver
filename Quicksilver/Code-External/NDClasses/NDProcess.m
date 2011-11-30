/*
	NDProcess.m

	Created by Nathan Day on 27.05.02 under a MIT-style license. 
	Copyright (c) 2008 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

#import "NDProcess.h"
#import "NSURL+NDCarbonUtilities.h"

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

#ifndef __OBJC_GC__
/*
 * -dealloc
 */
- (void)dealloc
{
	[name release];
	[url release];
	[super dealloc];
}
#endif

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
	Boolean						theResult = FALSE;
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
	NSString		* theOSTypeString,
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
		return [NSString stringWithFormat:@"name:\"%@\", procces ID: %i, time:[%ih %im %.1fs], type:'%@', signature:'%@'", [self name], [self processID], (int)theLaunchTime/3600,((int)theLaunchTime/60)%60,fmod(theLaunchTime, 60.0), theOSTypeString, theSignatureString];
	}
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

/*
 * +processWithProcessSerialNumber:
 */
+ (NDProcess *)processWithProcessSerialNumber: (ProcessSerialNumber)aProcessSerialNumber
{
	NDProcess  * theInstance = [[[NDProcess alloc] init] autorelease];
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
		theInstance = [[[NDProcess alloc] init] autorelease];
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
		theInstance = [[[NDProcess alloc] init] autorelease];
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
		theInstance = [[[NDProcess alloc] init] autorelease];
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
 * -isNoProcess
 */
- (BOOL)isNoProcess
{
	Boolean					theResult = FALSE;
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
#if MAC_OS_X_VERSION_MAX_ALLOWED < MAC_OS_X_VERSION_10_5
		else if( [self isSystemProcess] )
		{
			name = @"system process";
		}
#endif
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
#if __LP64__
		FSRef			theRef;
		infoRec.processInfoLength = 0;			// set to zero to force retireve process info
		infoRec.processAppRef = &theRef;

		if( [self fillProcessInfoRec] && infoRec.processAppRef != NULL )
			url = [[NSURL URLWithFSRef:&theRef] retain];
		
		infoRec.processAppRef = NULL;		// not valid after method call
#else
		FSSpec				theSpec;

		infoRec.processInfoLength = 0;			// set to zero to force retireve process info
		infoRec.processAppSpec = &theSpec;

		if( [self fillProcessInfoRec] && infoRec.processAppSpec != NULL )
		{
			FSRef			theRef;

			FSpMakeFSRef ( &theSpec, &theRef );			// I known this is deprecated, but that is because FSSpec is deprecated, so I have no choice but to use this
			url = [[NSURL URLWithFSRef:&theRef] retain];
		}
		
		infoRec.processAppSpec = NULL;		// not valid after method call
#endif
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

