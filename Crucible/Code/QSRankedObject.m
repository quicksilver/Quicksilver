

#import "QSRankedObject.h" 

@implementation QSRankedObject 
/*
 + (NSMutableArray *)rankedArrayWithObjects:(id *)objects scores:(float *)scores strings:(id *)strings count:(int)count{
	 NSMutableArray *rankedArray=[NSMutableArray arrayWithCapacity:count];
	 int i;
	 for (i=0;i<count;i++){
		 NSString *matched=strings[i];
		 QSLog(@"rai %@ %@", objects[i],[matched retain]);
		 [rankedArray addObject: [[QSRankedObject alloc]initWithObject:objects[i] score:scores[i] string:nil]];
	 }
	 [rankedArray makeObjectsPerformSelector:@selector(release)];
	 return rankedArray;
 }
 
 */
+ (id)rankedObjectWithObject:(id)newObject matchString:(NSString *)matchString order:(int)newOrder score:(float)newScore{
    return [[[QSRankedObject alloc]initWithObject:(id)newObject matchString:matchString order:(int)newOrder score:(float)newScore]autorelease];
}


- (NSComparisonResult)scoreCompare:(QSRankedObject *)compareObject{
	if (order == compareObject->order){
		
		if (score > compareObject->score)
			return NSOrderedAscending;
		else if (score < compareObject->score)
			return NSOrderedDescending;
		
	}else{
		return order - compareObject->order;	
	}
	
    return [self nameCompare:compareObject];
}


- (NSComparisonResult)nameCompare:(QSRankedObject *)compareObject{
    return [object nameCompare:compareObject->object];
	
}

- (NSComparisonResult)smartCompare:(QSRankedObject *)compareObject{
    if (score>=1.0 || compareObject->score >=1.0) return [self scoreCompare:compareObject];
    else return [object nameCompare:compareObject->object];
}

- (BOOL)isEqual:(id)anObject{
    return [anObject isEqual:object];
}
- (BOOL)respondsToSelector:(SEL)aSelector{
    if ([super respondsToSelector:aSelector]) return YES;
   if ([object respondsToSelector:aSelector]) return YES;
  // QSLog(@"%@ does not respond to %@",object,NSStringFromSelector(aSelector));
   return NO;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	//  QSLog(@"forward %@",invocation);
    if ([object respondsToSelector:[invocation selector]])
        [invocation invokeWithTarget:object];
    else
        [self doesNotRecognizeSelector:[invocation selector]];
}

-(NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
    NSMethodSignature *sig=[[self class] instanceMethodSignatureForSelector:sel];
    if (sig) return sig;
    return [object methodSignatureForSelector:sel];
}

- (id)initWithObject:(id)newObject matchString:(NSString *)matchString order:(int)newOrder score:(float)newScore{
    if ((self=[super init])){
        object=[newObject retain];
		order=newOrder;
        score=newScore;
        rankedString=[matchString retain]; 
		
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self=[self initWithObject:[coder decodeObjectForKey:@"object"]
				  matchString:[coder decodeObjectForKey:@"string"]
						order:[coder decodeIntForKey:@"order"]
						score:[coder decodeFloatForKey:@"score"]];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:object forKey:@"object"];
    [coder encodeObject:rankedString forKey:@"string"];
    [coder encodeFloat:score forKey:@"score"];
}



- (void)dealloc{
    [object release];
	[rankedString release];
    [super dealloc];
}
- (NSString *)displayName {
	// if (rankedString) QSLog(@"rao %@",rankedString);
    if (rankedString) return rankedString;
    return [object displayName];
}
- (NSString *)description{return [NSString stringWithFormat:@"[%@ %f]",object,score];}



- (float)score { return score; }
- (void)setScore:(float)newScore {
    score = newScore;
}

- (BOOL) enabled {
	return [(QSObject*)object enabled];	
}

- (id)object { return object; }

- (void)setObject:(id)newObject {
    [object release];
    object = [newObject retain];
}

- (int)order { return order; }
- (void)setOrder:(int)newOrder
{
    order = newOrder;
}


- (NSString *)rankedString { return rankedString; }

- (void)setRankedString:(NSString *)newRankedString {
    [rankedString release];
    rankedString = [newRankedString retain];
}

- (id)valueForKey:(NSString *)key{
	return [object valueForKey:key];	
}

- (void)setValue:(id)value forKey:(NSString *)key{
	[object setValue:value forKey:key];
}

- (NSMenu *)rankMenuWithTarget:(NSView *)target{
    NSMenu *menu=[[[NSMenu alloc]initWithTitle:@"RankMenu"]autorelease];
	
    NSMenuItem *item;
	
	int myOrder=[self order];
	NSString *title=[NSString stringWithFormat:@"Score: %.0f",[self score]*100];
	if (myOrder!=NSNotFound)
		title=[NSString stringWithFormat:@"Rank: %d, %@",myOrder+1,title];
	
	item=(NSMenuItem *)[menu addItemWithTitle:title action:NULL keyEquivalent:@""];
	[item setTarget:nil];
	[menu addItem:[NSMenuItem separatorItem]];
	
	if (myOrder!=0){
		item=(NSMenuItem *)[menu addItemWithTitle:@"Make Default" action:@selector(defineMnemonicImmediately:) keyEquivalent:@""];
		[item setTarget:target];
	}else{
		item=(NSMenuItem *)[menu addItemWithTitle:@"Remove Default" action:@selector(removeMnemonic:) keyEquivalent:@""];
		[item setTarget:target];
	}
	//[self mnemo
	item=(NSMenuItem *)[menu addItemWithTitle:@"Decrease Score" action:@selector(clearMnemonics:) keyEquivalent:@""];
	[item setTarget:target];
	
	
	
	return menu;
}
@end
