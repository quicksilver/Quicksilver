#import "QSObjectCell.h"

#import "QSObject.h"
#import "QSObject_Menus.h"

#import "QSAction.h"
#import "QSExecutor.h"
#import "QSCommand.h"

#import "QSObjectFormatter.h"

#import "QSResourceManager.h"
#import <QSFoundation/QSFoundation.h>
#import "QSSearchObjectView.h"
#import "QSNullObject.h"

#import "QSBadgeImage.h"

#define countBadgeTextAttributes [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:24] , NSFontAttributeName, [NSColor whiteColor] , NSForegroundColorAttributeName, nil]


NSImage *QSBadgeImageForCount(int count) {
	if (count <= 1) return nil;
	NSImage *badgeImage = nil;
	NSString *numString = [NSString stringWithFormat:@"%d", count];
	if ([numString length] <3)
		badgeImage = [QSResourceManager imageNamed:@"dragBadge1-2"];
	else if ([numString length] <4)
		badgeImage = [QSResourceManager imageNamed:@"dragBadge3"];
	else if ([numString length] <5)
		badgeImage = [QSResourceManager imageNamed:@"dragBadge4"];
	else
		badgeImage = [QSResourceManager imageNamed:@"dragBadge5"];

	if (!badgeImage) return nil;
	return badgeImage;
}

void QSDrawCountBadgeInRect(NSImage *countImage, NSRect badgeRect, int count) {
	[countImage drawInRect:badgeRect fromRect:rectFromSize([countImage size]) operation:NSCompositeSourceOver fraction:1.0];
	NSString *numString = [NSString stringWithFormat:@"%d", count];
	NSRect textRect = NSInsetRect(badgeRect, NSHeight(badgeRect) /4, NSHeight(badgeRect)/4);
	NSDictionary *numAttributes = [numString attributesToFitNumbersInRect:textRect withAttributes:countBadgeTextAttributes];
	//	NSLog(@"font metric: %f %f", [[numAttributes objectForKey:NSFontAttributeName] ascender] , [[numAttributes objectForKey:NSFontAttributeName] descender]);
	NSRect glyphRect = rectFromSize([numString sizeWithAttributes:numAttributes]);
	NSRect countTextRect = centerRectInRect(glyphRect, badgeRect);
	countTextRect.origin.y += (NSHeight(glyphRect) -[[numAttributes objectForKey:NSFontAttributeName] ascender])/2;

	//	[[NSColor blackColor] set];
	//	NSFrameRect(countTextRect);
	[numString drawInRect:countTextRect withAttributes:numAttributes];
}



NSRect alignRectInRect(NSRect innerRect, NSRect outerRect, int quadrant);

@implementation QSObjectCell


+ (NSFocusRingType) defaultFocusRingType {
	return NSFocusRingTypeExterior;
}
- (NSTextView *)fieldEditorForView:(NSView *)aControlView
{
  if (!fieldEditor) {
    fieldEditor = [[NSTextView alloc] initWithFrame:NSZeroRect];
    [fieldEditor setFieldEditor:YES];
    [fieldEditor setRichText:NO];
  }
  return fieldEditor;
}
- (void)dealloc{
	[fieldEditor release];
	//[nameFont release];
	//[detailsFont release];
	[super dealloc];
}
- (id)initTextCell:(NSString *)aString {

	if (self = [super initTextCell:aString]) {
		[self setTitle:@"Test"];

		// [self _setNeedsHighlightedTextHint:YES];
		[self setImage:[NSImage imageNamed:@"Arrow"]];
		[self setImagePosition:NSImageLeft];
		//NSLog(@"init cell");
		[self setShowsFirstResponder:YES];
		[self setFont:[NSFont systemFontOfSize:12.0]];
		[self setNameFont:nil];
		[self setDetailsFont:nil];
        cellRadiusFactor = 9;
		showDetails = YES;
		autosize = YES;
		[self setHighlightsBy:NSChangeBackgroundCellMask];
		// [self setBezelStyle:NSRegularSquareBezelStyle];
		[self setBordered:NO];
		[self setBezeled:NO];
		[self setAlignment:NSLeftTextAlignment];
		[self setState:NSOffState];
		[self setImagePosition:-1];
		[self setRepresentedObject:nil];
		// NSLog(@"%d pos", [self imagePosition]);
		//[self setFormatter:[[[QSObjectFormatter alloc] init] autorelease]];
		// [self setShowsBorderOnlyWhileMouseInside:YES];
	}
	return self;
}

