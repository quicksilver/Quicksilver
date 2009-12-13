//
//  QSKeyMap.m
//  Quicksilver
//
//
//  Copyright (c) 2008 Google Inc. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are
//  met:
//
//    * Redistributions of source code must retain the above copyright
//  notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above
//  copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the
//  distribution.
//    * Neither the name of Google Inc. nor the names of its
//  contributors may be used to endorse or promote products derived from
//  this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

#import "QSKeyMap.h"
//#import "QSLog.h"

@implementation QSKeyMap
+ (id)currentKeyMap {
	KeyMap keyMap;
	GetKeys(keyMap);
	return [[[self alloc] initWithKeyMap:keyMap] autorelease];
}

- (id)init {
	return [super init];
}

- (id)initWithKeyMap:(KeyMap)keyMap {
	if ((self = [super init])) {
		memcpy(keyMap_, keyMap, sizeof(KeyMapByteArray));
	}
	return self;
}

- (id)initWithKeys:(const UInt16 *)keys count:(NSUInteger)count {
	if (!keys || !count) {
		NSLog(@"Did you really mean to call us with Keys being nil "
					@"or count being 0?");
		return [self init];
	}
	KeyMapByteArray array;
	bzero(array, sizeof(array));
	for (NSUInteger k = 0; k < count; ++k) {
		UInt16 i = keys[k] / 8;
		UInt16 j = keys[k] % 8;
		array[i] |= 1 << j;
	}
	return [self initWithKeyMap:*((KeyMap*)&array)];
}

- (id)copyWithZone:(NSZone *)zone {
	return [[[self class] alloc] initWithKeyMap:*((KeyMap*)&keyMap_)];
}

- (NSUInteger)hash {
	// I tried to design this hash so it hashed better on 64 bit than on 32
	// bit. By keying it to the size of hash we can get a better value for our
	// keymap.
	NSUInteger hash = 0;
	NSUInteger *keyMapHash = (NSUInteger *)keyMap_;
	for (size_t i = 0; i < sizeof(keyMap_) / sizeof(hash); ++i) {
		hash += keyMapHash[i];
	}
	return hash;
}  

- (BOOL)isEqual:(id)keyMap {
	BOOL isEqual = [keyMap isKindOfClass:[self class]];
	if (isEqual) {
		KeyMapByteArray array;
		[keyMap getKeyMap:(KeyMap*)&array];
		isEqual = memcmp(keyMap_, array, sizeof(KeyMapByteArray)) == 0;
	}
	return isEqual;
}

- (NSString*)description {
	NSMutableString *string = [NSMutableString string];
	for (size_t i = 0; i < sizeof(keyMap_); i++) {
		[string appendFormat:@" %02hhX", keyMap_[i]];
	}
	return string;
}

- (QSKeyMap *)keyMapByAddingKey:(UInt16)keyCode {
	KeyMapByteArray array;
	[self getKeyMap:(KeyMap*)&array];
	
	UInt16 i = keyCode / 8;
	UInt16 j = keyCode % 8;
	array[i] |= 1 << j;
	return [[[[self class] alloc] initWithKeyMap:*((KeyMap*)&array)] autorelease];
}

- (QSKeyMap *)keyMapByInverting {
	KeyMapByteArray array;
	for (size_t i = 0; i < sizeof(array); ++i) {
		array[i] = ~keyMap_[i];
	}
	return [[[[self class] alloc] initWithKeyMap:*((KeyMap*)&array)] autorelease];
}

- (void)getKeyMap:(KeyMap*)keyMap {
	if (keyMap) {
		memcpy(*keyMap, keyMap_, sizeof(KeyMapByteArray));
	} else {
		NSLog(@"You probably don't want to call getKeyMap with a NULL ptr");
	}
}

- (BOOL)containsAnyKeyIn:(QSKeyMap *)keyMap {
	BOOL contains = NO;
	KeyMapByteArray array;
	[keyMap getKeyMap:(KeyMap*)&array];
	for (size_t i = 0; i < sizeof(KeyMapByteArray); ++i) {
		if (keyMap_[i] & array[i]) {
			contains = YES;
			break;
		}
	}
	return contains;
}

@end
