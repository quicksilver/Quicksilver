
// SLKeyPopUpButton.m
// Searchling
//
// Created by Alcor on Thu Jan 16 2003.
// Copyright (c) 2003 Blacktree, Inc. All rights reserved.
//

#import "QSObjectView.h"
#import "QSObjectCell.h"
#import "QSController.h"
#import "QSExecutor.h"
#import "QSInterfaceController.h"

#import <QSFoundation/QSFoundation.h>
#import "NSCursor_InformExtensions.h"
#import "QSObject_Drag.h"
#import "QSObject_Menus.h"
#import "QSObject_Pasteboard.h"
#import "QSAction.h"
//#import "NSString_CompletionExtensions.h"

#import <ApplicationServices/ApplicationServices.h>

@implementation QSObjectView

+ (Class) cellClass {
	return [QSObjectCell class];
}

- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
	id object = [self objectValue];
	if ([object respondsToSelector:@selector(dataDictionary)] && [[[object dataDictionary] allKeys] containsObject:sendType])
		return self;
	return nil;
}

- (void)awakeFromNib {
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, NSColorPboardType, NSFileContentsPboardType, NSFilenamesPboardType, NSFontPboardType, NSHTMLPboardType, NSPDFPboardType, NSPostScriptPboardType, NSRulerPboardType, NSRTFPboardType, NSRTFDPboardType, NSStringPboardType, NSTabularTextPboardType, NSTIFFPboardType, NSURLPboardType, NSVCardPboardType, NSFilesPromisePboardType, nil]];
	draggedObject = nil;
	[self setDropMode:QSFullDropMode];
}

- (QSInterfaceController *)controller {
	return (QSInterfaceController *)[[self window] windowController];
}

- (BOOL)acceptsFirstResponder {return NO;}

- (BOOL)resignFirstResponder {
	[self setNeedsDisplay:YES];
	return YES;
}

- (BOOL)becomeFirstResponder {
	//[controller setFocus:self];
	[self setNeedsDisplay:YES];
	return YES;
}
- (BOOL)isOpaque {
	return NO;
}

- (void)setImage:(NSImage *)image {}

- (void)mouseClicked:(NSEvent *)theEvent {
    
}

- (void)mouseDown:(NSEvent *)theEvent {
    // must be overridden, otherwise the mouseDragged: method is never called
}

- (void)mouseDragged:(NSEvent *)theEvent {
    
	switch ([theEvent type]) {
		case NSLeftMouseDragged: {
            QSObject *objectValue = [self objectValue];
			if (objectValue) {
                NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:objectValue];
                NSRect bounds = self.bounds;
                dragItem.draggingFrame = bounds;
                draggingFrame = CGRectNull;
                [self setupDraggingImage:dragItem];

                NSDraggingSession *draggingSession = [self beginDraggingSessionWithItems:[NSArray arrayWithObject:dragItem] event:theEvent source:self];
                //causes the dragging item to slide back to the source if the drag fails.
                draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
                
                draggingSession.draggingFormation = NSDraggingFormationNone;
                dragIsInView = YES;
            }
        }
            break;
        default:
            break;
    }
}

-(void)setupDraggingImage:(NSDraggingItem*)dragItem {
    __weak QSObjectView *weakSelf = self;
    dragItem.imageComponentsProvider = ^{
        NSDraggingImageComponent *imageComponent = [NSDraggingImageComponent draggingImageComponentWithKey:NSDraggingImageComponentIconKey];
        NSRect imageRect = [(QSObjectCell *)weakSelf.cell imageRectForBounds:weakSelf.bounds];
        imageComponent.frame = imageRect;
        NSImage *img = [weakSelf.cell image];
        [img setSize:imageRect .size];
        imageComponent.contents = img;
        return @[imageComponent];
    };
}


- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    // This demo does not allow dragging from this view to the Finder or other application
    switch (context) {
        case NSDraggingContextOutsideApplication:
            return YES;
            
            // by using this fall through pattern, we will remain compatible if the context get more precise in the future.
        case NSDraggingContextWithinApplication:
        default:
            return NO;
            break;
    }
}


- (BOOL)needsPanelToBecomeKey {
	return YES;
}

- (void)delete:(id)sender {
    [self setObjectValue:nil];
}

- (void)paste:(id)sender { [self readSelectionFromPasteboard:[NSPasteboard generalPasteboard]]; }

- (void)cut:(id)sender {
	[[self objectValue] putOnPasteboard:[NSPasteboard generalPasteboard] includeDataForTypes:nil];
	[self setObjectValue:nil];
}

