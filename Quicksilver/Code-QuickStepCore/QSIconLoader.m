#import "QSIconLoader.h"
#import "QSObject.h"

@implementation QSIconLoader

+ (id)loaderWithArray:(NSArray *)newArray {
	return [[self alloc] initWithArray:newArray];
}

- (id)initWithArray:(NSArray *)newArray {
	if (self = [super init]) {
		objectArray = newArray;
		loaderValid = YES;
        isLoading = NO;
	}
	return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)invalidate {
    isLoading = NO;
	loaderValid = NO;
}

- (void)loadIcons {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        BOOL rangeValid = NO;
        
        NSUInteger i, j, m;
        id <NSObject, QSObject> thisObject;
        while (!(rangeValid) && loaderValid) {
            isLoading = YES;
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
                if (![objectArray count] || m >= [objectArray count]) continue;
                thisObject = [objectArray objectAtIndex:m];
                
                if (![thisObject isKindOfClass:[NSNull class]] && ![thisObject iconLoaded]) {
                    [thisObject loadIcon];
                    [delegate iconLoader:self loadedIndex:m inArray:objectArray];
                }
                rangeValid = NSEqualRanges(loadRange, newRange);
            }
        }
        isLoading = NO;
    });
}

- (void)loadIconsInRange:(NSRange)range {
	if (!NSEqualRanges(range, newRange) ) {
		newRange = range;
        [self loadIcons];
	}
}

- (NSObject *)delegate { return delegate;  }
- (void)setDelegate:(NSObject *)aDelegate {
	if (delegate != aDelegate) {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		if (delegate)
			[nc removeObserver:self];
		delegate = aDelegate;
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

- (BOOL)isLoading { return isLoading; }

- (NSInteger) modulation { return modulation;  }

- (void)setModulation:(NSInteger)newModulation {
	modulation = newModulation;
}

@end