- (void)setImagePosition:(NSCellImagePosition)aPosition {
	autosize = (aPosition == -1);
	[super setImagePosition:aPosition];
}



- (BOOL)acceptsFirstResponder {return YES;}
- (BOOL)showsFirstResponder {return YES;}

- (BOOL)isOpaque {
	return NO;
}
/*
 - (BOOL)_shouldSetHighlightToFlag:(BOOL)fp8 {
	 NSLog(@"%d", fp8);
 }
 */


- (NSRect) titleRectForBounds:(NSRect)theRect {

	NSCellImagePosition pos = [self imagePosition];
	if (autosize) {
		BOOL wideDraw = NSWidth(theRect) /NSHeight(theRect) > 2;
		if (wideDraw || [self isBezeled])
			pos = NSImageLeft;
		else
			pos = NSImageAbove;
	}

	switch (pos) {
		case NSNoImage:
			return NSZeroRect;
		case NSImageOnly:
		case NSImageOverlaps:
			return theRect;
		case NSImageLeft:
			theRect.origin.x += NSHeight(theRect) * 18/16;
			// theRect.origin.y++;
			theRect.size.width -= theRect.size.height* 18/16;
			theRect = NSInsetRect(theRect, NSHeight(theRect) /16, 0);
			break;
		case NSImageRight:
			theRect.origin.x += theRect.size.width-theRect.size.height;
			theRect.size.width = theRect.size.height;
			break;
		case NSImageBelow:
			theRect.origin.y += theRect.size.height-16;
			theRect.size.height = 16;
			break;
		case NSImageAbove:
			theRect.size.height = 16;
			break;
	}

	// logRect(theRect);
	return theRect;
}




- (BOOL)hasBadge {
	return [[self representedObject] primaryCount] >1;
}

- (NSRect) imageRectForBounds:(NSRect)theRect {
	// NSLog(@"-------");
	// logRect(theRect);
	NSCellImagePosition pos = [self imagePosition];
	if (autosize) {
		BOOL wideDraw = NSWidth(theRect) /NSHeight(theRect) > 2;
		if (wideDraw || [self isBezeled])
			pos = NSImageLeft;
		else
			pos = NSImageAbove;
		//	 if ([self isBezeled]) m
		//		 theRect = NSMakeRect(12, 1, 16, 16);
	}

	switch (pos) {
		case NSNoImage:
			return NSZeroRect;
		case NSImageOnly:
		case NSImageOverlaps:
			return theRect;
		case NSImageLeft:
			theRect.size.width = theRect.size.height;
			break;
		case NSImageRight:
			theRect.origin.x += theRect.size.width-theRect.size.height;
			theRect.size.width = theRect.size.height;
			break;
		case NSImageBelow:
			theRect.size.height -= 16;
			break;
		case NSImageAbove:
			theRect.size.height -= 16;
			theRect.origin.y += 16;

			break;
	}
	if ([self isBezeled] && NSHeight(theRect) <= 20) {
		theRect.origin.y += 1+(int) ((NSHeight(theRect)-16)/2);
		theRect.size.height = 15;

	}
	if (!NSEqualSizes(iconSize, NSZeroSize) ) {
		theRect = NSIntersectionRect(centerRectInRect(rectFromSize(iconSize), theRect), theRect);

		//logRect(theRect);
	}
	return theRect;
}

- (NSRect) badgeRectForBounds:(NSRect)theRect badgeImage:(NSImage *)image {

	BOOL wideDraw = NSWidth(theRect) /NSHeight(theRect) > 2;
	NSRect countImageRect = rectFromSize([image size]);
	if ([self isBezeled]) {
		theRect = NSInsetRect(theRect, 6, 0);
		NSRect imageRect = sizeRectInRect(rectFromSize([image size]), theRect, NO);
		imageRect = NSOffsetRect(imageRect, NSMaxX(theRect) -NSMaxX(imageRect), NSMaxY(theRect)-NSMaxY(imageRect));
		return imageRect;

	} else if (wideDraw) {
		// theRect = NSInsetRect(theRect, 6, 0);
		NSRect imageRect = sizeRectInRect(rectFromSize([image size]), NSMakeRect(0, 0, 22, 22), NO);
		imageRect = NSOffsetRect(imageRect, NSMaxX(theRect) -NSMaxX(imageRect), NSMaxY(theRect)-NSMaxY(imageRect));
		return imageRect;
		theRect.size.width = theRect.size.height;

	} else {
		NSRect imageRect = [self imageRectForBounds:theRect];
		return alignRectInRect(countImageRect, imageRect, 3);
	}
	return theRect;
}

