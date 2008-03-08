

#import "QSWindow.h"


#import "QSWindowAnimation.h"
#import "QSPreferenceKeys.h"
#import <unistd.h>
//typedef int CGSConnection;
//extern CGSConnection _CGSDefaultConnection(void);

@implementation NSWindow (Effects)

- (void)pulse:(id)sender{
	CGSConnection conn = _CGSDefaultConnection();
	CGAffineTransform transform;
	CGSGetWindowTransform(conn,[self windowNumber], &transform); 
	NSSize size=[self frame].size;
	float f;
	for (f=1.0;f<=1.01;f+=0.001){		
		CGAffineTransform newTransform=CGAffineTransformConcat(transform,CGAffineTransformTranslate(CGAffineTransformMakeScale(1/f,1/f),-size.width/2 + size.width/2*f,-size.height/2+size.height/2*f));
		//CGSSetWindowAlpha(conn,[self windowNumber],f);
		CGSSetWindowTransform(conn,[self windowNumber], newTransform); 
		
	}
	CGSSetWindowTransform(conn,[self windowNumber], transform); 
}



#define FLAREDURATION 0.3f
- (void)flare:(id)sender{
	CGSConnection conn = _CGSDefaultConnection();
	CGAffineTransform transform;
	CGSGetWindowTransform(conn,[self windowNumber], &transform); 
	NSSize size=[self frame].size;
	float f;
	NSDate *date=[NSDate date];
	float elapsed;
	while ((elapsed=-[date timeIntervalSinceNow])<FLAREDURATION){
		f=elapsed/FLAREDURATION;
		float s=.97+3*pow(f-0.1,2);
		CGAffineTransform newTransform=CGAffineTransformConcat(transform,CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s,1/s),-size.width/2 + size.width/2*s,-size.height/2+size.height/2*s));
		CGSSetWindowAlpha(conn,[self windowNumber],pow(1-f,2));
		CGSSetWindowTransform(conn,[self windowNumber], newTransform); 
	}
}

#define SHRINKDURATION 0.333f
- (void)shrink:(id)sender{
	//QSLog(@"old shrink");
	CGSConnection conn = _CGSDefaultConnection();
	CGAffineTransform transform;
	CGSGetWindowTransform(conn,[self windowNumber], &transform); 
	NSSize size=[self frame].size;
	float f;
	NSDate *date=[NSDate date];
	
	float elapsed;
	while ((elapsed=-[date timeIntervalSinceNow])<FLAREDURATION){
		f=elapsed/FLAREDURATION;
		//float s=1+3*pow(f,4);
		
		float s=pow(1-f,4);
		CGAffineTransform newTransform=CGAffineTransformConcat(transform,CGAffineTransformTranslate(CGAffineTransformMakeScale(1/s,1/s),-size.width/2 + size.width/2*s,-size.height/2+size.height/2*s));
		CGSSetWindowAlpha(conn,[self windowNumber],pow(1-f,2));
		CGSSetWindowTransform(conn,[self windowNumber], newTransform); 
		usleep(10000);
	}
}

#define FOLDDURATION 0.333f
- (void)fold:(id)sender{
	CGSConnection conn = _CGSDefaultConnection();
	CGAffineTransform transform;
	CGSGetWindowTransform(conn,[self windowNumber], &transform); 
	NSSize size=[self frame].size;
	float f;
	NSDate *date=[NSDate date];
	
	float elapsed;
	while ((elapsed=-[date timeIntervalSinceNow])<FOLDDURATION){
		f=elapsed/FOLDDURATION;
		//float s=1+3*pow(f,4);
		
		float s=pow(1-f,2);
		CGAffineTransform modTransform=CGAffineTransformMakeScale(1/s,1);
		modTransform=CGAffineTransformTranslate(modTransform,-size.width/2 + size.width/2*s,0);
		CGAffineTransform newTransform=CGAffineTransformConcat(transform,modTransform);
		CGSSetWindowAlpha(conn,[self windowNumber],s);
		//QSLog(@"sc %f",s);
		CGSSetWindowTransform(conn,[self windowNumber], newTransform); 
	}
	
}

