//
//  QSObjectRanker.m
//  Quicksilver
//
//  Created by Alcor on 1/28/05.

//

#import "QSObjectRanker.h"
#import "QSStringRanker.h"

#import "QSRankedObject.h"
#import "QSMnemonics.h"
#import "QSObject.h"

#import "QSLibrarian.h"

#define QSUsePureStringRanking [[NSUserDefaults standardUserDefaults] boolForKey:@"QSUsePureStringRanking"]

Class QSCurrentStringRanker = nil;

typedef QSRankedObject* (*QSRankedObjectForObjectIMP) (id instance, SEL selector, QSBasicObject *object, NSString* anAbbreviation, NSString *context, NSArray *mnemonics, BOOL mnemonicsOnly);

typedef double (*QSScoreForAbbrevIMP)(id object, SEL selector, NSString * abbreviation);

QSScoreForAbbrevIMP scoreForAbbrevIMP;

@implementation QSDefaultObjectRanker
+ (void)initialize {
	NSString *className = [[NSUserDefaults standardUserDefaults] stringForKey:@"QSStringRankers"];
	if (!className)
		className = @"QSDefaultStringRanker";
	
	QSCurrentStringRanker = NSClassFromString(className);
	
	if (QSCurrentStringRanker)
        scoreForAbbrevIMP = (QSScoreForAbbrevIMP) [QSCurrentStringRanker instanceMethodForSelector:@selector(scoreForAbbreviation:)];
    else
        [NSException raise:NSInternalInconsistencyException format:@"No %@ class found !", className];
}

+ (id)rankerForObject:(QSBasicObject *)object {
	return [[[self alloc] initWithObject:object] autorelease];
}

+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString*)anAbbreviation inSet:(NSArray *)set inContext:(NSString *)context mnemonicsOnly:(BOOL)mnemonicsOnly{
	NSArray *abbreviationMnemonics = [[QSMnemonics sharedInstance] abbrevMnemonicsForString:anAbbreviation];
	
	NSMutableArray *rankObjects = [NSMutableArray arrayWithCapacity:[set count]];
	
	NSEnumerator *enumer = [set objectEnumerator];
	QSBasicObject *thisObject;
    
	QSRankedObjectForObjectIMP rankedObjectForObjectIMP = 
        (QSRankedObjectForObjectIMP) [self instanceMethodForSelector:@selector(rankedObject:forAbbreviation:inContext:withMnemonics:mnemonicsOnly:)];
	
    
	while ((thisObject = [enumer nextObject])) {
        
		id ranker = [thisObject ranker];
        
        QSRankedObject *rankedObject;
        if([ranker isKindOfClass:[QSDefaultObjectRanker class]])
            rankedObject = (*rankedObjectForObjectIMP) (ranker, @selector(rankedObject:forAbbreviation:inContext:withMnemonics:),
                                                 thisObject, anAbbreviation, context, abbreviationMnemonics, mnemonicsOnly);
        else
            rankedObject = [ranker rankedObject:thisObject forAbbreviation:anAbbreviation
                                      inContext:context
                                  withMnemonics:abbreviationMnemonics
                                  mnemonicsOnly:mnemonicsOnly];
        
		if (rankedObject) {
			[rankObjects addObject:rankedObject];
		}
	}
	return rankObjects;
}

- (id)initWithObject:(QSBasicObject *)object {
	if ((self = [super init])) {
		nameRanker = nil;
		labelRanker = nil;
		if ([object name])
			nameRanker = [[QSCurrentStringRanker alloc] initWithString:[object name]];
		if ([object label])
			labelRanker = [[QSCurrentStringRanker alloc] initWithString:[object label]];
		usageMnemonics = [[[QSMnemonics sharedInstance] objectMnemonicsForID:[object identifier]] retain];
        
    }
	return self;
}

