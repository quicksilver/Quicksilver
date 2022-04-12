#import "QSParser.h"
#import "QSObject.h"
#import "QSTypes.h"

#import "QSObject_FileHandling.h"
#import "QSObject_URLHandling.h"
#import "QSObject_StringHandling.h"
#import "NDAlias+AliasFile.h"
#import "NDAlias+QSMods.h"

#import "QSMacros.h"
#import "QSVoyeur.h"
@implementation QSParser
- (BOOL)validParserForPath:(NSString *)path {return NO;}

- (NSArray *)objectsFromData:(NSData *)data encoding:(NSStringEncoding)encoding settings:(NSDictionary *)settings source:(NSURL *)source {
	NSLog(@"QSParser's objectsFromData: should be overridden");
	return nil;
}

- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings {
	path = [path stringByStandardizingPath];
	NSData *data = [NSData dataWithContentsOfFile:path];
	return [self objectsFromData:data encoding:NSUTF8StringEncoding settings:settings source:[NSURL fileURLWithPath:path]];
}

- (NSArray *)objectsFromURL:(NSURL *)url withSettings:(NSDictionary *)settings {
 // NSData *data = [NSData dataWithContentsOfURL:url];
	NSError *error = nil;

	NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:url
															cachePolicy:NSURLRequestUseProtocolCachePolicy
														timeoutInterval:5.0];
	[theRequest setValue:kQSUserAgent forHTTPHeaderField:@"User-Agent"];
	NSStringEncoding encoding = NSUTF8StringEncoding;

	NSURLResponse *response = nil;
	//if (VERBOSE) NSLog(@"Downloading from %@", url);
	NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&error];
    // in the case where an error occurred, returning 'nil' causes the original catalog entry contents to be returned (see QSWebSource ojectsForEntry: )
    if (error) {
        return nil;
    }
	  if ([response textEncodingName])
		  encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef) [response textEncodingName]));

	// get the actual base URL from the response (e.g. in case of a redirect e.g. www → non-www or http:// → https://
	url = response.URL;

	return [self objectsFromData:data encoding:encoding settings:settings source:url];
}

@end

