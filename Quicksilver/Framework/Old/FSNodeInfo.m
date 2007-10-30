/*
	FSNodeInfo.m
	Copyright (c) 2001-2002, Apple Computer, Inc., all rights reserved.
	Author: Chuck Pisula

	Milestones:
	Initially created 3/1/01

	Encapsulates information about a file or directory.
*/

/*
 IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
 consideration of your agreement to the following terms, and your use, installation, 
 modification or redistribution of this Apple software constitutes acceptance of these 
 terms.  If you do not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and subject to these 
 terms, Apple grants you a personal, non-exclusive license, under Apple’s copyrights in 
 this original Apple software (the "Apple Software"), to use, reproduce, modify and 
 redistribute the Apple Software, with or without modifications, in source and/or binary 
 forms; provided that if you redistribute the Apple Software in its entirety and without 
 modifications, you must retain this notice and the following text and disclaimers in all 
 such redistributions of the Apple Software.  Neither the name, trademarks, service marks 
 or logos of Apple Computer, Inc. may be used to endorse or promote products derived from 
 the Apple Software without specific prior written permission from Apple. Except as expressly
 stated in this notice, no other rights or licenses, express or implied, are granted by Apple
 herein, including but not limited to any patent rights that may be infringed by your 
 derivative works or by other works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES, 
 EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, 
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS 
 USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS 
 OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, 
 REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND 
 WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR 
 OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "FSNodeInfo.h"

@implementation FSNodeInfo 

+ (FSNodeInfo*)nodeWithParent:(FSNodeInfo*)parent atRelativePath:(NSString *)path {
    return [[[FSNodeInfo alloc] initWithParent:parent atRelativePath:path] autorelease];
}

- (id)initWithParent:(FSNodeInfo*)parent atRelativePath:(NSString*)path {    
    self = [super init];
    if (self==nil) return nil;
    
    parentNode = parent;
    relativePath = [path retain];
    
    return self;
}

- (void)dealloc {
    // parentNode is not released since we never retained it.
    [relativePath release];
    relativePath = nil;
    parentNode = nil;
    [super dealloc];
}

- (NSArray *)subNodes {
    NSString       *subNodePath = nil;
    NSEnumerator   *subNodePaths = [[[NSFileManager defaultManager] directoryContentsAtPath: [self absolutePath]] objectEnumerator];
    NSMutableArray *subNodes = [NSMutableArray array];
    
    while ((subNodePath=[subNodePaths nextObject])) {
        FSNodeInfo *node = [FSNodeInfo nodeWithParent:self atRelativePath: subNodePath];
        [subNodes addObject: node];
    }
    return subNodes;
}

- (NSArray *)visibleSubNodes {
    FSNodeInfo     *subNode = nil;
    NSEnumerator   *allSubNodes = [[self subNodes] objectEnumerator];
    NSMutableArray *visibleSubNodes = [NSMutableArray array];
    
    while ((subNode=[allSubNodes nextObject])) {
        if ([subNode isVisible]) [visibleSubNodes addObject: subNode];
    }
    return visibleSubNodes;
}

- (BOOL)isLink {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[self absolutePath] traverseLink:NO];
    return [[fileAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeSymbolicLink];
}

- (BOOL)isExtensionHidden {
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] fileAttributesAtPath:[self absolutePath] traverseLink:NO];
    return [fileAttributes fileExtensionHidden];
}

- (BOOL)isDirectory {
    BOOL isDir = NO;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[self absolutePath] isDirectory:&isDir];
    return (exists && isDir);
}

- (BOOL)isReadable {
    return [[NSFileManager defaultManager] isReadableFileAtPath: [self absolutePath]];
}

- (BOOL)isVisible {
    // Make this as sophisticated for example to hide more files you don't think the user should see!
    BOOL visible=[[NSFileManager defaultManager]isVisible:[self absolutePath]];

    if ([[self absolutePath]isEqualToString:@"/Volumes"])return YES;
    return visible;
}

- (NSString*)fsType {
    if ([self isDirectory]) return @"Directory";
    else return @"Non-Directory";
}

- (NSString*)lastPathComponent {
    return [relativePath lastPathComponent];
}

- (NSString*)absolutePath {
    NSString *result = relativePath;
    if(parentNode!=nil) {
        NSString *parentAbsPath = [parentNode absolutePath];
        if ([parentAbsPath isEqualToString: @"/"]) parentAbsPath = @"";
        result = [NSString stringWithFormat: @"%@/%@", parentAbsPath, relativePath];
    }
    return result;
}

- (NSImage*)iconImageOfSize:(NSSize)size {
    NSString *path = [self absolutePath];
    NSImage *nodeImage = nil;
    
    nodeImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
    if (!nodeImage) {
        // No icon for actual file, try the extension.
        nodeImage = [[NSWorkspace sharedWorkspace] iconForFileType:[path pathExtension]];
    }
    [nodeImage setSize: size];
    
    if ([self isLink]) {
        NSImage *arrowImage = [NSImage imageNamed: @"FSIconImage-LinkArrow"];
        NSImage *nodeImageWithArrow = [[[NSImage alloc] initWithSize: size] autorelease];
        
	[arrowImage setScalesWhenResized: YES];
	[arrowImage setSize: size];
	
        [nodeImageWithArrow lockFocus];
	[nodeImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
        [arrowImage compositeToPoint:NSZeroPoint operation:NSCompositeSourceOver];
        [nodeImageWithArrow unlockFocus];
	
	nodeImage = nodeImageWithArrow;
    }
    
    if (nodeImage==nil) {
        nodeImage = [NSImage imageNamed:@"FSIconImage-Default"];
    }
    
    return nodeImage;
}

@end
