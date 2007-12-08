#import "QSCollection.h"

#import "QSPreferenceKeys.h"
#import "QSOldSearchObjectView.h"
#import "QSLibrarian.h"
#import "QSResultController.h"
#import "QSInterfaceController.h"
#import "QSFSBrowserMediator.h"
#import "QSMnemonics.h"
#import "QSWindow.h"
#import "QSRegistry.h"
//#import "QSFinderProxy.h"

#import <QSFoundation/QSFoundation.h>
#import "QSCollection.h"
//#import "QSFSBrowserMediator.h"

#import "QSObject.h"
#import "QSObject_Drag.h"
#import "QSAction.h"
#import "QSObject_FileHandling.h"
#import "QSObject_StringHandling.h"

#import "QSSeparatorObject.h"


#import "QSObject_Pasteboard.h"
#import "NSString_Purification.h"
#import "QSObject_PropertyList.h"
#import "QSBackgroundView.h"
#import "QSController.h"

#include "QSGlobalSelectionProvider.h"


#import "QSTextProxy.h"
#define pUserKeyBindingsPath [@"~/Library/Application Support/Quicksilver/KeyBindings.qskeys" stringByStandardizingPath]
NSMutableDictionary *bindingsDict=nil;



@implementation QSSearchObjectView 


- (void)awakeFromNib{
	[super awakeFromNib];

	sController=[[QSIncrementalSearchController alloc]init];
	rController=[[NSArrayController alloc]init];
	[rController setAvoidsEmptySelection:YES];
	//[rController bind:@"contentArray" toObject:sController withKeyPath:@"resultArray" options:nil];
	//[self bind:@"objectValue" toObject:results withKeyPath:@"selectedObjects" options:nil];
	[sController addObserver:self
				  forKeyPath:@"resultArray"
					 options:0
					 context:nil];
	[rController addObserver:self
				  forKeyPath:@"selectedObjects"
					 options:0
					 context:nil];
	
	
	allowNonActions=YES;
	allowText=YES;
	resultController=nil;//[[QSResultController alloc]initWithFocus:self];
		
		searchMode=SearchFilterAll;
		moreComing=NO;
		[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(hideResultView:) name:@"NSWindowDidResignKeyNotification" object:[self window]];
		
		defaults=[[NSUserDefaults standardUserDefaults]retain];
		resultsPadding=0;
		history=[[NSMutableArray alloc]initWithCapacity:10];
		parentStack=[[NSMutableArray alloc]initWithCapacity:10];
		
		validSearch=YES;
	}

@end






@implementation QSOldSearchObjectView
+(void)initialize{
	bindingsDict=[[[NSMutableDictionary alloc]initWithContentsOfFile:
		[[NSBundle bundleForClass:[QSOldSearchObjectView class]]pathForResource:@"DefaultBindings" ofType:@"qskeys"]]objectForKey:@"QSOldSearchObjectView"];
	
	NSDictionary *mods=[[NSDictionary dictionaryWithContentsOfFile:pUserKeyBindingsPath]objectForKey:@"QSOldSearchObjectView"];
	[bindingsDict addEntriesFromDictionary:mods];
	
}
- (void)awakeFromNib{
	[super awakeFromNib];
	resultTimer=nil;
	preferredEdge=NSMaxXEdge;
	sController=[[QSIncrementalSearchController alloc]init];
	rController=[[NSArrayController alloc]init];
	[rController setAvoidsEmptySelection:YES];
	//[rController bind:@"contentArray" toObject:sController withKeyPath:@"resultArray" options:nil];
	//[self bind:@"objectValue" toObject:results withKeyPath:@"selectedObjects" options:nil];
	[sController addObserver:self
		   forKeyPath:@"resultArray"
			  options:0
			  context:nil];
	[rController addObserver:self
		   forKeyPath:@"selectedObjects"
			  options:0
			  context:nil];
	
	
	allowNonActions=YES;
	allowText=YES;
	resultController=nil;//[[QSResultController alloc]initWithFocus:self];
	
	searchMode=SearchFilterAll;
	moreComing=NO;
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(hideResultView:) name:@"NSWindowDidResignKeyNotification" object:[self window]];
	
	defaults=[[NSUserDefaults standardUserDefaults]retain];
	resultsPadding=0;
	history=[[NSMutableArray alloc]initWithCapacity:10];
	parentStack=[[NSMutableArray alloc]initWithCapacity:10];
	
	validSearch=YES;
	
	[resultController window];    
	[[resultController window] setFrameUsingName:@"results" force:YES];
	[self setVisibleString:@""];
	
	[[self cell] bind:@"highlightColor"
			 toObject:[NSUserDefaultsController sharedUserDefaultsController]
		  withKeyPath:@"values.QSAppearance2A"
			  options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName forKey:@"NSValueTransformerName"]];
	
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if ([object isEqual:sController]){
		
	}else{
		
	}
		
		NSLog(@"change %@ %@ %@",keyPath,object,[object valueForKeyPath:keyPath]);
}

- (void)dealloc {
	[history release];
	[future release];
	[parentStack release];
	[resultTimer release];
	[resultController release];
	[defaults release];
	[editor release];
	[scoreData release];
	
	history = nil;
	future = nil;
	parentStack = nil;
	resultTimer = nil;
	resultController = nil;
	defaults = nil;
	editor = nil;
	scoreData = nil;
	
	[super dealloc];
}

- (BOOL)acceptsFirstResponder{return YES;}



	/*
	 - (void)selectionChange:(NSNotification*)notif{
		 //NSLog(@"selection changed to %d",[resultTable selectedRow]);
		 
		 if (!browsing){
			 if (selectedResult==[resultTable selectedRow])return;
			 
			 selectedResult=[resultTable selectedRow];
			 
			 id selection=[resultArray objectAtIndex:selectedResult];
			 if (selection!=primaryResult){
				 [self setPrimaryResult:selection];
			 }
			 
			 [resultView setObjectValue:selection];
			 if (searchString)
				 [(QSObjectView *)focus setSearchString:searchString];
			 
			 [resultCountField setStringValue:[NSString stringWithFormat:@"%d of %d",selectedResult+1,[resultArray count]]];
			 if (!loadingIcons) [NSThread detachNewThreadSelector:@selector(loadIcons) toTarget:self withObject:nil];
			 else iconLoadInvalid=YES;
			 
		 }else{
			 QSObject *selection=[QSObject fileObjectWithPath:[resultBrowser path]];
			 [selection loadImage];
			 [self setPrimaryResult:selection];
			 [(QSObjectView *)focus setSearchString:nil];
			 
			 [resultView setObjectValue:selection];
		 }
}
*/


	//Events
