//
//  QSCIEffectOverlay.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 11/20/05.

//

#import "QSCIEffectOverlay.h"
#define CGSWindowFilterRef fid;
CGSConnection cid;
//typedef int		CGSConnection;
//typedef int		CGSWindow;
//typedef int		CGSValue;
//
//typedef enum {
//	CGSTagExposeFade	= 0x0002,   // Fade out when Expose activates.
//	CGSTagNoShadow		= 0x0008,   // No window shadow.
//	CGSTagTransparent   = 0x0200,   // Transparent to mouse clicks.
//	CGSTagSticky		= 0x0800,   // Appears on all workspaces.
//} CGSWindowTag;
//
//extern OSStatus CGSGetWindowTags(const CGSConnection cid, const CGSWindow wid, 
//								 CGSWindowTag *tags, int thirtyTwo);
//extern OSStatus CGSSetWindowTags(const CGSConnection cid, const CGSWindow wid, 
//								 CGSWindowTag *tags, int thirtyTwo);
//extern OSStatus CGSClearWindowTags(const CGSConnection cid, const CGSWindow wid, 
//								   CGSWindowTag *tags, int thirtyTwo);

void DXSetWindowTag(int wid, CGSWindowTag tag,int state){	
    CGSConnection cid;
    
    cid = _CGSDefaultConnection();
	CGSWindowTag tags[2];
	tags[0] = tags[1] = 0;
	OSStatus retVal = CGSGetWindowTags(cid, wid, tags, 32);
	if(!retVal) {
		tags[0] = tag;
		if (state)
			retVal = CGSSetWindowTags(cid, wid, tags, 32);
		else
			retVal = CGSClearWindowTags(cid, wid, tags, 32);
	}
}

void DXSetWindowIgnoresMouse(int wid, int state){	
	DXSetWindowTag(wid,CGSTagTransparent,state);
}


#define NSRectToCGRect(r) CGRectMake(r.origin.x, r.origin.y, r.size.width, r.size.height)
CGRect QSCGRectFromScreenFrame(NSRect rect){
	CGRect screenBounds = CGDisplayBounds(kCGDirectMainDisplay);
	CGRect cgrect=NSRectToCGRect(rect);
	cgrect.origin.y+=screenBounds.size.height;
	cgrect.origin.y -=rect.size.height;
	
	return cgrect;
}

//static void DestroyCIFilterContext(MyCIFilterContext *context)
//{
//    if ( context )
//    {
//        if ( context->cid && context->filter )
//        {
//            if ( context->overlayWID )
//            {
//                CGSRemoveWindowFilter(context->cid, context->overlayWID, context->filter);
//                CGSReleaseWindow(context->cid, context->overlayWID);
//            }
//            CGSReleaseCIFilter(context->cid, context->filter);
//        }
//        free(context);
//    }
//}
	
@implementation QSCIEffectOverlay
- (id) initWithRect:(CGRect) r {
	self = [super init];
	if (self != nil) {
		cid=_CGSDefaultConnection();
		QSLog(@"create overlay rect:");
		//logRect(frame);
		[self createOverlayInRect:r];
		CGSOrderWindow(cid, wid, -1, 0);
		//		wid=QSCreateOverlayWindow((CGRect)frame);
	}
	return self;
}
-(void)setLevel:(int)level{
	QSLog(@"level %d",level);
	CGSSetWindowLevel(cid, wid,level);
	CGSOrderWindow(cid, wid, -1, 0);
}
- (void)createOverlayInRect:(CGRect) r{
	
	static CGRect   sWindowRgn = { {0.0, 0.0}, {1.0, 1.0} };
	CGError         error;
	CGSRegionRef    shape, opaqueShape;
	void           *unknown;
	bool            successful = false;
	error = CGSNewRegionWithRect(&sWindowRgn, &shape);
	error = CGSNewEmptyRegion(&opaqueShape);
	error = CGSNewWindowWithOpaqueShape(cid, 2, 0.0, 0.0, shape, opaqueShape, 0, &unknown, 32, &wid);
	CGSReleaseRegion(shape);
	CGSReleaseRegion(opaqueShape);
	QSLog(@"window %d",wid);
	if ( noErr == error )
	{
	//	CGRect r=NSRectToCGRect(rect);
		
		QSLog(@"%f %f %f %f",r.origin.x,r.origin.y,r.size.width,r.size.height);
		CGAffineTransform   t;    
		t.b = t.c = 0.0;
		t.a = 1.0 / r.size.width;
		t.d = 1.0 / r.size.height;
		t.tx = -r.origin.x * t.a;
		t.ty = -r.origin.y * t.d;
		
		CGSSetWindowTransform(cid, wid, t);
		CGSSetWindowLevel(cid, wid, CGWindowLevelForKey(kCGFloatingWindowLevelKey));
		DXSetWindowIgnoresMouse(wid,TRUE);
		CGContextRef cgContext = CGWindowContextCreate(cid, wid, NULL);
		if ( cgContext )
		{
			CGContextSetCompositeOperation(cgContext, 1);
            CGContextSetRGBFillColor(cgContext, 1.0, 1.0, 1.0, 0.0);
			CGContextFillRect(cgContext, sWindowRgn);
			CFRelease(cgContext);
			successful = true;
		}
	}
	
//	if ( successful )
//		return wid;
	return;
}	




- (void)setFilter:(NSString *)filterName{
	if (fid){
		CGSRemoveWindowFilter(cid,wid,fid);
		CGSReleaseCIFilter(cid,fid);
	}
	if (filterName){
		CGError error = CGSNewCIFilterByName(cid, (CFStringRef) filterName, &fid);
		if ( noErr == error )
		{
			error = CGSAddWindowFilter(cid,wid,fid, 0x00003001);
		}
		if (error) QSLog(@"setfilter err %d",error);
	}
}
-(void)setFilterValues:(NSDictionary *)filterValues{
	if (!fid) return;
///	CGError error = 
		CGSSetCIFilterValuesFromDictionary(cid, fid, (CFDictionaryRef)filterValues);
}

- (void) dealloc {
	CGSReleaseWindow(cid,wid);
	wid=0;
	[super dealloc];
}

@end