- (NSRect) countBadgeRectForBadgeBounds:(NSRect)theRect {

	return theRect;
}


- (NSRect) drawingRectForBounds:(NSRect)theRect {
	NSRect superRect = [super drawingRectForBounds:theRect];
	if ([self isBezeled]) {
		return NSInsetRect(theRect, NSHeight(theRect) /2, NSHeight(superRect)/18);
	}
	// return theRect;
	return NSInsetRect(superRect, NSHeight(superRect) /18, NSHeight(superRect)/18);
}

- (void)calcDrawInfo:(NSRect)aRect {
	[super calcDrawInfo:aRect];
}



- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	BOOL isFirstResponder = [[controlView window] firstResponder] == controlView && ![controlView isKindOfClass:[NSTableView class]];
	// BOOL isKey = [[controlView window] isKeyWindow];


	NSColor *fillColor;
	NSColor *strokeColor;


	//logRect(drawingRect);
	BOOL dropTarget = ([self isHighlighted] && ([self highlightsBy] & NSChangeBackgroundCellMask) && ![self isBezeled]);

	if (isFirstResponder) {
		fillColor = [self highlightColor];
		//if (![self isHighlighted]) fillColor = [fillColor colorWithAlphaComponent:(isKey?1.0:0.5)];
	} else {
		fillColor = [[self textColor] colorWithAlphaComponent:0.075];
	}

		if (dropTarget) {

			fillColor = [fillColor blendedColorWithFraction:0.1 ofColor:[self textColor] ?[self textColor] :[NSColor textColor]];
		}
	strokeColor = [[self textColor] colorWithAlphaComponent:dropTarget?0.4:0.2];




	[fillColor setFill];
	[strokeColor setStroke];



	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	if ([self isBezeled]) {
		//NSLog(@"%d", [self highlightsBy]);
		if ([self highlightsBy] || isFirstResponder) {
			QSObject *drawObject = [self representedObject];
			BOOL action = [drawObject respondsToSelector:@selector(argumentCount)];
			int argCount = (action ? [(QSAction *)drawObject argumentCount] : 0);
			//BOOL indentRight = (indentLeft && [drawObject argumentCount] >1);
			NSRect borderRect = NSInsetRect(cellFrame, 2.25, 2.25);
			[roundRect setLineWidth:1.5];
			[roundRect appendBezierPathWithRoundedRectangle:borderRect withRadius:NSHeight(borderRect) /2 indent:argCount];
			[roundRect fill];
			[roundRect stroke];
		}
	} else if ([self highlightsBy] && (isFirstResponder || [self state]) ) {
		[roundRect appendBezierPathWithRoundedRectangle:cellFrame withRadius:NSHeight(cellFrame)/cellRadiusFactor];
		[roundRect fill];
		//[roundRect setFlatness:0.0];
		//[roundRect setLineWidth:3.25];
		//[roundRect stroke];

	}
	[self drawInteriorWithFrame:[self drawingRectForBounds:cellFrame] inView:controlView];
}

- (NSArray*)imagesForTypes:(NSArray *)types {
	NSMutableArray *typeImageArray = [NSMutableArray arrayWithCapacity:1];
	NSString *thisType;
	NSDictionary *imageDictionary = [self typeImageDictionary];
	for(thisType in types) {
		NSImage *typeImage = [imageDictionary objectForKey:thisType];
		if (typeImage) [typeImageArray addObject:typeImage];
	}
	return typeImageArray;
}
- (NSDictionary *)typeImageDictionary {
	return [NSDictionary dictionaryWithObjectsAndKeys:
		NSFilenamesPboardType, [NSImage imageNamed:@"fileType"] ,
		NSStringPboardType, [NSImage imageNamed:@"textType"] ,
		NSURLPboardType, [NSImage imageNamed:@"webType"] ,
		NSRTFDPboardType, [NSImage imageNamed:@"stylizedTextType"] ,
		nil];
}
- (NSImage *)image {
	return [[self representedObject] icon];
}

