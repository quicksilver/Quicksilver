//
//  QSSeparatorObject.m
//  Quicksilver
//
//  Created by Alcor on Fri Jun 11 2004.

//

#import "QSSeparatorObject.h"


@implementation QSSeparatorObject
+(id)separator{
	return [[[self alloc]initWithName:nil]autorelease];
}
+(id)separatorWithName:(NSString *)newName{
	return [[[self alloc]initWithName:newName]autorelease];
}
-(id)initWithName:(NSString *)newName{
	if ((self=[super init])){
		name=[newName retain];
	}
	return self;
}
- (void)dealloc{
	[name release];
	name=nil;
	[super dealloc];
}

- (NSString *)name{ return name?name:@"-";}
@end
