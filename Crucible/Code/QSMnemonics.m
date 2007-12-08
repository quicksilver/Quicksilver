

#import "QSMnemonics.h"
#import "QSPaths.h"


@implementation QSMnemonics
+ (id)sharedInstance{
    static QSMnemonics *_sharedInstance = nil;
    if (!_sharedInstance){
        _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    }
    return _sharedInstance;
}
- (id) init{
    if (!(self=[super init])) return nil;
	writeTimer=nil;
	recentMnemonics=[[NSMutableDictionary dictionary]retain];
    mnemonics=[[NSMutableDictionary alloc] initWithContentsOfFile:[pMnemonicStorage stringByStandardizingPath]];
	[mnemonics removeObjectsForKeys:[NSArray arrayWithObjects:@"defined",nil]];
	
    if (!mnemonics)
        mnemonics=[[NSMutableDictionary alloc] initWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"DefaultMnemonics" ofType:@"plist"]];
    if (!mnemonics)
        mnemonics=[[NSMutableDictionary alloc]initWithCapacity:1];
    if (!(objectMnemonics=[mnemonics objectForKey:@"implied"]))
        [mnemonics setObject:(objectMnemonics=[NSMutableDictionary dictionaryWithCapacity:1]) forKey:@"implied"];
    if (!(abbrevMnemonics=[mnemonics objectForKey:@"abbreviation"]))
        [mnemonics setObject:(abbrevMnemonics=[NSMutableDictionary dictionaryWithCapacity:1]) forKey:@"abbreviation"];
	
    
    
	if (DEBUG_STARTUP) 
		QSLog(@"Loaded %d implied and %d defined mnemonics",[objectMnemonics count],[abbrevMnemonics count]);
	
    return self;
}

- (NSDictionary *)objectMnemonics{
    return objectMnemonics;
}
- (NSDictionary *)objectMnemonicsForID:(NSString *)key{
    return [objectMnemonics objectForKey:key];
}

- (NSArray *)abbrevMnemonicsForString:(NSString *)key{
    return [abbrevMnemonics objectForKey:key];
}

- (void)removeAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key{
    if (!mnem)return;
    [[abbrevMnemonics objectForKey:mnem]removeObject:key];
    [self writeItems:self];
}

- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key{
	[self addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key relativeToID:nil immediately:NO];
}

- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key immediately:(BOOL)immediately{
	[self addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key relativeToID:nil immediately:immediately];
}

- (void)addAbbrevMnemonic:(NSString *)mnem forID:(NSString *)key relativeToID:(NSString *)above immediately:(BOOL)immediately{
	if (!key)return;
   if (!mnem)return;
   
    NSMutableArray *objectEntry;
    if (!(objectEntry=[abbrevMnemonics objectForKey:mnem])){
        objectEntry=[NSMutableArray arrayWithCapacity:1];
        [abbrevMnemonics setObject:objectEntry forKey:mnem];
    }
	//QSLog(@"recent %@ %@",[recentMnemonics objectForKey:mnem],key);
	int index=[objectEntry indexOfObject:above];
	
	
//	if (VERBOSE)  QSLog(@"%@",[objectEntry description]);
	
	
	if (index!=NSNotFound){
		if (![[recentMnemonics objectForKey:mnem]isEqual:key] || immediately)index++; //Put after topmost unless is most recently used
		[objectEntry insertObject:key atIndex:index];
	}else{
		if ([[recentMnemonics objectForKey:mnem]isEqualToString:key]||immediately){ //Put after topmost unless is most recently used
			
			[objectEntry removeObject:key];
			[objectEntry insertObject:key atIndex:0];
		//	QSLog(@"MAKEDEFAULT %@",key);
		}else if (key){
			if (![objectEntry containsObject:key]){
				[objectEntry addObject:key];
			}
		}
	}
	
	//if (VERBOSE)  QSLog(@"%@ %@ %@ %d\r%@",mnem,key,above,index,[objectEntry description]);
	
	[recentMnemonics setObject:key forKey:mnem];

	[self writeItems:self];
}


- (void)removeObjectMnemonic:(NSString *)mnem forID:(NSString *)key{
    if (!mnem) mnem=@"";
    if (!key)return;
    [[objectMnemonics objectForKey:key] removeObjectForKey:mnem];
    [self writeItems:self];
}


- (void) setWriteTimer{
	if ([writeTimer isValid])
		[writeTimer invalidate];
	[writeTimer release];
	writeTimer=[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(writeItems:) userInfo:nil repeats:NO];	
	[writeTimer retain];
}
- (void)addObjectMnemonic:(NSString *)mnem forID:(NSString *)key{
    if (!mnem) mnem=@"";
	
    if (!key)return;
    NSMutableDictionary *objectEntry;
    if (!(objectEntry=[objectMnemonics objectForKey:key])){
        objectEntry=[NSMutableDictionary dictionaryWithCapacity:1];
        [objectMnemonics setObject:objectEntry forKey:key];
    }
    [objectEntry setObject:[NSNumber numberWithInt:([[objectEntry objectForKey:mnem]intValue])+1] forKey:mnem];
	//  [self writeItems:self];
	[self setWriteTimer];
}



- (void) writeItems:(id)sender{
    NSFileManager *manager=[NSFileManager defaultManager];
    NSString *path=[pMnemonicStorage stringByStandardizingPath];
    if (![manager fileExistsAtPath:[path stringByDeletingLastPathComponent] isDirectory:nil])
        [manager createDirectoryAtPath:[path stringByDeletingLastPathComponent] attributes:nil];
	//QSLog(@"Mnemonics:%@",mnemonics);
    [mnemonics writeToFile:path atomically:YES];
}

@end
