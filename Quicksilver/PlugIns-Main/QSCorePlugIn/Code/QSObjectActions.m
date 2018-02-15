//
// QSObjectActions.m
// Quicksilver
//
// Created by Alcor on 7/26/04.
// Copyright 2004 Blacktree. All rights reserved.
//

#import "QSObjectActions.h"
#import "QSObject_StringHandling.h"
#import "QSObject_FileHandling.h"
#import "QSMnemonics.h"

#import "QSInterfaceController.h"
#import "QSController.h"

#import "QSProxyObject.h"

#import "QSObject_Menus.h"

#import "QSCatalogPrefPane.h"

# define kQSObjectSearchChildrenAction @"QSObjectSearchChildrenAction"
# define kQSObjectShowChildrenAction @"QSObjectShowChildrenAction"
# define kQSObjectShowSourceAction @"QSObjectShowSourceAction"
# define kQSObjectOmitAction @"QSObjectOmitAction"
# define kQSObjectAssignLabelAction @"QSObjectAssignLabelAction"
# define kQSObjectExplodeCombinedAction @"QSObjectExplodeCombinedAction"

#import "QSTextProxy.h"
#import "QSWindowAnimation.h"

@implementation QSObjectActions

- (NSArray *)validActionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject {

	NSMutableArray *newActions = [NSMutableArray arrayWithCapacity:1];

	if ([dObject hasChildren]) {
		[newActions addObject:kQSObjectSearchChildrenAction];

		[newActions addObject:kQSObjectShowChildrenAction];
	}
    if ([[QSLibrarian sharedInstance] firstEntryContainingObject:dObject])
    {
            [newActions addObject:kQSObjectShowSourceAction];
    }
	if ([dObject count] > 1) {
		[newActions addObject:kQSObjectExplodeCombinedAction];
	}
	return newActions;
}

- (QSObject *)selectObjectInCommandWindow:(QSObject *)dObject {
	QSInterfaceController *controller = [(QSController *)[NSApp delegate] interfaceController];

	[[controller dSelector] redisplayObjectValue:[dObject resolvedObject]];
	[[controller dSelector] updateHistory];
	[controller actionActivate:self];

	return nil;
}
- (QSObject *)searchChildren:(QSObject *)dObject {
	QSInterfaceController *controller = [(QSController *)[NSApp delegate] interfaceController];
	[controller searchArray:(NSMutableArray *)[[dObject resolvedObject] children]];
	return nil;
}

- (QSObject *)showChildren:(QSObject *)dObject {
	QSInterfaceController *controller = [(QSController *)[NSApp delegate] interfaceController];
	[controller showArray:(NSMutableArray *)[[dObject resolvedObject] children]];
	return nil;
}

