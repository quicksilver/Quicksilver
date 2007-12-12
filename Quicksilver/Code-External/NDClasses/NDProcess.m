/*
 * NDProcess.m
 * ProcessesObjectTest
 *
 * Created by Nathan Day on Mon May 27 2002.
 * Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDProcess.h"
#import "NSURL+NDCarbonUtilities.h"

NDProcess *reusedInstance = nil;
#define kBundleExecutableKey @"CFBundleExecutable"

@interface NDProcess (Private)
- (void)setProcessSerialNumber:(ProcessSerialNumber)aProcessSerialNumber;
- (BOOL)fillProcessInfoRec;
@end

@interface NDProcessesEnumerater : NSEnumerator {
	ProcessSerialNumber	currentProcessSerialNumber;
}
+ (NDProcessesEnumerater *)processesEnumerater;
@end

@implementation NDProcess

- (id)initWithProcessSerialNumber:(ProcessSerialNumber)aProcessSerialNumber {
	if ( self = [self init] )
		[self setProcessSerialNumber:aProcessSerialNumber];
	return self;
}

- (void)dealloc {
	[name release];
	[url release];
	[super dealloc];
}

- (ProcessSerialNumber) processSerialNumber { return processSerialNumber; }

- (BOOL)isFrontProcess {
	Boolean						theResult = FALSE;
	ProcessSerialNumber		theProccessSerialNumber;

	if ( GetFrontProcess( &theProccessSerialNumber ) == noErr ) {
		if ( SameProcess( &theProccessSerialNumber, &processSerialNumber, &theResult ) != noErr ) {
			theResult = FALSE;
		}
	}
	return theResult != FALSE;
}

- (BOOL)isCurrentProcess {
	Boolean						theResult = FALSE;
	ProcessSerialNumber		theProccessSerialNumber;

	if ( GetCurrentProcess( &theProccessSerialNumber ) == noErr ) {
		if ( SameProcess( &theProccessSerialNumber, &processSerialNumber, &theResult ) != noErr ) {
			theResult = FALSE;
		}
	}
	return theResult != FALSE;
}

- (BOOL)makeFrontProcess { return SetFrontProcess( &processSerialNumber ) == noErr; }

- (BOOL)wakeUpProcess { return WakeUpProcess( &processSerialNumber ) == noErr; }

- (BOOL)isEqual:(id)anObject {
	Boolean						theResult = FALSE;
	if ( [anObject isKindOfClass:[self class]] ) {
		ProcessSerialNumber		theProccessSerialNumber;

		theProccessSerialNumber = [anObject processSerialNumber];

		if ( SameProcess( &processSerialNumber, &theProccessSerialNumber, &theResult ) != noErr )
			theResult = FALSE;
	}

	return theResult != FALSE;
}

- (NSString *)description {
	OSType			theOSType;
	UInt32			theSignature;
	NSString		*theOSTypeString, *theSignatureString;
	NSTimeInterval	theLaunchTime;

	if ( [self isNoProcess] ) {
		return [self name];
	} else {
		theOSType = [self type];
		theSignature = [self signature];

		theOSTypeString = (theOSType) ? [NSString stringWithCString:(char*)&theOSType length:4] : @"NULL";
		theSignatureString = (theSignature) ? [NSString stringWithCString:(char*)&theSignature length:4] : @"NULL";

		theLaunchTime = [self launchTime];
		return [NSString stringWithFormat:@"name:\"%@\"\ttime:[%ih %im %.1fs]\ttype:'%@'\tsignature:'%@'", [self name] , (int) theLaunchTime/3600, ((int)theLaunchTime/60)%60, fmod(theLaunchTime, 60), theOSTypeString, theSignatureString];
	}
}

- (id)retain {
	if ( self == reusedInstance ) {
		reusedInstance = nil;
		[self autorelease]; 		// autorelease since not kept with reusedInstance
	}
	return [super retain];
}

- (id)copy {
	[self retain];
	return self;
}

@end

@implementation NDProcess (Private)

- (void)setProcessSerialNumber:(ProcessSerialNumber)aProcessSerialNumber {
	processSerialNumber = aProcessSerialNumber;
	infoRec.processInfoLength = 0;
	[name release];
	name = nil;
	[url release];
	url = nil;
}

- (BOOL)fillProcessInfoRec {
	if ( infoRec.processInfoLength == 0 ) {
		infoRec.processInfoLength = sizeof(ProcessInfoRec);

		if ( GetProcessInformation( &processSerialNumber, &infoRec ) != noErr) {
			infoRec.processInfoLength = 0;
		}
	}

	return infoRec.processInfoLength != 0;
}

@end

@implementation NDProcess (Constructors)

NDProcess * reusableInstance();

+ (NDProcess *)processWithProcessSerialNumber: (ProcessSerialNumber)aProcessSerialNumber {
	NDProcess * theInstance = reusableInstance();
	[theInstance setProcessSerialNumber:aProcessSerialNumber];
	return theInstance;
}

+ (NDProcess *)currentProcess {
	NDProcess					* theInstance = nil;
	ProcessSerialNumber		theProccessSerialNumber;

	if ( GetCurrentProcess( &theProccessSerialNumber ) == noErr ) {
		theInstance = reusableInstance();
		[theInstance setProcessSerialNumber:theProccessSerialNumber];
	}

	return theInstance;
}

+ (NDProcess *)frontProcess {
	NDProcess					* theInstance = nil;
	ProcessSerialNumber		theProccessSerialNumber;

	if ( GetFrontProcess( &theProccessSerialNumber ) == noErr ) {
		theInstance = reusableInstance();
		[theInstance setProcessSerialNumber:theProccessSerialNumber];
	}

	return theInstance;
}

- (id)initWithCurrentProcess; {
	ProcessSerialNumber		theProccessSerialNumber;

	if ( GetCurrentProcess( &theProccessSerialNumber ) == noErr )
		return [self initWithProcessSerialNumber:theProccessSerialNumber];
	else
		return nil;
}

- (id)initWithFrontProcess {
	id								theInstance = nil;
	ProcessSerialNumber		theProccessSerialNumber;

	if ( GetFrontProcess( &theProccessSerialNumber ) == noErr )
		theInstance = [self initWithProcessSerialNumber:theProccessSerialNumber];

	return theInstance;
}

+ (NSEnumerator *)processesEnumerater {
	return [NDProcessesEnumerater processesEnumerater];
}

+ (NSArray *)everyProcess {
	return [[self processesEnumerater] allObjects];
}

+ (NSArray *)everyProcessNamed:(NSString *)aName {
	NSEnumerator		* theEnumerator;
	NSMutableArray		* theProcessesArray;
	NDProcess			* theProcess;

	theProcessesArray = [NSMutableArray array];
	theEnumerator = [self processesEnumerater];
	while( theProcessesArray != nil && (theProcess = [theEnumerator nextObject]) != nil ) {
		if ( [[theProcess name] isEqualToString:aName] )
			[theProcessesArray addObject:theProcess];
	}

	return theProcessesArray;
}

+ (NDProcess *)firstProcessNamed:(NSString *)aName {
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess = nil;

	theEnumerator = [self processesEnumerater];
	while( (theProcess = [theEnumerator nextObject]) != nil ) {
		if ( [[theProcess name] isEqualToString:aName] )
			break; 							// FOUND
	}

	return theProcess;
}

+ (NDProcess *)processForURL:(NSURL *)aURL {
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess;

	theEnumerator = [self processesEnumerater];
	while( theProcess = [theEnumerator nextObject] ) {
		if ( [[theProcess url] isEqual:aURL] )
			return theProcess; 						// RETURN found process
	}

	return nil;
}

+ (NDProcess *)processForPath:(NSString *)aPath {
	return [self processForURL:[NSURL fileURLWithPath:aPath]];
}

+ (NDProcess *)processForApplicationURL:(NSURL *)aURL {
	return [self processForApplicationPath:[aURL path]];
}

+ (NDProcess *)processForApplicationPath:(NSString *)aPath {
	BOOL				theIsDir;
	NDProcess		* theProcess = nil;
	if ([[NSFileManager defaultManager] fileExistsAtPath:aPath isDirectory:&theIsDir]) {
		if ( theIsDir ) {
			NSDictionary		* theDictionary;

			theDictionary = [NSDictionary dictionaryWithContentsOfFile:[aPath stringByAppendingString:@"/Contents/Info.plist"]];

			aPath = [aPath stringByAppendingFormat:@"/Contents/MacOS/%@", [theDictionary objectForKey:kBundleExecutableKey]];
		}


		theProcess = [self processForPath:aPath];
	}

	return theProcess;
}

+ (NSArray *)everyProcessBeginingWithURL:(NSURL *)aURL {
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess;
	NSMutableArray		* theFoundProcesses;

	theFoundProcesses = [NSMutableArray array];
	theEnumerator = [self processesEnumerater];

	while( theProcess = [theEnumerator nextObject] ) {
		if ( [[[theProcess url] absoluteString] isEqualToString:[aURL absoluteString]] )
			[theFoundProcesses addObject:theProcess];
	}

	return theFoundProcesses;
}

+ (NSArray *)everyProcessBeginingWithPath:(NSString *)aPath {
	NSEnumerator		* theEnumerator;
	NDProcess			* theProcess;
	NSMutableArray		* theFoundProcesses;

	theFoundProcesses = [NSMutableArray array];
	theEnumerator = [self processesEnumerater];

	while( theProcess = [theEnumerator nextObject] ) {
		if ( [[theProcess path] isEqualToString:aPath] )
			[theFoundProcesses addObject:theProcess];
	}

	return theFoundProcesses;
}

NDProcess * reusableInstance() {
	if ( reusedInstance == nil)
		reusedInstance = [[NDProcess alloc] init];
	return reusedInstance;
}

- (BOOL)isNoProcess {
	Boolean						theResult = FALSE;
	ProcessSerialNumber		theProccessSerialNumber;

	theProccessSerialNumber.highLongOfPSN = 0;
	theProccessSerialNumber.lowLongOfPSN = kNoProcess;

	if ( SameProcess( &processSerialNumber, &theProccessSerialNumber, &theResult ) != noErr )
		theResult = FALSE;

	return theResult != FALSE;
}

- (BOOL)isSystemProcess {
	Boolean						theResult = FALSE;
	ProcessSerialNumber		theProccessSerialNumber;

	theProccessSerialNumber.highLongOfPSN = 0;
	theProccessSerialNumber.lowLongOfPSN = kSystemProcess;

	if ( SameProcess( &processSerialNumber, &theProccessSerialNumber, &theResult ) != noErr )
		theResult = FALSE;

	return theResult != FALSE;
}

- (BOOL)isValid {
	infoRec.processInfoLength = 0; 			// set to zero to force attempt to retireve process info
	return [self fillProcessInfoRec];
}

@end

@implementation NDProcess (ProcessInfoRec)

- (NSString *)name {
	if ( name == nil ) {
		if ( [self isNoProcess] ) {
			name = @"no process";
		} else if ( [self isSystemProcess] ) {
			name = @"system process";
		} else {
			char			theProcessName[32];

			infoRec.processInfoLength = 0; 			// set to zero to force retireve process info
			infoRec.processName = theProcessName;

			if ( [self fillProcessInfoRec] && infoRec.processName != NULL ) {
				name = [[NSString alloc] initWithCString:(theProcessName + 1) length:*theProcessName];
				infoRec.processName = NULL; 		// not valid after this method call
			}
		}
	}

	return name;
}

- (OSType) type {
	return [self fillProcessInfoRec] ? infoRec.processType : 0;
}

- (OSType) signature {
	return [self fillProcessInfoRec] ? infoRec.processSignature : 0;
}

- (UInt32) mode {
	return [self fillProcessInfoRec] ? infoRec.processMode : 0;
}

- (NDProcess *)launcher {
	return [self fillProcessInfoRec] ? [[[NDProcess alloc] initWithProcessSerialNumber:infoRec.processLauncher] autorelease] : nil;
}

- (NSTimeInterval) launchTime {
	return [self fillProcessInfoRec] ? (NSTimeInterval) TicksToEventTime( infoRec.processLaunchDate )/kEventDurationSecond : 0;
}

- (NSURL *)url {
	if ( url == nil ) {
		FSSpec				theSpec;

		infoRec.processInfoLength = 0; 			// set to zero to force retireve process info
		infoRec.processAppSpec = &theSpec;

		if ( [self fillProcessInfoRec] && infoRec.processAppSpec != NULL ) {
			FSRef			theRef;

			FSpMakeFSRef ( &theSpec, &theRef );
			url = [[NSURL URLWithFSRef:&theRef] retain];
		}

		infoRec.processAppSpec = NULL; 		// not valid after method call
	}

	return url;
}

- (NSString *)path {
	return [[self url] path];
}

@end

@implementation NDProcessesEnumerater

+ (NDProcessesEnumerater *)processesEnumerater {
	return [[[self alloc] init] autorelease];
}

- (id)init {
	if ( self = [super init] ) {
		currentProcessSerialNumber.highLongOfPSN = kNoProcess;
		currentProcessSerialNumber.lowLongOfPSN = 0;
	}

	return self;
}

- (id)nextObject {
	NDProcess		* theNextNDProcess = nil;

	if ( GetNextProcess ( &currentProcessSerialNumber ) == noErr && !(currentProcessSerialNumber.highLongOfPSN == kNoProcess && currentProcessSerialNumber.lowLongOfPSN == 0) ) {
		theNextNDProcess = [NDProcess processWithProcessSerialNumber:currentProcessSerialNumber];
	}

	return theNextNDProcess;
}

@end

