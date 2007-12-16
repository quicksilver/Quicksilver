

#import "QSIconLoader.h"


#import "QSObject.h"


@implementation QSIconLoader

+ (id)loaderWithArray:(NSArray *)newArray{
	return [[[self alloc]initWithArray:newArray] autorelease];
}	
- (id)initWithArray:(NSArray *)newArray{
    if ((self=[super init])){
		//loadRange={0,0};	
		array=[newArray retain];
		loaderValid=YES;
	}
	return self;
}
-(void)dealloc{
	//	if (VERBOSE)QSLog(@"dealloc loader");
	[self setDelegate:nil];
	[array release];	
	array=nil;
	[super dealloc];
}
-(void)invalidate{
	loaderValid=NO;	
}
-(void)loadIcons{
    //return nil;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[[self retain]autorelease];
    loadThread=[NSThread currentThread];
	//  [NSThread setThreadPriority:0.0];
    NSArray *sourceArray=nil;
    
    BOOL rangeValid=NO;
	// BOOL arrayValid=NO;
    int i,j,m;
    id <NSObject,QSObject> thisObject;
    while (!(rangeValid) && loaderValid){
		
        loadRange=newRange;
 		rangeValid=YES;
		
        for (i=0;i<=loadRange.length && loaderValid && rangeValid;i++){     
            m=loadRange.location;
            j=i;
			if (modulation){
				j=loadRange.length/2-j/2+j*(j%2); //Center Modulation
				j=loadRange.length/2-j/2+j*(j%2); //Center Modulation
				j=loadRange.length/2-j/2+j*(j%2); //Center Modulation
			}
            m+=j; 
			if (m<0 || m>=[array count]) continue;
            thisObject=[array objectAtIndex:m];
            if (![thisObject isKindOfClass:[NSNull class]] && ![thisObject iconLoaded]){
				[thisObject loadIcon];
				[delegate iconLoader:self loadedIndex:m inArray:sourceArray]; 
			}
			
            rangeValid=NSEqualRanges(loadRange,newRange);
        }
    }
	//	[delegate iconLoader:self finishedLoadingArray:sourceArray]; 
	
	loadThread=nil;
    [pool release];
}

-(void)loadIconsInRange:(NSRange)range{
	if (!NSEqualRanges(range,newRange)){
		newRange=range;	
		//QSLog(@"%d,%d",range,NSMaxRange(range));
		
		if (!loadThread) [NSThread detachNewThreadSelector:@selector(loadIcons) toTarget:self withObject:nil];
	}
}


- (NSObject *)delegate { return [[delegate retain] autorelease]; }

- (void)setDelegate:(NSObject *)aDelegate {
    if (delegate != aDelegate) {
		
		if (delegate)
			[[NSNotificationCenter defaultCenter] removeObserver:self];
        [delegate release];
        delegate = [aDelegate retain];
		
		if (aDelegate){
			//QSLog(@"obsorve %@",aDelegate);
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(cancelLoading:)
														 name:QSIconLoaderDelegateCanceled object:aDelegate];
		}
	}
}
+ (void)invalidateLoaderForDelegate:(id)delegate{
	//QSLog(@"invalidate %@",delegate);
	[[NSNotificationCenter defaultCenter] postNotificationName:QSIconLoaderDelegateCanceled  object:delegate];
}
-(BOOL)cancelLoading:(NSNotification *)notif{
	//QSLog(@"invalidate");
	[self invalidate];
	return YES;
}

-(BOOL)isLoading{
	return loadThread!=nil;
}

- (int)modulation { return modulation; }
- (void)setModulation:(int)newModulation
{
    modulation = newModulation;
}


@end
/*
 
@implementation QSIconLoader (NSTableViewConvenience)
+(QSIconLoader *)loaderForArray:(NSArray *)array inTable:(NSTableView *)table{
	QSIconLoader *loader=[[[QSIconLoader alloc]initWithArray:array]autorelease];
	[loader setDelegate:table];
	[loader setArray:array];
	
	return loader;
}
@end
*/