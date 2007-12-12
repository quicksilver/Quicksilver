/*
 *  QSShading.h
 *  Quicksilver
 *
 *  Created by Alcor on 10/17/04.
 *  Copyright 2004 Blacktree. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

typedef enum {
	QSGlossFlat = 0, 			// Flat Highlight.
	QSGlossUpArc = 1, 			// Upward Arc.
	QSGlossDownArc = 2, 		// Downward Arc.
	QSGlossRisingArc = 3, 		// Flat Highlight.
	QSGlossControl = 4, 		// Glass Control style.

} QSGlossStyle;


void QSFillRectWithGradientFromEdge(NSRect rect, NSColor *start, NSColor *end, NSRectEdge startEdge);

NSBezierPath *QSGlossClipPathForRectAndStyle(NSRect rect, QSGlossStyle style);
