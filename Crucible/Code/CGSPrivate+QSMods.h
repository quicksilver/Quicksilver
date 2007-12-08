#import "CGSPrivate.h"


#define CGSFlip 9
#define CGSTransparentBackgroundMask (1<<7)
typedef struct CGPointWarp CGPointWarp;

struct CGPointWarp {
	CGPoint local;
	CGPoint global;
};

extern CGError CGSSetWindowWarp(const CGSConnection cid, const CGSWindow wid, int w, int h, CGPointWarp mesh[h][w]);
extern OSStatus CGSSetWindowListBrightness(const CGSConnection cid, CGSWindow *wids, float *brightness,int count);

#define CGSConnectionID CGSConnection
#define CGSWindowID CGSWindow

//extern OSStatus CGSNewCIFilter(const CGSConnection cid, CGSWindow *wids, float *brightness,int count);
//extern OSStatus CGSMoveWindow(const CGSConnection cid, CGSWindow *wids, float *brightness,int count);
//extern OSStatus CGSSetCIFilterValues(const CGSConnection cid, CGSWindow *wids, float *brightness,int count);
//extern OSStatus CGSSetCIFilterValuesFromDictionary(const CGSConnection cid, CGSWindow *wids, float *brightness,int count);

//CGSIntersectRegionWithRect
//CGSSetWindowTransformsAtPlacement
//CGSSetWindowListGlobalClipShape

/*
 *  Created by Jason Harris on 11/19/05.
 *  Copyright 2005 Geekspiff. All rights reserved.
 */

//typedef void *CGSConnectionID;
//extern CGSConnectionID _CGSDefaultConnection();
//extern CGError CGSDisableUpdate(CGSConnectionID cid);
//extern CGError CGSReenableUpdate(CGSConnectionID cid);

typedef void *CGSRegionRef;
extern CGError CGSNewRegionWithRect(CGRect const *inRect, CGSRegionRef *outRegion);
extern CGError CGSNewEmptyRegion(CGSRegionRef *outRegion);
extern CGError CGSReleaseRegion(CGSRegionRef region);

//typedef void *CGSWindowID;
extern CGError CGSNewWindowWithOpaqueShape(CGSConnectionID cid, int always2, float x, float y, CGSRegionRef shape, CGSRegionRef opaqueShape, int unknown1, void *unknownPtr, int always32, CGSWindowID *outWID);
extern CGError CGSReleaseWindow(CGSConnectionID cid, CGSWindowID wid);
extern CGContextRef CGWindowContextCreate(CGSConnectionID cid, CGSWindowID wid, void *unknown);
//extern CGError CGSSetWindowTransform(CGSConnectionID cid, CGSWindowID wid, CGAffineTransform t);
extern CGError CGSSetWindowLevel(CGSConnectionID cid, CGSWindowID wid, CGWindowLevel level);
//extern CGError CGSOrderWindow(CGSConnectionID cid, CGSWindowID wid1, int ordering, CGSWindowID wid2);
extern CGError CGSGetWindowBounds(CGSConnectionID cid, CGSWindowID wid, CGRect *outBounds);

typedef void *CGSWindowFilterRef;
extern CGError CGSNewCIFilterByName(CGSConnectionID cid, CFStringRef filterName, CGSWindowFilterRef *outFilter);
extern CGError CGSAddWindowFilter(CGSConnectionID cid, CGSWindowID wid, CGSWindowFilterRef filter, int flags);
extern CGError CGSRemoveWindowFilter(CGSConnectionID cid, CGSWindowID wid, CGSWindowFilterRef filter);
extern CGError CGSReleaseCIFilter(CGSConnectionID cid, CGSWindowFilterRef filter);
extern CGError CGSSetCIFilterValuesFromDictionary(CGSConnectionID cid, CGSWindowFilterRef filter, CFDictionaryRef filterValues);




