#import "QSMnemonics.h"

@implementation QSMnemonics
+ (id)sharedInstance {
	static QSMnemonics *_sharedInstance = nil;
	if (!_sharedInstance) {
		_sharedInstance = [[[self class] allocWithZone:nil] init];
	}
	return _sharedInstance;
}

- (id)init {
	if (!(self = [super init]) ) return nil;
	writeTimer = nil;
	recentMnemonics = [NSMutableDictionary dictionary];
	mnemonics = [[NSMutableDictionary alloc] initWithContentsOfFile:[pMnemonicStorage stringByStandardizingPath]];
	[mnemonics removeObjectsForKeys:[NSArray arrayWithObjects:@"defined", nil]];

	if (!mnemonics)
		mnemonics = [[NSMutableDictionary alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"DefaultMnemonics" ofType:@"plist"]];
	if (!mnemonics)
		mnemonics = [[NSMutableDictionary alloc] initWithCapacity:1];
	if (!(objectMnemonics = [mnemonics objectForKey:@"implied"]) )
		[mnemonics setObject:(objectMnemonics = [NSMutableDictionary dictionaryWithCapacity:1]) forKey:@"implied"];
	if (!(abbrevMnemonics = [mnemonics objectForKey:@"abbreviation"]) )
		[mnemonics setObject:(abbrevMnemonics = [NSMutableDictionary dictionaryWithCapacity:1]) forKey:@"abbreviation"];

#ifdef DEBUG
	if (DEBUG_STARTUP)
		NSLog(@"Loaded %ld implied and %ld defined mnemonics", (long)[objectMnemonics count], (long)[abbrevMnemonics count]);
#endif
	write_queue = dispatch_queue_create("quicksilver.mnemonics.write", DISPATCH_QUEUE_SERIAL);
	return self;
}

- (NSDictionary *)objectMnemonics {
	return objectMnemonics;
}

- (NSDictionary *)objectMnemonicsForID:(NSString *)key {
	return [objectMnemonics objectForKey:key];
}

- (NSArray *)abbrevMnemonicsForString:(NSString *)key {
	return [abbrevMnemonics objectForKey:key];
}

- (void)removeAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key {
	if (!mnem) return;
	[[abbrevMnemonics objectForKey:mnem] removeObject:key];
	[self setWriteTimer];
}

- (BOOL)addAbbrevMnemonic:(NSString *)mnem forObject:(QSObject *)object {
	return [self addAbbrevMnemonic:mnem forObject:object relativeToID:nil immediately:NO];
}

- (BOOL)addAbbrevMnemonic:(NSString *)mnem forObject:(QSObject *)object immediately:(BOOL)immediately {
	return [self addAbbrevMnemonic:mnem forObject:object relativeToID:nil immediately:immediately];
}

- (BOOL)addAbbrevMnemonic:(NSString *)mnem forObject:(QSObject *)object relativeToID:(NSString *)above immediately:(BOOL)immediately {
    
    if (![self checkForValidObject:object withMnemonic:mnem]) {
        return NO;
    }
    
    NSString *key = [object identifier];
    if (!key.length) {
        return NO;
    }
    
    
    // Abbreviations are case insensitive
    mnem = [mnem lowercaseString];
    

	NSMutableArray *objectEntry;
	if (!(objectEntry = [abbrevMnemonics objectForKey:mnem]) ) {
		objectEntry = [NSMutableArray arrayWithCapacity:1];
		[abbrevMnemonics setObject:objectEntry forKey:mnem];
	}
	//NSLog(@"recent %@ %@", [recentMnemonics objectForKey:mnem] , key);
	NSInteger index = [objectEntry indexOfObject:above];

//	if (VERBOSE) NSLog(@"%@", [objectEntry description]);

	if (index != NSNotFound) {
		if (![[recentMnemonics objectForKey:mnem] isEqual:key] || immediately)
            index++; //Put after topmost unless is most recently used
		[objectEntry insertObject:key atIndex:index];
	} else {
		if ([[recentMnemonics objectForKey:mnem] isEqualToString:key] || immediately) { //Put after topmost unless is most recently used

			[objectEntry removeObject:key];
			[objectEntry insertObject:key atIndex:0];
		//	NSLog(@"MAKEDEFAULT %@", key);
		} else if (key) {
			if (![objectEntry containsObject:key]) {
				[objectEntry addObject:key];
			}
		}
	}

	//if (VERBOSE) NSLog(@"%@ %@ %@ %d\r%@", mnem, key, above, index, [objectEntry description]);

	[recentMnemonics setObject:key forKey:mnem];

	[self setWriteTimer];
    return YES;
}

- (void)removeObjectMnemonic:(NSString *)mnem forID:(NSString *)key {
	if (!mnem) mnem = @"";
	if (!key) return;
	[[objectMnemonics objectForKey:key] removeObjectForKey:mnem];
	[self setWriteTimer];
}

- (void)setWriteTimer {
	if ([writeTimer isValid])
		[writeTimer invalidate];
	writeTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(writeItems:) userInfo:nil repeats:NO];
}

- (BOOL)checkForValidObject:(QSObject *)object withMnemonic:(NSString *)mnem {
    if (!object || ![object identifier] || [[object identifier] isEqualToString:@""]) {
        return NO;
    }
    
    if (![QSDefaultObjectRanker rankedObjectsForAbbreviation:mnem options:@{QSRankingObjectsInSet : @[object], QSRankingIncludeOmitted : [NSNumber numberWithBool:YES]}].count) {
        // the mnemonic doesn't match the object, so don't add it
        // WARNING: we could set up a synonym?
        return NO;
    }
    return YES;
}

- (BOOL)addObjectMnemonic:(NSString *)mnem forObject:(QSObject *)object {
    
    if (![self checkForValidObject:object withMnemonic:mnem]) {
        return NO;
    }
    
    NSString *key = [object identifier];
	if (!mnem) mnem = @"";
    
    mnem = [mnem lowercaseString];

	NSMutableDictionary *objectEntry;
	if (!(objectEntry = [objectMnemonics objectForKey:key]) ) {
		objectEntry = [NSMutableDictionary dictionaryWithCapacity:1];
		[objectMnemonics setObject:objectEntry forKey:key];
	}
	[objectEntry setObject:[NSNumber numberWithInteger:([[objectEntry objectForKey:mnem] integerValue]) +1] forKey:mnem];
	
	[self setWriteTimer];
    return YES;
}

- (void)writeItems:(id)sender {
	dispatch_async(write_queue, ^{
		NSFileManager *manager = [NSFileManager defaultManager];
		NSString *path = [pMnemonicStorage stringByStandardizingPath];
		if (![manager fileExistsAtPath:[path stringByDeletingLastPathComponent] isDirectory:nil])
			[manager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:NO attributes:nil error:nil];
		//NSLog(@"Mnemonics:%@", mnemonics);
		[self->mnemonics writeToFile:path atomically:YES];
	});
}

@end