- (void)dealloc {
	[usageMnemonics release];
    usageMnemonics = nil;
	[nameRanker release];
	nameRanker = nil;
	[labelRanker release];
	labelRanker = nil;
    [super dealloc];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ for object %@ with %d mnemonics:\n%@", [super description], [nameRanker rankedString], [usageMnemonics count], usageMnemonics];
}

- (NSString*)matchedStringForAbbreviation:(NSString*)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context{
	if (anAbbreviation) {
        float nameScore = [nameRanker scoreForAbbreviation:anAbbreviation];
        if (labelRanker && [labelRanker scoreForAbbreviation:anAbbreviation] > nameScore) {
            *hitmask = [labelRanker maskForAbbreviation:anAbbreviation];
            return [labelRanker rankedString];
        } else {
            *hitmask = [nameRanker maskForAbbreviation:anAbbreviation];
            return [nameRanker rankedString];
        }
    }
    *hitmask = nil;
    return nil;
}


- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context withMnemonics:(NSArray *)mnemonics mnemonicsOnly:(BOOL)mnemonicsOnly {
	QSRankedObject *rankedObject = nil;
	if ([object isKindOfClass:[QSRankedObject class]]) { // Reuse old ranked object if possible
		rankedObject = (QSRankedObject *)object;
		object = [rankedObject object];
	}
	//	BOOL mnemonicsOnly=NO;
	NSString *matchedString = nil;
	if (![anAbbreviation length]) {
		anAbbreviation = @"";
		//	mnemonicsOnly=YES;
	}
	float newScore = 1.0;
	//float modifier=0.0;
	int newOrder = NSNotFound;
	
	if (!nameRanker) {
		//QSLog(@"No Name!");	
		return nil;
	}
	if (anAbbreviation && !mnemonicsOnly) {
        /* get base score for both name and label */
        
		newScore = (*scoreForAbbrevIMP) (nameRanker, @selector(scoreForAbbreviation:), anAbbreviation);
		
		if (labelRanker) {
			float labelScore = (*scoreForAbbrevIMP) (labelRanker, @selector(scoreForAbbreviation:), anAbbreviation);
			
			if (labelScore > newScore) {
				newScore = labelScore;
				matchedString = [labelRanker rankedString];
			}
		}
	}
	
	//	QSLog(@"newscore %f %@",newScore,rankedObject);
	if (!QSUsePureStringRanking || mnemonicsOnly) {
		//QSLog(@"mnem");
		if (newScore) { // Add modifiers
			if (mnemonics)
				newOrder = [mnemonics indexOfObject:[object identifier]];
			
			if(mnemonicsOnly)
				newScore += [object rankModification];
		}
		
		int useCount = 0;
		
		// get number of times this abbrev. has been used
		if ([anAbbreviation length])
			useCount = [[usageMnemonics objectForKey:anAbbreviation] intValue]; 
		
		if (useCount) {
			newScore += (1 - 1 / (useCount + 1));
		} else if (newScore) {
			// otherwise add points for similar starting abbreviations
			NSEnumerator *enumerator = [usageMnemonics keyEnumerator];
			id key;
			while ((key = [enumerator nextObject])) {
				if (prefixCompare(key, anAbbreviation) == NSOrderedSame) {
					newScore += (1 - 1 / ([[usageMnemonics objectForKey:key] floatValue])) / 4;
				}
			}
		}
		
		if (newScore)
            newScore += sqrt([object retainCount]) / 100; // If an object appears many times, increase score, this may be bad
		
		//*** in the future, increase for recent document, increase for partial match, increase for higher source index
	}
	
	// Create the ranked object
	if (rankedObject){
		[rankedObject setScore:newScore];
		[rankedObject setOrder:newOrder];
	}
	
	if (newScore > QSMinScore) {
		if (rankedObject) {
			[rankedObject setRankedString:matchedString];
			return [[rankedObject retain] autorelease];
		} else {
			return [[[QSRankedObject alloc] initWithObject:object matchString:matchedString order:newOrder score:newScore] autorelease];
		}
	}
	return nil;
}

@end