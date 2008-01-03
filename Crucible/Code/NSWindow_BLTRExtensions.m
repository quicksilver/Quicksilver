#import "NSWindow_BLTRExtensions.h"

#import "NSGeometry_BLTRExtensions.h"
//typedef int CGSConnection;
//typedef int CGSWindow;
//extern CGSConnection _CGSDefaultConnection(void);
//
//OSStatus CGSGetWindowTags(CGSConnection cid,CGSWindow widow,int *tags,int other);
//OSStatus CGSSetWindowTags(CGSConnection cid,CGSWindow widow,int *tags,int other);

@implementation NSWindow (Fade)
- (id)windowPropertyForKey:(NSString *)key{return nil;}

-(void)setSticky:(BOOL)flag {
    CGSConnection cid;
    
    CGSWindow wid;
    
    wid = [self windowNumber ];
    cid = _CGSDefaultConnection();
    CGSWindowTag tags = 0;
    OSStatus retVal = CGSGetWindowTags(cid, wid, &tags, 32);
    if(!retVal) {
        if (flag)
            tags = tags | 0x00000800;
        else
            tags = tags & 0x00000800;
        retVal = CGSSetWindowTags(cid, wid, &tags, 32);
    }
}

-(void)setAlphaValue:(float)fadeOut fadeTime:(float)seconds{
    float newAlpha, elapsed;
    NSTimeInterval fadeStart = [NSDate timeIntervalSinceReferenceDate];
    float fadeIn=[self alphaValue];
    float distance=fadeOut-fadeIn;
    newAlpha = (([NSDate timeIntervalSinceReferenceDate] - fadeStart)/seconds);
    for(elapsed=0; elapsed<1; elapsed = (([NSDate timeIntervalSinceReferenceDate] - fadeStart)/seconds)){
        [self setAlphaValue:fadeIn+elapsed*distance];
       // [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds/300]];
    }
    [self setAlphaValue:fadeOut];
}

- (BOOL)animationIsValid{return YES;}
- (void)reallyCenter{
	NSRect screenRect=[[self screen]frame];
	NSRect windowRect=[self frame];
	NSRect centeredRect=NSOffsetRect(windowRect,NSMidX(screenRect)-NSMidX(windowRect),NSMidY(screenRect)-NSMidY(windowRect));
	[self setFrame:centeredRect display:NO];	
}
- (void)setFrame:(NSRect)frameRect alphaValue:(float)alpha display:(BOOL)displayFlag animate:(BOOL)animationFlag{
    if (alpha==[self alphaValue]) [self setFrame:frameRect display:displayFlag animate:animationFlag];

    float newAlpha, elapsed;
    float seconds=(float)[self animationResizeTime:frameRect];
    NSTimeInterval fadeStart = [NSDate timeIntervalSinceReferenceDate];
    NSRect startRect=[self frame];
    float fadeIn=[self alphaValue];
    float distance=alpha-fadeIn;
    newAlpha = (([NSDate timeIntervalSinceReferenceDate] - fadeStart)/seconds);
    for(elapsed=0; elapsed<1; elapsed = (([NSDate timeIntervalSinceReferenceDate] - fadeStart)/seconds)){
        [self setAlphaValue:fadeIn+elapsed*distance];
        [self setFrame:blendRects(startRect,frameRect,elapsed) display:displayFlag];

        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:seconds/20]];
    }
    [self setAlphaValue:alpha];
    [self setFrame:frameRect display:displayFlag];
 }