#define FLIPDURATION 0.15f
- (void)flip:(id)sender{
	CGSConnection conn = _CGSDefaultConnection();
	
	
	CGAffineTransform transform;
	CGSGetWindowTransform(conn,[self windowNumber], &transform); 
	NSSize size=[self frame].size;
	float f;
	NSDate *date=[NSDate date];
	
	float elapsed;
	while ((elapsed=-[date timeIntervalSinceNow])<FLIPDURATION){
		f=elapsed/FLIPDURATION;	
		f=cos(f*M_PI_2);
		float s=pow(f,2);
		CGAffineTransform modTransform=CGAffineTransformMakeScale(1/s,1);
		modTransform=CGAffineTransformTranslate(modTransform,-size.width/2 + size.width/2*s,0);
		CGAffineTransform newTransform=CGAffineTransformConcat(transform,modTransform);
		CGSSetWindowTransform(conn,[self windowNumber], newTransform); 
		usleep(10000);
	}
	date=[NSDate date];
	while ((elapsed=-[date timeIntervalSinceNow])<FLIPDURATION){
		f=elapsed/FLIPDURATION;
		f=sin(f*M_PI_2);
		float s=pow(f,2);
		
		CGAffineTransform modTransform=CGAffineTransformMakeScale(1/s,1);
		modTransform=CGAffineTransformTranslate(modTransform,-size.width/2 + size.width/2*s,0);
		CGAffineTransform newTransform=CGAffineTransformConcat(transform,modTransform);
		CGSSetWindowTransform(conn,[self windowNumber], newTransform); 
		usleep(10000);
	}
	
}


@end

@implementation QSWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag{
	
	
	
    NSWindow* result = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
  	//QSLog(@">%@ %d",result,aStyle);
	//[self setBackgroundColor: [NSColor clearColor]]; //colorWithCalibratedWhite:0.75 alpha:0.5]];
	// [self setBackgroundColor: [NSColor clearColor]];
    //[self setOpaque:NO];
	// [self center];
    [self setMovableByWindowBackground:YES];
    [self setHasShadow:YES];
    [self setLevel:NSNormalWindowLevel];
    
	//[self setBottomCornerRounded:YES];
	
    //[self setLevel:26];
    [self setShowOffset:NSMakePoint(0,50)];
    [self setHideOffset:NSMakePoint(0,-50)];
	//   QSLog(@"%@",self);
	
    trueRect=contentRect;
	//  logRect([[self _borderView]frame]);
	//  QSLog(@"%@",[self _borderView]);
    return result;
}

- (void)dealloc
{
    [helper release];
    [properties release];
    [eventDelegates release];
	
    helper = nil;
    properties = nil;
    eventDelegates = nil;
    [super dealloc];
}


- (NSRect)constrainFrameRect:(NSRect)frameRect toScreen:(NSScreen *)aScreen{
    return frameRect;
}
- (BOOL)makeFirstResponder:(NSResponder *)aResponder{
    BOOL responderChanged=[super makeFirstResponder:aResponder];
    if(responderChanged && [[self delegate]respondsToSelector:@selector(firstResponderChanged:)])
        [[self delegate]firstResponderChanged:aResponder];
    return responderChanged;    
}

- (void)sendEvent:(NSEvent *)theEvent{
//	[self retain];
    if (delegatesEvents && [[self delegate]respondsToSelector:@selector(shouldSendEvent:)] && ![[self delegate] shouldSendEvent:theEvent])
        return;
	if (eventDelegates){
		foreach(eDelegate,eventDelegates){
			if ([eDelegate respondsToSelector:@selector(shouldSendEvent:)] 
				&& ![eDelegate shouldSendEvent:theEvent])
				return;
		}
	}
    [super sendEvent:theEvent];
//	[self release];
}

- (void)reallySendEvent:(NSEvent *)theEvent{
    [super sendEvent:theEvent];
}

- (NSTimeInterval)animationResizeTime:(NSRect)newFrame{
    return MAX([super animationResizeTime:newFrame]/3,0.125);
}

-(BOOL)acceptsFirstResponder{
    return YES;
}

-(BOOL)canBecomeKeyWindow{
    return YES;
}


