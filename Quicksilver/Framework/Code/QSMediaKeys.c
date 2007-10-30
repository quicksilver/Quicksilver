/*
 *  QSMediaKeys.c
 *  Quicksilver
 *
 *  Created by Alcor on 12/29/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#include "QSMediaKeys.h"
#import <IOKit/hidsystem/IOHIDLib.h>
#include <AssertMacros.h>
#include <string.h>

io_connect_t get_event_driver(void){
	static  mach_port_t sEventDrvrRef = 0;
	mach_port_t masterPort, service, iter;
	kern_return_t    kr;
	
	if (!sEventDrvrRef)
	{
		// Get master device port
		kr = IOMasterPort( bootstrap_port, &masterPort );
		check( KERN_SUCCESS == kr);
		
		kr = IOServiceGetMatchingServices( masterPort, IOServiceMatching(
																		 kIOHIDSystemClass ), &iter );
		check( KERN_SUCCESS == kr);
		
		service = IOIteratorNext( iter );
		check( service );
		
		kr = IOServiceOpen( service, mach_task_self(),
							kIOHIDParamConnectType, &sEventDrvrRef );
		check( KERN_SUCCESS == kr );
		
		IOObjectRelease( service );
		IOObjectRelease( iter );
	}
	return sEventDrvrRef;
}

void HIDPostSysDefinedKey(const UInt8 sysKeyCode )
{
	NXEventData        event;
	kern_return_t    kr;
	IOGPoint        loc = { 0, 0 };
	
	bzero(&event, sizeof(NXEventData));
	
	event.compound.subType = sysKeyCode;
	kr = IOHIDPostEvent( get_event_driver(), NX_SYSDEFINED, loc, &event,
						 kNXEventDataVersion, 0, FALSE );
	check( KERN_SUCCESS == kr );
}


 void HIDPostAuxKey(const UInt8 auxKeyCode )
{
	NXEventData        event;
	kern_return_t    kr;
	IOGPoint        loc = { 0, 0 };
	
	bzero(&event, sizeof(NXEventData));
	
	event.compound.subType = NX_SUBTYPE_AUX_CONTROL_BUTTONS;
	event.compound.misc.S[0] = auxKeyCode;
	event.compound.misc.C[2] = NX_KEYDOWN;
	
	kr = IOHIDPostEvent( get_event_driver(), NX_SYSDEFINED, loc, &event,
						 kNXEventDataVersion, 0, FALSE );
	check( KERN_SUCCESS == kr );
}