+(NSWindow *)windowWithImage:(NSImage *)image{
	NSRect windowRect=NSMakeRect(0,0,[image size].width,[image size].height);
	NSWindow *window = [[[self class] alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[window setIgnoresMouseEvents:YES];
	[window setBackgroundColor: [NSColor clearColor]];
	[window setOpaque:NO];
	[window setHasShadow:NO];
	[[window contentView] lockFocus];
	[image compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
	[[window contentView] unlockFocus];
	[window setAutodisplay:NO];
	[window setReleasedWhenClosed:YES];
	return window;
}
@end


@implementation NSWindow (Physics)
-(void)animateVelocity:(float)velocity inDirection:(float)angle withFriction:(float)friction startTime:(NSTimeInterval)startTime{
    //QSLog(@"Animating Velocity:%f,%f,%f",velocity,angle,friction);
    //friction=friction/10;
    
    float v=velocity;
   // NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    NSTimeInterval thisTime, elapsedTime;

    thisTime=startTime;
    //NSRect startFrame=[self frame];
        NSRect newFrame=[self frame];
        
    while (v>0){

        //QSLog(@"Animating Velocity:%f",v);
        
        //thisTime = [NSDate timeIntervalSinceReferenceDate];
        elapsedTime=[NSDate timeIntervalSinceReferenceDate]-startTime;


        newFrame.origin.x+= v * elapsedTime * sin(angle);
        newFrame.origin.y+= v * elapsedTime * cos(angle);

        if (!NSContainsRect([[self screen] frame], newFrame)){
            //QSLog(@"---------");

            float dMaxX=NSMaxX(newFrame) - NSMaxX([[self screen] frame]);
            float dMinX=NSMinX(newFrame) - NSMinX([[self screen] frame]);
            float dMaxY=NSMaxY(newFrame) - NSMaxY([[self screen] frame]);
            float dMinY=NSMinY(newFrame) - NSMinY([[self screen] frame]);

            NSPoint coordVelocity=NSMakePoint(sin(angle),cos(angle));
            //QSLog(@"bounce %f %f, %f",coordVelocity.x,coordVelocity.y, angle*180/pi);

            if (dMaxX >= 0){
                //QSLog(@"xmax");
                coordVelocity.x=-fabs(coordVelocity.x);
                newFrame.origin.x-=2*dMaxX;
            }
            else if (dMinX <= 0){
                //QSLog(@"xmin");
                coordVelocity.x=fabs(coordVelocity.x);
                newFrame.origin.x-=2*dMinX;
            }
            //else QSLog(@"notx %f %f",dMaxX, dMinX);

            if (dMaxY >= 0){
                //QSLog(@"ymax");
                coordVelocity.y=-fabs(coordVelocity.y);
                newFrame.origin.y-=2*dMaxY;
            }
            else if (dMinY <= 0){
                //QSLog(@"xmin");
                coordVelocity.y=fabs(coordVelocity.y);
                newFrame.origin.y-=2*dMinY;
            }
            // else QSLog(@"noty %f %f",dMaxY, dMinY);
            
            // if (NSMaxY([self frame]) > NSMaxY([[self screen] frame]))coordVelocity.y=-fabs(coordVelocity.y);
            //else if ( NSMinY([self frame]) < NSMinY([[self screen] frame])) coordVelocity.y=fabs(coordVelocity.y);


          

            angle=atan2(coordVelocity.x,coordVelocity.y);
            v-=friction * 4;
            //QSLog(@"bouncd %f %f, %f",coordVelocity.x,coordVelocity.y, angle*180/pi);
            //newFrame=NSOffsetRect([self frame], v * elapsedTime * coordVelocity.x,v * elapsedTime * coordVelocity.y);
        }
        
        [self setFrame:newFrame  display:YES animate:NO];
        v=v-friction * elapsedTime;
        //[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:.001]];
        
    }
    newFrame.origin.x=(int)newFrame.origin.x;
    newFrame.origin.y=(int)newFrame.origin.y;
  [self setFrame:newFrame  display:YES animate:NO];
}
@end

@implementation NSWindow (Widgets)
- (void) addInternalWidgets{
    [self addInternalWidgetsForStyleMask:[self styleMask]];
}


- (void) addInternalWidgetsForStyleMask:(int)styleMask closeOnly:(BOOL)closeOnly{    
	NSButton *closeButton=[NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:styleMask];
	NSPoint widgetOrigin=NSMakePoint(3,NSHeight([self frame])-NSHeight([closeButton frame])-3);
    [closeButton setFrameOrigin:widgetOrigin];
	[closeButton setAutoresizingMask:NSViewMinYMargin];
    [[self contentView]addSubview:closeButton];
	
    widgetOrigin.x+=NSWidth([closeButton frame])+2;
	
	
	if (!closeOnly){
	NSButton *minimizeButton=[NSWindow standardWindowButton:NSWindowMiniaturizeButton forStyleMask:styleMask];
    NSButton *zoomButton=[NSWindow standardWindowButton:NSWindowZoomButton forStyleMask:styleMask];
	[minimizeButton setFrameOrigin:widgetOrigin];
    widgetOrigin.x+=NSWidth([closeButton frame])+2;
    [zoomButton setFrameOrigin:widgetOrigin];
    widgetOrigin.x+=NSWidth([closeButton frame])+2;
   [minimizeButton setAutoresizingMask:NSViewMinYMargin];
    [zoomButton setAutoresizingMask:NSViewMinYMargin];
	[[self contentView]addSubview:minimizeButton];
    [[self contentView]addSubview:zoomButton];
	}
//	[zoomButton cell]._hasRollover=YES;
    
}
- (void) addInternalWidgetsForStyleMask:(int)styleMask{
	[self addInternalWidgetsForStyleMask:(int)styleMask closeOnly:NO];
}
@end