-(BOOL)canBecomeMainWindow{
    return YES;
}
/*
 - (void)performClose:(id)sender{ 
	 // ***warning   * implement normal close
	 [[self delegate]windowShouldClose:(id)sender
		 [self orderOut:sender];
}
*/
- (void)performMiniaturize:(id)sender{
    [self miniaturize:sender];
}


- (void)orderOut:(id)sender{
    [NSApp preventWindowOrdering];
    if ([self isVisible] && [[NSUserDefaults standardUserDefaults]boolForKey:kUseEffects]){
		[self hideThreaded:sender];	
	}
	else
        [super orderOut:sender];
}

- (void)reallyOrderFront:(id)sender{
	[super orderFront:sender];
}

- (void)reallyOrderOut:(id)sender{
	[super orderOut:sender];
}

/*
 - (void)orderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWindowNumber{
	 // QSLog(@"%d,%d %@",place, otherWindowNumber,self);
	 [super orderWindow:(NSWindowOrderingMode)place relativeTo:(int)otherWindowNumber];
 }
 */
- (void)orderFront:(id)sender{
    if ([self isVisible] || fastShow ||![[NSUserDefaults standardUserDefaults]boolForKey:kUseEffects]){
		[self setAlphaValue:1.0];
		[super orderFront:sender];
    }else{
        [self setAlphaValue:0.0];
        [super orderFront:sender];
		[super display];
        [self showThreaded:self];
        //  [NSThread detachNewThreadSelector:@selector(showThreaded:) toTarget:self withObject:sender];
    }
}

- (void)makeKeyAndOrderFront:(id)sender{
    if ([self isVisible] || fastShow ||  ![[NSUserDefaults standardUserDefaults]boolForKey:kUseEffects]){
		[self setAlphaValue:1.0];
		[super makeKeyAndOrderFront:sender];
    }else{
		[self setAlphaValue:0.0];
        [super makeKeyAndOrderFront:sender];
		// [self showThreaded:self];
		//[self showThreaded:self];
		
		//        [self showThreaded:self];
		
        [self showThreaded:self];
		//     [NSThread detachNewThreadSelector:@selector(showThreaded:) toTarget:self withObject:sender];
    }
	
}
/*
 - (void)setFrame:(NSRect)frameRect display:(BOOL)displayFlag animate:(BOOL)animationFlag{
	 [super setFrame:frameRect display:displayFlag animate:animationFlag];
	 [super setFrame:frameRect display:displayFlag];
 }
 */

- (void)finishShow:(id)sender{
    [self setAlphaValue:1.0];
    [self display];
	if ([self drawers])
		[self performSelector:@selector(_unhideAllDrawers)];
	
	[self setHelper:nil];
}


- (void)performEffect:(NSDictionary *)effect{
	id hl=[QSWindowAnimation effectWithWindow:self attributes:effect];
	[hl startAnimation];
}






- (void)showWithEffect:(id)showEffect{
    trueRect=[self frame];
	
	//QSLog(@"effect",showEffect);
	if (!showEffect)
		showEffect=[self showEffect];
	
	if (!showEffect){
		showEffect=[NSDictionary dictionaryWithObjectsAndKeys:@"QSDefaultGrowEffect",@"transformFn",@"show",@"type",[NSNumber numberWithFloat:0.2],@"duration",nil];
		
	}
	if (showEffect){
		//[self disableScreenUpdatesUntilFlush];
		id hl=[QSWindowAnimation effectWithWindow:self attributes:showEffect];
		[hl setDelegate:self];
	
	//	[hl setTarget:self];
	//	[hl setAction:@selector(finishShow:)];
		[hl startAnimation];
	}else{
		[self setFrame:NSOffsetRect(trueRect,showOffset.x,showOffset.y)  display:YES animate:NO];
		
		[[self helper] setTarget:self];
		[[self helper] setAction:@selector(finishShow:)];
		[[self helper] _resizeWindow:self toFrame:trueRect alpha:1.0 display:YES];
		//QSLog(@"show");
	}
	return;
	
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	//	QSLog(@"orderfront!");
    [NSThread setThreadPriority:1.0];
    if (!isMoving)
        trueRect=[self frame];
    isMoving++;
    
	//   QSLog(@"orderfronta");
	//   logRect(NSOffsetRect(trueRect,showOffset.x,showOffset.y));
    [self setFrame:NSOffsetRect(trueRect,showOffset.x,showOffset.y)  display:YES animate:NO];
    
	//    QSLog(@"orderfrontb");
    [self setFrame:trueRect alphaValue:1.0 display:NO animate:YES];
    
	//    QSLog(@"orderfront");
    [self setAlphaValue:1.0];
    [self display];
	if ([self drawers])
		[self performSelector:@selector(_unhideAllDrawers)];
    isMoving--;
    [pool release];
}
- (IBAction) showThreaded:(id)sender{
	[self showWithEffect:[self showEffect]];
}
- (BOOL)animationIsValid{return !animationInvalid;}

