/*
 *  NSAppleEventDescriptor+NDAppleScriptObject.m
 *  AppleScriptObjectProject
 *
 *  Created by Nathan Day on Fri Dec 14 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

#import "NSAppleEventDescriptor+NDAppleScriptObject.h"
#import "NSURL+NDCarbonUtilities.h"

/*
 * class implementation NSAppleEventDescriptor (NDAppleScriptObject)
 */
@implementation NSAppleEventDescriptor (NDAppleScriptObject)

/*
 * +descriptorWithAEDescNoCopy:
 */
+ (id)descriptorWithAEDescNoCopy:(const AEDesc *)aDesc
{
	return [[[self alloc] initWithAEDescNoCopy:aDesc] autorelease];
}

/*
 * +descriptorWithAEDesc:
 */
+ (id)descriptorWithAEDesc:(const AEDesc *)anAEDesc
{
	return [[[self alloc] initWithAEDesc:anAEDesc] autorelease];
}

/*
 * -initWithAEDesc:
 */
- (id)initWithAEDesc:(const AEDesc *)anAEDesc
{
	AEDesc	theAEDesc;
	return AEDuplicateDesc( anAEDesc, &theAEDesc ) == noErr ? [self initWithAEDescNoCopy:&theAEDesc] : nil;
}

/*
 * isTargetCurrentProcess
 */
- (BOOL)isTargetCurrentProcess
{
	ProcessSerialNumber		theProcessSerialNumber;

	theProcessSerialNumber = [self targetProcessSerialNumber];

	return theProcessSerialNumber.highLongOfPSN == 0 && theProcessSerialNumber.lowLongOfPSN == kCurrentProcess;
}

/*
 * -getAEDesc:
 */
- (BOOL)getAEDesc:(AEDesc *)aDescPtr
{
	NSData		* theData;

	theData = [self data];
	return AECreateDesc( [self descriptorType], [theData bytes], [theData length], aDescPtr ) == noErr;
}

@end

@implementation NSAppleEventDescriptor (NDConversion)

/*
 * targetProcessSerialNumber
 */
- (ProcessSerialNumber)targetProcessSerialNumber
{
	NSAppleEventDescriptor	* theTarget;
	ProcessSerialNumber		theProcessSerialNumber = { 0, 0 };

	theTarget = [self attributeDescriptorForKeyword:keyAddressAttr];

	if( theTarget )
	{
		if( [theTarget descriptorType] != typeProcessSerialNumber )
			theTarget = [theTarget coerceToDescriptorType:typeProcessSerialNumber];

		[[theTarget data] getBytes:&theProcessSerialNumber length:sizeof(ProcessSerialNumber)];
	}
	return theProcessSerialNumber;
}

/*
 * targetCreator
 */
- (OSType)targetCreator
{
	NSAppleEventDescriptor	* theTarget;
	OSType						theCreator = 0;

	theTarget = [self attributeDescriptorForKeyword:keyAddressAttr];

	if( theTarget )
	{
		if( [theTarget descriptorType] != typeApplSignature )
			theTarget = [theTarget coerceToDescriptorType:typeApplSignature];

		[[theTarget data] getBytes:&theCreator length:sizeof(OSType)];
	}
	return theCreator;
}

/*
 * currentProcessDescriptor
 */
+ (NSAppleEventDescriptor *)currentProcessDescriptor
{
	ProcessSerialNumber	theCurrentProcess = { 0, kCurrentProcess };
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:(void*)&theCurrentProcess length:sizeof(theCurrentProcess)];
}

/*
 * + aliasListDescriptorWithArray:
 */
+ (NSAppleEventDescriptor *)aliasListDescriptorWithArray:(NSArray *)anArray
{
	NSAppleEventDescriptor	* theEventList = nil;
	unsigned int				theIndex,
									theNumOfParam;

	theNumOfParam = [anArray count];

	if( theNumOfParam > 0)
	{
		theEventList = [self listDescriptor];
	
		for( theIndex = 0; theIndex < theNumOfParam; theIndex++ )
		{
			NSAppleEventDescriptor	* theAliasDesc;
			theAliasDesc = [self aliasDescriptorWithFile:[anArray objectAtIndex:theIndex]];
			
			NSAssert1( theAliasDesc != nil, @"Could not get an alias NSAppleEventDescriptor for %@", [anArray objectAtIndex:theIndex] );

			[theEventList insertDescriptor:theAliasDesc atIndex:theIndex+1];
		}
	}

	return theEventList;
}

/*
 * + descriptorWithURL:
 */
+ (id)descriptorWithURL:(NSURL *)aURL
{
	return [self descriptorWithDescriptorType:typeFileURL data:[NSData dataWithBytes:(void *)aURL length:sizeof(NSURL)]];
}