- (QSObject *)setObjectMnemonic:(QSObject *)dObject string:(QSObject *)iObject {
	if (![[QSMnemonics sharedInstance] addObjectMnemonic:[iObject stringValue] forObject:dObject] || ![[QSMnemonics sharedInstance] addAbbrevMnemonic:[iObject stringValue] forObject:dObject relativeToID:nil immediately:NO]) {
        QSShowAppNotifWithAttributes(@"ActionFailed", NSLocalizedStringFromTableInBundle(@"Unable to assign abbreviation", nil, [NSBundle bundleForClass:[self class]], nil), [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Unable to assign abbreviation '%@' to object %@. Perhaps you want to create a synonym?", nil, [NSBundle bundleForClass:[self class]], nil),  [iObject stringValue], [dObject name]]);
    } else {
        [dObject updateMnemonics];
    }
	return nil;
}

- (QSObject *)findObjectInCatalog:(QSObject *)dObject {

	QSCatalogEntry *theEntry = [[QSLibrarian sharedInstance] firstEntryContainingObject:dObject];

    [NSClassFromString(@"QSCatalogPrefPane") performSelectorOnMainThread:@selector(showEntryInCatalog:) withObject:theEntry waitUntilDone:NO];
    
    return nil;
}

- (NSWindow *)windowForObject:(QSObject *)object atPoint:(NSPoint)loc {
	NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(loc.x, loc.y, 1, 1) styleMask:NSBorderlessWindowMask backing: NSBackingStoreBuffered defer:NO];
	[window orderFront:nil];
	[window setReleasedWhenClosed:YES];
    return window;
}

- (NSWindow *)showMenu:(NSMenu *)menu forObject:(QSObject *)object {
	NSPoint loc = [NSEvent mouseLocation];
    
	NSWindow *window = nil;
	window = [self windowForObject:object atPoint:loc];
    
    if (!window) return nil;
    
    NSView * cView = [window contentView];
    
    NSEvent *theEvent = [NSEvent mouseEventWithType:NSRightMouseDown 
                                           location:NSMakePoint(1, 1) 
                                      modifierFlags:0 
                                          timestamp:0 
                                       windowNumber:[window windowNumber] 
                                            context:nil 
                                        eventNumber:0 
                                         clickCount:1 
                                           pressure:0];
    
	[window setAlphaValue:0.5 fadeTime:0.1];
	[NSMenu popUpContextMenu:menu withEvent:theEvent forView:cView withFont:[NSFont systemFontOfSize:11]];
																				  //[window orderOut:nil];
    [window setAlphaValue:0.0 fadeTime:0.3];
    return nil;
}

- (QSObject *)showChildMenu:(QSObject *)dObject {
	[self showMenu:[[dObject resolvedObject] childrenMenu] forObject:dObject];
	return nil;
}
- (QSObject *)showMenu:(QSObject *)dObject {
	[self showMenu:[[dObject resolvedObject] fullMenu] forObject:dObject];
	return nil;
}
- (QSObject *)showActionMenu:(QSObject *)dObject {
	[self showMenu:[[dObject resolvedObject] actionsMenu] forObject:dObject];
	return nil;
}

- (QSObject *)saveObject:(QSObject *)dObject toDirectory:(QSObject *)iObject {
	dObject = [dObject resolvedObject];
	id handler = [dObject handler];
	NSData *data = nil;
	NSString *filename = nil;
	if ([handler respondsToSelector:@selector(fileRepresentationForObject:)])
		data = [handler fileRepresentationForObject:dObject];

	if ([handler respondsToSelector:@selector(filenameForObject:)])
		filename = [handler filenameForObject:dObject];

	if (!filename) filename = [dObject displayName];

    if ([filename length] > 200) {
		filename = [filename substringToIndex:200];
    }
    
    NSString *savePath = nil;
    
    // attempt to get a path for the file from the iObject
	if (iObject) {
		savePath = [iObject singleFilePath];
        NSFileManager *fm = [[NSFileManager alloc] init];
        if ([fm fileExistsAtPath:savePath]) {
            savePath = [savePath stringByAppendingPathComponent:filename];
        } else {
            savePath = nil;
        }
	}
    
    // If there is no iObject or the iObject path doesn't exist, ask the user for a path
    if (!savePath) {
		[NSApp activateIgnoringOtherApps:YES];
		NSSavePanel *savePanel = [NSSavePanel savePanel];
		[savePanel setRepresentedFilename:filename];
		[savePanel setPrompt:@"Create"];
        [savePanel setTitle:@"Choose a file name and location to save the file"];
		[savePanel setCanCreateDirectories:YES];
		[savePanel setAllowedFileTypes:[NSArray arrayWithObject:[filename pathExtension]]];
		[savePanel runModal];
		if ([savePanel URL]) {
			savePath = [[savePanel URL] path];
        }
    }
    
    // No filename, beep and return the original object
    if(!savePath) {
        NSBeep();
        return dObject;
    }
    
	[data writeToFile:savePath atomically:NO];
	return [QSObject fileObjectWithPath:savePath];

}

- (QSObject *)explodeCombinedObject:(QSObject *)dObject
{
	NSMutableArray *components = [[dObject splitObjects] mutableCopy];
	QSInterfaceController *controller = [(QSController *)[NSApp delegate] interfaceController];
	[controller showArray:components];
	return nil;
}

- (QSObject *)logObjectToConsole:(QSObject *)dObject
{
	NSLog(@"Printing Object\n%@", [dObject name]);
	NSLog(@"\n%@", [dObject dictionaryRepresentation]);
	return nil;
}

- (NSArray *)validIndirectObjectsForAction:(NSString *)action directObject:(QSObject *)dObject {
	if ([action isEqualToString:@"QSCreateFileAction"]) {
		return nil;
	} else if ([action isEqualToString:@"QSObjectAssignMnemonic"]) {
        NSString *suggestion = [[[(QSController *)[NSApp delegate] interfaceController] dSelector] matchedString];
        QSObject *textObject = [QSObject textProxyObjectWithDefaultValue:suggestion];
        return [NSArray arrayWithObject:textObject];
	} else {
	QSObject *textObject = [QSObject textProxyObjectWithDefaultValue:@""];
	return [NSArray arrayWithObject:textObject]; //[[QSLibrarian sharedInstance]arrayForType:NSFilenamesPboardType];
	}
}

- (void)closeWindow:(NSTimer *)timer {
	NSWindow *window = [timer userInfo];
	[window setAlphaValue:0.0 fadeTime:0.3];
	[window close];
}

@end