- (void)keyDown:(NSEvent *)theEvent{
	[NSThread setThreadPriority:1.0];
	NSTimeInterval now=[NSDate timeIntervalSinceReferenceDate];
	NSTimeInterval delay=[theEvent timestamp]-lastTime;
	//if (VERBOSE) NSLog(@"KeyD: %@\r%@",[theEvent characters], theEvent);
	lastTime=[theEvent timestamp];
	lastProc=now;
	
	// ***warning   * should check for additional keydowns up to now so the search isn't done too often.
	float resetDelay=[defaults floatForKey:kResetDelay];
	if ((resetDelay && delay>resetDelay) ||  [sController shouldResetSearchString]){
		[sController reset];
	}//else if (now-lastProc > resetDelay){
	 //NSLog(@"event wast delayed");
	 //}
	 //if (fALPHA) moreComing=nil!=[NSApp nextEventMatchingMask:NSKeyDownMask untilDate:[NSDate date] inMode:NSDefaultRunLoopMode dequeue:NO];
	 //if (VERBOSE && moreComing)NSLog(@"moreComing");


	if ([[theEvent charactersIgnoringModifiers] isEqualToString:@"/"] && [self handleSlashEvent:theEvent])
	return;
	if (([[theEvent characters] isEqualToString:@"~"] || [[theEvent characters] isEqualToString:@"`"]) &&  [self handleTildeEvent:theEvent])
	return;
	if ([self handleBoundKey:theEvent])
	return;

	// ***warning   * have downshift move to indirect object

	if ([defaults boolForKey:@"Shift Actions"]
		&& [theEvent modifierFlags]&NSShiftKeyMask
		&& ([[theEvent characters] length] >= 1)
		&& [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[[theEvent characters] characterAtIndex:0]]
		&& self==[self directSelector]){
		[self handleShiftedKeyEvent:theEvent];
		return;
	}

	if ([theEvent isARepeat] && !([theEvent modifierFlags]&NSFunctionKeyMask))
	if ([self handleRepeaterEvent:theEvent])return;

	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}


-(BOOL) handleShiftedKeyEvent:(NSEvent *)theEvent{
	if([[resultController window] isVisible]){
		[self hideResultView:self];
		[sController setShouldResetSearchString:YES];
	}else {
		[resultTimer invalidate];
	}
	[[self window]makeFirstResponder:[self actionSelector]];
	// ***warning   * toggle first responder on key up
	
	[(QSInterfaceController *)[[self window]windowController]fireActionUpdateTimer];
	[[self actionSelector]keyDown:theEvent];
	return;
}
-(BOOL)handleSlashEvent:(NSEvent *)theEvent{
	if ([theEvent isARepeat]) return YES;
	
	if (!allowNonActions) return YES;
	NSEvent *upEvent=[NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];
	
	if ([[upEvent charactersIgnoringModifiers]isEqualToString:@"/"]){
		[self moveRight:self];
	}else{
		[self setObjectValue:[QSObject fileObjectWithPath:@"/"]];
		upEvent=[NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];
		if (fBETA && !upEvent)
			[self moveRight:self];
	}
	
	return YES;
}

- (BOOL)handleTildeEvent:(NSEvent *)theEvent{
	if ([theEvent isARepeat]) return;
	if (!allowNonActions) return;
	[self setObjectValue:[QSObject fileObjectWithPath:NSHomeDirectory()]];
	
	NSEvent *upEvent=[NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:0.25] inMode:NSDefaultRunLoopMode dequeue:YES];
	if (!upEvent)
		[self moveRight:self];
	return;
}


- (BOOL)handleRepeaterEvent:(NSEvent *)theEvent{
	
	//if (VERBOSE) NSLog(@"repeater");
	[resultTimer invalidate];
	
	NSDictionary *mnemonics=[[QSMnemonics sharedInstance]objectMnemonicsForID:[[self objectValue]identifier]];
	
#warning fix me
//	if (![mnemonics objectForKey:partialString]){
//		//NSLog(@"delaying before execution %@ %@",mnemonics,partialString);
//		
//		NSEvent *keyUp=[NSApp nextEventMatchingMask:NSKeyUpMask untilDate:[NSDate dateWithTimeIntervalSinceNow:2.0] inMode:NSDefaultRunLoopMode dequeue:YES];
//		if (keyUp){
//			[NSApp discardEventsMatchingMask:NSKeyDownMask beforeEvent:keyUp];
//			return;
//		}
//	}
	
	[[self window]makeFirstResponder:[self window]];
	
	
	if (1){
		[self insertNewline:self];   
		
		NSEvent *nextEvent;
		NSDate *absorbDate=[NSDate dateWithTimeIntervalSinceNow:0.5];
		
		
		while(nextEvent=[NSApp nextEventMatchingMask:NSKeyUpMask untilDate:absorbDate inMode:NSDefaultRunLoopMode dequeue:NO]){
			
			if (VERBOSE)    NSLog(@"discarding events till  %@",nextEvent); 
			[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:nextEvent];
			
		}
		return;
	}else{
		while(1){
			NSEvent *nextEvent=[NSApp nextEventMatchingMask:NSKeyUpMask|NSKeyDownMask untilDate:[NSDate distantFuture] inMode:NSDefaultRunLoopMode dequeue:YES];
			if ([nextEvent isARepeat] && [[nextEvent charactersIgnoringModifiers]isEqualToString:[theEvent charactersIgnoringModifiers]]) continue;
			
			if ([nextEvent type]==NSKeyUp && [[nextEvent charactersIgnoringModifiers]isEqualToString:[theEvent charactersIgnoringModifiers]]){
				////NSLog(@"exec");
				[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:nextEvent];
				[self insertNewline:self];
				return;
			}else if ([nextEvent keyCode]==53){ //Escape key
												//if (VERBOSE) NSLog(@"Escape chord");
				[[self window]makeFirstResponder:self];
				break;
			}else if ([nextEvent type]==NSKeyDown){
				// NSLog(@"otherchar %@",[theEvent charactersIgnoringModifiers]);
				
				[[self window]makeFirstResponder:[self actionSelector]];
				// ***warning   * toggle first responder on key up
				[[self actionSelector]keyDown:nextEvent];
				
				[NSApp discardEventsMatchingMask:NSAnyEventMask beforeEvent:nextEvent];
				[[self window]makeFirstResponder:[self actionSelector]];
				return;
				//[self insertNewline:self];
				// return;
			}else{
				//NSLog(@"event %@",nextEvent);   
			}
			
			
		}
	}
	return;
}
- (void)drawRect:(NSRect)rect {
	if ([self currentEditor]){
		//NSLog(@"editor draw");
		[super drawRect:rect];
		rect=[self frame];
		
		if(NSWidth(rect)>128 && NSHeight(rect)>128){
			CGContextRef context = (CGContextRef)([[NSGraphicsContext currentContext] graphicsPort]);
			CGContextSetAlpha(context, 0.92);
		}
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.92]set];
		NSBezierPath *roundRect=[NSBezierPath bezierPath];
		rect=[self frame];
		rect.origin=NSZeroPoint;
		[roundRect appendBezierPathWithRoundedRectangle:NSInsetRect(rect,3,3) withRadius:NSHeight(rect)/16];
		[roundRect fill];  
		
		[[NSColor alternateSelectedControlColor]set];
		[roundRect stroke];
		
		
		
		
		
		//[super drawRect:rect];
	}else{
		[super drawRect:rect];
	}
}