/*
 * + aliasDescriptorWithURL:
 */
+ (NSAppleEventDescriptor *)aliasDescriptorWithURL:(NSURL *)aURL
{
	return [self aliasDescriptorWithFile:aURL];
}

+ (NSAppleEventDescriptor *)aliasDescriptorWithString:(NSString *)aPath
{
	return [self aliasDescriptorWithFile:aPath];
}

+ (NSAppleEventDescriptor *)aliasDescriptorWithFile:(id)aFile
{
	AliasHandle						theAliasHandle;
	FSRef								theReference;
	NSAppleEventDescriptor		* theAppleEventDescriptor = nil;

	if( [aFile getFSRef:&theReference] == YES && FSNewAliasMinimal( &theReference, &theAliasHandle ) == noErr )
	{
		HLock((Handle)theAliasHandle);
		theAppleEventDescriptor = [self descriptorWithDescriptorType:typeAlias data:[NSData dataWithBytes:*theAliasHandle length:GetHandleSize((Handle) theAliasHandle)]];
		HUnlock((Handle)theAliasHandle);
		DisposeHandle((Handle)theAliasHandle);
	}

	return theAppleEventDescriptor;
}

// typeTrue
/*
 * +descriptorWithTrueBoolean
 */
+ (id)descriptorWithTrueBoolean
{						// doesn't need any data
	return [self descriptorWithDescriptorType:typeTrue data:[NSData data]];
}
// typeFalse
/*
 * +descriptorWithFalseBoolean
 */
+ (id)descriptorWithFalseBoolean
{						// doesn't need any data
	return [self descriptorWithDescriptorType:typeFalse data:[NSData data]];
}
// typeShortInteger
/*
 * +descriptorWithShort:
 */
