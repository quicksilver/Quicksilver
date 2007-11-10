//
//  NSDictionary+BLTRExtensions.m
//  Quicksilver
//
//  Created by Alcor on 3/27/05.

//

#import "NSDictionary+BLTRExtensions.h"


@implementation NSDictionary (ExistingKeys)

- (NSArray *)objectsForExistingKeys:(NSArray *)keys{
	//#warning finish me
	return nil;
}


- (NSArray *)keysSortedByValueUsingDescriptors:(NSArray *)descriptors{
	NSArray *values=[[self allValues]sortedArrayUsingDescriptors:descriptors];
	NSMutableArray *array=[NSMutableArray array];
	foreach(value,values){
		[array addObjectsFromArray:[self allKeysForObject:value]];
	}
	return array;
}


@end


