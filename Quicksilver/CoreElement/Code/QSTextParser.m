//
//  QSTextParser.m
//  Quicksilver
//
//  Created by Alcor on 4/6/05.

//

#import "QSTextParser.h"

@implementation QSTextLineParser
- (BOOL)validParserForPath:(NSString *)path{
    NSFileManager *manager=[NSFileManager defaultManager];
    BOOL isDirectory, exists;
    exists=[manager fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
    return !isDirectory;
}


- (NSArray *)linesFromString:(NSString *)string atPath:(NSString *)path lineType:(NSString *)lineType{
    NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
    QSObject *newObject;
	string=[string stringByReplacing:@"\n" with:@"\r"];
	NSArray *lines=[string componentsSeparatedByString:@"\r"];
	NSString *line;
	for (int i=0;i<[lines count];i++){
		line=[lines objectAtIndex:i];
		if (lineType)
			newObject=[QSObject objectWithType:lineType value:line name:line];
		else
			newObject=[QSObject objectWithString:line];
		
		[newObject setDetails:nil];
		
		if (path){
			[newObject setObject:[NSDictionary dictionaryWithObjectsAndKeys:path,@"path",[NSNumber numberWithInt:i+1],@"line",nil]
						 forType:@"QSLineReferenceType"];
		}		
		if (newObject)
			[array addObject:newObject];
	}
				return array;
}
- (NSArray *)linesFromString:(NSString *)string atPath:(NSString *)path{
	return [self linesFromString:(NSString *)string atPath:(NSString *)path lineType:nil];
}
- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
    NSString *string=[NSString stringWithContentsOfFile: [path stringByStandardizingPath]];
    return [self linesFromString:string atPath:path lineType:[settings objectForKey:@"lineContentType"]];
}
- (NSArray *)objectsFromURL:(NSURL *)url withSettings:(NSDictionary *)settings{
    NSString *string=[NSString stringWithContentsOfURL:url];
    return [self linesFromString:string atPath:nil lineType:[settings objectForKey:@"lineContentType"]];
}
@end

@interface QSPlistParser : NSObject
@end

@implementation QSPlistParser
- (BOOL)validParserForPath:(NSString *)path{
    NSFileManager *manager=[NSFileManager defaultManager];
    BOOL isDirectory, exists;
    exists=[manager fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
    return !isDirectory && [[path pathExtension]isEqual:@"plist"];
}
- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
	//    NSData *data=[NSData dataWithContentsOfFile: [path stringByStandardizingPath]];
	
	return nil;
	//[NSPropertyListSerialization propertyListFromData:data mutabilityOption:kCFPropertyListImmutable format:nil errorDescription:nil];
	//return [self linesFromString:string];
}
- (NSArray *)linesFromString:(NSString *)string{
    NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
    QSObject *newObject;
    foreach(line,[string componentsSeparatedByString:@"\n"]){
        newObject=[QSObject objectWithString:line];
        [newObject setDetails:nil];
		if (newObject)
            [array addObject: newObject];
    }
    return array;
}

@end
