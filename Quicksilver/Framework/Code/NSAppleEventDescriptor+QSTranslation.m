//
//  NSAppleEventDescriptor+QSTranslation.m
//  Quicksilver
//
//  Created by Alcor on Thu Aug 28 2003.

//

#import "NSAppleEventDescriptor+QSTranslation.h"
#import <Carbon/Carbon.h>

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

@implementation NSAppleEventDescriptor (QSTranslation)

+ (NSAppleEventDescriptor *)descriptorWithObjectAPPLE:(id)object{
	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] descriptorByTranslatingObject:object ofType:nil inSuite:nil];
}

- (id)objectValueAPPLE{
	return [[NSAEDescriptorTranslator sharedAEDescriptorTranslator] objectByTranslatingDescriptor:self toType:nil inSuite:nil];
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