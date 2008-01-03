//
//  QSRegistry+Convenience.m
//  Blocks
//
//  Copyright 2007 Blacktree. All rights reserved.
//

#import "QSRegistry+Convenience.h"
// TODO: There is need for cleanup in there...
//
@implementation QSRegistry (Convenience)

- (NSBundle *)bundleWithIdentifier:(NSString *)ident {
	return [[self pluginWithID:ident] bundle];
}

- (BElement *)elementForClassName:(NSString *)className {
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	[request setEntity:[NSEntityDescription entityForName:@"element" inManagedObjectContext:[self managedObjectContext]]];
    [request setPredicate:[NSPredicate predicateWithFormat:@"objcClass = %@", className]];
	
	NSError *error = nil;
	NSArray *array = [[self managedObjectContext] executeFetchRequest:request error:&error];
	return [array lastObject];
}


- (NSBundle *)bundleForClassName:(NSString *)className {
	BLog(@"bundle requested for class %@", className);
	return nil;
}

- (id)getClassInstance:(NSString *)className {
    BElement *classElement = [self elementForClassName:className];
    BLogError(@"[QSReg getClassInstance:] is deprecated. (%@ %@)", className, classElement);
    return [classElement elementInstance];
}

- (id)instanceForKey:(NSString *)key inTable:(NSString *)table {
	return [self instanceForPointID:table withID:key];
}

- (NSDictionary *)instancesForTable:(NSString *)key {
    return [self loadedInstancesForPointID:key];
}

#pragma mark Unimplemented
- (NSDictionary *)retainedTableNamed:(NSString *)key {
    Debugger();
    return nil;
}

- (Class)getClass:(NSString*)className {
	BLog(@" requested class %@", className);
	return nil;
}

- (NSDictionary *)tableNamed:(NSString *)key {
    Debugger();
    return nil;
}

@end

@implementation QSRegistry (ObjectSource)

- (id)sourceNamed:(NSString *)sourceID {
    return [self instanceForPointID:kQSObjectSources withID:sourceID];
}

#pragma mark Unimplemented
- (NSMutableDictionary *)objectSources {
	Debugger();
    return [self elementsForPointID:kQSObjectSources];
}
@end

@implementation QSRegistry (ObjectHandlers)

+ (NSMutableDictionary *)objectHandlers {
	return [[self sharedInstance] objectHandlers];
}

- (NSMutableDictionary *)objectHandlers {
    return [self loadedInstancesByIDForPointID:kQSObjectHandlers];
}

@end


@implementation NSObject (InstancePerform)

+ (id)performSelectorWithInstance:(SEL)selector {
	return [[QSReg getClassInstance:NSStringFromClass([self class])]performSelector:selector];
}
@end

@implementation QSRegistry (Mediators)
- (id)getMediator:(NSString *)name {
	BExtensionPoint *point = [self extensionPointWithID:name];
	NSDictionary *header = [point plistContent];
  
	if (!header) return nil;
	NSString *selector = [header objectForKey:@"selector"];
	NSBundle *bundle = [[point plugin] bundle];
	if (bundle && ![bundle isLoaded]) [bundle load];
	SEL sel = NSSelectorFromString(selector);
	id mediator = nil;
	if (sel)
		mediator = [self performSelector:sel withObject:name];
  
	return mediator;
}

- (id)getMediatorID:(NSString *)name {
	BExtensionPoint *point = [self extensionPointWithID:name];
	NSDictionary *header = [point plistContent];
	NSString *selector = [header objectForKey:@"registryPreferredSelector"];
	NSBundle *bundle = [[point plugin] bundle];
	if (bundle && ![bundle isLoaded]) [bundle load];
	SEL sel = NSSelectorFromString(selector);
	if (sel)
		return [self performSelector:sel withObject:name];
	else
		return nil;
}
@end