- (void)copy:(id)sender {
	[[self objectValue] putOnPasteboard:[NSPasteboard generalPasteboard] includeDataForTypes:nil];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard {
	[self setObjectValue:[QSObject objectWithPasteboard:pboard]];
	return YES;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
	[[self objectValue] putOnPasteboard:pboard includeDataForTypes:types];
	return YES;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
	NSLog(@"write to %@", [dropDestination path]);
	NSString *name = [[(QSObject *)[self objectValue] name] stringByAppendingPathExtension:@"silver"];
	name = [name stringByReplacing:@"/" with:@"_"];
	name = [name stringByReplacing:@":" with:@"_"];
	NSString *file = [[dropDestination path] stringByAppendingPathComponent:name];
	[(QSObject *)[self objectValue] writeToFile:file];
	return [NSArray arrayWithObject:name];
}

- (NSSize) cellSize {
	return [[self cell] cellSize];
}

//Standard Accessors
- (QSObject *)previousObjectValue
{
  return previousObjectValue;
}

- (void)setPreviousObjectValue:(QSObject *)aValue
{
  previousObjectValue = aValue;
}

- (id)objectValue { return [[self cell] representedObject];  }
- (void)setObjectValue:(QSBasicObject *)newObject {
    [self setPreviousObjectValue:[self objectValue]];
	[newObject loadIcon];
	[newObject becameSelected];
	// [self setToolTip:[newObject toolTip]];
	[[self cell] setRepresentedObject:newObject];
	[self setNeedsDisplay:YES];
}

- (QSObjectDropMode) dropMode { return dropMode;  }
- (void)setDropMode:(QSObjectDropMode)aDropMode {
	dropMode = aDropMode;
}

- (BOOL)acceptsDrags { return [self dropMode];  }

- (BOOL)initiatesDrags { return initiatesDrags;  }
- (void)setInitiatesDrags:(BOOL)flag {
	initiatesDrags = flag;
}

- (QSObject *)draggedObject { return draggedObject;  }

- (void)setDraggedObject:(QSObject *)newDraggedObject {
	draggedObject = newDraggedObject;
}

- (NSString *)searchString { return searchString;  }

- (void)setSearchString:(NSString *)newSearchString {
	if (newSearchString == searchString) return;
	searchString = newSearchString;
	// [self setNeedsDisplay:YES];
}


//Dragging

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender {
	if (![self acceptsDrags] || ([self objectValue] && ![[self objectValue] respondsToSelector: @selector(actionForDragOperation:withObject:)]))
		return NSDragOperationNone;

	[self setDragAction:nil];
	lastDragMask = NSDragOperationNone;

	if ([[sender draggingSource] isKindOfClass:[self class]])
		[self setDraggedObject:[[sender draggingSource] objectValue]];
	else
		[self setDraggedObject:[QSObject objectWithPasteboard:[sender draggingPasteboard]]];
	return [self draggingUpdated:sender];
}

- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>)sender {
	if ([self objectValue] && ![[self objectValue] respondsToSelector: @selector(actionForDragOperation:withObject:)])
		return NSDragOperationNone;
	NSDragOperation operation = 0;
	if (![self objectValue] || [self dropMode] == QSSelectDropMode)
		operation = NSDragOperationGeneric;
	else if ([[self objectValue] respondsToSelector:@selector(draggingEntered:withObject:)])
		operation = [[self objectValue] draggingEntered:sender withObject:[self draggedObject]];
	NSCursor *cursor;
	if (operation == NSDragOperationGeneric) {
		cursor = [NSCursor informativeCursorWithString:@"Select"];
		[cursor set];
		[[self cell] setHighlighted:NO];
	} else if ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask) {
		cursor = [NSCursor informativeCursorWithString:@"Choose Action..."];
		[cursor performSelector:@selector(set) withObject:nil afterDelay:0.0];
		operation = NSDragOperationPrivate;
	} else {
		if (operation != lastDragMask) {
			NSString *action = [[self objectValue] actionForDragOperation:operation withObject:draggedObject];
			cursor = [NSCursor informativeCursorWithString:[[QSExec actionForIdentifier:action] name]];
			[cursor performSelector:@selector(set) withObject:nil afterDelay:0.0];
		}
		if (operation)
			[[self cell] setHighlighted:YES];
	}
	lastDragMask = operation;
	return operation;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	[[self cell] setHighlighted:NO];
	[self setDraggedObject:nil];
	[NSCursor pop];
	[self setNeedsDisplay:YES];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {}

- (void)drawRect:(NSRect)rect { [[self cell] drawWithFrame:rectFromSize([self frame].size) inView:self];  }

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSString *action = [[self objectValue] actionForDragOperation:lastDragMask withObject:draggedObject];

	if ([[NSApp currentEvent] modifierFlags] & NSControlKeyMask) {
        if ([[[self objectValue] resolvedObject] respondsToSelector:@selector(actionsMenu)]) {
            NSMenu *actionsMenu = [[[self objectValue] resolvedObject] performSelector:@selector(actionsMenu)];
            [NSMenu popUpContextMenu:actionsMenu withEvent:[NSApp currentEvent] forView:self];
        }
	} else if (action && [self dropMode] != QSSelectDropMode) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self concludeDragWithAction:[QSExec actionForIdentifier:action]];
        });
	} else if (lastDragMask & NSDragOperationGeneric) {
		id winController = [[self window] windowController];
		if ([winController isKindOfClass:[QSInterfaceController class]] ) {
			[(QSInterfaceController *)winController invalidateHide];
			[[self window] makeKeyAndOrderFront:self];
		}
		[NSCursor pop];
		[[self window] selectNextKeyView:self];
		[self setObjectValue:[self draggedObject]];
		[self setDraggedObject:nil];
	} else {
		return NO;
	}
	[[self cell] setHighlighted:NO];
	[[self window] makeFirstResponder:self];
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	[self setDragAction:nil];
}

- (void)concludeDragWithAction:(QSAction *)actionObject {
    [actionObject performOnDirectObject:[self draggedObject] indirectObject:[self objectValue]];
}

- (NSString *)dragAction { return dragAction;  }

- (void)setDragAction:(NSString *)aDragAction {
	if (dragAction != aDragAction) {
		dragAction = aDragAction;
	}
}

@end

