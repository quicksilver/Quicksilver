//
// QSObjectRanker.m
// Quicksilver
//
// Created by Alcor on 1/28/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSObjectRanker.h"
#import "QSStringRanker.h"

#import "QSRankedObject.h"
#import "QSMnemonics.h"
#import "QSObject.h"

#import "QSRegistry.h"
#import "QSLibrarian.h"

Class QSCurrentStringRanker = nil;

typedef QSRankedObject * (*QSScoreForObjectIMP) (id instance, SEL selector, QSBasicObject *object, NSString *anAbbreviation, NSDictionary *options);

typedef CGFloat (*QSScoreForAbbrevIMP) (id object, SEL selector, NSString * abbreviation);
QSScoreForAbbrevIMP scoreForAbbrevIMP;

@implementation QSDefaultObjectRanker
+ (void)initialize {
    NSString *className = [[NSUserDefaults standardUserDefaults] stringForKey:@"QSStringRankers"];
    [self setDefaultStringRanker:className];
}

+ (BOOL)setDefaultStringRanker:(NSString *)className {
    Class rankerClass = NSClassFromString(className);

    if (!rankerClass) {
        // ok, maybe the bundle wasn't loaded right away, let's try to load it now
        NSBundle *rankerBundle = [QSReg bundleForClassName:className];
        if (rankerBundle && [rankerBundle load]) {
            rankerClass = NSClassFromString(className);
        }
    }

    if (!rankerClass) {
        QSShowNotifierWithAttributes([NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"Ranker Changed", nil), QSNotifierTitle, NSLocalizedString(@"Could not load preferred string ranker. Switching to default", nil), QSNotifierText, [QSResourceManager imageNamed:kQSBundleID], QSNotifierIcon, nil]);
        className = @"QSDefaultStringRanker";
        rankerClass = NSClassFromString(className);
        if (!rankerClass) {
            [NSException raise:NSInternalInconsistencyException format:@"No %@ class found !", className];
        }
    }

    if ([rankerClass instancesRespondToSelector:@selector(scoreForAbbreviation:)]) {
        QSCurrentStringRanker = rankerClass;
        scoreForAbbrevIMP = (QSScoreForAbbrevIMP) [QSCurrentStringRanker instanceMethodForSelector:@selector(scoreForAbbreviation:)];
        return YES;
    }
    return NO;
}

+ (id)rankerForObject:(QSBasicObject *)object {
	return [[self alloc] initWithObject:object];
}

NSString *QSRankingMnemonicsOnly = @"QSRankingMnemonicsOnly";   // BOOL
NSString *QSRankingObjectsInSet = @"QSRankingObjectsInSet";     // NSArray
NSString *QSRankingContext = @"QSRankingContext";               // NSString, unused ?
NSString *QSRankingUsePureString = @"QSRankingUsePureString";   // BOOL
NSString *QSRankingIncludeOmitted = @"QSRankingIncludeOmitted"; // BOOL

NSString *QSRankingAbbreviationMnemonics = @"QSRankingAbbreviationMnemonics"; // NSArray (internal)


