//
//  NSAppleEventDescriptor+NDAppleScriptObject_QSMods.m
//  Quicksilver
//
//  Created by Alcor on 8/19/04.

//

#import "NSAppleEventDescriptor_QSMods.h"
#import "NSURL+NDCarbonUtilities.h"

@implementation NSAppleEventDescriptor (NDAppleScriptObject_QSMods)

+ (NSAppleEventDescriptor *)targetDescriptorWithTypeSignature:(OSType)type{
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature bytes:(void*)&type length:sizeof(type)];
}


-(NSAppleEventDescriptor *)AESend{
	[self AESendWithSendMode:kAENoReply priority:kAENormalPriority timeout:100];
	return nil;
}

-(NSAppleEventDescriptor *)AESendWithSendMode:(AESendMode)sendMode priority:(AESendPriority)priority timeout:(long)timeout{
	AppleEvent reply;
	OSStatus err=AESend([self aeDesc],&reply,sendMode,priority,timeout,NULL,NULL);
	if (err){
		QSLog(@"sendAppleEventError %d",err);
	}else{
		AEDisposeDesc(&reply);
		return [NSAppleEventDescriptor descriptorWithAEDescNoCopy:&reply];
    }	
	return nil;
}

//[self appleEventWithEventClass:kCoreEventClass eventID:kAEQuitApplication targetDescriptor:aTargetDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID] : nil;


@end
