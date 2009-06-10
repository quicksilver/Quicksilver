//
//  QSObject_StringHandling.m
//  Quicksilver
//
//  Created by Alcor on 8/5/04.

//


#import "QSObject_StringHandling.h"
#import "QSTypes.h"
#import "QSObject_URLHandling.h"


@implementation QSObject (StringHandling)
+ (id)objectWithString:(NSString *)string{
    return [[(QSObject *)[QSObject alloc]initWithString:string]autorelease];
}
- (id)initWithString:(NSString *)string{
    if ((self = [self init])){
        [data setObject:string forKey:QSTextType];
        [self setName:string];
        [self setPrimaryType:QSTextType];
        [self sniffString];
		[self loadIcon];
    }
    return self;
}


- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type{
	return [object objectForType:type];	
	return nil;
}


- (void)sniffString{
    NSString *stringValue=[self objectForType:QSTextType];
    
	if (([stringValue hasPrefix:@"="])){
		[self setObject:stringValue forType:QSFormulaType];
		[self setObject:nil forType:QSTextType];
		[self setPrimaryType:QSFormulaType];
		return;
	}	
	if ([stringValue hasPrefix:@"tell app"]){
		//QSLog(@"Script!");
		[self setObject:@"AppleScriptRunTextAction" forMeta:kQSObjectDefaultAction];
		return;
	}	
	
	
    if ([stringValue hasPrefix:@"/"] || [stringValue hasPrefix:@"~"]){
		NSMutableArray *files=[[[stringValue componentsSeparatedByString:@"\n"]mutableCopy]autorelease];
		[files removeObject:@""];
		[files arrayByPerformingSelector:@selector(stringByStandardizingPath)];
		//NSString *path=[stringValue stringByStandardizingPath];
		//QSLog(@"%@",files);
		int line=-1;
		if ([files count]){
			NSString *path=[files objectAtIndex:0];
			NSArray *extComp=[[path pathExtension]componentsSeparatedByString:@":"];
			if ([extComp count]==2){
				line=[[extComp lastObject]intValue];
				files=[NSArray arrayWithObject:[path substringToIndex:[path length]-1-[[extComp lastObject]length]]];
				//QSLog(@"files %@",files);
			}
		}
		if([[NSFileManager defaultManager] filesExistAtPaths:files]){
			if (line>=0){
				[self setObject:[NSDictionary dictionaryWithObjectsAndKeys:[files lastObject],@"path",[NSNumber numberWithInt:line],@"line",nil]
						forType:@"QSLineReferenceType"];	
			}
			[self setObject:files forType:QSFilePathType];
			[self setPrimaryType:QSFilePathType];
			
		}
		return;
	}
	stringValue=[stringValue trimWhitespace];
	if ([stringValue rangeOfString:@" "].location!=NSNotFound)return;
	NSString *urlString=[self cleanQueryURL:stringValue];
	if ([urlString rangeOfString:@"\n"].location!=NSNotFound||[urlString rangeOfString:@"\r"].location!=NSNotFound){
		urlString=[[urlString lines]componentsJoinedByString:@""];	
		
	}
	NSURL *url=[NSURL URLWithString:urlString];
	
	if ([url scheme]){
		[self setObject:urlString forType:QSURLType];
		[self setPrimaryType:QSURLType];
		return;
	}
	
	if ([stringValue rangeOfString:@"."].location!=NSNotFound){
		if ([stringValue rangeOfString:@"@"].location!=NSNotFound && [stringValue rangeOfString:@"/"].location==NSNotFound){
			[self setObject:[NSArray arrayWithObject:stringValue] forType:QSEmailAddressType];
			
			[self setObject:[@"mailto:" stringByAppendingString:stringValue] forType:QSURLType];
			[self setPrimaryType:QSURLType];
		}else{
			NSString *host=[[stringValue componentsSeparatedByString:@"/"]objectAtIndex:0];
			NSArray *components=[host componentsSeparatedByString:@"."];
			
			if ([host length]&&[host rangeOfString:@" "].location==NSNotFound&&[components count] && ![[components lastObject]hasPrefix:@"htm"]){
				
				if ([components count]==4||([(NSString *)[components lastObject]length]>1 && [[components lastObject]rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location==NSNotFound)){ //Last component has no numbers
					
					urlString=[@"http://" stringByAppendingString:urlString];
					[self setObject:urlString  forType:QSURLType];
					[self setPrimaryType:QSURLType];
					
				}
			}
		}
	}  
}	
- (NSString *)stringValue{
	NSString *string=[self objectForType:QSTextType]; 
	//QSLog(@"string %@",string);
	// ***warning   * should convert other objects to strings
	
	if (!string)
		string=[self objectForType:QSURLType];
	
	//  QSLog(string);
	if (!string) string=[self displayName];
	
	return string;
}

@end