+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString *)anAbbreviation options:(NSDictionary *)anOptions {
    NSArray *abbreviationMnemonics = [[QSMnemonics sharedInstance] abbrevMnemonicsForString:anAbbreviation];

    NSMutableDictionary *options = [anOptions mutableCopy];
    if (abbreviationMnemonics)
        [options setObject:abbreviationMnemonics forKey:QSRankingAbbreviationMnemonics];

    NSArray *objectsInSet = [options objectForKey:QSRankingObjectsInSet];
	NSMutableArray *rankObjects = [NSMutableArray arrayWithCapacity:[objectsInSet count]];

    BOOL includeOmitted = [[options objectForKey:QSRankingIncludeOmitted] boolValue];
    QSScoreForObjectIMP scoreForObjectIMP =
        (QSScoreForObjectIMP) [self instanceMethodForSelector:@selector(rankedObject:forAbbreviation:options:)];
    
    NSObject *lock = [[NSObject alloc] init];
    
    @autoreleasepool {
        [objectsInSet enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id thisObject, NSUInteger idx, BOOL *stop) {
            if (!includeOmitted && [[QSLibrarian sharedInstance] itemIsOmitted:thisObject]) return;
            
            id ranker = [thisObject ranker];
            
            QSRankedObject *rankedObject = nil;
            if ([ranker isKindOfClass:[QSDefaultObjectRanker class]]) {
                rankedObject = (*scoreForObjectIMP) (ranker, @selector(rankedObject:forAbbreviation:options:),
                                                     thisObject, anAbbreviation, options);
            } else if ([ranker respondsToSelector:@selector(rankedObject:forAbbreviation:options:)]) {
                rankedObject = [ranker rankedObject:thisObject
                                    forAbbreviation:anAbbreviation
                                            options:options];
            }
            
            if (rankedObject) {
                @synchronized(lock) {
                    [rankObjects addObject:rankedObject];
                }
            }
        }];
    }
	return rankObjects;
}

+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString *)anAbbreviation inSet:(NSArray *)set inContext:(NSString *)context mnemonicsOnly:(BOOL)mnemonicsOnly {
    NSMutableDictionary *options = [NSMutableDictionary dictionary];
    if (set)
        [options setObject:set forKey:QSRankingObjectsInSet];
    if (context)
        [options setObject:context forKey:QSRankingContext];
    if (mnemonicsOnly)
        [options setObject:[NSNumber numberWithBool:mnemonicsOnly] forKey:QSRankingMnemonicsOnly];
    return [self rankedObjectsForAbbreviation:anAbbreviation options:options];
}

- (id)initWithObject:(QSBasicObject *)object {
	if (self = [super init]) {
		nameRanker = nil;
		labelRanker = nil;
		cacheRanker = nil;
		if ([object name])
			nameRanker = [[QSCurrentStringRanker alloc] initWithString:[object name]];
		if ([object label] && ![[object label] isEqualToString:[object name]])
			labelRanker = [[QSCurrentStringRanker alloc] initWithString:[object label]];
		// Initialize cache ranker with additional search context (e.g., OCR text from images)
		id cacheContent = [object additionalSearchContext];
		if (cacheContent && [cacheContent isKindOfClass:[NSString class]])
			cacheRanker = [[QSCurrentStringRanker alloc] initWithString:(NSString *)cacheContent];
		usageMnemonics = [[QSMnemonics sharedInstance] objectMnemonicsForID:[object identifier]];
	}
	return self;
}

- (void)dealloc {
	usageMnemonics = nil;
	nameRanker = nil;
	labelRanker = nil;
	cacheRanker = nil;
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@ for object %@ with %lu mnemonics:\n%@", [super description], [nameRanker rankedString], (unsigned long)[usageMnemonics count], usageMnemonics];
}

- (NSString*)matchedStringForAbbreviation:(NSString*)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context {
	if (!anAbbreviation) return nil;
    
	if (labelRanker && [labelRanker scoreForAbbreviation:anAbbreviation] > 0) {
		*hitmask = [labelRanker maskForAbbreviation:anAbbreviation];
		return [labelRanker rankedString];
	} else {
		*hitmask = [nameRanker maskForAbbreviation:anAbbreviation];
		return [nameRanker rankedString];
	}
	return nil;
}

//- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context withMnemonics:(NSArray *)mnemonics mnemonicsOnly:(BOOL)mnemonicsOnly {
- (QSRankedObject *)rankedObject:(QSBasicObject *)object forAbbreviation:(NSString *)anAbbreviation options:(NSDictionary *)options {
    
    if (!nameRanker) {
		//NSLog(@"No Name!");
		return nil;
	}
    
//    NSString *context = [options objectForKey:QSRankingContext];
    NSArray *mnemonics = [options objectForKey:QSRankingAbbreviationMnemonics];
    BOOL mnemonicsOnly = [[options objectForKey:QSRankingMnemonicsOnly] boolValue];
    BOOL usePureString = [[options objectForKey:QSRankingUsePureString] boolValue];
	QSRankedObject *rankedObject = nil;
	if ([object isKindOfClass:[QSRankedObject class]]) { // Reuse old ranked object if possible
		rankedObject = (QSRankedObject *)object;
		object = [rankedObject object];
	}

	NSString *matchedString = nil;
	if (![anAbbreviation length]) {
		anAbbreviation = @"";
	}
	CGFloat newScore = 1.0;
	//float modifier = 0.0;
	NSInteger newOrder = NSNotFound;
	//	QSRankInfo *info = object->rankData;
	//	if (!info) info = [object getRankData];

	if (anAbbreviation && !mnemonicsOnly) { // get base score for both name and label
										  //newScore = [nameRanker scoreForAbbreviation:anAbbreviation]; //QSScoreForAbbreviation((CFStringRef) info->name, (CFStringRef)searchString, nil);
		newScore = (*scoreForAbbrevIMP) (nameRanker, @selector(scoreForAbbreviation:), anAbbreviation);
        matchedString = [nameRanker rankedString];
        
		if (labelRanker) {
			//float labelScore = [labelRanker scoreForAbbreviation:anAbbreviation]; //QSScoreForAbbreviation((CFStringRef) info->label, (CFStringRef)searchString, nil);
			CGFloat labelScore = (*scoreForAbbrevIMP) (labelRanker, @selector(scoreForAbbreviation:), anAbbreviation);

			if (labelScore > newScore) {
				newScore = labelScore;
                matchedString = [labelRanker rankedString];
			}
		}
		
		// Also check cache for matches (e.g., OCR text from images)
		if (cacheRanker) {
			CGFloat cacheScore = (*scoreForAbbrevIMP) (cacheRanker, @selector(scoreForAbbreviation:), anAbbreviation);
			if (cacheScore > newScore) {
				newScore = cacheScore;
				matchedString = [cacheRanker rankedString];
			}
		}
	}

	//	NSLog(@"newscore %f %@", newScore, rankedObject);
    
    // This MUST evaluate to TRUE if anAbbreviation (the typed text) is nil/an empty string
	if ((!usePureString || mnemonicsOnly) && newScore) {
		//NSLog(@"mnem");
        if (mnemonics)
            newOrder = [mnemonics indexOfObject:[object identifier]];
        //			if ( != NSNotFound)
        //				modifier += 10.0f;
        //			newScore += modifier;
#if 0
        if (mnemonicsOnly)
            newScore += [object rankModification];
#endif
        
		// get number of times this abbrev. has been used (only check if the abbrev. matches the object - i.e. newScore > 0)
        NSUInteger useCount = 0;
        if ([anAbbreviation length]) {
            useCount = [[usageMnemonics objectForKey:anAbbreviation] integerValue];
        } else {
            // for an empty string, consider the total use count
            for (id key in usageMnemonics) {
                useCount += [[usageMnemonics objectForKey:key] integerValue];
            }
        }
        if (useCount) {
            newScore += 1.0 - 1.0 / (useCount + 1.0);
        } else if ([anAbbreviation length]) {
            // otherwise add points for similar starting abbreviations
            for (id key in usageMnemonics) {
                if (prefixCompare(key, anAbbreviation) == NSOrderedSame) {
                    newScore += (1-1/([[usageMnemonics objectForKey:key] doubleValue]) )/4;
                }
            }
        }
        // set newscore
        //newScore += sqrt([object retainCount]) /100; // If an object appears many times, increase score, this may be bad
        
        //*** in the future, increase for recent document, increase for partial match, increase for higher source index
	}

	// Create the ranked object
	if (rankedObject) {
		[rankedObject setScore:newScore];
		[rankedObject setOrder:newOrder];
	}

	if (newScore > QSMinScore) {
		if (rankedObject) {
			[rankedObject setRankedString:matchedString];
			return rankedObject;
		} else {
			return [[QSRankedObject alloc] initWithObject:object matchString:matchedString order:newOrder score:newScore];
		}
	}
	return nil;
}

@end
