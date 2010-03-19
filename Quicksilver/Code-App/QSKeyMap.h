//
//  QSKeyMap.h
//  Quicksilver
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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

// Wrapper around a standard carbon keymap. These are all virtual keycodes
// several of which are defing in Events.h. This is an immutable object.
@interface QSKeyMap : NSObject <NSCopying> {
@private
	KeyMapByteArray keyMap_;
}

// Return an autoreleased keymap representing the current keys that are down
+ (id)currentKeyMap;

// Return an empty keyMap
- (id)init;

// Return a keymap object representing the keyMap
- (id)initWithKeyMap:(KeyMap)keyMap;

// Return a keymap with a |count| size array of |keys| down
- (id)initWithKeys:(const UInt16 *)keys count:(NSUInteger)count;

// Return a new autoreleased key map that has a key added to it
- (QSKeyMap *)keyMapByAddingKey:(UInt16)keyCode;

// Inverts a keymap
- (QSKeyMap *)keyMapByInverting;

// Gets a copy of the key map wrapped by this object
- (void)getKeyMap:(KeyMap *)keyMap;

// Returns true if one or more of the keys in |keyMap| are also in us.
// So if you wanted to check if "M" was down, you would create a keyMap 
// containing "kVK_ANSI_M" and then call 
// [myMap containsAnyKeyIn:[QSKeyMap currentKeyMap]]
- (BOOL)containsAnyKeyIn:(QSKeyMap *)keyMap;
@end
