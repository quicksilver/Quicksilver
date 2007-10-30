
#import "QSFilteringArrayController.h"
#import <Foundation/NSKeyValueObserving.h>


@implementation QSFilteringArrayController


- (void)clearFilters{
	[filters release];
	filters=nil;
}

- (void)addFilterForKeyPath:(NSString *)string matchingValue:(NSString *)match withCondition:(NSString *)condition{
	if (!filters)filters=[[NSMutableArray alloc]init];
	
	NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
		string,@"keyPath",
		match,@"match",
		condition,@"condition",
		nil];
	
	[filters addObject:dict];
	[self rearrangeObjects];
}


- (NSArray *)arrangeObjects:(NSArray *)objects{
	if (![filters count]){
		return [super arrangeObjects:objects];   
	}
	
	NSMutableArray *matchedObjects = [NSMutableArray arrayWithCapacity:[objects count]];
	
	id item;	
	NSEnumerator *fEnum = [objects objectEnumerator];
	id filter;
	

	id keyPath;
	id condition;
	id value;
	id match;
	
	for (item in objects){
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		
		BOOL valid=YES;
		for (filter in filters){
			keyPath=[filter objectForKey:@"keyPath"];
			value=[item valueForKeyPath:keyPath];
			match=[filter objectForKey:@"match"];
			condition=[filter objectForKey:@"condition"];
			
			if ([value isKindOfClass:[NSString class]]){
				valid = valid && ([value rangeOfString:match options:NSCaseInsensitiveSearch].location != NSNotFound);
			}else if ([value isKindOfClass:[NSArray class]]){
				valid = valid && [value containsObject:match];
			}else{
				valid = valid && [value isEqual:match];
			}
		}
		
		if (valid)[matchedObjects addObject:item];
		[pool release];
	}
	
	return [super arrangeObjects:matchedObjects];
}

- (void)dealloc{
    [self clearFilters];
    [super dealloc];
}



- (NSMutableArray *)filters { return [[filters retain] autorelease]; }
- (void)setFilters:(NSMutableArray *)newFilters
{
    [filters autorelease];
    filters = [newFilters retain];
	[self rearrangeObjects];
}

@end
