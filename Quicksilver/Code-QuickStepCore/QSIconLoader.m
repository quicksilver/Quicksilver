#import "QSIconLoader.h"
#import "QSObject.h"

@implementation QSIconLoader

+ (id)loaderWithArray:(NSArray *)newArray {
	return [[[self alloc] initWithArray:newArray] autorelease];
}

- (id)initWithArray:(NSArray *)newArray {
	if (self = [super init]) {
		array = [newArray retain];
		loaderValid = YES;
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[delegate release];
	[array release];
	[loadedIndexes release];
	[super dealloc];
}

- (void)invalidate {
	loaderValid = NO;
}

- (void)loadIcons {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[[self retain] autorelease];
	loadThread = [NSThread currentThread];
	// [NSThread setThreadPriority:0.0];
	NSArray *sourceArray = nil;

	BOOL rangeValid = NO;

	int i, j, m;
	id <NSObject, QSObject> thisObject;
	while (!(rangeValid) && loaderValid) {
		loadRange = newRange;
 		rangeValid = YES;
		for (i = 0; i <= loadRange.length && loaderValid && rangeValid; i++) {
			m = loadRange.location;
			j = i;
			if (modulation) {
				j = loadRange.length/2-j/2+j*(j%2); //Center Modulation
				j = loadRange.length/2-j/2+j*(j%2); //Center Modulation
				j = loadRange.length/2-j/2+j*(j%2); //Center Modulation
			}
			m += j;
			if (m<0 || m >= [array count]) continue;
			thisObject = [array objectAtIndex:m];
			if (![thisObject isKindOfClass:[NSNull class]] && ![thisObject iconLoaded]) {
				[thisObject loadIcon];
				[delegate iconLoader:self loadedIndex:m inArray:sourceArray];
			}
			rangeValid = NSEqualRanges(loadRange, newRange);
		}
	}
	loadThread = nil;
	[pool release];
}

- (void)loadIconsInRange:(NSRange)range {
	if (!NSEqualRanges(range, newRange) ) {
		newRange = range;
		//NSLog(@"%d, %d", range, NSMaxRange(range) );
		if (!loadThread) [NSThread detachNewThreadSelector:@selector(loadIcons) toTarget:self withObject:nil];
	}
}

- (NSObject *)delegate { return delegate;  }
- (void)setDelegate:(NSObject *)aDelegate {
	if (delegate != aDelegate) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		if (delegate)
			[nc removeObserver:self];
		[delegate release];
		delegate = [aDelegate retain];
		if (aDelegate)
			[nc addObserver:self selector:@selector(cancelLoading:) name:QSIconLoaderDelegateCanceled object:aDelegate];
	}
}

+ (void)invalidateLoaderForDelegate:(id)delegate {
	//NSLog(@"invalidate %@", delegate);
	[[NSNotificationCenter defaultCenter] postNotificationName:QSIconLoaderDelegateCanceled object:delegate];
}

- (BOOL)cancelLoading:(NSNotification *)notif {
	//NSLog(@"invalidate");
	[self invalidate];
	return YES;
}

- (BOOL)isLoading { return loadThread != nil; }

- (int) modulation { return modulation;  }

- (void)setModulation:(int)newModulation {
	modulation = newModulation;
}

@end
