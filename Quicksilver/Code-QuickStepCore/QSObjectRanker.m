//
//  QSObjectRanker.m
//  Quicksilver
//
//  Created by Alcor on 1/28/05.
//  Copyright 2005 Blacktree. All rights reserved.
//

#import "QSObjectRanker.h"
#import "QSStringRanker.h"

#import "QSRankedObject.h"
#import "QSMnemonics.h"
#import "QSObject.h"

#import "QSRegistry.h"
#import "QSLibrarian.h"

//float gMinScore=0.333333;
Class QSCurrentStringRanker;
BOOL QSUsePureStringRanking;
QSRankedObject *QSMakeRankObject(NSString *searchString,QSBasicObject *object,float modifier,BOOL mnemonicsOnly,NSDictionary *definedMnemonics);

typedef double (*QSScoreForAbbrevIMP)(id object, SEL selector, NSString * abbreviation);

QSScoreForAbbrevIMP scoreForAbbrevIMP;



@implementation QSDefaultObjectRanker
+(void)initialize{
	NSString *className=[[NSUserDefaults standardUserDefaults]stringForKey:@"QSStringRankers"];
	if (!className)
		className=@"QSDefaultStringRanker";
	
	[[QSReg bundleForClassName:className]load]; //performSelectorOnMainThread:@selector(load) withObject:nil waitUntilDone:YES];
	
	QSCurrentStringRanker=NSClassFromString(className);
	
	if (!QSCurrentStringRanker)QSCurrentStringRanker=NSClassFromString(@"QSDefaultStringRanker");
	
	QSUsePureStringRanking=[[NSUserDefaults standardUserDefaults]boolForKey:@"QSUsePureStringRanking"];
	//	QSUsePureStringRanking=YES;
	//NSLog(@"%@",QSCurrentStringRanker);
	
	
	
	scoreForAbbrevIMP = (QSScoreForAbbrevIMP) [QSCurrentStringRanker instanceMethodForSelector:@selector(scoreForAbbreviation:)];
	}


+(id)rankerForObject:(QSBasicObject *)object{
	return [[[self alloc]initWithObject:object]autorelease];
}
-(id)initWithObject:(QSBasicObject *)object{
	if (self=[super init]){
		nameRanker=nil;
		labelRanker=nil;
		if ([object name])
			nameRanker=[[QSCurrentStringRanker alloc]initWithString:[object name]];
		if ([object label])
			labelRanker=[[QSCurrentStringRanker alloc]initWithString:[object label]];
		usageMnemonics=[[[QSMnemonics sharedInstance] objectMnemonicsForID:[object identifier]]retain];
	
		
		[self setOmitted:[QSLib itemIsOmitted:object]];
    }
	return self;
}

- (void)dealloc{
	
	[usageMnemonics release];
    usageMnemonics=nil;
	[nameRanker release];
	nameRanker=nil; 
	[labelRanker release];
	labelRanker=nil;
    [super dealloc];
}


+ (NSMutableArray *)rankedObjectsForAbbreviation:(NSString*)anAbbreviation inSet:(NSArray *)set inContext:(NSString *)context mnemonicsOnly:(BOOL)mnemonicsOnly{
	NSArray *abbreviationMnemonics=[[QSMnemonics sharedInstance]abbrevMnemonicsForString:anAbbreviation];
	
	NSEnumerator *enumer=[set objectEnumerator];
	QSBasicObject *thisObject;
	
	int count=[(NSArray *)set count];
	NSMutableArray *rankObjects=[NSMutableArray arrayWithCapacity:count];
	
	QSRankedObject *rankedObject;
	
	typedef QSRankedObject * (*QSScoreForObjectIMP)(id instance, SEL selector,QSBasicObject *object,NSString* anAbbreviation,NSString *context,NSArray * mnemonics, BOOL mnemonicsOnly);
	QSScoreForObjectIMP scoreForObjectIMP = 
		(QSScoreForObjectIMP) [self instanceMethodForSelector:@selector(rankedObject:forAbbreviation:inContext:withMnemonics:mnemonicsOnly:)];
	
	while (thisObject=[enumer nextObject]){
		
		id ranker=[thisObject ranker];
		if (!ranker){
			
			NSLog(@"ranker %@",thisObject);
			ranker=[thisObject getRanker];
		}
		//rankedObject=[ranker rankedObject:thisObject forAbbreviation:anAbbreviation inContext:nil withMnemonics:abbreviationMnemonics];
		rankedObject = (*scoreForObjectIMP)(ranker,@selector(rankedObject:forAbbreviation:inContext:withMnemonics:),
											thisObject,anAbbreviation,@"test",abbreviationMnemonics,mnemonicsOnly);
		
		
		
		
		
		if (rankedObject){
			[rankObjects addObject:rankedObject];
			// NSLog(@"rank %@",rankedObject);
		}
	}
	[rankObjects makeObjectsPerformSelector:@selector(release)];
	
	//NSLog(@"newscore %@",rankObjects);
	return rankObjects;
}