- (NSSize) iconSize { return iconSize;  }
- (void)setIconSize:(NSSize)anIconSize {
	iconSize = anIconSize;
}


- (NSSize) cellSize {
	NSSize size = NSZeroSize;
	size.height = 18;
	if ([self representedObject]) {
		size.width = [[[self representedObject] displayName] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[self font] , NSFontAttributeName, nil]].width+48;
		if ([self isBezeled] && [self hasBadge])
			size.width += 16;
		// ***warning  *this should change based on the badge
	} else
		size.width = 128;

	return size;

}

- (void)highlightRect:(NSRect) highlightRect inView:(NSView *)controlView {
	highlightRect = NSInsetRect(highlightRect, -highlightRect.size.height/16, -highlightRect.size.height/16);
	[[[NSColor blackColor] colorWithAlphaComponent:0.25] set];
	NSBezierPath *roundRect = [NSBezierPath bezierPath];
	[roundRect appendBezierPathWithRoundedRectangle:highlightRect withRadius:MAX(NSHeight(highlightRect) /16, 2)];
	[roundRect fill];
}

- (void)drawSearchPlaceholderWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSString *defaultText = NSLocalizedStringWithDefaultValue(@"Type to search", nil, [NSBundle mainBundle], @"Type to search", @"Hint that appears in the first pane of the QS interface when it's empty.");
	NSSize textSize = [defaultText sizeWithAttributes:detailsAttributes];
	NSRect textRect = centerRectInRect(rectFromSize(textSize), cellFrame);
	  BOOL isFirstResponder = [[controlView window] firstResponder] == controlView && ![controlView isKindOfClass:[NSTableView class]];

	  if (isFirstResponder && [controlView isKindOfClass:[QSSearchObjectView class]]) {
		  NSImage *find = [NSImage imageNamed:@"Find"];
		  [find setSize:NSMakeSize(128, 128)];
		  [find setFlipped:NO];
		  NSRect findImageRect = fitRectInRect(rectFromSize([find size]), cellFrame, 0);

		  if (NSHeight(findImageRect) >= 64)
			  [find drawInRect:findImageRect fromRect:rectFromSize([find size]) operation:NSCompositeSourceOver fraction:0.25];

		  [defaultText drawInRect:textRect withAttributes:detailsAttributes];
          
          // Set the button cell's title, which is used by VoiceOver to announce the name of the button.
          // Then post notifications of a change in the GUI using the accessibility API.
          [[controlView cell] setTitle:defaultText];
          NSAccessibilityPostNotification([controlView cell], NSAccessibilityTitleChangedNotification);
          NSAccessibilityPostNotification([controlView cell], NSAccessibilityFocusedWindowChangedNotification);
	  }
}
- (id)objectValue {
	return [self representedObject];
}

- (void)setObjectValue:(id)value {
	[self setRepresentedObject:value];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	QSObject *drawObject = [self representedObject];

	[self buildStylesForFrame:cellFrame inView:controlView];

	if ([drawObject isKindOfClass:[QSNullObject class]]) return;
	//	[drawObject loadIcon];
	if (!drawObject) { // Draw default string
		[self drawSearchPlaceholderWithFrame:cellFrame inView:controlView];
		return;
	}

	[self drawIconForObject:drawObject withFrame:cellFrame inView:controlView];
	[self drawTextForObject:drawObject withFrame:cellFrame inView:controlView];
}

- (void)drawIconForObject:(QSObject *)object withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	NSRect drawingRect = NSIntegralRect(fitRectInRect(NSMakeRect(0, 0, 1, 1), [self imageRectForBounds:cellFrame] , NO) );
	[self drawObjectImage:object inRect:drawingRect cellFrame:cellFrame controlView:controlView flipped:[controlView isFlipped] opacity:1.0];
	//[self drawObjectImage:object inRect:NSOffsetRect(drawingRect, 0, -NSHeight(drawingRect) *1.1) cellFrame:cellFrame controlView:controlView flipped:!flipped opacity:0.25];
}