- (void)animationDidEnd:(NSAnimation*)animation{	
	NSString *type=[[(QSWindowAnimation *)animation attributes]valueForKey:@"type"];
	if ([type isEqualToString:@"hide"]){
		[self finishHide:animation];
	}else if ([type isEqualToString:@"show"]){
		[self finishShow:animation];
	}
}
- (void)finishHide:(id)sender{	
	[super orderOut:sender];
    if (hadShadow){
		[self setHasShadow:YES];
	}
	[self setFrame:trueRect display:NO animate:NO];
    [self setAlphaValue:0.0];
	[self setHelper:nil];
	
}

- (IBAction) hideThreaded:(id)sender{
	[self hideWithEffect:[self hideEffect]];
}
	
- (void)hideWithEffect:(id)hideEffect{
	[self retain];
	//  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//if (!helper){
	if ([self drawers])
		[self performSelector:@selector(_hideAllDrawers)];
	
    trueRect=[self frame];
	hadShadow=[self hasShadow];
	
    [self setHasShadow:NO];
	if (!hideEffect){
		hideEffect=[NSDictionary dictionaryWithObjectsAndKeys:@"QSDefaultShrinkEffect",@"transformFn",@"hide",@"type",[NSNumber numberWithFloat:0.2],@"duration",nil];

	}
	if (hideEffect){
		
		id hl=[QSWindowAnimation effectWithWindow:self attributes:hideEffect];
		[hl setDelegate:self];
		[hl startAnimation];
		
	}else{
		[[self helper] setTarget:self];
		[[self helper] setAction:@selector(finishHide:)];
		[[self helper] _resizeWindow:self toFrame:NSOffsetRect(trueRect,hideOffset.x,hideOffset.y) alpha:0.0 display:YES];
	}
	return;
	//}
    if (isMoving){
        animationInvalid=YES;
        NSDate *startDate=[NSDate date];
        while (isMoving && ([startDate timeIntervalSinceNow]>-1))
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    // [NSThread setThreadPriority:0.0];
    trueRect=[self frame];

    if ([self drawers])
    [self performSelector:@selector(_hideAllDrawers)];

    [self setFrame:NSOffsetRect(trueRect,hideOffset.x,hideOffset.y) alphaValue:0.0 display:NO animate:YES];
    [self setFrame:trueRect display:NO animate:NO];
    [super orderOut:self];
    if (hadShadow)[self setHasShadow:YES];
    [self setAlphaValue:1.0];
    animationInvalid=NO;
	//   [pool release];
	[self release];
}

#define RESIZE_SIZE 16

- (NSPoint)hideOffset { return hideOffset; }
- (void)setHideOffset:(NSPoint)newHideOffset {
    hideOffset = newHideOffset;
}

- (NSPoint)showOffset { return showOffset; }
- (void)setShowOffset:(NSPoint)newShowOffset {
    showOffset = newShowOffset;
}

- (char)_hasMainAppearance{
    return YES;
}


- (NSImage *) _gradientImage{
    return nil;
}

- (char)_scalesBackgroundHorizontally{
    return NO;
}
- (char)_hasGradientBackground{
    return YES;
}

- (BOOL)isKeyWindow{
    return [super isKeyWindow] && !liesAboutKey;
}


-(void)fakeResignKey{
	
	NSDisableScreenUpdates();
	
	[super orderOut:self];
	[super orderFront:self];	
	NSEnableScreenUpdates();
}


- (bool)liesAboutKey { return liesAboutKey; }
- (void)setLiesAboutKey:(bool)flag {
    liesAboutKey = flag;
}

- (bool)fastShow { return fastShow; }
- (void)setFastShow:(bool)flag {
    fastShow = flag;
}
- (bool)delegatesEvents { return delegatesEvents; }
- (void)setDelegatesEvents:(bool)flag {
    delegatesEvents = flag;
}

- (QSMoveHelper *)helper {
	if (!helper)
		[self setHelper:[[[QSMoveHelper alloc]init]autorelease]];
	return helper;
}

- (void)setHelper:(QSMoveHelper *)aHelper {
    if (helper != aHelper) {
		//QSLog(@"sethelper %p",aHelper);
        [helper release];
        helper = [aHelper retain];
    }
}


- (NSMutableDictionary *)mutableProperties {
	if (!properties){
		properties=[[NSMutableDictionary alloc]init];
	}else if (![properties isKindOfClass:[NSMutableDictionary class]]){
		[properties autorelease];
		properties=[properties mutableCopy];
	}
	return [[properties retain] autorelease];
}

- (NSMutableDictionary *)properties {
	return [[properties retain] autorelease];
}



- (id)windowPropertyForKey:(NSString *)key{return[properties objectForKey:key];}

- (void)setWindowProperty:(id)prop forKey:(NSString *)key{
	if (!key)return;
	if (prop)
		[[self mutableProperties]setObject:prop forKey:key];
	else 
		[[self mutableProperties]removeObjectForKey:key];
}

- (id)hideEffect { return [properties objectForKey:kQSWindowHideEffect]; }

- (void)setHideEffect:(id)aHideEffect{
	[self setWindowProperty:aHideEffect forKey:kQSWindowHideEffect];
}


- (id)showEffect { return [properties objectForKey:kQSWindowShowEffect]; }

- (void)setShowEffect:(id)aShowEffect{
	[self setWindowProperty:aShowEffect forKey:kQSWindowShowEffect];

}


- (void)setProperties:(NSMutableDictionary *)newProperties{
    [properties autorelease];
    properties = [newProperties retain];
}

- (void)addEventDelegate:(id)eDelegate{
	if (!eventDelegates)
		eventDelegates=[[NSMutableArray alloc]init];
	[eventDelegates addObject:eDelegate];
}

-(void)removeEventDelegate:(id)eDelegate{
	[eventDelegates removeObject:eDelegate];
	if (![eventDelegates count]){
		[eventDelegates release];
		eventDelegates=nil;
	}
}


@end

@implementation QSBorderlessWindow
- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag{
    if ((self = [super initWithContentRect:contentRect styleMask:NSNonactivatingPanelMask|NSBorderlessWindowMask | NSClosableWindowMask backing:bufferingType defer:YES])){
   
		[self setBackgroundColor: [NSColor clearColor]];
        [self setOpaque:NO];
    }
    return self;
}
@end

@implementation NSWindow (CGSTransitionRedraw)
- (void) displayWithTransition:(CGSTransitionType)type option:(CGSTransitionOption)option duration:(float)duration;
{
	CGSConnection cgs=_CGSDefaultConnection();
	int handle;
	CGSTransitionSpec spec;
	spec.unknown1=0;
	spec.type=type;
	spec.option=option | CGSTransparentBackgroundMask;
	spec.wid=[self windowNumber];
	spec.backColour=NULL;
	CGSNewTransition(cgs, &spec, &handle);
	[self display];
	CGSInvokeTransition(cgs, handle, duration);
	usleep((useconds_t)(duration * 1000000));
	//[NSTimer scheduledTimerWithTimeInterval:duration target:<#(id)aTarget#> selector:<#(SEL)aSelector#> userInfo:<#(id)userInfo#> repeats:<#(BOOL)yesOrNo#>
	QSLog(@"end"); 
	CGSReleaseTransition(cgs, handle);
}
@end