+ (id)descriptorWithShort:(short int)aValue
{
	return [self descriptorWithDescriptorType:typeShortInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeLongInteger
/*
 * +descriptorWithLong:
 */
+ (id)descriptorWithLong:(long int)aValue
{
	return [self descriptorWithDescriptorType:typeLongInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeInteger
/*
 * +descriptorWithInt:
 */
+ (id)descriptorWithInt:(int)aValue
{
	return [self descriptorWithDescriptorType:typeInteger data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeShortFloat
/*
 * +descriptorWithFloat:
 */
+ (id)descriptorWithFloat:(float)aValue
{
	return [self descriptorWithDescriptorType:typeShortFloat data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeLongFloat
/*
 * +descriptorWithDouble:
 */
+ (id)descriptorWithDouble:(double)aValue
{
	return [self descriptorWithDescriptorType:typeLongFloat data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}
// typeMagnitude
/*
 * +descriptorWithUnsignedInt:
 */
+ (id)descriptorWithUnsignedInt:(unsigned int)aValue
{
	return [self descriptorWithDescriptorType:typeMagnitude data:[NSData dataWithBytes:&aValue length: sizeof(aValue)]];
}

/*
 * +descriptorWithCString:
 */
+ (id)descriptorWithCString:(const char *)aString
{
	return [self descriptorWithDescriptorType:typeText bytes:aString length:strlen(aString)];
}

/*
 * +descriptorWithUnsignedInt:
 */
+ (id)descriptorWithNumber:(NSNumber *)aNumber
{
	const char					* theType = [aNumber objCType];
	NSAppleEventDescriptor	* theDescriptor = nil;
	unsigned int				theIndex;
	struct
	{
		char				* objCType;
		DescType			descType;
		unsigned short	size;
	}		theTypes[] = {
		{ @encode(float), typeIEEE32BitFloatingPoint, sizeof(float) },
		{ @encode(double), typeIEEE64BitFloatingPoint, sizeof(double) },
		{ @encode(long double), type128BitFloatingPoint, sizeof(long double) },
		{ @encode(unsigned char), typeUInt32, sizeof(unsigned char) },
		{ @encode(char), typeSInt16, sizeof(char) },
		{ @encode(unsigned short int), typeUInt32, sizeof(unsigned short int) },
		{ @encode(short int), typeSInt16, sizeof(short int) },
		{ @encode(unsigned int), typeUInt32, sizeof(unsigned int) },
		{ @encode(int), typeSInt32, sizeof(int) },
		{ @encode(unsigned long int), typeUInt32, sizeof(unsigned long int) },
		{ @encode(long int), typeSInt32, sizeof(long int) },
		{ @encode(unsigned long long), typeSInt64, sizeof(unsigned long long) },			// no unsigned 64
		{ @encode(long long), typeSInt64, sizeof(long long) },
		{ @encode(BOOL), typeBoolean, sizeof(BOOL) },			// most likely picked up by char
		{ NULL, 0, 0 }
	};

	for( theIndex = 0; theDescriptor == nil && theTypes[theIndex].objCType != NULL; theIndex++ )
	{
		if( strcmp( theTypes[theIndex].objCType, theType ) == 0 )
		{
			char		* theBuffer[64];
			[aNumber getValue:theBuffer];
			theDescriptor = [self descriptorWithDescriptorType:theTypes[theIndex].descType bytes:theBuffer length:theTypes[theIndex].size];
		}
	}

	return theDescriptor;
}

+ (id)descriptorWithValue:(NSValue *)aValue
{
	NSAppleEventDescriptor		* theDescriptor = nil;
	const char						* theObjCType = [aValue objCType];
	if( strcmp( theObjCType, @encode( NSRange ) ) == 0 )
	{
		AEDesc		theDesc,
						theValues[2];
		NSRange		theRange;

		[aValue getValue:(void*)&theRange];
		theRange.length += theRange.location;
		
		if( AECreateDesc( keyAERangeStart, (void*)&theRange.location, sizeof(unsigned int), &theValues[0] ) == noErr )
		{
			if( AECreateDesc( keyAERangeStop, (void*)&theRange.length, sizeof(unsigned int), &theValues[1] ) == noErr )
			{

				if( AECreateDesc( typeRangeDescriptor, (void*)&theRange, sizeof(NSRange), &theDesc ) == noErr )
				{
					theDescriptor = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc];
				}
				else
					AEDisposeDesc( &theDesc );

				AEDisposeDesc( &theValues[1] );
			}
			AEDisposeDesc(
					  &theValues[0] );
		}
	}

	return theDescriptor;
}

/*
 * +descriptorWithObject:
 */
+ (id)descriptorWithObject:(id)anObject
{
	NSAppleEventDescriptor		* theDescriptor = nil;

	if( anObject == nil || [anObject isKindOfClass:[NSNull class]] )
	{
		theDescriptor = [NSAppleEventDescriptor nullDescriptor];
	}
	else if( [anObject isKindOfClass:[NSNumber class]] )
	{
		theDescriptor = [self descriptorWithNumber:anObject];
	}
	else if( [anObject isKindOfClass:[NSValue class]] )
	{
		theDescriptor = [self descriptorWithValue:anObject];
	}
	else if( [anObject isKindOfClass:[NSString class]] )
	{
		theDescriptor = [self descriptorWithString:anObject];
	}
	else if( [anObject isKindOfClass:[NSArray class]] )
	{
		theDescriptor = [self descriptorWithArray:anObject];
	}
	else if( [anObject isKindOfClass:[NSDictionary class]] )
	{
		theDescriptor = [self descriptorWithDictionary:anObject];
	}
	else if( [anObject isKindOfClass:[NSURL class]] )
	{
		theDescriptor = [self aliasDescriptorWithURL:anObject];
	}
	else if( [anObject isKindOfClass:[NSAppleEventDescriptor class]] )
	{
		theDescriptor = anObject;
	}
	else if( [anObject isKindOfClass:NSClassFromString(@"NDAppleScriptObject")] )
	{
		theDescriptor = [self performSelector:NSSelectorFromString(@"descriptorWithAppleScript:") withObject:anObject];
	}

	return theDescriptor;
}

/*
 * +descriptorWithArray:
 */
+ (id)descriptorWithArray:(NSArray *)anArray
{
	NSAppleEventDescriptor	* theEventList = nil;
	unsigned int				theIndex,
									theNumOfParam;

	theNumOfParam = [anArray count];

	if( theNumOfParam > 0)
	{
		theEventList = [self listDescriptor];

		for( theIndex = 0; theIndex < theNumOfParam; theIndex++ )
			[theEventList insertDescriptor:[self descriptorWithObject:[anArray objectAtIndex:theIndex]] atIndex:theIndex+1];
	}

	return theEventList;
}

/*
 * +listDescriptorWithObjects:...
 */
+ (id)listDescriptorWithObjects:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor = nil;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [self listDescriptorWithObjects:anObject arguments:theArgList];
	va_end( theArgList );

	return theDescriptor;
}

/*
 * +listDescriptorWithObjects:arguments:
 */
+ (id)listDescriptorWithObjects:(id)anObject arguments:(va_list)anArgList
{
	unsigned int					theIndex = 1;
	NSAppleEventDescriptor		* theEventList = [self listDescriptor];

	do
		[theEventList insertDescriptor:[self descriptorWithObject:anObject] atIndex:theIndex++];
	while( (anObject = va_arg( anArgList, id ) ) != nil );
	return theEventList;
}

/*
 * +recordDescriptorWithObjects:keywords:count:
 */
+ (NSAppleEventDescriptor *)recordDescriptorWithObjects:(id *)anObjects keywords:(AEKeyword *)aKeywords count:(unsigned int)aCount
{
	NSAppleEventDescriptor	* theDescriptor = nil;
	if( (theDescriptor = [self recordDescriptor]) != nil )
	{
		unsigned int		theIndex;
		for( theIndex = 0; theIndex < aCount; theIndex++ )
		{
			[theDescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObjects[theIndex]] forKeyword:aKeywords[theIndex]];
		}
	}
	return theDescriptor;
}

/*
 * +recordDescriptorWithDictionary:
 */
+ (NSAppleEventDescriptor *)recordDescriptorWithDictionary:(NSDictionary *)aDictionary
{
	NSAppleEventDescriptor	* theDescriptor = nil;
	if( aDictionary != nil && (theDescriptor = [self recordDescriptor]) != nil )
	{
		NSNumber			* theKey;
		NSEnumerator	* theEnumerator = [aDictionary keyEnumerator];
		Class				theNumberClass = [NSNumber class];
		while( (theKey = [theEnumerator nextObject]) != nil )
		{
			NSParameterAssert( [theKey isKindOfClass:theNumberClass] );
			[theDescriptor setDescriptor:[NSAppleEventDescriptor descriptorWithObject:[aDictionary objectForKey:theKey]] forKeyword:[theKey unsignedIntValue]];
		}
	}
	return theDescriptor;
}

/*
 * +descriptorWithDictionary:
 */
+ (id)descriptorWithDictionary:(NSDictionary *)aDictionary
{
	NSAppleEventDescriptor		* theRecordDescriptor = [self recordDescriptor];
	[theRecordDescriptor setDescriptor:[NSAppleEventDescriptor userRecordDescriptorWithDictionary:aDictionary] forKeyword:keyASUserRecordFields];
	return theRecordDescriptor;
}

/*
 * +descriptorWithObjectsAndKeys:...
 */
+ (id)descriptorWithObjectAndKeys:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor = nil,
									* theRecordDescriptor = nil;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [self userRecordDescriptorWithObjectAndKeys:anObject arguments:theArgList];
	va_end( theArgList );

	theRecordDescriptor = theDescriptor ? [self recordDescriptor] : nil;
	[theRecordDescriptor setDescriptor:theDescriptor forKeyword:keyASUserRecordFields];
	return theRecordDescriptor;
}

+ (id)descriptorWithObjectAndKeys:(id)anObject arguments:(va_list)anArgList
{
	NSAppleEventDescriptor		* theRecordDescriptor = [self recordDescriptor];
	[theRecordDescriptor setDescriptor:[NSAppleEventDescriptor userRecordDescriptorWithObjectAndKeys:anObject arguments:anArgList] forKeyword:keyASUserRecordFields];
	return theRecordDescriptor;
}

/*
 * +userRecordDescriptorWithObjectAndKeys:...
 */
+ (id)userRecordDescriptorWithObjectAndKeys:(id)anObject, ...
{
	NSAppleEventDescriptor	* theDescriptor = nil;
	va_list	theArgList;
	va_start( theArgList, anObject );
	theDescriptor = [self userRecordDescriptorWithObjectAndKeys:anObject arguments:theArgList];
	va_end( theArgList );

	return theDescriptor;
}

/*
 * +userRecordDescriptorWithObjectAndKeys:arguments:
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithObjectAndKeys:(id)anObject arguments:(va_list)anArgList
{
	NSAppleEventDescriptor		* theUserRecord = [self listDescriptor];
	if( theUserRecord )
	{
		unsigned int		theIndex = 1;
		do
		{
			NSString		* theKey = va_arg( anArgList, id );
			NSParameterAssert( theKey != nil );
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[theKey description]] atIndex:theIndex++];
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject] atIndex:theIndex++];
		}
		while( (anObject = va_arg( anArgList, id ) ) != nil );
	}

	return theUserRecord;
}

/*
 * +userRecordDescriptorWithObjects:keys:count:
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithObjects:(id *)anObject keys:(NSString **)aKeys count:(unsigned int)aCount
{
	NSAppleEventDescriptor		* theUserRecord = [self listDescriptor];
	if( theUserRecord )
	{
		unsigned int		theIndex;
		for( theIndex = 0; theIndex < aCount; theIndex++ )
		{
			NSParameterAssert( aKeys[theIndex] != nil );
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithString:aKeys[theIndex]] atIndex:theIndex+1];
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObject[theIndex]] atIndex:theIndex+2];
		}
	}

	return theUserRecord;
}

/*
 * +userRecordDescriptorWithDictionary:
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithDictionary:(NSDictionary *)aDictionary
{
	NSAppleEventDescriptor	* theUserRecord = nil;

	if( [aDictionary count] > 0 && (theUserRecord = [self listDescriptor]) != nil )
	{
		NSEnumerator	* theEnumerator = [aDictionary keyEnumerator];
		id					theKey;
		unsigned int	theIndex = 1;

		while ((theKey = [theEnumerator nextObject]) != nil )
		{
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[theKey description]] atIndex:theIndex++];
			[theUserRecord insertDescriptor:[NSAppleEventDescriptor descriptorWithObject:[aDictionary objectForKey:theKey]] atIndex:theIndex++];		
		}
	}

	return theUserRecord;
}

/*
 * - arrayValue:
 */
- (NSArray *)arrayValue
{
	SInt32						theNumOfItems,
									theIndex;
	NSAppleEventDescriptor	* theDescriptor;
	NSMutableArray				* theArray;

	theNumOfItems = [self numberOfItems];
	theArray = [NSMutableArray arrayWithCapacity:theNumOfItems];

	for( theIndex = 1; theIndex <= theNumOfItems; theIndex++)
	{
		if( theDescriptor = [self descriptorAtIndex:theIndex] )
		{
			[theArray addObject:[theDescriptor objectValue]];
		}
	}

	return theArray;
}

/*
 * - dictionaryValueFromRecordDescriptor
 */
-(NSDictionary *)dictionaryValueFromRecordDescriptor
{
	unsigned int				theIndex,
									theNumOfItems = [self numberOfItems];
	NSMutableDictionary		*theDictionary = [NSMutableDictionary dictionaryWithCapacity:theNumOfItems];

	NSParameterAssert( sizeof( AEKeyword ) == sizeof( unsigned long ) );
	for( theIndex = 1; theIndex <= theNumOfItems; theIndex++ )
	{
		AEKeyword	theKeyword = [self keywordForDescriptorAtIndex:theIndex];
		id				theObject = theKeyword == keyASUserRecordFields
										? [self descriptorForKeyword:keyASUserRecordFields]
										: [self descriptorForKeyword:theKeyword];
		[theDictionary setObject:[theObject objectValue] forKey:[NSNumber numberWithUnsignedInt:theKeyword]];
	}

	return theDictionary;
}

/*
 * -dictionaryValue
 */
- (NSDictionary *)dictionaryValue
{
	NSAppleEventDescriptor	* theUserRecordFields = [self descriptorForKeyword:keyASUserRecordFields];
	unsigned int				theIndex,
									theNumOfItems = [theUserRecordFields numberOfItems];
	NSMutableDictionary		* theDictionary = theNumOfItems
									? [NSMutableDictionary dictionaryWithCapacity:theNumOfItems/2]
									: nil;

	for( theIndex = 1; theIndex+1 <= theNumOfItems; theIndex+=2)
	{
		[theDictionary setObject:[[theUserRecordFields descriptorAtIndex:theIndex+1] objectValue] forKey:[[theUserRecordFields descriptorAtIndex:theIndex] stringValue]];
	}

	return theDictionary;
}

/*
 * - urlValue:
 */
- (NSURL *)urlValue
{
	id					theURL = nil;
	OSAError			theError;

	switch([self descriptorType])
	{
		case typeAlias:							//	alias record
		{
			unsigned int	theSize;
			Handle			theAliasHandle;
			FSRef				theTarget;
			Boolean			theWasChanged;

			theSize = (unsigned int)AEGetDescDataSize([self aeDesc]);
			theAliasHandle = NewHandle( theSize );
			HLock(theAliasHandle);
			theError = AEGetDescData([self aeDesc], *theAliasHandle, theSize);
			HUnlock(theAliasHandle);
			if( theError == noErr  && FSResolveAlias( NULL, (AliasHandle)theAliasHandle, &theTarget, &theWasChanged ) == noErr )
			{
				theURL = [NSURL URLWithFSRef:&theTarget];
			}

			DisposeHandle(theAliasHandle);
			break;
		}
		case typeFileURL:					// ???		NOT IMPLEMENTED YET
			NSLog(@"NOT IMPLEMENTED YET: Attempt to create a NSURL from 'typeFileURL' AEDesc" );
			break;
	}

	return theURL;
}

/*
 * -unsignedIntValue
 */
- (unsigned int)unsignedIntValue
{
	unsigned int		theUnsignedInt = 0;
	if( AEGetDescData([self aeDesc], &theUnsignedInt, sizeof(unsigned int)) != noErr )
		NSLog(@"Failed to get unsigned int value from NSAppleEventDescriptor");

	return theUnsignedInt;
}

/*
 * -floatValue
 */
- (float)floatValue
{
	float		theFloat = 0.0;
	if( AEGetDescData([self aeDesc], &theFloat, sizeof(float)) != noErr )
		NSLog(@"Failed to get float value from NSAppleEventDescriptor");
	
	return theFloat;
}

/*
 * -doubleValue
 */
- (double)doubleValue
{
	double		theDouble = 0.0;
	if( AEGetDescData([self aeDesc], &theDouble, sizeof(double)) != noErr )
		NSLog(@"Failed to get double value from NSAppleEventDescriptor");

	return theDouble;
}

/*
 * -value
 */
- (NSValue *)value
{
	NSValue		* theValue = nil;

	switch([self descriptorType])
	{
		case typeBoolean:						//	Boolean value
		case typeShortInteger:				//	16-bit integer
		case typeLongInteger:				//	32-bit integer
		case typeShortFloat:					//	SANE single
		case typeFloat:						//	SANE double
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeTrue:							//	TRUE Boolean value
		case typeFalse:						//	FALSE Boolean value
			theValue = [self numberValue];
			break;
		case typeOSAErrorRange:
		{
			DescType		theTypeCode;
			Size			theActualSize;
			short int	theStart,
							theEnd;
			if( AEGetParamPtr([self aeDesc], keyOSASourceStart, typeShortInteger, &theTypeCode, (void*)&theStart, sizeof(short int), &theActualSize ) == noErr && AEGetParamPtr([self aeDesc], keyOSASourceEnd, typeShortInteger, &theTypeCode, (void*)&theEnd, sizeof(short int), &theActualSize ) == noErr )
			{
				theValue = [NSValue valueWithRange:NSMakeRange( theStart, theEnd - theStart )];
			}
			break;
		}
		case typeRangeDescriptor:
		{
			DescType		theTypeCode;
			Size			theActualSize;
			short int	theStart,
							theEnd;
			if( AEGetParamPtr ([self aeDesc], keyAERangeStart, typeShortInteger, &theTypeCode, (void*)&theStart, sizeof(short int), &theActualSize ) == noErr && AEGetParamPtr ([self aeDesc], keyAERangeStop, typeShortInteger, &theTypeCode, (void*)&theEnd, sizeof(short int), &theActualSize ) == noErr )
			{
				theValue = [NSValue valueWithRange:NSMakeRange( theStart, theEnd - theStart )];
			}
			break;
		}
		default:
			theValue = nil;
			break;
	}

	return theValue;
}

/*
 * -numberValue
 */
- (NSNumber *)numberValue
{
	NSNumber		* theNumber = nil;

	switch([self descriptorType])
	{
		case typeBoolean:						//	Boolean value
			theNumber = [NSNumber numberWithBool:[self booleanValue]];
			break;
		case typeShortInteger:				//	16-bit integer
			theNumber = [NSNumber numberWithShort: [self int32Value]];
			break;
		case typeLongInteger:				//	32-bit integer
//		case typeInteger:							//	32-bit integer
		{
			int		theInteger;
			if( AEGetDescData([self aeDesc], &theInteger, sizeof(int)) == noErr )
				theNumber = [NSNumber numberWithInt: theInteger];
			break;
		}
		case typeShortFloat:					//	SANE single
//		case typeSMFloat:							//	SANE single
		{
			theNumber = [NSNumber numberWithFloat:[self floatValue]];
			break;
		}
		case typeFloat:						//	SANE double
//		case typeLongFloat:						//	SANE double
		{
			theNumber = [NSNumber numberWithDouble:[self doubleValue]];
			break;
		}
//		case typeExtended:						//	SANE extended
//			break;
//		case typeComp:							//	SANE comp
//			break;
		case typeMagnitude:					//	unsigned 32-bit integer
		{
			theNumber = [NSNumber numberWithUnsignedLong:[self unsignedIntValue]];
			break;
		}
		case typeTrue:							//	TRUE Boolean value
			theNumber = [NSNumber numberWithBool:YES];
			break;
		case typeFalse:						//	FALSE Boolean value
			theNumber = [NSNumber numberWithBool:NO];
			break;
		case typeType:
			theNumber = [NSNumber numberWithUnsignedLong:[self typeCodeValue]];
			break;
		default:
			theNumber = nil;
			break;
	}

	return theNumber;
}

/*
 * -objectValue
 */
- (id)objectValue
{
	id			theResult;
	DescType	theDescType = [self descriptorType];

#if 0
	printf("descriptor type = %s\n", [NSFileTypeForHFSTypeCode(theDescType) lossyCString] );
#endif
	
	switch(theDescType)
	{
		case typeBoolean:						//	1-byte Boolean value
		case typeShortInteger:				//	16-bit integer
//		case typeSMInt:							//	16-bit integer
		case typeLongInteger:				//	32-bit integer
//		case typeInteger:							//	32-bit integer
		case typeShortFloat:					//	SANE single
//		case typeSMFloat:							//	SANE single
		case typeFloat:						//	SANE double
 //		case typeLongFloat:						//	SANE double
//		case typeExtended:						//	SANE extended
//		case typeComp:							//	SANE comp
		case typeMagnitude:					//	unsigned 32-bit integer
		case typeTrue:							//	TRUE Boolean value
		case typeFalse:						//	FALSE Boolean value
			theResult = [self numberValue];
			break;
		case typeOSAErrorRange:
			theResult = [self value];
			break;
//		case typeChar:								//	unterminated string, equal to typeText
		case typeText:							//	plain text
		case kTXNUnicodeTextData:			//	unicode string
			theResult = [self stringValue];
			break;
		case typeAEList:						//	list of descriptor records
			theResult = [self arrayValue];
			break;
		case typeAERecord:					//	list of keyword-specified
			theResult = [self numberOfItems] == 1 && [self keywordForDescriptorAtIndex:1] == keyASUserRecordFields ? [self dictionaryValue] : [self dictionaryValueFromRecordDescriptor];
			break;
		case typeAlias:						//	alias record
		case typeFileURL:
			theResult = [self urlValue];
			break;
//		case typeEnumerated:					//	enumerated data
//			break;
		case cScript:							// script data
		{
			SEL		theSelector;

			theSelector = NSSelectorFromString(@"appleScriptValue");
			theResult = [self respondsToSelector:theSelector] ? [self performSelector:theSelector] : self;
			break;
		}
		case cEventIdentifier:
		{
			unsigned int		*theValues;
			theValues = (unsigned int*)[[self data] bytes];
			theResult = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:theValues[0]], @"EventClass", [NSNumber numberWithUnsignedInt:theValues[1]], @"EventID", nil];
			break;
		}
		case typeNull:
			theResult = [NSNull null];
			break;
		default:
			theResult = self;
			break;
	}

	return theResult;
}

@end

/*
 * class implementation NSAppleEventDescriptor (NDCompleteEvents)
 */
@implementation NSAppleEventDescriptor (NDCompleteEvents)

/*
 * -openEventDescriptorWithTargetDescriptor:
 */
+ (NSAppleEventDescriptor *)openEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)aTargetDescriptor
{
	return aTargetDescriptor ? [self appleEventWithEventClass:kCoreEventClass eventID:kAEOpenApplication targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] : nil;
}

/*
 * -openEventDescriptorWithTargetDescriptor:array:
 */
+ (NSAppleEventDescriptor *)openEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)aTargetDescriptor array:(NSArray *)anArray 
{
	NSAppleEventDescriptor	* theEvent = nil,
									* theEventList = nil;

	if( aTargetDescriptor != nil)
	{
		theEventList = [NSAppleEventDescriptor aliasListDescriptorWithArray:anArray];

		if( theEventList )
		{
			theEvent = [self appleEventWithEventClass:kCoreEventClass eventID:kAEOpenDocuments targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
			[theEvent setParamDescriptor:theEventList forKeyword:keyDirectObject];
		}
	}

	return theEvent;
}

/*
 * -quitEventDescriptorWithTargetDescriptor:
 */
+ (NSAppleEventDescriptor *)quitEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)aTargetDescriptor
{
	return aTargetDescriptor ? [self appleEventWithEventClass:kCoreEventClass eventID:kAEQuitApplication targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] : nil;
}

/*
 * +descriptorWithSubroutineName:argumentsListDescriptor:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName argumentsListDescriptor:(NSAppleEventDescriptor *)aParam
{
	return [[[NSAppleEventDescriptor alloc] initWithSubroutineName:aRoutineName argumentsListDescriptor:aParam] autorelease];
}

/*
 * +descriptorWithSubroutineName:argumentsArray:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName argumentsArray:(NSArray *)aParamArray
{
	return [[[NSAppleEventDescriptor alloc] initWithSubroutineName:aRoutineName argumentsListDescriptor:aParamArray ? [NSAppleEventDescriptor descriptorWithArray:aParamArray] : nil] autorelease];
}

/*
 * +descriptorWithSubroutineName:arguments:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName arguments:(id)aFirstArg, ...
{
	NSAppleEventDescriptor		* theListDescriptor = nil;
	va_list	theArgList;
	va_start( theArgList, aFirstArg );
	theListDescriptor = [NSAppleEventDescriptor listDescriptorWithObjects:aFirstArg arguments:theArgList];
	va_end( theArgList );
	return [[[self alloc] initWithSubroutineName:aRoutineName argumentsListDescriptor:theListDescriptor] autorelease];
}

/*
 * +descriptorWithSubroutineName:prepositionalArgumentObjects:forKeyword:count:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels argumentObjects:(id *)anObjects count:(unsigned int)aCount
{
	return [[[self alloc] initWithSubroutineName:aRoutineName labels:aLabels arguments:anObjects count:aCount] autorelease];
}

/*
 * +descriptorWithSubroutineName:labels:argumentDescriptors:count:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels argumentDescriptors:(NSAppleEventDescriptor **)aParam count:(unsigned int)aCount
{
	return [[[self alloc] initWithSubroutineName:aRoutineName labels:aLabels argumentDescriptors:aParam  count:aCount] autorelease];
}

/*
 * +descriptorWithSubroutineName:labelsAndArguments:
 */
+ (id)descriptorWithSubroutineName:(NSString *)aRoutineName labelsAndArguments:(AEKeyword)aKeyWord, ...
{
	NSAppleEventDescriptor	* theDescriptor;
	va_list	theArgList;
	va_start( theArgList, aKeyWord );
	theDescriptor = [[[self alloc] initWithSubroutineName:aRoutineName labelsAndArguments:aKeyWord arguments:theArgList] autorelease];
	va_end( theArgList );
	return theDescriptor;
}

/*
 * -initWithSubroutineName:argumentsArray:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName argumentsArray:(NSArray *)aParamArray
{
	return [self initWithSubroutineName:aRoutineName argumentsListDescriptor:aParamArray ? [NSAppleEventDescriptor descriptorWithArray:aParamArray] : nil];
}

/*
 * -initWithSubroutineName:argumentsListDescriptor:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName argumentsListDescriptor:(NSAppleEventDescriptor *)aParam
{
	if( self = [self initWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent
									 targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] )
	{
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		[self setParamDescriptor:aParam ? aParam : [NSAppleEventDescriptor listDescriptor] forKeyword:keyDirectObject];
	}

	return self;
}

/*
 * -initWithSubroutineName:labels:arguments:count:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels arguments:(id *)anObjects count:(unsigned int)aCount
{
	if( self = [self initWithEventClass:kASAppleScriptSuite eventID:kASPrepositionalSubroutine
														 targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] )
	{
		unsigned int		theIndex;
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		for( theIndex = 0; theIndex < aCount; theIndex++ )
		{
			if( aLabels[theIndex] == keyASPrepositionGiven
					&& [anObjects[theIndex] isKindOfClass:[NSDictionary class]] )
			{
				[self setParamDescriptor:[NSAppleEventDescriptor userRecordDescriptorWithDictionary:anObjects[theIndex]] forKeyword:keyASUserRecordFields];
			}
			else if( aLabels[theIndex] == keyASPrepositionGiven
					&& [anObjects[theIndex] isKindOfClass:[NSAppleEventDescriptor class]] )
			{
				[self setParamDescriptor:anObjects[theIndex] forKeyword:keyASUserRecordFields];
			}
			else
			{
				[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithObject:anObjects[theIndex]] forKeyword:aLabels[theIndex]];
			}
		}
	}

	return self;
}

/*
 * -initWithSubroutineName:prepositionalArgumentDescriptors:forKeywords:count:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName labels:(AEKeyword*)aLabels argumentDescriptors:(NSAppleEventDescriptor **)aParam count:(unsigned int)aCount
{
	if( self = [self initWithEventClass:kASAppleScriptSuite eventID:kASPrepositionalSubroutine
												  targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] )
	{
		unsigned int		theIndex;
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		for( theIndex = 0; theIndex < aCount; theIndex++ )
			[self setParamDescriptor:aParam[theIndex] forKeyword:aLabels[theIndex]];
	}

	return self;
}

/*
 * -initWithSubroutineName:labelsAndArguments:arguments:
 */
- (id)initWithSubroutineName:(NSString *)aRoutineName labelsAndArguments:(AEKeyword)aKeyWord arguments:(va_list)anArgList
{
	if( self = [self initWithEventClass:kASAppleScriptSuite eventID:kASPrepositionalSubroutine targetDescriptor:[NSAppleEventDescriptor currentProcessDescriptor] returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] )
	{
		[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithCString:[[aRoutineName lowercaseString] lossyCString]] forKeyword:keyASSubroutineName];
		do
		{
			id		theObject = va_arg( anArgList, id );

			if( aKeyWord == keyASPrepositionGiven )
			{
				[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithObject:[NSAppleEventDescriptor userRecordDescriptorWithObjectAndKeys:theObject arguments:anArgList]] forKeyword:keyASUserRecordFields];
				break;				// all the arguments have been got
			}
			else
				[self setParamDescriptor:[NSAppleEventDescriptor descriptorWithObject:theObject] forKeyword:aKeyWord];
		}
		while( (aKeyWord = va_arg( anArgList, AEKeyword ) ) != nil );
	}

	return self;
}

@end

