/*
 *  NDComponentInstance.m
 *  NDAppleScriptObjectProject
 *
 *  Created by Nathan Day on Tue May 20 2003.
 *  Copyright (c) 2002 Nathan Day. All rights reserved.
 */

#import "NDComponentInstance.h"
#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

const OSType					kFinderCreatorCode = 'MACS';

/*
 * category interface NDComponentInstance (Private)
 */
@interface NDComponentInstance (Private)
- (ComponentInstance)scriptingComponent;
@end

/*
 * class implementation NDComponentInstance
 */
@implementation NDComponentInstance

static NDComponentInstance		* sharedComponentInstance = nil;

/*
 * +sharedComponentInstance
 */
+ (id)sharedComponentInstance
{
	if( sharedComponentInstance == nil && (sharedComponentInstance = [[self alloc] init]) == NULL)
		NSLog(@"Could not create shared Component Instance");

	return sharedComponentInstance;
}

/*
 * +closeSharedComponentInstance
 */
+ (void)closeSharedComponentInstance
{
	[sharedComponentInstance release];
	sharedComponentInstance = nil;
}

/*
 * findNextComponent
 */
+ (Component)findNextComponent
{
	ComponentDescription		theReturnCompDesc;
	static Component			theLastComponent = NULL;
	ComponentDescription		theComponentDesc;

	theComponentDesc.componentType = kOSAComponentType;
	theComponentDesc.componentSubType = kOSAGenericScriptingComponentSubtype;
	theComponentDesc.componentManufacturer = 0;
	theComponentDesc.componentFlags =  kOSASupportsCompiling | kOSASupportsGetSource | kOSASupportsAECoercion | kOSASupportsAESending | kOSASupportsConvenience | kOSASupportsDialects | kOSASupportsEventHandling;

	theComponentDesc.componentFlagsMask = theComponentDesc.componentFlags;

	do
	{
		theLastComponent = FindNextComponent( theLastComponent, &theComponentDesc );
 	}
	while( GetComponentInfo( theLastComponent, &theReturnCompDesc, NULL, NULL, NULL ) == noErr && theComponentDesc.componentSubType == kOSAGenericScriptingComponentSubtype );

	return theLastComponent;
}

/*
 * + componentInstance
 */
+ (id)componentInstance
{
	return [[[self alloc] init] autorelease];
}

/*
 * +componentInstanceWithComponent:
 */
+ (id)componentInstanceWithComponent:(Component)aComponent
{
	return [[[self alloc] initWithComponent:aComponent] autorelease];
}

/*
 * -init
 */
- (id)init
{
	return [self initWithComponent:NULL];
}

/*
 * -initWithComponent:
 */
- (id)initWithComponent:(Component)aComponent
{
	if( self = [super init] )
	{
		if( aComponent == NULL )
		{
			// crashes here
			if( (scriptingComponent = OpenDefaultComponent( kOSAComponentType, kAppleScriptSubtype )) == NULL )
			{
				[self release];
				self = nil;
				NSLog(@"Could not open connection with default AppleScript component");
			}
		}
		else if( (scriptingComponent = OpenComponent( aComponent )) == NULL )
		{
			[self release];
			self = nil;
			NSLog(@"Could not open connection with component");
		}
	}
	return self;
}

/*
 * - dealloc
 */
-(void)dealloc
{
	[self setAppleEventSendTarget:nil];
	[activeTarget release];

	if( scriptingComponent != NULL )
	{
		
		CloseComponent( scriptingComponent );
	}
	[super dealloc];
}

/*
 * - setDefaultTarget:
 */
- (void)setDefaultTarget:(NSAppleEventDescriptor *)aDefaultTarget
{
	if( OSASetDefaultTarget( [self scriptingComponent], [aDefaultTarget aeDesc] ) != noErr )
		NSLog( @"Could not set default target" );
}

/*
 * - setDefaultTargetAsCreator:
 */
