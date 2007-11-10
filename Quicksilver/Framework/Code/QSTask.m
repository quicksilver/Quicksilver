//
//  QSTask.m
//  Quicksilver
//
//  Created by Nicholas Jitkoff on 6/29/05.

//

#import "QSTask.h"
#import "QSTaskController.h"

NSMutableDictionary *tasksDictionary;
@implementation QSTask
+ (void)initialize{
	tasksDictionary=[[NSMutableDictionary alloc]init];
	//[QSTaskController sharedInstance];
	[self setKeys:[NSArray arrayWithObject:@"progress"]
 triggerChangeNotificationsForDependentKey:@"indeterminateProgress"];
	[self setKeys:[NSArray arrayWithObject:@"progress"]
 triggerChangeNotificationsForDependentKey:@"animateProgress"];
}

+ (QSTask *)taskWithIdentifier:(NSString *)identifier{
	QSTask *task=[tasksDictionary objectForKey:identifier];
	if (!task)
		task=[[[QSTask alloc]initWithIdentifier:identifier]autorelease];
	return task;
}

+ (QSTask *)findTaskWithIdentifier:(NSString *)identifier{
	QSTask *task=[tasksDictionary objectForKey:identifier];
	return task;
}
//- (NSScriptObjectSpecifier *) objectSpecifier
//{
////	NSIndexSpecifier *specifier = [[NSIndexSpecifier alloc]
////      initWithContainerClassDescription:
////        (NSScriptClassDescription *)[myContainer classDescription]
////					 containerSpecifier: [myContainer objectSpecifier]
////									key: @"foobazi"];
////	[specifier setIndex: [myContainer indexOfObjectInFoobazi: self]];
////	return [specifier autorelease];
//	QSLog(@"specifier");
//	return nil;
//}
	
- (NSString *)nameAndStatus{
	//QSLog(@"stat %@",[self name]);
	return [self name];	
}
- (NSImage *)icon{
	if (!icon && delegate && [delegate respondsToSelector:@selector(iconForTask:)]){
		[self setIcon:[delegate iconForTask:self]];
	}
	if (!icon)return [NSImage imageNamed:@"NSApplicationIcon"];
	return [[icon retain] autorelease];
}
- (NSString *)description{
	return [NSString stringWithFormat:@"[%@:%@:%@]",identifier,name,status];
}
- (id) initWithIdentifier:(NSString *)newIdentifier {
	self = [super init];
	if (self != nil) {
		[self setIdentifier:newIdentifier];
	}
	return self;
}

- (void) release {
//	if ([self retainCount]<=3)
//		QSLog(@"release task %x %@ %d",self,name,[self retainCount]);
	if ([self retainCount]==2 && identifier){
		[self setIdentifier:nil];
	}
	[super release];
}
- (void) dealloc {
//	if (VERBOSE)	QSLog(@"Dealloc Task: %@",[self name]);
	//QSLog(@"dealloc task %x %@ %@ %d",self,name,identifier,[self retainCount]);
//	if ([tasksDictionary objectForKey:[self identifier]]){
//		[self retain];
//		[tasksDictionary removeObjectForKey:[self identifier]];
//		[self setIdentifier:nil];
//		return;
//	}
//	QSLog(@"really dealloc task %@ %@ %d",name,identifier,[self retainCount]);
	[self setIdentifier:nil];
	
	//QSLog(@"really task %x",self);
	[self setName:nil];
	[self setStatus:nil];
	[self setResult:nil];
	[self setCancelTarget:nil];
	[self setSubtasks:nil];
	[super dealloc];
//	QSLog(@"done dealloc task");	
}




- (void)cancel:(id)sender{
	if (cancelTarget){
		QSLog(@"Cancel Task: %@",self);
		
		[cancelTarget performSelector:cancelAction withObject:sender];	
	}
}

- (BOOL)isRunning{
	return running;
}
- (void)startTask:(id)sender{
//	QSLog(@"start %@",self);
	if (!running){
		running=YES;
		
		[QSTasks taskStarted:[[self retain]autorelease]];
		//[QSTasks performSelectorOnMainThread:@selector(taskStarted:) withObject:self waitUntilDone:NO];
	}
}
- (void)stopTask:(id)sender{
	if (running){
		//if (VERBOSE)	QSLog(@"End Task: %@",[self identifier]);
		
		running=NO;
		[QSTasks taskStopped:self];
		
	}
}


// Bindings

- (BOOL)animateProgress{
	return progress<0;
}

- (BOOL)indeterminateProgress{
	return progress<0;
}
- (BOOL)canBeCancelled{
	return cancelAction!=NULL;
}




// Accessors



- (NSString *)identifier {
    return [[identifier retain] autorelease];
}

- (void)setIdentifier:(NSString *)value {
    if (identifier != value) {
		NSString *oldIdentifier=identifier;
		[identifier autorelease];
		identifier = [value copy];
		
		if (tasksDictionary){
			if (value)[tasksDictionary setObject:self forKey:value];
			if (oldIdentifier)[tasksDictionary removeObjectForKey:oldIdentifier];
		}
    }
}

- (NSString *)name {
	if (!name)return [self identifier];
	return [[name retain] autorelease];
}

- (void)setName:(NSString *)value {
    if (name != value) {
        [name release];
        name = [value copy];
    }
}

- (NSString *)status {
    return [[status retain] autorelease];
}

- (void)setStatus:(NSString *)value {
    if (status != value) {
        [status autorelease];
        status = [value copy];
    }
}

- (float)progress {
    return progress;
}

- (void)setProgress:(float)value {
    if (progress != value) {
        progress = value;
    }
}

- (QSObject *)result {
    return [[result retain] autorelease];
}

- (void)setResult:(QSObject *)value {
    if (result != value) {
        [result release];
        result = [value copy];
    }
}

- (SEL)cancelAction {
    return cancelAction;
}

- (void)setCancelAction:(SEL)value {
	cancelAction = value;
}

- (id)cancelTarget {
    return [[cancelTarget retain] autorelease];
}

- (void)setCancelTarget:(id)value {
    if (cancelTarget != value) {
        [cancelTarget release];
        cancelTarget = [value retain];
    }
}

- (BOOL)showProgress {
    return showProgress;
}

- (void)setShowProgress:(BOOL)value {
    if (showProgress != value) {
        showProgress = value;
    }
}

- (NSArray *)subtasks {
	return nil;
    return [[subtasks retain] autorelease];
}

- (void)setSubtasks:(NSArray *)value {
    if (subtasks != value) {
        [subtasks release];
        subtasks = [value copy];
    }
}

- (void)setIcon:(NSImage *)newIcon
{
    if (icon != newIcon) {
        [icon release];
        icon = [newIcon retain];
    }
}


- (id)delegate { return [[delegate retain] autorelease]; }
- (void)setDelegate:(id)newDelegate
{
    if (delegate != newDelegate) {
        [delegate release];
        delegate = [newDelegate retain];
    }
}


@end
