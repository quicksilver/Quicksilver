/*
    Copyright (c) 2001, bDistributed.com, Inc.
    All rights reserved.

    Redistribution and use in source and binary forms, with or
    without modification, are permitted provided that the following
    conditions are met:

    *   Redistributions of source code must retain the above
        copyright notice, this list of conditions and the following
        disclaimer.
    
    *   Redistributions in binary form must reproduce the above
        copyright notice, this list of conditions and the following
        disclaimer in the documentation and/or other materials
        provided with the distribution.
    
    *   Neither the name of bDistributed.com, Inc. nor the names of
        its contributors may be used to endorse or promote products
        derived from this software without specific prior written
        permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
    CONTRIBUTORS ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
    OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
    TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
    OF SUCH DAMAGE.
*/

#include <assert.h>

#import "BDAlias.h"


static Handle DataToHandle(CFDataRef inData);
static CFDataRef HandleToData(Handle inHandle);

static OSStatus PathToFSRef(CFStringRef inPath, FSRef *outRef);
static CFStringRef FSRefToPathCopy(const FSRef *inRef);


static Handle DataToHandle(CFDataRef inData)
{
    CFIndex	len;
    Handle	handle = NULL;
    
    if (inData == NULL) {
        return NULL;
    }
    
    len = CFDataGetLength(inData);
    
    handle = NewHandle(len);
    
    if ((handle != NULL) && (len > 0)) {
        HLock(handle);
        BlockMoveData(CFDataGetBytePtr(inData), *handle, len);
        HUnlock(handle);
    }
    
    return handle;
}

static CFDataRef HandleToData(Handle inHandle)
{
    CFDataRef	data = NULL;
    CFIndex	len;
    SInt8	handleState;
    
    if (inHandle == NULL) {
        return NULL;
    }
    
    len = GetHandleSize(inHandle);
    
    handleState = HGetState(inHandle);
    
    HLock(inHandle);
    
    data = CFDataCreate(kCFAllocatorDefault, (const UInt8 *) *inHandle, len);
    
    HSetState(inHandle, handleState);
    
    return data;
}

static OSStatus PathToFSRef(CFStringRef inPath, FSRef *outRef)
{
    CFURLRef	tempURL = NULL;
    Boolean	gotRef = false;
    
    tempURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, inPath,
                                            kCFURLPOSIXPathStyle, false);
    
    if (tempURL == NULL) {
        return fnfErr;
    }
    
    gotRef = CFURLGetFSRef(tempURL, outRef);
    
        CFRelease(tempURL);
    
    if (gotRef == false) {
        return fnfErr;
    }
    
    return noErr;
}

static CFStringRef FSRefToPathCopy(const FSRef *inRef)
{
    CFURLRef	tempURL = NULL;
    CFStringRef	result = NULL;
    
    if (inRef != NULL) {
        tempURL = CFURLCreateFromFSRef(kCFAllocatorDefault, inRef);
        
        if (tempURL == NULL) {
            return NULL;
        }
        
        result = CFURLCopyFileSystemPath(tempURL, kCFURLPOSIXPathStyle);
        
        CFRelease(tempURL);
    }
    
    return result;
}


@implementation BDAlias

- (id)initWithAliasHandle:(AliasHandle)alias
{
    id ret = [super init];
    
    if (ret != nil) {
        _alias = alias;
    }
    
    return ret;
}

- (id)initWithData:(NSData *)data
{
    return [self initWithAliasHandle:(AliasHandle)DataToHandle((CFDataRef) data)];
}

- (id)initWithPath:(NSString *)fullPath
{
    OSStatus	anErr = noErr;
    FSRef		ref;
    
    anErr = PathToFSRef((CFStringRef) fullPath, &ref);
    
    if (anErr != noErr) {
        return nil;
    }
    
    return [self initWithFSRef:&ref];;
}

