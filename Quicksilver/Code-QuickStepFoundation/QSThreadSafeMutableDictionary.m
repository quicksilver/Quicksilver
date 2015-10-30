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

#import <libkern/OSAtomic.h>

#define LOCKED(...) OSSpinLockLock(&_lock); \
__VA_ARGS__; \
OSSpinLockUnlock(&_lock);

@implementation QSThreadSafeMutableDictionary {
    OSSpinLock _lock;
    NSMutableDictionary *_dictionary; // Class Cluster!
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        _dictionary = [[NSMutableDictionary alloc] init];
        _lock = OS_SPINLOCK_INIT;
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
        _lock = OS_SPINLOCK_INIT;
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSMutableDictionary

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    LOCKED(_dictionary[aKey] = anObject)
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary {
    LOCKED([_dictionary addEntriesFromDictionary:otherDictionary]);
}

- (void)setDictionary:(NSDictionary *)otherDictionary {
    LOCKED([_dictionary setDictionary:otherDictionary]);
}

- (void)removeObjectForKey:(id)aKey {
    LOCKED([_dictionary removeObjectForKey:aKey])
}

- (void)removeAllObjects {
    LOCKED([_dictionary removeAllObjects]);
}

- (NSUInteger)count {
    LOCKED(NSUInteger count = _dictionary.count)
    return count;
}

- (NSArray *)allKeys {
    LOCKED(NSArray *allKeys = _dictionary.allKeys)
    return allKeys;
}

- (NSArray *)allValues {
    LOCKED(NSArray *allValues = _dictionary.allValues)
    return allValues;
}

- (id)objectForKey:(id)aKey {
    LOCKED(id obj = _dictionary[aKey])
    return obj;
}

- (NSEnumerator *)keyEnumerator {
    LOCKED(NSEnumerator *keyEnumerator = [_dictionary keyEnumerator])
    return keyEnumerator;
}

- (id)copyWithZone:(NSZone *)zone {
    return [self mutableCopyWithZone:zone];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    LOCKED(id copiedDictionary = [[self.class allocWithZone:zone] initWithDictionary:_dictionary])
    return copiedDictionary;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __unsafe_unretained [])stackbuf
                                    count:(NSUInteger)len {
    LOCKED(NSUInteger count = [[_dictionary copy] countByEnumeratingWithState:state objects:stackbuf count:len]);
    return count;
}

- (void)performLockedWithDictionary:(void (^)(NSDictionary *dictionary))block {
    if (block) {
        LOCKED(block(_dictionary));
    }
}

- (BOOL)isEqual:(id)object {
    if (object == self) return YES;
    
    if ([object isKindOfClass:QSThreadSafeMutableDictionary.class]) {
        QSThreadSafeMutableDictionary *other = object;
        __block BOOL isEqual = NO;
        [other performLockedWithDictionary:^(NSDictionary *dictionary) {
            [self performLockedWithDictionary:^(NSDictionary *otherDictionary) {
                isEqual = [dictionary isEqual:otherDictionary];
            }];
        }];
        return isEqual;
    }
    return NO;
}

@end