- (void)buildStylesForFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	//	BOOL wideDraw = NSWidth(cellFrame) /NSHeight(cellFrame) > 2;
	//  BOOL isFirstResponder = [[controlView window] firstResponder] == controlView && ![controlView isKindOfClass:[NSTableView class]];


	NSMutableParagraphStyle *style = [[[NSMutableParagraphStyle alloc] init] autorelease];
	[style setLineBreakMode:NSLineBreakByTruncatingTail];
	[style setFirstLineHeadIndent:1.0];
	[style setHeadIndent:1.0];
	[style setAlignment:[self alignment]];
	//
	/// NSLog(@"%d %d", [self isHighlighted] , [self state]);

	//  NSView *controlView = [self controlView];
	BOOL useAlternateColor = [controlView isKindOfClass:[NSTableView class]] && [(NSTableView *)controlView isRowSelected:[(NSTableView *)controlView rowAtPoint:cellFrame.origin]];
	NSColor *mainColor = (textColor?textColor:(useAlternateColor?[NSColor alternateSelectedControlTextColor] :[NSColor controlTextColor]) );
	NSColor *fadedColor = [mainColor colorWithAlphaComponent:0.80];
	
	if(!nameFont)
	{
		[self setNameFont:[NSFont fontWithName:[[self font] fontName] size:MIN([[self font] pointSize] , NSHeight(cellFrame) *1.125*2/3) -1]];
	}
	if(!detailsFont)
	{
		[self setDetailsFont:[NSFont fontWithName:[[self font] fontName] size:[[self font] pointSize] *5/6]];
	}
	
	[nameAttributes release];
	nameAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		nameFont, NSFontAttributeName,
		mainColor, NSForegroundColorAttributeName,
		style, NSParagraphStyleAttributeName,
		nil];

	[detailsAttributes release];
	detailsAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		detailsFont, NSFontAttributeName,
		fadedColor, NSForegroundColorAttributeName,
		style, NSParagraphStyleAttributeName,
		nil];
}

// method for drawing the text (e.g. object label, name etc.) on the interface
- (void)drawTextForObject:(QSObject *)drawObject withFrame:(NSRect)cellFrame inView:(NSView *)controlView {
	if ([self imagePosition] != NSImageOnly) { // Text Drawing Routines
		NSString *abbreviationString = nil;
		if ([controlView respondsToSelector:@selector(matchedString)])
			abbreviationString = [(QSSearchObjectView *)controlView matchedString];
        
		NSString *nameString = nil;
		NSIndexSet *hitMask = nil;
        
        id ranker = [drawObject ranker];
		if (ranker && abbreviationString) {
			nameString = [ranker matchedStringForAbbreviation:abbreviationString hitmask:&hitMask inContext:nil];
        }
		if (!nameString) nameString = [drawObject displayName];
		if (!nameString) nameString = @"<Unknown>";
        
		//NSLog(@"usingname: %@", nameString);
		NSSize nameSize = [nameString sizeWithAttributes:nameAttributes];
        
        BOOL validDetailsString = NO;
        
        NSString *detailsString = [drawObject details];
        if(detailsString && [detailsString length] && ![detailsString isEqualToString:nameString]) {
            validDetailsString = YES;
        }
        
		BOOL useAlternateColor = [controlView isKindOfClass:[NSTableView class]] && [(NSTableView *)controlView isRowSelected:[(NSTableView *)controlView rowAtPoint:cellFrame.origin]];
		NSColor *mainColor = (textColor?textColor:(useAlternateColor?[NSColor alternateSelectedControlTextColor] :[NSColor controlTextColor]));
		NSColor *fadedColor = [mainColor colorWithAlphaComponent:0.80];
        
		NSRect textDrawRect = [self titleRectForBounds:cellFrame];
        
		NSMutableAttributedString *titleString = [[[NSMutableAttributedString alloc] initWithString:nameString] autorelease];
		[titleString setAttributes:nameAttributes range:NSMakeRange(0, [titleString length])];
        
		if (abbreviationString && ![abbreviationString hasPrefix:@"QSActionMnemonic"]) {
			[titleString addAttribute:NSForegroundColorAttributeName value:fadedColor range:NSMakeRange(0, [titleString length])];
            
			// Organise displaying the text, underlining the letters typed (in the name)
			int i = 0;
			int j = 0;
			unsigned int hits[[titleString length]];
			int count = [hitMask getIndexes:(unsigned int *)&hits maxCount:[titleString length] inIndexRange:nil];
			NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                        mainColor, NSForegroundColorAttributeName,
                                        mainColor, NSUnderlineColorAttributeName,
                                        [NSNumber numberWithInt:2.0] , NSUnderlineStyleAttributeName,
                                        [NSNumber numberWithFloat:1.0] , NSBaselineOffsetAttributeName,
                                        nil];
            
            //	  NSLog(@"hit %@ %@", [titleString string] , hitMask);
			for(i = 0; i<count; i += j) {
				for (j = 1; i+j<count && hits[i+j-1] +1 == hits[i+j]; j++);
				//	 NSLog(@"hit (%d, %d) ", hits[i] , j);
				[titleString addAttributes:attributes range:NSMakeRange(hits[i], j)];
				//				 NSLog(@"5");
			}
		} else {
			[titleString addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-1.0] range:NSMakeRange(0, [titleString length])];
		}
        
        if (validDetailsString) {
            NSSize detailsSize = NSZeroSize;
            detailsSize = [detailsString sizeWithAttributes:detailsAttributes];
            
            if (showDetails && ([[NSUserDefaults standardUserDefaults] integerForKey:@"QSResultViewRowHeight"] >= 34)) {
                //NSLog(@"Strings are %@, %@, sizes are %@, %@", nameString, detailsString, NSStringFromSize(nameSize), NSStringFromSize(detailsSize));
                float detailHeight = NSHeight(textDrawRect) -nameSize.height;
                NSRange returnRange;
                if (detailHeight<detailsSize.height && (returnRange = [detailsString rangeOfString:@"\n"]) .location != NSNotFound)
                    detailsString = [detailsString substringToIndex:returnRange.location];
                if ([detailsString length] >100) detailsString = [detailsString substringWithRange:NSMakeRange(0, 100)];
                // ***warning  ** this should take first line only?
                //if ([titleString length]) [titleString appendAttributedString:;
                [titleString appendAttributedString:
                 [[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@", [titleString length] ?@"\r":@"", detailsString] attributes:detailsAttributes] autorelease]
                 ];
                
            }
        }
		NSRect centerRect = rectFromSize([titleString size]);
		centerRect.size.width = NSWidth(textDrawRect);
		centerRect.size.height = MIN(NSHeight(textDrawRect), centerRect.size.height);
		[titleString drawInRect:centerRectInRect(centerRect, textDrawRect)];
        
        // Set the button cell's title, which is used by VoiceOver to announce the name of the button.
        // Then post notifications of a change in the GUI using the accessibility API.
        [[controlView cell] setTitle:[titleString string]];
        NSAccessibilityPostNotification([controlView cell], NSAccessibilityTitleChangedNotification);
        NSAccessibilityPostNotification([controlView cell], NSAccessibilityFocusedWindowChangedNotification);
	}
}