- (BOOL)shortCircuit:(id)sender{
	[(QSInterfaceController *)[[self window]windowController]shortCircuit:self];
	[resultTimer invalidate];
	
	return YES;
}


- (void)insertSpace:(id)sender{
	int behavior=[defaults integerForKey:@"QSSearchSpaceBarBehavior"];
	
	switch(behavior){
		case 1: //Normal
			[self insertText:@" "];
			break;
		case 2: //Select next result
			if ([[NSApp currentEvent] modifierFlags]&NSShiftKeyMask)
				[self moveUp:sender];
			else
				[self moveDown:sender];
			break;
		case 3: //Jump to Indirect
			[self shortCircuit:sender];
			break;
		case 4: //Switch to text
			[self transmogrify:sender];
			break;
	}
}



- (BOOL)becomeFirstResponder{
	if ([[[self objectValue]primaryType]isEqual:QSTextProxyType]){
		NSString *defaultValue=[[self objectValue]objectForType:QSTextProxyType];
		[self transmogrify:self];
		//   NSLog(@"%@",[[self objectValue]dataDictionary]);
		if (defaultValue){
			
			[self setObjectValue:[QSObject objectWithString:defaultValue]];
			[[self currentEditor]setString:defaultValue];
			[[self currentEditor]selectAll:self];
		}
	}
	
	return  [super becomeFirstResponder];
}



- (void)setFrame:(NSRect)frameRect{
	[super setFrame:frameRect];
	if ([self currentEditor]){
		NSRect editorFrame=[self frame];
		
		editorFrame.origin=NSZeroPoint;
		editorFrame=NSInsetRect(editorFrame,3,3);
		[[[self currentEditor]enclosingScrollView] setFrame: editorFrame];
		[[self currentEditor] setMinSize:editorFrame.size];
	}
}


- (void)deleteBackward:(id)sender{
	[self clearSearch];
}

-(void)clearSearch{
	[sController clearSearch];
	[self setVisibleString:@""];
	[self setMatchedString:nil];
}

- (void)setVisibleString:(NSString *)string{
	[resultController->searchStringField setStringValue:string];
	if ([[self controller]respondsToSelector:@selector(searchView:changedString:)])
		[(id)[self controller]searchView:self changedString:string];
}

- (void)scrollWheel:(NSEvent *)theEvent{
	// ***warning   * this still goes to the wrong view if over another search view
	if (![[resultController window] isVisible]){
		[self showResultView:self];
		
	}
	
	
	
	if(NSMouseInRect([NSEvent mouseLocation],NSInsetRect([[resultController window] frame],0,0),NO)){ 
		[resultController scrollWheel:theEvent];
		return;
	}
	float delta=[theEvent deltaY];
	
	// This is really really awful.
    UnsignedWide currentTime;  	
    double currentTimeDouble = 0;
    Microseconds(&currentTime);
    currentTimeDouble = (((double) currentTime.hi) * 4294967296.0) + currentTime.lo;
	
	//If the scroll event is really delayed (Nonactivating panels cause this) then ignore
	if (currentTimeDouble/1000000-[theEvent timestamp]>0.25) return;
	
	
	while (theEvent = [NSApp nextEventMatchingMask: NSScrollWheelMask untilDate:[NSDate date] inMode:NSDefaultRunLoopMode dequeue:YES]){
		delta+=[theEvent deltaY];
	}
	
	[self moveSelectionBy:-(int)delta];
	
	// [resultController->resultTable scrollWheel:theEvent];
}

- (void)moveWordRight:(id)sender{
	[self browse:1];
	
}
- (void)moveWordLeft:(id)sender{
	[self browse:-1];
	
}
- (void)moveRight:(id)sender{
	[self browse:1];
	
}
-(void)moveLeft:(id)sender{
	[self browse:-1];
}

-(void)selectHome:(id)sender{
	NSLog(@"act%d",allowNonActions);
	//	if (allowNonActions)
	//		[self setObjectValue:[QSObject fileObjectWithPath:NSHomeDirectory()]];
}
-(void)selectRoot:(id)sender{
	if (allowNonActions)
		[self setObjectValue:[QSObject fileObjectWithPath:@"/"]];
}

- (void)browse:(int)direction{
	
	NSArray *newObjects=nil;
	QSBasicObject * newSelectedObject=[super objectValue];
	QSBasicObject * parent=nil;
	NSArray *siblings;
	//if (self==[self actionSelector]){
	//}
	
	BOOL alt=([[NSApp currentEvent]modifierFlags] & NSAlternateKeyMask) > 0;

	//   NSLog(@"child %d %d",[[NSApp currentEvent]modifierFlags] & NSAlternateKeyMask,[[NSApp currentEvent] modifierFlags]);
	if (direction>0){ //Should show childrenLevel
		newObjects=(alt?[newSelectedObject altChildren]:[newSelectedObject children]);
		if ([newObjects count]){[parentStack addObject:newSelectedObject];
			// if (VERBOSE) NSLog(@"addobject %@ %@",newSelectedObject,newObjects);
		}
		newSelectedObject=nil;
	}else{
		parent=[newSelectedObject parent];
		
		
		if (parent && [[NSApp currentEvent]modifierFlags] & NSControlKeyMask){
			[parentStack removeAllObjects];
		}else if ([parentStack count]){
			browsing=YES;
			
			parent=[parentStack lastObject]; 
			// ***warning   * this should check for a valid parent
			[[parent retain]autorelease];
			[parentStack removeLastObject];
			
			if (VERBOSE) NSLog(@"Using parent from stack: %@ (%@)",parent, [parentStack componentsJoinedByString:@", "]);
			//    if (
			//      && ![[parent children]containsObject:newSelectedObject])
		}
		
		//[[parent children]containsObject:newSelectedObject]
		
		if (!browsing &&[self searchMode]==SearchFilterAll&&[[resultController window] isVisible]){
			//Maintain selection, but show siblings 
			siblings=(alt?[parent altChildren]:[parent children]);
			newObjects=siblings;
			
		}else{
			//Should show parent's level
			
			newSelectedObject=parent;
			if (newSelectedObject){
				
				newObjects=(alt?[newSelectedObject altSiblings]:[newSelectedObject siblings]);
				if (![newObjects containsObject:newSelectedObject])
					newObjects=[newSelectedObject altSiblings];
				
				if (!newObjects && [parentStack count]){
					parent=[parentStack lastObject];
					newObjects=[parent children];
				}
				if (!newObjects){
					newObjects=history;
				}
			}
		}
		
}


if ([newObjects count]){
	browsing=YES;
	
	[self updateHistory];
	[self saveMnemonic];
	[self clearSearch]; 
	int defaultMode=[defaults integerForKey:kBrowseMode];
	[self setSearchMode:defaultMode?defaultMode:SearchSnap];
	[self setResultArray:(NSMutableArray *)newObjects]; // !!!:nicholas:20040319 
	[self setSearchArray:newObjects];
	
	if (!newSelectedObject)
		[self selectIndex:0];
	else
		[self selectObject:newSelectedObject];
	
	
	[self setVisibleString:@"Browsing"];
	
	[self showResultView:self]; 
}else if(![[NSApp currentEvent] isARepeat]){
	
	[self showResultView:self]; 
	if ([[resultController window] isVisible])
		[resultController bump:(direction*4)];
	else
		NSBeep();
}


}