- (void)setDefaultTargetAsCreator:(OSType)aCreator
{
	NSAppleEventDescriptor	* theAppleEventDescriptor;

	theAppleEventDescriptor = [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature data:[NSData dataWithBytes:&aCreator length:sizeof(aCreator)]];
	[self setDefaultTarget:theAppleEventDescriptor];
}

/*
 * - setFinderAsDefaultTarget
 */
- (void)setFinderAsDefaultTarget
{
	[self setDefaultTargetAsCreator:kFinderCreatorCode];
}

/*
 * setAppleEventSendTarget:
 */
- (void)setAppleEventSendTarget:(id<NDAppleScriptObjectSendEvent>)aTarget
{
	if( aTarget != sendAppleEventTarget )
	{
		OSErr		AppleEventSendProc( const AppleEvent *theAppleEvent, AppleEvent *reply, AESendMode sendMode, AESendPriority sendPriority, long timeOutInTicks, AEIdleUPP idleProc, AEFilterUPP filterProc, long refCon );

		NSParameterAssert( sizeof(long) == sizeof(id) );
		
		/*	need to save the default send proceedure as we will call it in our send proceedure	*/
		if( aTarget != nil )
		{
			if( defaultSendProcPtr == NULL )		// need to save this so we can restor it
			{
				ComponentInstance		theComponent = [self scriptingComponent];

				NSAssert( OSAGetSendProc( theComponent, &defaultSendProcPtr, &defaultSendProcRefCon) == noErr, @"Could not get default AppleScript send procedure");
				NSAssert( OSASetSendProc( theComponent, AppleEventSendProc, (long)self ) == noErr, @"Could not set send procedure" );
			}

			[sendAppleEventTarget release];
			sendAppleEventTarget = [aTarget retain];
		}
		else
		{
			[sendAppleEventTarget release];
			sendAppleEventTarget = nil;

			NSAssert( OSASetSendProc( [self scriptingComponent], defaultSendProcPtr, defaultSendProcRefCon ) == noErr, @"Could not restore default send procedure");

			defaultSendProcPtr = NULL;
			defaultSendProcRefCon = 0;
		}
	}
}

/*
 * appleEventSendTarget
 */
- (id<NDAppleScriptObjectSendEvent>)appleEventSendTarget
{
	return sendAppleEventTarget;
}

/*
 * setActiveTarget:
 */
- (void)setActiveTarget:(id<NDAppleScriptObjectActive>)aTarget
{
	OSErr						AppleScriptActiveProc( long aRefCon );

	if( aTarget != activeTarget )
	{
		NSParameterAssert( sizeof(long) == sizeof(id) );

		if( aTarget != nil )
		{
			/*	need to save the default active proceedure as we will call it in our active proceedure	*/
			if( defaultActiveProcPtr == NULL )
			{
				ComponentInstance		theComponent = [self scriptingComponent];

				NSAssert( OSAGetActiveProc(theComponent, &defaultActiveProcPtr, &defaultActiveProcRefCon ) == noErr, @"Could not get default AppleScript active procedure");
				NSAssert( OSASetActiveProc( theComponent, AppleScriptActiveProc , (long)self ) == noErr, @"Could not set AppleScript active procedure.");
			}

			[activeTarget release];
			activeTarget = [aTarget retain];
		}
		else if( defaultActiveProcPtr == NULL )
		{
			[activeTarget release];
			activeTarget = nil;
			NSAssert( OSASetActiveProc( [self scriptingComponent], defaultActiveProcPtr, defaultActiveProcRefCon ) == noErr, @"Could not set default active procedure.");
			defaultActiveProcPtr = NULL;
			defaultActiveProcRefCon = 0;
		}
	}
}

/*
 * -activeTarget
 */
- (id<NDAppleScriptObjectActive>)activeTarget
{
	return activeTarget;
}

/*
 * -sendAppleEvent:sendMode:sendPriority:timeOutInTicks:idleProc:filterProc:
 */