- (void)drawObjectImage:(QSObject *)drawObject inRect:(NSRect)drawingRect cellFrame:(NSRect)cellFrame controlView:(NSView *)controlView flipped:(BOOL)flipped opacity:(float)opacity {
	NSImage *icon = [[[drawObject icon] retain] autorelease];
	NSImage *cornerBadge = nil;
	// NSLog(@"icon");
	BOOL proxyDraw = [[icon name] isEqualToString:QSDirectObjectIconProxy];
	if (proxyDraw) {
		if ([controlView isKindOfClass:[QSSearchObjectView class]]) {
			cornerBadge = [[[(QSSearchObjectView *)controlView directSelector] objectValue] icon];
			icon = [QSResourceManager imageNamed:@"defaultAction"];
		} else {
			icon = [QSResourceManager imageNamed:@"defaultAction"];
		}
	}
	// NSRect imageRect = rectFromSize([icon size]);


	BOOL handlerDraw = NO;
	if (NSWidth(drawingRect) >64)
		handlerDraw = [drawObject drawIconInRect:(NSRect) drawingRect flipped:flipped];
#warning - gave me a random exception (Patrick Robertson 07/05/11)
	if (!handlerDraw) {
		[icon setFlipped:flipped];

		NSImageRep *bestRep = [icon bestRepresentationForSize:drawingRect.size];
		if (bestRep) [icon setSize:[bestRep size]];

		BOOL noInterpolation = (NSHeight(drawingRect) /[bestRep size] .width >= 4);
		//NSLog(@"noInterpolation %f", [bestRep size] .width);
		[[NSGraphicsContext currentContext] setImageInterpolation:noInterpolation?NSImageInterpolationNone:NSImageInterpolationHigh];
		BOOL faded = ![drawObject iconLoaded];
		drawingRect = fitRectInRect(rectFromSize([icon size]), drawingRect, NO);

		[icon drawInRect:drawingRect fromRect:rectFromSize([icon size]) operation:NSCompositeSourceOver fraction:faded?0.5:1.0];
		if (noInterpolation) [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

		if (proxyDraw && NSWidth(drawingRect) >= 32) {
			// [cornerBadge setSize:NSMakeSize(128, 128)];
			[cornerBadge setFlipped:flipped];
			NSRect badgeRect = NSMakeRect(0, 0, NSWidth(drawingRect) /2, NSHeight(drawingRect)/2);
			NSImageRep *bestBadgeRep = [cornerBadge bestRepresentationForSize:badgeRect.size];
			[cornerBadge setSize:[bestBadgeRep size]];
			NSPoint offset = rectOffset(badgeRect, drawingRect, 2);
			badgeRect = NSOffsetRect(badgeRect, offset.x, offset.y);

			[cornerBadge drawInRect:badgeRect fromRect:rectFromSize([cornerBadge size]) operation:NSCompositeSourceOver fraction:1.0];
		}

		if ([drawObject primaryCount] >1 && MIN(NSWidth(drawingRect), NSHeight(drawingRect) ) >= 64) {
			NSImage *countImage = [QSCountBadgeImage badgeForCount:[drawObject primaryCount]];
			//NSImage *countImage = QSBadgeImageForCount([drawObject primaryCount]);
			if (countImage) {
				NSRect badgeRect = [self badgeRectForBounds:cellFrame badgeImage:countImage];
				[countImage drawInRect:badgeRect fromRect:rectFromSize([countImage size]) operation:NSCompositeSourceOver fraction:1.0];
			}
		}
	}
}

- (NSMenu *)menu {
	if (![[self controlView] isKindOfClass:[QSObjectView class]]) return nil;
	return [self menuForObject:[self representedObject]];
}

- (NSMenu *)menuForObject:(id)object {
  if (!object) return nil;
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"ContextMenu"] autorelease];

	NSArray *actions = [QSExec validActionsForDirectObject:object indirectObject:nil];
	NSArray *nameSortedActions = [actions sortedArrayUsingDescriptors:[NSSortDescriptor descriptorArrayWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)]];

	NSMenuItem *item;
  NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:11],NSFontAttributeName,nil];
  
	if ([nameSortedActions count]) {
		NSMenu *actionsMenu = [[[NSMenu alloc] initWithTitle:@"Actions"] autorelease];

		for (QSAction *action in nameSortedActions) {
			if (action) {
				NSArray *componentArray = [[action name] componentsSeparatedByString:@"/"];
        [action loadIcon];
				NSImage *icon = [[[action icon] copy] autorelease];
				[icon setSize:NSMakeSize(16, 16)];
				[icon setFlipped:NO];

				id command = [QSCommand commandWithDirectObject:object actionObject:action indirectObject:nil];
				// NSLog(@"%@", command);
				if ([componentArray count] >1) {
					NSMenuItem *groupMenu = [menu itemWithTitle:[componentArray objectAtIndex:0]];
					if (!groupMenu) {
						groupMenu = [[[NSMenuItem alloc] initWithTitle:[componentArray objectAtIndex:0] action:nil keyEquivalent:@""] autorelease];
						[groupMenu setAttributedTitle:[[[NSAttributedString alloc] initWithString:[groupMenu title] attributes:attrs] autorelease]];
						if (icon) [groupMenu setImage:icon];
						[groupMenu setSubmenu:[[[NSMenu alloc] initWithTitle:[componentArray objectAtIndex:0]] autorelease]];
						[actionsMenu addItem:groupMenu];
					}
					item = (NSMenuItem *)[[groupMenu submenu] addItemWithTitle:[componentArray objectAtIndex:1] action:@selector(execute) keyEquivalent:@""];
					[item setAttributedTitle:[[[NSAttributedString alloc] initWithString:[item title] attributes:attrs] autorelease]];
				} else
					item = (NSMenuItem *)[actionsMenu addItemWithTitle:[action name] action:@selector(execute) keyEquivalent:@""];
					[item setAttributedTitle:[[[NSAttributedString alloc] initWithString:[item title] attributes:attrs] autorelease]];
				[item setTarget:command];
				[item setRepresentedObject:command];

				if (icon) [item setImage:icon];

			}
		}
		item = [[[NSMenuItem alloc] initWithTitle:@"Actions" action:nil keyEquivalent:@""] autorelease];
		[item setSubmenu: actionsMenu];
    [item setAttributedTitle:[[[NSAttributedString alloc] initWithString:[item title] attributes:attrs] autorelease]];
		[menu addItem:item];
		[menu addItem:[NSMenuItem separatorItem]];
	}
	item = [[[NSMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@""] autorelease];
  [item setAttributedTitle:[[[NSAttributedString alloc] initWithString:[item title] attributes:attrs] autorelease]];
  [menu addItem:item];
  item = [[[NSMenuItem alloc] initWithTitle:@"Remove" action:@selector(delete:) keyEquivalent:@""] autorelease];
  [item setTarget:[self controlView]];
  [item setAttributedTitle:[[[NSAttributedString alloc] initWithString:[item title] attributes:attrs] autorelease]];
  [menu addItem:item];
	return menu;
}