- (void)doCommandBySelector:(SEL)aSelector{
	if (VERBOSE &&![self respondsToSelector:aSelector])
		NSLog(@"Unhandled Command: %@",NSStringFromSelector(aSelector));
	[super doCommandBySelector:aSelector];
}



- (void)pageUp:(id)sender{[self pageScroll:-1];}
- (void)pageDown:(id)sender{[self pageScroll:1];}
- (void)scrollPageUp:(id)sender{[self pageScroll:-1];}
- (void)scrollPageDown:(id)sender{[self pageScroll:1];}

- (void)pageScroll:(int)direction{
	if (![[resultController window] isVisible]) [self showResultView:self];
	
	int movement=direction * (NSHeight([[resultController->resultTable enclosingScrollView]frame])/[resultController->resultTable rowHeight]);
	//NSLog(@"%d",movement);
	[self moveSelectionBy:movement];
}

- (void)goForward:(id)sender{
	//NSLog(@"goforward@",sender);
	if ([self resultArray]==history){
		[self moveUp:sender];   
	}
}
- (void)goBackward:(id)sender{
	
	//NSLog(@"gobackward@",sender);
	if ([self resultArray]!=history){
		
		[self setVisibleString:@"History"];
		[self setMatchedString:nil];
		[self updateHistory];
		[self setResultArray:history];
		[self moveDown:sender]; 
	}
	else{
		[self moveDown:sender];   
	}
}

- (void)moveDown:(id)sender{
	if (![[resultController window] isVisible]) [self showResultView:self];
	[self moveSelectionBy:1];
}

- (void)moveUp:(id)sender{
	if (![[resultController window] isVisible]) [self showResultView:self];
	[self moveSelectionBy:-1];
}
- (void)moveSelectionBy:(int)d{
	// NSLog(@"newselect %d",selection+d);    
	[self selectIndex:selection+d];
}
//- (BOOL)respondsToSelector:(SEL)aSelector{
//NSLog(NSStringFromSelector(aSelector));
//	return[super respondsToSelector:aSelector];
//}

- (void)complete:(id)sender{
	[self cancelOperation:sender];
}
- (void)performClose:(id)sender{
	[self cancelOperation:sender];
}

- (void)reset:(id)sender{
	if([[resultController window] isVisible]){
		[self hideResultView:self];
	}     
	if (browsing){
		browsing=NO;
		[self setSearchMode:SearchFilterAll];
	}

#warning collecting=no
	[sController setShouldResetSearchString:YES];
	[resultTimer invalidate];
}

- (void)cancelOperation:(id)sender{
	if ([self currentEditor]){
		[[self window] makeFirstResponder:self];
		return;
	}else if([[resultController window] isVisible]){
		[self hideResultView:self];
		[sController setShouldResetSearchString:YES];
	}else {
		[resultTimer invalidate];
		[[[self window]windowController] hideMainWindowFromCancel:self];
	}
	return;    
}
- (void)selectAll:(id)sender{
	[self setObjectValue:[QSObject objectByMergingObjects:[sController arrangedObjects]]] ;
	
}


- (void)insertTab:(id)sender{
	[resultTimer invalidate];
	[[self window] selectNextKeyView:self];
}
- (void)insertBacktab:(id)sender{
	[resultTimer invalidate];
	[[self window] selectPreviousKeyView:self];
}
- (void)insertNewlineIgnoringFieldEditor:(id)sender{
	[self insertNewline:sender];   
}

- (void)insertNewline:(id)sender{
	[resultTimer invalidate];
	if ([sController searchPending]){
		[sController runSearchNow];
		[self display];
	}
#warning [resetTimer fire];
	[(QSInterfaceController *)[[self window] windowController] executeCommand:self];	
}

- (void)mouseDown:(NSEvent *)theEvent{
	//NSPoint p = [self convertPoint: [theEvent locationInWindow] fromView: nil];
	/*	
	if (editor != nil) {
		[self setNeedsDisplayInRect: [self frame]];
		[[self window] makeFirstResponder: nil];
		[editor removeFromSuperview];
		editor = nil;
	}
	 */
	if ([theEvent clickCount] > 1) {
		[(QSInterfaceController *)[[self window] windowController] executeCommand:self];
	}
	else{
		[super mouseDown:theEvent];      
	}
}

- (BOOL)handleBoundKey:(NSEvent *)theEvent{
	NSString *selectorString=[bindingsDict objectForKey:[self stringForEvent:theEvent]];
	if (selectorString){
		SEL selector=NSSelectorFromString(selectorString);
		//[self doCommandBySelector:selector];
		[self performSelector:selector withObject:theEvent];
		return YES;
	}
	return NO;
}


- (BOOL)performKeyEquivalent:(NSEvent *)theEvent{	
	
	if ([[theEvent charactersIgnoringModifiers]isEqualToString:@"\r"]){
		[self insertNewline:nil];
		return YES;
	}
	BOOL higher=[[[self window]delegate]performKeyEquivalent:(NSEvent *)theEvent];	
	if ([[self window]firstResponder]==self && !higher){
		if ([self handleBoundKey:theEvent])return YES;
	}
	return higher;
}

- (NSString *)stringForEvent:(NSEvent *)theEvent{
	int flags=[theEvent modifierFlags];
	NSString *string=[NSString stringWithFormat:@"%@%@%@%@%@%@",
					  flags&NSShiftKeyMask?@"$":@"",
					flags&NSControlKeyMask?@"^":@"",
				  flags&NSAlternateKeyMask?@"~":@"",
					flags&NSCommandKeyMask?@"@":@"",
				   flags&NSFunctionKeyMask?@"#":@"",
		[theEvent charactersIgnoringModifiers]];
	return string;
	//	return [[[self window]delegate]performKeyEquivalent:(NSEvent *)theEvent];
}


- (BOOL)executeText:(NSEvent *)theEvent{
	
	[self clearSearch];
	[self insertText:[theEvent charactersIgnoringModifiers]];
	[self insertNewline:self];
	return YES;
}

- (IBAction)logObjectDictionary:(id)sender{
	
	NSLog(@"Printing Object\r%@",[[self objectValue]name]);
	NSLog(@"Dictionary\r%@",[[self objectValue]archiveDictionary]);
	NSLog(@"Icon\r%@",[[self objectValue]icon]);
	
}