- (int)matchedStringForAbbreviation:(NSString*)anAbbreviation hitmask:(NSIndexSet **)hitmask inContext:(NSString *)context{
//- (NSIndexSet*)maskForAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context{
//- (NSIndexSet*)hitMaskForObject:(QSBasicObject *)object abbreviation:(NSString *)anAbbreviation index:(int *)index{
	if (!anAbbreviation)return nil;
	
	float nameScore = [nameRanker scoreForAbbreviation:anAbbreviation];
	if (labelRanker && [labelRanker scoreForAbbreviation:anAbbreviation]>nameScore){
		*hitmask=[labelRanker maskForAbbreviation:anAbbreviation];
		return 1;
	}else{
		*hitmask=[nameRanker maskForAbbreviation:anAbbreviation];
		return 0;
	}
	return -1;
}


- (QSRankedObject *)rankedObject:(QSObject *)object forAbbreviation:(NSString*)anAbbreviation inContext:(NSString *)context withMnemonics:(NSArray *)mnemonics mnemonicsOnly:(BOOL)mnemonicsOnly{
	
	//QSRankedObject *QSMakeRankObject(NSString *searchString,QSBasicObject *object,float modifier,BOOL mnemonicsOnly,NSDictionary *definedMnemonics){
	QSRankedObject *rankedObject=nil;
	if ([object isKindOfClass:[QSRankedObject class]]){ // Reuse old ranked object if possible
		rankedObject=(QSRankedObject *)object;
		object=[rankedObject object];
	}
	//	BOOL mnemonicsOnly=NO;
	NSString *matchedString=nil;
	if (![anAbbreviation length]){
		anAbbreviation=@"";
		//	mnemonicsOnly=YES;
	}
	float newScore=1.0;
	//float modifier=0.0;
	int newOrder=NSNotFound;
	//	QSRankInfo *info=object->rankData;
	//	if (!info) info=[object getRankData];
	
	if (self->omitted)
		return nil;
	if (!nameRanker){
		//NSLog(@"No Name!");	
		return nil;
	}
	if (anAbbreviation && !mnemonicsOnly){ // get base score for both name and label
										   //newScore = [nameRanker scoreForAbbreviation:anAbbreviation];//QSScoreForAbbreviation((CFStringRef)info->name, (CFStringRef)searchString,nil);
		newScore = (*scoreForAbbrevIMP)(nameRanker,@selector(scoreForAbbreviation:),anAbbreviation);
		
		if (labelRanker){
			//float labelScore=[labelRanker scoreForAbbreviation:anAbbreviation];//QSScoreForAbbreviation((CFStringRef)info->label, (CFStringRef)searchString,nil);
			float labelScore = (*scoreForAbbrevIMP)(labelRanker,@selector(scoreForAbbreviation:),anAbbreviation);
			
			if (labelScore>newScore){
				newScore=labelScore;
				//matchedString=info->label;
			}
		}
	}
	
	//	NSLog(@"newscore %f %@",newScore,rankedObject);
	
	
	if (!QSUsePureStringRanking || mnemonicsOnly){
		//NSLog(@"mnem");
		if (newScore){ // Add modifiers
			if (mnemonics)
				newOrder=[mnemonics indexOfObject:[object identifier]];
//			if (!=NSNotFound)
//				modifier+=10.0f;
//			newScore+=modifier;
			
			if(mnemonicsOnly)
				newScore+=[object rankModification];
		}
		
		int useCount=0;
		
		// get number of times this abbrev. has been used
		if ([anAbbreviation length])
			useCount=[[usageMnemonics objectForKey:anAbbreviation]intValue]; 
		
		
		if (useCount){
			newScore+=(1-1/(useCount+1));
			
		} else if (newScore){
			// otherwise add points for similar starting abbreviations
			NSEnumerator *enumerator = [usageMnemonics keyEnumerator];
			id key;
			while ((key = [enumerator nextObject])) {
				if (prefixCompare(key, anAbbreviation)==NSOrderedSame){
					newScore+=(1-1/([[usageMnemonics objectForKey:key]floatValue]))/4;
				}
			}
			
		}
		
		if (newScore)  newScore+=sqrt([object retainCount])/100; // If an object appears many times, increase score, this may be bad
		
		//*** in the future, increase for recent document, increase for partial match, increase for higher source index
		
		
	}
	
	
	
	//if (!newOrder)NSLog(@"object %@",object);
	
	
	// Create the ranked object
	if (rankedObject){
		[rankedObject setScore:newScore];
		[rankedObject setOrder:newOrder];
	}
	
	if (newScore>0.3333){
		if (rankedObject){
			[rankedObject setRankedString:matchedString];
			
			return [rankedObject retain];
		}else{
			
			return [[QSRankedObject alloc]initWithObject:(id)object matchString:matchedString order:newOrder score:(float)newScore];
			
		}
	}
	return nil;
	
	}





- (void)setOmitted:(BOOL)flag
{
    omitted = flag;
}




@end