- (void)performMenuAction:(NSMenuItem *)item {
#ifdef DEBUG
	if (VERBOSE) NSLog(@"perf");
#endif

	QSCommand* command = [item representedObject];

	[command execute];
	//int argumentCount = [(QSAction *)action argumentCount];

	/*
	 if (argumentCount == 2)
	 [[[NSApp delegate] interfaceController] executePartialCommand:[NSArray arrayWithObjects:[self representedObject] , action, nil]];
	 else
	 [action performOnDirectObject:[self representedObject] indirectObject:nil];
	 */
}


/*
 - (NSString *)abbreviationString { return [[abbreviationString retain] autorelease];  }

 - (void)setAbbreviationString:(NSString *)newAbbreviationString {
	 [abbreviationString release];
	 abbreviationString = [newAbbreviationString retain];
 }
 */

- (BOOL)showDetails { return showDetails;  }
- (void)setShowDetails:(BOOL)flag {
	showDetails = flag;
}

- (NSFont *)nameFont {
    return nameFont;
}

- (void)setNameFont:(NSFont *)newNameFont {
    [nameFont autorelease];
    nameFont = [newNameFont retain];
    [[self controlView] setNeedsDisplay:YES];
}

- (NSFont *)detailsFont {
    return detailsFont;
}

- (void)setDetailsFont:(NSFont *)newDetailsFont {
    [detailsFont autorelease];
    detailsFont = [newDetailsFont retain];
    [[self controlView] setNeedsDisplay:YES];
}