- (IBAction)sortByScore:(id)sender{
	[(NSMutableArray *)[self resultArray]sortUsingSelector:@selector(scoreCompare:)];
	[self reloadResultTable];
	
}
- (IBAction)sortByName:(id)sender{
	[(NSMutableArray *)[self resultArray] sortUsingSelector:@selector(nameCompare:)];
	[self reloadResultTable];
	
}





- (IBAction) toggleResultView:sender{
	if([[resultController window] isVisible])
		[self hideResultView:sender];
	else
		[self showResultView:sender];
}


- (IBAction) showResultView:sender{
	if ([[self window]firstResponder]!=self)[[self window]makeFirstResponder:self];
	if ([[resultController window] isVisible]) return; //[resultController->resultTable reloadData];
	
	[[resultController window]setLevel:[[self window]level]+1];
	[[resultController window] setFrameUsingName:@"results" force:YES];
	//   if (fALPHA) [resultController setSplitLocation];
	
	NSRect windowRect=[[resultController window]frame];
	NSRect screenRect=[[[resultController window]screen]frame];
	if (preferredEdge==NSMaxXEdge){
		
		NSPoint resultPoint=[self convertPoint:NSZeroPoint toView:nil];
		
		resultPoint=[[self window] convertBaseToScreen:resultPoint];
		
		if (resultPoint.x+NSWidth([self frame])+NSWidth(windowRect)<NSMaxX(screenRect)){
			if (hFlip){
				[[[resultController window]contentView] flipSubviewsOnAxis:NO];
				hFlip=NO;
			}
			
			resultPoint.x+=NSWidth([self frame]);
			resultPoint.y+=NSHeight([self frame])+1;
		}else{
			if (!hFlip){
				[[[resultController window]contentView] flipSubviewsOnAxis:NO];
				hFlip=YES;
			}
			resultPoint.x-=NSWidth(windowRect);
			resultPoint.y+=NSHeight([self frame])+1;
		}
		
		[[resultController window] setFrameTopLeftPoint:resultPoint];
		
	}else{
		NSPoint resultPoint=[[self window] convertBaseToScreen:[self frame].origin];
		//resultPoint.x;
		float extraHeight=windowRect.size.height-(resultPoint.y-screenRect.origin.y);
		
		//resultPoint.y+=2;
		windowRect.origin.x=resultPoint.x;
		if (extraHeight>0){
			windowRect.origin.y=screenRect.origin.y;
			windowRect.size.height-=extraHeight;
		}else{
			//		NSLog(@"pad %f",resultsPadding);
			windowRect.origin.y=resultPoint.y-windowRect.size.height-resultsPadding;
		}
		
		windowRect=NSIntersectionRect(windowRect,screenRect);
		[[resultController window] setFrame:windowRect display:NO];
	}
	
	
	
	
	[self updateResultView:sender];
	
	if ([[self controller]respondsToSelector:@selector(searchView:resultsVisible:)])
		[(id)[self controller]searchView:self resultsVisible:YES];
	
	if ([[self window]isVisible]){
		
		[[resultController window] orderFront:nil];
		[[self window] addChildWindow:[resultController window] ordered:NSWindowAbove];
	}
	
}




- (IBAction) updateResultView:sender{
	//[resultController->searchModePopUp selectItemAtIndex:[resultController->searchModePopUp indexOfItemWithTag:searchMode]];
	[self reloadResultTable];
	[resultController->resultTable selectRow:selection byExtendingSelection:NO];
	[resultController updateSelectionInfo];  
}



- (void)clearObjectValue{
	[self updateHistory];
	[super setObjectValue:nil];
	selection--;
	//	[[NSNotificationCenter defaultCenter] postNotificationNamse:@"SearchObjectChanged" object:self];
}

- (void)selectObjectValue:( QSObject *)newObject {
	if ( newObject!=[self objectValue]){
		
		// if (newObject)NSLog(@"%p set value %@",self,newObject);
		// [newObject loadIcon];
		[super setObjectValue:newObject];
#warning if (!collecting) [self emptyCollection:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchObjectChanged" object:self];
	}
}

- (void)updateHistory{
	// [NSDictionary dictionaryWithObjectsAndKeys:[self objectValue],@"object",nil];
	//  
	
	QSObject *currentValue=[self objectValue];
	if (!currentValue)return;
	
	[history removeObject:currentValue];
	[history insertObject:currentValue atIndex:0];
	if ([history count]>20) [history removeLastObject];
	// NSLog(@"history %@",history);
}

- (void)setObjectValue:(QSBasicObject *)newObject {
	
	[self hideResultView:self];
	
	[self clearSearch];
	[parentStack removeAllObjects];
	[self setResultArray:[NSArray arrayWithObjects:newObject,nil]];    
	[super setObjectValue:newObject];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SearchObjectChanged" object:self];
}

- (BOOL)resignFirstResponder{
	//NSLog(@"resign first");
	if ([self currentEditor]){
		
		// NSLog(@"resign first with monkey %@",self);
		// [[self currentEditor] endEditing];
	}
	[resultTimer invalidate];
	[self hideResultView:self];
	[sController setShouldResetSearchString:YES];
//[sController resetString];
	[self setNeedsDisplay:YES];
	return YES;
}
- (IBAction) hideResultView:sender{
	[[self window] removeChildWindow:[resultController window]];
	[resultController setResultIconLoader:nil];
	[[resultController window] orderOut:self];
	if (browsing){
		browsing=NO;
		[self setSearchMode:SearchFilterAll];
	}
	if ([[self controller]respondsToSelector:@selector(searchView:resultsVisible:)])
		[(id)[self controller]searchView:self resultsVisible:NO];
}






- (BOOL)validateMenuItem:(NSMenuItem*)anItem {
	
	if ([anItem action]==@selector(newFile:)){
		return fDEV;
	}
	if ([anItem action]==@selector(goForward:)){
		return [self resultArray]==history;
	}
	if ([anItem action]==@selector(goBackward:)){
		return YES;
	}
	if ([anItem action]==@selector(defineMnemonic:)){
		if (![self matchedString]) return NO;
		[anItem setTitle:[NSString stringWithFormat:@"Set as Default for \"%@\"",[[self matchedString]uppercaseString]]];
		return YES;
	}
	if ([anItem action]==@selector(removeMnemonic:)){
		if (![self matchedString]) return NO;
		[anItem setTitle:[NSString stringWithFormat:@"Remove as Default for \"%@\"",[[self matchedString]uppercaseString]]];
		return YES;
	}
	return YES;
}



- (void)rowClicked:(int)index{
	
}

