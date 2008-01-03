

#import "QSParser.h"
#import "QSObject.h"
#import "QSTypes.h"

#import "QSObject_FileHandling.h"
#import "QSObject_URLHandling.h"
#import "QSObject_StringHandling.h"
#import "NDAlias.h"
#import "NDAlias+AliasFile.h"
#import "NDAlias+QSMods.h"


#import "QSMacros.h"
#import "QSVoyeur.h"
@implementation QSParser
- (BOOL)validParserForPath:(NSString *)path{return NO;}

- (NSArray *)objectsFromData:(NSData *)data encoding:(NSStringEncoding)encoding settings:(NSDictionary *)settings source:(NSURL *)source{
	QSLog(@"QSParser's objectsFromData: should be overridden");
	return nil;
}

- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
	path=[path stringByStandardizingPath];
    NSData *data=[NSData dataWithContentsOfFile:path];
    return [self objectsFromData:data encoding:NSUTF8StringEncoding settings:settings source:[NSURL fileURLWithPath:path]];
}

- (NSArray *)objectsFromURL:(NSURL *)url withSettings:(NSDictionary *)settings{
  //  NSData *data=[NSData dataWithContentsOfURL:url];
	NSError *error;
	
	NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:url
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:10.0];
	[theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"]; 
	NSStringEncoding encoding = 0;
	    
	
	NSURLResponse *response=nil;
	//if (VERBOSE)QSLog(@"Downloading from %@",url);
	NSData *data=[NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
	   if ([response textEncodingName])
		   encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)[response textEncodingName]));
//if (VERBOSE)QSLog(@"Downloading complete - %@",url);

	   //	NSString *string=[[[NSString alloc]initWithData:data encoding:encoding]autorelease];
	return [self objectsFromData:data encoding:encoding settings:settings source:url];
}



@end



