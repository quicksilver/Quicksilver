
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

- (void)viewDidMoveToWindow {
//	NSMutableParagraphStyle *truncatedStyle = [[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
//	[truncatedStyle setLineBreakMode:NSLineBreakByTruncatingMiddle];

	//detailAttributes = [[NSDictionary dictionaryWithObjectsAndKeys:
//		[NSFont systemFontOfSize:10] , NSFontAttributeName,
//		[NSColor grayColor] , NSForegroundColorAttributeName,
//		truncatedStyle, NSParagraphStyleAttributeName,
//		nil] retain];
	//NSLog(@"move");
//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setNeedsDisplay:) name:NSSystemColorsDidChangeNotification object:nil];

}

- (void)awakeFromNib {
////	[self viewDidMoveToWindow];
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType, NSColorPboardType, NSFileContentsPboardType, NSFilenamesPboardType, NSFontPboardType, NSHTMLPboardType, NSPDFPboardType, NSPostScriptPboardType, NSRulerPboardType, NSRTFPboardType, NSRTFDPboardType, NSStringPboardType, NSTabularTextPboardType, NSTIFFPboardType, NSURLPboardType, NSVCardPboardType, NSFilesPromisePboardType, nil]];
	// [self setToolTip:@"No Selection"];
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

- (void)mouseDown:(NSEvent *)theEvent {
	//BOOL isInside = YES;
	//NSPoint mouseLoc;

	theEvent = [[self window] nextEventMatchingMask: NSLeftMouseUpMask | NSLeftMouseDraggedMask];
	//mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	//isInside = [self mouse:mouseLoc inRect:[self bounds]];

	switch ([theEvent type]) {
		case NSLeftMouseDragged:
			performingDrag = YES;
			// [super mouseDragged:theEvent];
			if ([self objectValue]) {
				NSRect reducedRect = [self frame];
				//reducedRect.size.width = MIN(NSWidth([self frame]), 52+MAX([[[self objectValue] name] sizeWithAttributes:nil] .width, [[[self objectValue] details] sizeWithAttributes:detailAttributes] .width) );
				NSImage *dragImage = [[NSImage alloc] initWithSize:reducedRect.size];
				[dragImage lockFocus];
				[[self cell] drawInteriorWithFrame:NSMakeRect(0, 0, [dragImage size] .width, [dragImage size] .height) inView:self];
				[dragImage unlockFocus];
//				NSSize dragOffset = NSMakeSize(0.0, 0.0); // Just use NSZeroSize: Ankur, 21 Dec
				if (!([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) ) {
					NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
					[[self objectValue] putOnPasteboard:pboard includeDataForTypes:nil];
					[self dragImage:[dragImage imageWithAlphaComponent:0.5] at:NSZeroPoint offset:NSZeroSize event:theEvent pasteboard:pboard source:self slideBack:!([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask)];
				} else {
					NSPoint dragPosition;
					NSRect imageLocation;
					dragPosition = [self convertPoint:[theEvent locationInWindow] fromView:nil];
					dragPosition.x -= 16;
					dragPosition.y -= 16;
					imageLocation.origin = dragPosition;
					imageLocation.size = QSSize32;
					[self dragPromisedFilesOfTypes:[NSArray arrayWithObject:@"silver"] fromRect:imageLocation source:self slideBack:YES event:theEvent];
				}

			}
		break;
		case NSLeftMouseUp:
			[self mouseClicked:theEvent];
		break;
		default:
		break;
	}

	return;
}

- (void)mouseClicked:(NSEvent *)theEvent {}

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
	name = [name stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
	name = [name stringByReplacingOccurrencesOfString:@":" withString:@"_"];
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

- (NSDragOperation) draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	if (isLocal) return NSDragOperationMove;
	else return ([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) ? NSDragOperationNone : NSDragOperationEvery;
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	performingDrag = NO;
//	NSLog(@"ended at %f %f %d", aPoint.x, aPoint.y, operation);
	//	if (operation == NSDragOperationNone) NSShowAnimationEffect(NSAnimationEffectDisappearingItemDefault, aPoint, NSZeroSize, nil, nil, nil);
	//	if (operation == NSDragOperationMove) [self removeFromSuperview];
}

//Dragging

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>)sender {
	if (![self acceptsDrags] || performingDrag || ([self objectValue] && ![[self objectValue] respondsToSelector: @selector(actionForDragOperation:withObject:)]))
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

