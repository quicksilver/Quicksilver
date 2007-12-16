//
//  QSIdleWatcher.m
//  Quicksilver
//
//  Created by Alcor on 12/29/04.

//

#import "QSIdleWatcher.h"
#import "QSMacros.h"

extern double CGSSecondsSinceLastInputEvent(unsigned long evType);
double QSCurrentIdleTime(){
    double idleTime = CGSSecondsSinceLastInputEvent(-1);	
    //On MDD Powermacs, the above function will return a large value when the machine is active (-1?).
	if(idleTime >= 18446744000.0) idleTime = 0.0; //18446744073.0
    return(idleTime);
}
@implementation QSIdleWatcher

mSHARED_INSTANCE_CLASS_METHOD

// -1 is all apps
// 0 is time since system came out of sleep?
// 1 is seconds since last mouse click
- (void)test:(id)obj{
	//QSLog(@"tested idler%@",obj);	
}
- (id)init{
	if ((self=[super init])){
		callbacks=[[NSMutableArray alloc]init];
		lastIdle=0.0;
		idleDate=[[NSDate alloc]initWithTimeIntervalSinceNow:0.0];
	}
	return self;
}
- (void)dealloc{
	[idleCheckTimer invalidate];
	[idleCheckTimer release];
	[super dealloc];
}

- (NSDate *)idleDate{
	return idleDate;
}

- (void)performCallback:(NSDictionary *)callback{
	[[callback objectForKey:@"target"]
 performSelector:NSSelectorFromString([callback objectForKey:@"action"]) 
	  withObject:[callback objectForKey:@"argument"]];
}
- (void)scheduleIdleTimer{
	
	if (![callbacks count]) return;
	
	NSNumber *nextFire=[callbacks valueForKeyPath:@"@min.delay"];
	//QSLog(@"log %@",nextFire);
	if (nextFire){
		NSTimeInterval idleRemaining=[nextFire doubleValue]-QSCurrentIdleTime();
		//if (VERBOSE) 
		//QSLog(@"Next Idle in %f (%f)",idleRemaining,QSCurrentIdleTime());
		if (idleRemaining<0.0) idleRemaining=1.0f;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkIdle) object:nil];
		[self performSelector:@selector(checkIdle) withObject:nil afterDelay:idleRemaining];	
	}
}

-(void)checkIdle{
	double idle=QSCurrentIdleTime();
	//	if (idle>=10*MINUTES && lastIdle<10*MINUTES){
	//		if (VERBOSE)QSLog(@"Idle for %f minutes",(float)idle/MINUTES );
	//		[[NSNotificationCenter defaultCenter]postNotificationName:QSIdleNotification object:self];
	//	}
	
	if (idle<lastIdle && lastIdle>1.0f){
		[[NSNotificationCenter defaultCenter]postNotificationName:QSIdleActivityNotification object:idleDate
														 userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithDouble:lastIdle] forKey:@"duration"]];
		//QSLog(@"unidle %f",idle);
		[idleDate release];
		idleDate=[[NSDate alloc]initWithTimeIntervalSinceNow:-idle];
	}
	
	NSExpression *delay = [NSExpression expressionForKeyPath:@"delay"];
	NSPredicate *greaterThanPredicate = [NSComparisonPredicate
    predicateWithLeftExpression:delay
				rightExpression: [NSExpression expressionForConstantValue:[NSNumber numberWithFloat:lastIdle]]
					   modifier:NSDirectPredicateModifier
						   type:NSGreaterThanPredicateOperatorType
						options:0];
	NSPredicate *lessThanPredicate = [NSComparisonPredicate
    predicateWithLeftExpression:delay
				rightExpression:[NSExpression expressionForConstantValue:[NSNumber numberWithDouble:idle]]
					   modifier:NSDirectPredicateModifier
						   type:NSLessThanOrEqualToPredicateOperatorType
						options:0];
	NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
		[NSArray arrayWithObjects:greaterThanPredicate, lessThanPredicate, nil]];
	
	NSArray *shouldHaveFired=[callbacks filteredArrayUsingPredicate:predicate];
	//if (VERBOSE)
	//	QSLog(@"idles matching predicate %@\r%@",predicate,shouldHaveFired);
	
	
	foreach(callback,shouldHaveFired){
		[self performCallback:callback];
		if (![[callback objectForKey:@"repeat"]boolValue])
			[callbacks removeObject:callback];
	}
	
	
		
	lastIdle=idle;
	[self scheduleIdleTimer];
}



- (void)scheduleIdleCall:(id)object performSelector:(SEL)aSelector withObject:(id)anArgument afterIdleFor:(NSTimeInterval)delay repeat:(BOOL)repeat{
	NSDictionary *entry=[NSDictionary dictionaryWithObjectsAndKeys:
		object,@"target",
		NSStringFromSelector(aSelector),@"action",
		[NSNumber numberWithDouble:delay],@"delay",
		[NSNumber numberWithBool:repeat],@"repeat",
		anArgument,@"argument",
		nil];
	[callbacks addObject:entry];
	
	[self scheduleIdleTimer];
}
- (void)cancelPreviousPerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anArgument{
	foreach(callback,callbacks){
		
		if ([aTarget isEqual:[callback objectForKey:@"target"]]
			&& [NSStringFromSelector(aSelector) isEqualToString:[callback objectForKey:@"action"]]
			&& ([anArgument isEqual:[callback objectForKey:@"argument"]] || !anArgument)){
			QSLog(@"removing callback %@",callback);
			[callbacks removeObject:callback];
		}
	}
}
@end


@implementation NSObject (QSIdlePerform)
- (void)performSelector:(SEL)aSelector withObject:(id)anArgument afterIdleFor:(NSTimeInterval)delay repeat:(BOOL)repeat{
	[[QSIdleWatcher sharedInstance] scheduleIdleCall:self performSelector:aSelector
										  withObject:anArgument afterIdleFor:delay repeat:repeat];
}

+ (void)cancelPreviousIdlePerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anArgument{
	[[QSIdleWatcher sharedInstance] cancelPreviousPerformRequestsWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anArgument];
}
@end