- (float)cellRadiusFactor {
    return cellRadiusFactor;
}

- (void)setCellRadiusFactor:(float)newRadius {
    if (cellRadiusFactor == newRadius) {
        return;
    }
    cellRadiusFactor = newRadius;
    [[self controlView] setNeedsDisplay:YES];
}

- (NSColor *)textColor { return textColor;  }

- (void)setTextColor:(NSColor *)newTextColor {
    [textColor release];
    textColor = [newTextColor retain];
    [[self controlView] setNeedsDisplay:YES];
}

- (NSColor *)highlightColor { return highlightColor;  }

- (void)setHighlightColor:(NSColor *)aHighlightColor {
	if (highlightColor != aHighlightColor) {
		[highlightColor release];
		highlightColor = [aHighlightColor retain];
		[[self controlView] setNeedsDisplay:YES];
	}
}
//text attachment cell

- (NSRect) cellFrameForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(NSRect)lineFrag glyphPosition:(NSPoint)position characterIndex:(unsigned)charIndex {
	return lineFrag;
}
- (BOOL)wantsToTrackMouse {return NO;} ;
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)aTextView atCharacterIndex:(unsigned)charIndex untilMouseUp:(BOOL)flag {return NO;} ;
- (NSPoint) cellBaselineOffset {return NSZeroPoint;}
- (NSTextAttachment *)attachment { return attachment;  }
- (void)setAttachment:(NSTextAttachment *)newAttachment {attachment = newAttachment;}
- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)aView {return;}
- (BOOL)wantsToTrackMouseForEvent:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView atCharacterIndex:(unsigned)charIndex {return NO;}
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)aView characterIndex:(unsigned)charIndex {return;}
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(unsigned)charIndex layoutManager:(NSLayoutManager *)layoutManager {return;}
- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)aTextView untilMouseUp:(BOOL)flag {return NO;}
@end
