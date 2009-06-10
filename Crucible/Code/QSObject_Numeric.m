//
//  QSObject_Numeric.m
//  Quicksilver
//
//  Created by Alcor on 8/21/04.

//

#import "QSObject_Numeric.h"
#import "QSTypes.h"

@implementation QSObject (Numeric)
+ (QSObject *)numericObjectWithName:(NSString *)name value:(NSNumber *)value {
	QSObject *object = [[[QSObject alloc] init] autorelease];
	[object setName:name];
	[object setObject:value forType:QSNumericType];
	return object;
}

+ (QSObject *)numericObjectWithName:(NSString *)name intValue:(int)value {
	return [self numericObjectWithName:name value:[NSNumber numberWithInt:value]];
}

+ (NSArray *)booleanObjects {
	return [self booleanObjectsWithToggle:NO];
}

+ (NSArray *)booleanObjectsWithToggle {
	return [self booleanObjectsWithToggle:YES];
}

+ (NSArray *)booleanObjectsWithToggle:(BOOL)toggle {
	QSObject *toggleObject = nil;
	if (toggle) {
		toggleObject = [[[QSObject alloc] init] autorelease];
		[toggleObject setName:@"Toggle"];
		[toggleObject setObject:[NSNumber numberWithInt:-1] forType:QSNumericType];
		[toggleObject setObject:@"BooleanTOGGLE" forMeta:kQSObjectIconName];
	}
	
	QSObject *trueObject = [[[QSObject alloc] init] autorelease];
	[trueObject setName:@"Yes"];
	[trueObject setObject:[NSNumber numberWithBool:YES] forType:QSNumericType];
	[trueObject setObject:@"BooleanYES" forMeta:kQSObjectIconName];
	
	QSObject *falseObject = [[[QSObject alloc] init] autorelease];
	[falseObject setName:@"No"];
	[falseObject setObject:[NSNumber numberWithBool:NO] forType:QSNumericType];
	[falseObject setObject:@"BooleanNO" forMeta:kQSObjectIconName];
	
    if (toggle && fALPHA)
        return [NSArray arrayWithObjects:toggleObject, trueObject, falseObject, nil];
    else
        return [NSArray arrayWithObjects:trueObject, falseObject, nil];
}

@end