- (NSAppleEventDescriptor *)sendAppleEvent:(NSAppleEventDescriptor *)theAppleEventDescriptor sendMode:(AESendMode)aSendMode sendPriority:(AESendPriority)aSendPriority timeOutInTicks:(long)aTimeOutInTicks idleProc:(AEIdleUPP)anIdleProc filterProc:(AEFilterUPP)aFilterProc
{
	NSAppleEventDescriptor		* theReplyAppleEventDesc = nil;
	AppleEvent						theReplyAppleEvent;

	NSParameterAssert( defaultSendProcPtr != NULL );

	if( defaultSendProcPtr( [theAppleEventDescriptor aeDesc], &theReplyAppleEvent, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, defaultSendProcRefCon ) == noErr )
	{
		theReplyAppleEventDesc = [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theReplyAppleEvent];
	}
	
	return theReplyAppleEventDesc;
}

/*
 * appleScriptActive
 */
- (BOOL)appleScriptActive
{
	NSParameterAssert( defaultActiveProcPtr != NULL );
	return defaultActiveProcPtr( defaultActiveProcRefCon ) == noErr;
}

/*
 * description
 */
- (NSString *)description
{
	AEDesc		theDesc = { typeNull, NULL };
	NSString		* theDescription = nil;
	OSErr			theError;
	if ( (theError = OSAScriptingComponentName( [self scriptingComponent], &theDesc)) == noErr )
	{
		theDescription = [@"NDComponentInstance name:" stringByAppendingString:[[NSAppleEventDescriptor descriptorWithAEDescNoCopy:&theDesc] stringValue]];
	}
	else
	{
		theDescription = @"NDComponentInstance: name not available";
	}

	return theDescription;
}

/*
 * function AppleEventSendProc
 */
OSErr AppleEventSendProc( const AppleEvent *anAppleEvent, AppleEvent *aReply, AESendMode aSendMode, AESendPriority aSendPriority, long aTimeOutInTicks, AEIdleUPP anIdleProc, AEFilterUPP aFilterProc, long aRefCon )
{
	NDComponentInstance			* self = (id)aRefCon;
	OSErr								theError = errOSASystemError;
	id									theSendTarget = [self appleEventSendTarget];
	NSAppleEventDescriptor		* theAppleEventDescReply,
										* theAppleEventDescriptor = [NSAppleEventDescriptor descriptorWithAEDesc:anAppleEvent];

	NSCParameterAssert( self != nil );
	
	/*	if we have an instance, it has a target and we can create a NSAppleEventDescriptor	*/
	if( theSendTarget != nil && theAppleEventDescriptor != nil )
	{
		theAppleEventDescReply = [theSendTarget sendAppleEvent:theAppleEventDescriptor sendMode:aSendMode sendPriority:aSendPriority timeOutInTicks:aTimeOutInTicks idleProc:anIdleProc filterProc:aFilterProc];

		if( [theAppleEventDescReply getAEDesc:(AEDesc*)aReply] )
		{
			theError = noErr;			// NO ERROR
		}
	}
	else if( self->defaultSendProcPtr != NULL )
	{
		theError = (self->defaultSendProcPtr)( anAppleEvent, aReply, aSendMode, aSendPriority, aTimeOutInTicks, anIdleProc, aFilterProc, self->defaultSendProcRefCon );

	}

	return theError;
}

/*
 * function AppleScriptActiveProc
 */
OSErr AppleScriptActiveProc( long aRefCon )
{
	NDComponentInstance	* self = (id)aRefCon;
	id							theActiveTarget = [self activeTarget];
	OSErr						theError = errOSASystemError;

	NSCParameterAssert( self != nil );
	
	if( theActiveTarget != nil )
		theError = [theActiveTarget appleScriptActive] ? noErr : errOSASystemError;
	else
		theError = (self->defaultActiveProcPtr)( self->defaultActiveProcRefCon );

	return theError;
}

@end

/*
 * category implementation NDComponentInstance (Private)
 */
@implementation NDComponentInstance (Private)

/*
 * -scriptingComponent
 */
- (ComponentInstance)scriptingComponent
{
	return scriptingComponent;
}

@end