- (id)initWithPath:(NSString *)path relativeToPath:(NSString *)relPath
{
    OSStatus	anErr = noErr;
    FSRef		ref, relRef;
    
    anErr = PathToFSRef((CFStringRef) [relPath stringByAppendingPathComponent:path],
                        &ref);
    
    if (anErr != noErr) {
        return nil;
    }
    
    anErr = PathToFSRef((CFStringRef) relPath, &relRef);
    
    if (anErr != noErr) {
        return nil;
    }
    
    return [self initWithFSRef:&ref relativeToFSRef:&relRef];
}

- (id)initWithFSRef:(FSRef *)ref
{
    return [self initWithFSRef:ref relativeToFSRef:NULL];
}

- (id)initWithFSRef:(FSRef *)ref relativeToFSRef:(FSRef *)relRef
{
    OSStatus	anErr = noErr;
    AliasHandle	alias = NULL;
    
    anErr = FSNewAlias(relRef, ref, &alias);
    
    if (anErr != noErr) {
        return nil;
    }
    
    return [self initWithAliasHandle:alias];
}

- (void)dealloc
{
    if (_alias != NULL) {
        DisposeHandle((Handle) _alias);
        _alias = NULL;
    }
    
    [super dealloc];
}

- (AliasHandle)alias
{
    return _alias;
}

- (void)setAlias:(AliasHandle)newAlias
{
    if (_alias != NULL) {
        DisposeHandle((Handle) _alias);
    }
    
    _alias = newAlias;
}

- (NSData *)aliasData
{
    NSData *result;
    
    result = (NSData *)HandleToData((Handle) _alias);
    
    return [result autorelease];
}

- (void)setAliasData:(NSData *)newAliasData
{
    [self setAlias:(AliasHandle) DataToHandle((CFDataRef) newAliasData)];
}



- (NSString *)quickPath
{
    
    CFStringRef pathString=nil;
    FSCopyAliasInfo (
                     _alias,
                     NULL,NULL,
                     &pathString,
                     NULL,
                     NULL
                     );
  
   // QSLog(@"alias %@",pathString);
    return (NSString *)pathString;
}

- (NSString *)fullPath
{
    return [self fullPathRelativeToPath:nil];
}

- (NSString *)fullPathRelativeToPath:(NSString *)relPath
{
    OSStatus	anErr = noErr;
    FSRef	relPathRef;
    FSRef	tempRef;
    NSString	*result = nil;
    Boolean	wasChanged;
    
    if (_alias != NULL) {
        if (relPath != nil) {
            anErr = PathToFSRef((CFStringRef)relPath, &relPathRef);
            
            if (anErr != noErr) {
                return NULL;
            }
            
            anErr = FSResolveAlias(&relPathRef, _alias, &tempRef, &wasChanged);
        } else {
            anErr = FSResolveAlias(NULL, _alias, &tempRef, &wasChanged);
        }
        
        if (anErr != noErr) {
            return NULL;
        }
        
        result = (NSString *)FSRefToPathCopy(&tempRef);
    }
    
    return [result autorelease];
}

+ (BDAlias *)aliasWithAliasHandle:(AliasHandle)alias
{
    return [[[BDAlias alloc] initWithAliasHandle:alias] autorelease];
}

+ (BDAlias *)aliasWithData:(NSData *)data
{
    return [[[BDAlias alloc] initWithData:data] autorelease];
}

+ (BDAlias *)aliasWithPath:(NSString *)fullPath
{
    return [[[BDAlias alloc] initWithPath:fullPath] autorelease];
}

+ (BDAlias *)aliasWithPath:(NSString *)path relativeToPath:(NSString *)relPath
{
    return [[[BDAlias alloc] initWithPath:path relativeToPath:relPath] autorelease];
}

+ (BDAlias *)aliasWithFSRef:(FSRef *)ref
{
    return [[[BDAlias alloc] initWithFSRef:ref] autorelease];
}

+ (BDAlias *)aliasWithFSRef:(FSRef *)ref relativeToFSRef:(FSRef *)relRef
{
    return [[[BDAlias alloc] initWithFSRef:ref relativeToFSRef:relRef] autorelease];
}

@end