//- (void)selectIndex:(int)index{
//	// NSLog(@"selectindex %d %d",self,index);
//	
//	if (index<0)
//		selection=0;
//	else if (index>=[resultArray count])
//		selection=[resultArray count]-1;
//	else
//		selection=index;
//	
//	if ([resultArray count]){
//		QSObject *object=[resultArray objectAtIndex:selection];
//		
//		[self selectObjectValue:object];
//		[resultController->resultTable scrollRowToVisible:selection];
//		//[resultController->resultTable centerRowInView:selection];
//		[resultController->resultTable selectRow:selection byExtendingSelection:NO];
//	}
//	else
//		[self selectObjectValue:nil];
//	
//	if ([[resultController window]isVisible])
//		[resultController updateSelectionInfo];    
//}

- (void)selectObject:(QSBasicObject *)obj{	
	if (obj)
		[results setSelectedObjects:[NSArray arrayWithObject:obj]];
//	int index=0;
//	//[self updateHistory];
//	if (obj){
//		index=[resultArray indexOfObject:obj];
//		//NSLog(@"index %d",index);
//		if (index==NSNotFound){
//			if (VERBOSE)NSLog(@"Unable To Select Object : %@ in \r %@",[obj identifier],resultArray);
//			
//			index=nil;
//			return;
//		}
//	}else{
//		[self selectObjectValue:nil];
//		return;
//	}
//	[self selectIndex:index];
}

#warning implement me
//- (void)setResultArray:(NSMutableArray *)newResultArray {
//	[resultArray release];
//	resultArray = [newResultArray retain];
//	
//	if ([[resultController window] isVisible])
//		[self reloadResultTable];
//	
//	if ([[self controller]respondsToSelector:@selector(searchView:changedResults:)])
//		[(id)[self controller]searchView:self changedResults:newResultArray];
//	
//}

- (void)reloadResultTable{
	//[resultController->resultTable reloadData];
	[resultController arrayChanged:nil];
}



- (QSOldSearchObjectView *)directSelector{
	return [[[self window]windowController]dSelector];
}
- (QSOldSearchObjectView *)actionSelector{
	//NSLog(@"action");
	return [[[self window]windowController]aSelector];
}
- (QSOldSearchObjectView *)indirectSelector{
	return [[[self window]windowController]iSelector];
}

- (void)setSearchMode:(QSSearchMode)newSearchMode {
	[sController setSearchMode:newSearchMode];
	[resultController->resultTable setNeedsDisplay:YES];
		if (browsing)
			[defaults setInteger:newSearchMode forKey:kBrowseMode];
}
- (void)setResultArray:(NSArray *)newResultArray {
	[sController setResultArray:nil];
}

- (void)setSearchArray:(NSArray *)newSearchArray {
	[sController setSearchArray:nil];
}

- (void)setMatchedString:(NSString *)newResultsMatchedString {
	[sController setResultsMatchedString:newResultsMatchedString];
}

- (void)insertText:(id)aString{
	[sController insertText:aString];
#warning	if (![partialString length])[self updateHistory];
}


