//
//  QSThreadSafeMutableDictionary.m
//  Quicksilver
//
//  Created by Patrick Robertson on 12/03/2014.
//
//
// Originall taken from https://gist.github.com/steipete/5928916
// Copyright (c) 2013 Peter Steinberger, PSPDFKit GmbH. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "QSThreadSafeMutableDictionary.h"

//#import <libkern/OSAtomic.h>

@implementation QSThreadSafeMutableDictionary {
	NSMutableDictionary *_dictionary;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
	if ((self = [super init])) {
		_dictionary = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys {
	if ((self = [self initWithCapacity:objects.count])) {
		[objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
			_dictionary[keys[idx]] = obj;
		}];
	}
	return self;
}

- (id)initWithCapacity:(NSUInteger)capacity {
	if ((self = [super init])) {
		_dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
	}
	return self;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSMutableDictionary

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
	@synchronized(_dictionary) { _dictionary[aKey] = anObject; }
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
	@synchronized(_dictionary) { [_dictionary addEntriesFromDictionary:otherDictionary]; };
}

- (void)setDictionary:(NSDictionary *)otherDictionary {
	@synchronized(_dictionary) { [_dictionary setDictionary:otherDictionary]; };
}

- (void)removeObjectForKey:(id)aKey {
	@synchronized(_dictionary) { [_dictionary removeObjectForKey:aKey]; }
}

- (void)removeAllObjects {
	@synchronized(_dictionary) { [_dictionary removeAllObjects]; };
}

- (NSUInteger)count {
	@synchronized(_dictionary) {
		NSUInteger count = _dictionary.count;
		return count;}
}

- (NSArray *)allKeys {
	@synchronized(_dictionary) {
		NSArray *allKeys = _dictionary.allKeys;
		return allKeys;
	}
}

- (NSArray *)allValues {
	@synchronized(_dictionary) {
		NSArray *allValues = _dictionary.allValues;
		return allValues;
	}
}

- (id)objectForKey:(id)aKey {
	@synchronized(_dictionary) {
		id obj = _dictionary[aKey];
		return obj;
	}
}

- (NSEnumerator *)keyEnumerator {
	@synchronized(_dictionary) {
		NSEnumerator *keyEnumerator = [_dictionary keyEnumerator];
		return keyEnumerator;
	}
}

- (id)copyWithZone:(NSZone *)zone {
	return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
	@synchronized(_dictionary) {
		id copiedDictionary = [[self.class allocWithZone:zone] initWithDictionary:_dictionary];
		return copiedDictionary;
	}
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
								  objects:(id __unsafe_unretained [])stackbuf
									count:(NSUInteger)len {
	@synchronized(_dictionary) {
		NSUInteger count = [[_dictionary copy] countByEnumeratingWithState:state objects:stackbuf count:len];
		return count;
	};
}

- (BOOL)isEqual:(id)object {
	if (object == self) return YES;

	if ([object isKindOfClass:QSThreadSafeMutableDictionary.class]) {
		QSThreadSafeMutableDictionary *other = object;
		@synchronized (_dictionary) {
			@synchronized (other) {
				return [_dictionary isEqual:other];
			}
		}
	}
	return NO;
}

@end