- (NSAttributedString *)attributedSubstringFromRange:(NSRange)theRange{
	NSLog(@"attributedSubstringFromRange");
	return [[NSAttributedString alloc]initWithString:[partialString substringWithRange:theRange]];
}
- (unsigned int)characterIndexForPoint:(NSPoint)thePoint{
	NSLog(@"index");
	return 0;
}
- (long)conversationIdentifier{
	//		NSLog(@"conv");
	return (long)self;
}
//- (void)doCommandBySelector:(SEL)aSelector{
//}
- (NSRect)firstRectForCharacterRange:(NSRange)theRange{
	//		NSLog(@"rect");
	return NSZeroRect;
}
- (BOOL)hasMarkedText{
	//			NSLog(@"marked?");
	return NO;
}
//- (void)insertText:(id)aString{
//}
- (NSRange)markedRange{
	//		NSLog(@"rang");
	return NSMakeRange([partialString length]-1,1);
}
- (NSRange)selectedRange{
	//		NSLog(@"selectr");
	return NSMakeRange(NSNotFound,0);
}
- (void)setMarkedText:(id)aString selectedRange:(NSRange)selRange{
	if ([(NSString *)aString length]){
		NSLog(@"setmark %@ %d,%d", [aString string],selRange.location,selRange.length);
		aString=[[[aString string] purifiedString]lowercaseString];
		[partialString setString:aString];
		[self partialStringChanged];
	}
}
- (void)unmarkText{
	//	NSLog(@"Unmark");
}
- (NSArray *)validAttributesForMarkedText{
	return [NSArray array];
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview{
	if (!newSuperview){
		[self reset:self];
	}
}

@end


@implementation QSOldSearchObjectView (Transmogrification)

- (IBAction) conditionalTransmogrify:(id)sender{
	if (![partialString length]) [self transmogrify:sender]; 
}


- (IBAction) calculate:(id)sender{
	[self transmogrify:self];
	[[self currentEditor]setString:@"="];
}



-(void)transmogrifyWithText:(NSString *)string{
	if (![self allowText])return;
	if ([self currentEditor]){
		[[self window] makeFirstResponder: self];
	}else{
		//NSLog(@"%p trans",sender);
		//  [self setObjectValue:[QSObject objectWithString:@""]];
		editor = [[self window] fieldEditor: YES forObject: self];
		// NSLog(@"%@ %@",editor,[editor superview]);
		
		if(string){
			[editor setString:string];
			[editor setSelectedRange:NSMakeRange([[editor string]length],0)];
#warning fix me
		}else if([partialString length]){// &&  ([resetTimer isValid] || ![defaults floatForKey:kResetDelay])){
			[editor setString:[partialString stringByAppendingString:[[NSApp currentEvent]charactersIgnoringModifiers]]];
			[editor setSelectedRange:NSMakeRange([[editor string]length],0)];
		}else{
			NSString *stringValue=[[self objectValue]  stringValue];
			if (stringValue)[editor setString:stringValue];
			[editor setSelectedRange:NSMakeRange(0,[[editor string]length])];
		}
		
		
		NSRect titleFrame=[self frame];
		NSRect editorFrame=NSInsetRect(titleFrame,NSHeight(titleFrame)/16,NSHeight(titleFrame)/16);
		editorFrame.origin=NSMakePoint(NSHeight(titleFrame)/16,NSHeight(titleFrame)/16);
		
		//logRect(editorFrame);
		
		
		//  [editor setTarget: self];
		// [editor setMaxSize: NSMakeSize(256,256)];
		[editor setHorizontallyResizable: YES];
		[editor setVerticallyResizable: YES];
		[editor setDrawsBackground: NO];
		[editor setDelegate: self];
		//[editor setFrame:NSZeroRect];
		[editor setMinSize: editorFrame.size];
		[editor setFont:[NSFont systemFontOfSize:12.0]];
		[editor setTextColor:[NSColor blackColor]];
		[editor setContinuousSpellCheckingEnabled:YES];
        [editor setEditable:YES];
        [editor setSelectable:YES];
		[editor setTextContainerInset:NSZeroSize];
		
		
		NSScrollView *scrollView=[[[NSScrollView alloc]initWithFrame:editorFrame]autorelease];
		[scrollView setBorderType:NSNoBorder];
        [scrollView setHasVerticalScroller:NO];
		// [scrollView setHasHorizontalScroller:YES];
		[scrollView setAutohidesScrollers:YES];
		[scrollView setDrawsBackground:NO];
		
       	
		NSSize contentSize = [scrollView contentSize];
        [editor setMinSize:NSMakeSize(0, contentSize.height)];
        [editor setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
		
        [editor setVerticallyResizable:YES];
        [editor setHorizontallyResizable:YES];
        
		//[[editor textContainer] setContainerSize:NSMakeSize(contentSize.width, FLT_MAX)];
		//     [[editor textContainer] setWidthTracksTextView:YES];
		//	[[editor textContainer] setHeightTracksTextView:YES];
		
		[editor setFieldEditor: YES];
		[scrollView setDocumentView:editor];
		//[scrollView addSubview:editor];
		[self addSubview: scrollView];
		
		//NSLog(@"iseditor %d",[editor isFieldEditor]);
		[[self window] makeFirstResponder: editor];
		[self setCurrentEditor:editor]; 
		
		
	}
} 
- (IBAction) transmogrify:(id)sender{
	[self transmogrifyWithText:nil];
}


- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector{
	//   NSLog(@"%@",NSStringFromSelector(commandSelector));
	if (commandSelector == @selector(insertTab:)) {
		[[self window] selectKeyViewFollowingView:self];
		return YES;
	}
	if (commandSelector == @selector(insertBacktab:)) {
		[[self window] selectKeyViewPrecedingView:self];
		return YES;
	}
	if (commandSelector == @selector(insertNewline:)) {
		
		[[self window] selectKeyViewFollowingView:self];
		[[[self window]windowController]executeCommand:self];
		return YES;
	}
	if (commandSelector == @selector(complete:)) {
		[[self window] makeFirstResponder:self];
		return YES;
	}
	return NO;
}
- (void)textDidChange:(NSNotification *)aNotification{
	NSString *string=[[[[aNotification object] string]copy]autorelease];
	if ([[[aNotification object] string]isEqualToString:@" "]){
		[(QSInterfaceController *)[[self window]windowController]shortCircuit:self];
		return;
	}
	[self setObjectValue:[QSObject objectWithString:string]];
	[self setMatchedString:nil];
}

- (void)textDidEndEditing:(NSNotification *)aNotification{
	NSString *string=[[[[aNotification object] string]copy]autorelease];
	[self setObjectValue:[QSObject objectWithString:string]];
	[self setMatchedString:nil];
	//[[self window] makeFirstResponder: self];
	[self setCurrentEditor:nil]; 
	[[editor enclosingScrollView] removeFromSuperview];
}


@end
@implementation QSOldSearchObjectView (OpenAndSave)
- (IBAction)newFile:(id)sender{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSView *content=[savePanel contentView];
	// NSLog(@"sub %@",[content subviews]);
	if  (![content isKindOfClass:[QSBackgroundView class]]){
		NSView *newBackground=[[[QSBackgroundView alloc]init]autorelease];
		[savePanel setContentView:newBackground];
		[newBackground addSubview:content];
	}
	
	[savePanel setNameFieldLabel:@"Create Item:"];
	[savePanel setCanCreateDirectories:YES];
	NSString *oldFile=[[self objectValue]singleFilePath];
	
	//if (![openPanel runModalForDirectory:oldFile file:nil types:nil])return;
	//  beginSheetForDirectory:file:types:modalForWindow:modalDelegate:didEndSelector:contextInfo:
	
	[savePanel beginSheetForDirectory:oldFile
								 file:nil
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:sender];
}
- (void)savePanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	[self setObjectValue:[QSObject fileObjectWithPath:[sheet filename]]];
}

- (IBAction)openFile:(id)sender{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	NSView *content=[openPanel contentView];
	// NSLog(@"sub %@",[content subviews]);
	if  (![content isKindOfClass:[QSBackgroundView class]]){
		NSView *newBackground=[[[QSBackgroundView alloc]init]autorelease];
		[openPanel setContentView:newBackground];
		[newBackground addSubview:content];
	}
	NSString *oldFile=[[self objectValue]singleFilePath];
	
	//if (![openPanel runModalForDirectory:oldFile file:nil types:nil])return;
	//  beginSheetForDirectory:file:types:modalForWindow:modalDelegate:didEndSelector:contextInfo:
	
	
	[openPanel beginSheetForDirectory:oldFile
								 file:nil
								types:nil
					   modalForWindow:[self window]
						modalDelegate:self
					   didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:sender];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
	[self setObjectValue:[QSObject fileObjectWithPath:[sheet filename]]];
}
@end
@implementation QSOldSearchObjectView (Mnemonics)

- (IBAction)assignMnemonic:(id)sender{
}

- (IBAction)defineMnemonic:(id)sender{
	if ([self matchedString])
		[[QSMnemonics sharedInstance] addAbbrevMnemonic:[self matchedString] forID:[[self objectValue]identifier]];
	[self rescoreSelectedItem];
}
- (IBAction)removeImpliedMnemonic:(id)sender{
	if ([self matchedString])
		[[QSMnemonics sharedInstance] removeObjectMnemonic:[self matchedString] forID:[[self objectValue]identifier]];
	[self rescoreSelectedItem];
}

- (IBAction)removeMnemonic:(id)sender{
	if ([self matchedString]){
		[[QSMnemonics sharedInstance] removeAbbrevMnemonic:[self matchedString] forID:[[self objectValue]identifier]];
		[self rescoreSelectedItem];
	}
}

- (void)rescoreSelectedItem{
	if (![self objectValue])return;
	//[QSLib scoredArrayForString:[self matchedString] inSet:[NSArray arrayWithObject:[self objectValue]] mnemonicsOnly:![self matchedString]];
	[QSLib scoredArrayForString:[self matchedString] inSet:[NSArray arrayWithObject:[self objectValue]]];
	if ([[resultController window] isVisible])
		[resultController->resultTable reloadData];
}
- (BOOL)mnemonicDefined{
	return [[[QSMnemonics sharedInstance] abbrevMnemonicsForString:[self matchedString]]
indexOfObject:[[self objectValue]identifier]]!=NSNotFound;
}
- (BOOL)impliedMnemonicDefined{
	return nil!=[[[QSMnemonics sharedInstance] objectMnemonicsForID:[[self objectValue]identifier]]objectForKey:[self matchedString]];
}

- (void)saveMnemonic{
	NSString *mnemonicKey=[self matchedString];
	//	if (VERBOSE) NSLog(@"Added Mnemonic: %@", [self matchedString]);
	[[QSMnemonics sharedInstance] addObjectMnemonic:mnemonicKey forID:[[self objectValue]identifier]];
	[[QSMnemonics sharedInstance] addAbbrevMnemonic:mnemonicKey forID:[[self objectValue]identifier] relativeToID:nil];
	
	
	[[self objectValue]updateMnemonics];
	[self rescoreSelectedItem];
	//   NSLog(@"mnem: %@",[self searchString]);
}

@end




@implementation QSOldSearchObjectView (GrabAndDrag)

- (IBAction) getFinderSelection:sender{
	if (!allowNonActions) return;
	QSObject *entry=[QSObject fileObjectWithArray:[[QSReg getMediator:kQSFSBrowserMediators] selection]];
	// [entry loadIcon];
	[self setSearchString:nil];
	[self setObjectValue:entry];
}

- (id)externalSelection{
	if (defaultBool(@"QSUseGlobalSelectionForGrab"))
		return [QSGlobalSelectionProvider currentSelection];
	else
		return [QSObject fileObjectWithArray:[[QSReg getMediator:kQSFSBrowserMediators] selection]];
}
- (IBAction) grabSelection:sender{
	if (!allowNonActions) return;
	QSObject *newSelection=[self externalSelection];
	[self setObjectValue:newSelection];
}

- (IBAction)dropSelection:sender{ 
	if (!allowNonActions) return;
	QSObject *newSelection=[self externalSelection];
	[self dropObject:newSelection];
}
- (IBAction)dropClipboard:sender{ 
	if (!allowNonActions) return;
	QSObject *newSelection=[QSObject objectWithPasteboard:[NSPasteboard generalPasteboard]];
	[self dropObject:newSelection];
}
- (void) dropObject:(QSBasicObject *)newSelection{        
	NSString *action=[[self objectValue] actionForDragOperation:NSDragOperationEvery withObject:newSelection];
	//NSLog(@"action %@",action);
	QSAction *actionObject=[QSLib actionForIdentifier:action];
	
	if (!action){
		NSBeep();
		return;
	}
	if ([[[self window]windowController] isKindOfClass:[QSInterfaceController class]]){
		[(QSInterfaceController *)[[self window]windowController] setCommandWithArray:[NSArray arrayWithObjects:newSelection,actionObject,[self objectValue],nil]];
	}else{
		[actionObject performOnDirectObject:(QSObject *)newSelection indirectObject:[self objectValue]];
	}
}
@end

@implementation QSCollectingSearchObjectView


- (void)deleteBackward:(id)sender{
	if ([collection count] && ![partialString length])
		[self uncollectLast:sender];
	else
		[super deleteBackward:sender];
	//	NSText *fieldEditor=[[self window]fieldEditor:YES forObject:self];
	//[[self cell]editWithFrame:[self frame]inView:self editor:fieldEditor delegate:self event:nil];
}

-(IBAction) collect:(id)sender{ //Adds additional objects to a collection
	if (!fBETA) return;
	
	if (!collecting) collecting=YES;
	if ([super objectValue]){
		
		//[collection removeObject:[super objectValue]];
		[collection addObject:[super objectValue]];
		[self setNeedsDisplay:YES];
	}
	[sController setShouldResetSearchString:YES];
	return;
}
-(IBAction) uncollect:(id)sender{ //Removes an object to a collection
	if ([collection count])
		[collection removeObject:[super objectValue]];
	if (![collection count])collecting=NO;
	[self setNeedsDisplay:YES];
}
-(IBAction) uncollectLast:(id)sender{ //Removes an object to a collection
	if ([collection count])
		[collection removeLastObject];
	
	if (![collection count])collecting=NO;
	[self setNeedsDisplay:YES];
	if ([[resultController window] isVisible])
		[resultController->resultTable setNeedsDisplay:YES];}

-(IBAction) emptyCollection:(id)sender{ 
	collecting=NO;
	[collection removeAllObjects];
}
-(IBAction) combine:(id)sender{ //Resolve a collection as a single object
	[self setObjectValue:[self objectValue]];
	[self emptyCollection:sender];
	
	collecting=NO;
}

- (id)objectValue {
	if ([collection count])
		return [QSObject objectByMergingObjects:(NSArray *)collection withObject:[super objectValue]];
	else
		return [super objectValue];
}

- (void)setObjectValue:(QSBasicObject *)newObject {	
	if (!collecting) [self emptyCollection:self];
	[super setObjectValue:newObject];
}
- (BOOL)objectIsInCollection:(QSObject *)thisObject{
	return [collection containsObject:thisObject];	
}



- (void)drawRect:(NSRect)rect {
	if ([collection count]){
		NSRect top=NSMakeRect(0,20,NSWidth([self frame]),NSHeight([self frame])-20);
		//NSRect bottom=NSMakeRect(0,0,NSWidth([self frame]),20);
		[[self cell]drawWithFrame:top inView:self];
		
		[[NSColor colorWithDeviceWhite:1.0 alpha:0.92]set];
		NSBezierPath *roundRect=[NSBezierPath bezierPath];
		
		[roundRect appendBezierPathWithRoundedRectangle:top withRadius:NSHeight(rect)/16];
		//[roundRect fill];  
		
		
		int i;
		int count=[collection count];
		float opacity=collecting?1.0:0.5;
		QSObject *object;
		for (i=0;i<count;i++){
			object=[collection objectAtIndex:i];
			NSImage *icon=[object icon];
			[icon setSize:NSMakeSize(16,16)];
			[icon setFlipped:NO];
			[icon drawInRect:NSMakeRect(16*i,2,16,16) fromRect:rectFromSize([icon size]) operation:NSCompositeSourceOver fraction:opacity];
		}
	}else{
		[super drawRect:rect];	
	}
}
@end




@implementation QSOldSearchObjectView (Accessors)
- (NSArrayController *)results {
    return [[results retain] autorelease]; 
}
- (void)setResults:(NSArrayController *)newResults {
    if (results != newResults) {
        [results release];
        results = [newResults copy];
    }
}


- (void)setResultsPadding:(float)aResultsPadding
{
	resultsPadding = aResultsPadding;
}




- (NSRectEdge)preferredEdge { return preferredEdge; }
- (void)setPreferredEdge:(NSRectEdge)newPreferredEdge {
	preferredEdge = newPreferredEdge;
}




- (id)selectedObject { return selectedObject; }

- (void)setSelectedObject:(id)newSelectedObject {
	[selectedObject release];
	selectedObject = [newSelectedObject retain];
}



- (NSText *)currentEditor {
	if ([super currentEditor])
		return [super currentEditor];
	else
		return [[currentEditor retain] autorelease]; 
}

- (void)setCurrentEditor:(NSText *)aCurrentEditor
{
    if (currentEditor != aCurrentEditor) {
        [currentEditor release];
        currentEditor = [aCurrentEditor retain];
    }
}
- (BOOL)allowText { return allowText; }
- (void)setAllowText:(BOOL)flag {
	allowText = flag;
}

- (BOOL)allowNonActions { return allowNonActions; }
- (void)setAllowNonActions:(BOOL)flag{
    allowNonActions = flag;
}

@end
