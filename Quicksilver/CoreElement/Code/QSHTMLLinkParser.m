//
//  QSHTMLLinkParser.m
//  Quicksilver
//
//  Created by Alcor on 11/7/04.

//

#import "QSHTMLLinkParser.h"

//#define NSStringFromEKStr(ekstr) [[[NSString alloc] initWithCString:ekstr->str length:ekstr->len] autorelease]
//#define NSStringFromEKStrP(ekstr) [[[NSString alloc] initWithCString:ekstr.str length:ekstr.len] autorelease]
// function definitions for the parser callbacks






//
//static void handle_starttag(void *delegate, ekhtml_string_t *tag,ekhtml_attr_t *attrs);
//static void handle_data(void *delegate, ekhtml_string_t *str);
//static void handle_endtag(void *delegate, ekhtml_string_t *str);


@implementation QSHTMLLinkParser


- (id)init{
	if ((self = [super init])){
		//		ekparser = ekhtml_parser_new(NULL);
		//		ekhtml_parser_datacb_set(ekparser, handle_data);
		//		ekhtml_parser_startcb_add(ekparser, NULL, handle_starttag);
		//		ekhtml_parser_endcb_add(ekparser, NULL, handle_endtag);
		//		thisText=nil;
		//		thisLink=nil;
	}
    return self;
}

- (BOOL)validParserForPath:(NSString *)path{
    NSFileManager *manager=[NSFileManager defaultManager];
    BOOL isDirectory, exists;
    exists=[manager fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
    return !isDirectory;
}
- (NSArray *)objectsFromData:(NSData *)data encoding:(NSStringEncoding)encoding settings:(NSDictionary *)settings source:(NSURL *)source{
	//	return nil;
	//- (NSArray *)objectsFromData:(NSData *)data settings:(NSDictionary *)settings source:(NSURL *)source{
	NSString *string=[[[NSString alloc]initWithData:data encoding:encoding?encoding:NSISOLatin1StringEncoding]autorelease];
	//QSLog(@"data %d %@, settings %@, source %@",[data length],string,settings,source);
	
	 NSString *prefix;
	 if ((prefix=[settings objectForKey:@"contentPrefix"])){
		 NSRange prefixRange=[string rangeOfString:prefix];
		 if (prefixRange.location!=NSNotFound){
			 string=[string substringFromIndex:NSMaxRange(prefixRange)+1];
		 }
	 }
	 NSString *suffix;
	 if ((suffix=[settings objectForKey:@"contentSuffix"])){
		 NSRange suffixRange=[string rangeOfString:suffix];
		 if (suffixRange.location!=NSNotFound){
			 string=[string substringToIndex:suffixRange.location];
		 }
	 }
	 
  if (prefix || suffix)
    data = [string dataUsingEncoding:encoding];
  
	 NSString *script=[[NSBundle bundleForClass:[self class]]pathForResource:@"QSURLExtractor" ofType:@"pl"];
	//QSLog(@"parsing with %@\r%@",script,source);
	 NSTask *task=[NSTask taskWithLaunchPath:@"/usr/bin/perl" arguments:[NSArray arrayWithObject:script]];
	 NSPipe *readPipe = [NSPipe pipe];
	 NSFileHandle *readHandle = [readPipe fileHandleForReading];
	 NSPipe *writePipe = [NSPipe pipe];
	 NSFileHandle *writeHandle = [writePipe fileHandleForWriting];
	 [task setStandardInput: writePipe];
	 [task setStandardOutput: readPipe];
	// [task setStandardError: [NSPipe pipe]];
	 
	 [task launch];
	 [writeHandle writeData:data];
	
	 [writeHandle closeFile];
 	 
	 NSMutableData *returnData = [[NSMutableData alloc] init];
	 NSData *readData;
	//  QSLog(@"read");
	 while ((readData = [readHandle availableData])
			&& [readData length]) {
		 // QSLog(@"append");
		 [returnData appendData: readData];
	 }
	//  QSLog(@"dona");
	//	 data=[task launchAndReturnOutput];
	 
	 string=[[[NSString alloc]initWithData:returnData encoding:encoding?encoding:NSISOLatin1StringEncoding]autorelease];
	 [returnData release];

	 NSArray *array=[string componentsSeparatedByStrings:[NSArray arrayWithObjects:@"\n",@"\t",nil]];
	 //QSLog(@"Arrays %@ %@",array,string);	
	 
	
	/*
	 NSXMLParser *linkParser=[[[NSXMLParser alloc]initWithData:data]autorelease];
	 
	 [linkParser setDelegate:self];
	 [linkParser parse];
	 */
	
	//NSArray *links=[NSMutableArray arrayWithCapacity:1];
	
	//	[self addLinksFromString:string document:@"test"];
	
    NSMutableArray *objects=[NSMutableArray arrayWithCapacity:1];
    QSObject *newObject;
	NSArray *link;
	NSCharacterSet *wncs=[NSCharacterSet whitespaceAndNewlineCharacterSet];
	for(link in array){
		//QSLog(@"link %@",link);
		if ([link count]<4) continue;
		NSString *shortcut=[link objectAtIndex:2];
		NSString *url=[link objectAtIndex:0];
		url=[url stringByReplacing:@"&amp;" with:@"&"];
		url=[url stringByReplacing:@"%s" with:@"***"];
		NSString *text=[link objectAtIndex:1];
		NSString *imageurl=[link objectAtIndex:3];
		
		//text=[[[[NSAttributedString alloc]initWithHTML:[text dataUsingEncoding:NSISOLatin1StringEncoding]
		//							documentAttributes:nil]autorelease]string];
		
		if (text){
			NSString *name=[shortcut length]?shortcut:text;
			NSString *label=[shortcut length]?text:nil;
			//QSLog(@"url %@",url);	  
			//QSLog(@"urs %@",link);
			if (url)
				url=[[NSURL URLWithString:url relativeToURL:source]absoluteString];
			//QSLog(@"url '%@' '%@' %@",url,name,imageurl);			
			newObject=[QSObject URLObjectWithURL:url title:[name stringByTrimmingCharactersInSet:wncs]];
			if (label) [newObject setLabel:label];
			if (imageurl){
				imageurl=[[NSURL URLWithString:imageurl relativeToURL:source]absoluteString];
				[newObject setObject:imageurl forMeta:kQSObjectIconName];
			}
			if (newObject)
				[objects addObject:newObject];
		}
	}
    return objects;	
	}


		   //- (void)addLink:(NSDictionary *)linkDict{
		   //	//QSLog(@"dict %@",linkDict);	
		   //	if(linkDict)
		   //		[links addObject:linkDict];
		   //	
		   //}
		   //
		   //- (void)handleData:(NSString *)data{
		   //	[thisText appendString:data];
		   //}
		   //- (void)handleStartTag:(NSString *)tag attributes:(NSDictionary *)attributes{
		   //	if (![tag caseInsensitiveCompare:@"A"]){ // a tag
		   //		[self setThisText:[NSMutableString stringWithCapacity:0]];
		   //		[self setThisLink:(NSMutableDictionary *)attributes];
		   //	}else{
		   //		
		   //		NSMutableArray *otherTag=[NSMutableArray arrayWithObject:tag];
		   //		foreachkey(value,key,attributes){
		   //			[otherTag addObject:[NSString stringWithFormat:@"%@=\"%@\"",tag,key]];
		   //		}
		   //		[thisText appendFormat:@"<%@>",[otherTag componentsJoinedByString:@" "]];
		   //	}
		   //	
		   //}
		   //- (void)handleEndTag:(NSString *)tag{
		   //	if (![tag caseInsensitiveCompare:@"A"]){ // a tag
		   //		[thisLink setObject:thisText forKey:@"content"];
		   //		if (thisLink)
		   //			[links addObject:thisLink];
		   //		[self setThisText:nil];
		   //		[self setThisLink:nil];
		   //	}else{
		   //		[thisText appendFormat:@"</%@>",tag];
		   //	}
		   //}
		   //
		   //- (void)addLinksFromString:(NSString *)str document:(NSString *)docPath{
		   //     ekhtml_string_t ek_str;
		   //  	 ek_str.str = [str UTF8String];
		   //	 ek_str.len = [str length];
		   //	 
		   //    ekhtml_parser_cbdata_set(ekparser, self);
		   //    ekhtml_parser_feed(ekparser, &ek_str);
		   //	ekhtml_parser_flush(ekparser, 0);
		   //  	
		   //	
		   //    //    QSLog(@"%@", took_action == 0 ? @"took no action" : @"took action");
		   //	
		   //}
		   //
		   //
		   ///*
		   //- (NSArray *)linksFromHTML:(NSString *)html basePath:(NSString *)path{
		   //    NSURL *baseURL=[NSURL fileURLWithPath:path];
		   //    NSScanner *scanner=[NSScanner scannerWithString:html];
		   //    NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
		   //    
		   //    NSString *url=nil;
		   //    NSString *title;
		   //    QSObject *urlObject;
		   //    while (![scanner isAtEnd]){
		   //        [scanner scanUpToString:@"<a href=\"" intoString:nil];
		   //        [scanner scanString:@"<a href=\"" intoString:nil];
		   //        
		   //        [scanner scanUpToString:@"\"" intoString:&url];
		   //        [scanner scanString:@"\"" intoString:nil];
		   //        
		   //		// SHORTCUTURL="google"
		   //		
		   //        [scanner scanUpToString:@">" intoString:nil];
		   //        [scanner scanString:@">" intoString:nil];
		   //        
		   //        [scanner scanUpToString:@"</a>" intoString:&title];
		   //        //QSLog(url);
		   //        if (url){
		   //			//  NSURL *url=[NSURL URLWithString:url];
		   //            url=[[NSURL URLWithString:url relativeToURL:baseURL]absoluteString];
		   //            url=[url stringByReplacing:@"&amp;" with:@"&"];
		   //        }
		   //        urlObject=[QSObject URLObjectWithURL:url title:title];
		   //        
		   //        if (urlObject)
		   //            [array addObject: urlObject];
		   //        url=nil;
		   //        
		   //    }
		   //    return array;
		   //    
		   //    return nil;
		   //}
		   //*/
		   //- (NSMutableDictionary *)thisLink {
		   //    return [[thisLink retain] autorelease]; 
		   //}
		   //- (void)setThisLink:(NSMutableDictionary *)newThisLink {
		   //    if (thisLink != newThisLink) {
		   //        [thisLink release];
		   //        thisLink = [newThisLink retain];
		   //    }
		   //}
		   //
		   //- (NSMutableString *)thisText {
		   //    return [[thisText retain] autorelease]; 
		   //}
		   //- (void)setThisText:(NSMutableString *)newThisText {
		   //    if (thisText != newThisText) {
		   //        [thisText release];
		   //        thisText = [newThisText retain];
		   //    }
		   //}
		   //
@end
//
//static void handle_starttag(void *delegate, ekhtml_string_t *tag,ekhtml_attr_t *attrs){
//    ekhtml_attr_t *attr_cur;;
//    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
//    for(attr_cur = attrs; attr_cur; attr_cur = attr_cur->next){
//        [attributes setObject:NSStringFromEKStrP(attr_cur->val) forKey:[NSStringFromEKStrP(attr_cur->name) lowercaseString]];
//    }
//	[(id)delegate handleStartTag:NSStringFromEKStr(tag) attributes:attributes];
//}
//
//static void handle_data(void *delegate, ekhtml_string_t *str){
//	[(id)delegate handleData:NSStringFromEKStr(str)];	
//}
//static void handle_endtag(void *delegate, ekhtml_string_t *str){
//	[(id)delegate handleEndTag:NSStringFromEKStr(str)];	
//}
//
//
//
///*
//@implementation QSOldHTMLLinkParser
//- (BOOL)validParserForPath:(NSString *)path{
//    NSFileManager *manager=[NSFileManager defaultManager];
//    BOOL isDirectory, exists;
//    exists=[manager fileExistsAtPath:[path stringByStandardizingPath] isDirectory:&isDirectory];
//    return !isDirectory;
//}
//- (NSArray *)objectsFromPath:(NSString *)path withSettings:(NSDictionary *)settings{
//    NSString *string=[NSString stringWithContentsOfFile: [path stringByStandardizingPath]];
//    return [self linksFromHTML:string basePath:path];
//}
//- (NSArray *)objectsFromURL:(NSURL *)url withSettings:(NSDictionary *)settings{
//    NSString *string=[NSString stringWithContentsOfURL:url];
//	
//	NSString *prefix;
//	if ((prefix=[settings objectForKey:@"contentPrefix"])){
//		NSRange prefixRange=[string rangeOfString:prefix];
//		if (prefixRange.location!=NSNotFound){
//			string=[string substringFromIndex:NSMaxRange(prefixRange)+1];
//		}
//	}
//	NSString *suffix;
//	if ((suffix=[settings objectForKey:@"contentSuffix"])){
//		NSRange suffixRange=[string rangeOfString:suffix];
//		if (suffixRange.location!=NSNotFound){
//			string=[string substringToIndex:suffixRange.location];
//		}
//	}
//	//QSLog(string);
//    return [self linksFromHTML:string basePath:[url absoluteString]];
//}
//- (NSArray *)linksFromHTML:(NSString *)html basePath:(NSString *)path{
//    NSURL *baseURL=[NSURL fileURLWithPath:path];
//    NSScanner *scanner=[NSScanner scannerWithString:html];
//    NSMutableArray *array=[NSMutableArray arrayWithCapacity:1];
//    
//    NSString *url=nil;
//    NSString *title;
//    QSObject *urlObject;
//    while (![scanner isAtEnd]){
//        [scanner scanUpToString:@"<a href=\"" intoString:nil];
//        [scanner scanString:@"<a href=\"" intoString:nil];
//        
//        [scanner scanUpToString:@"\"" intoString:&url];
//        [scanner scanString:@"\"" intoString:nil];
//        
//		// SHORTCUTURL="google"
//		
//        [scanner scanUpToString:@">" intoString:nil];
//        [scanner scanString:@">" intoString:nil];
//        
//        [scanner scanUpToString:@"</a>" intoString:&title];
//        //QSLog(url);
//        if (url){
//			//  NSURL *url=[NSURL URLWithString:url];
//            url=[[NSURL URLWithString:url relativeToURL:baseURL]absoluteString];
//            url=[url stringByReplacing:@"&amp;" with:@"&"];
//        }
//        urlObject=[QSObject URLObjectWithURL:url title:title];
//        
//        if (urlObject)
//            [array addObject: urlObject];
//        url=nil;
//        
//    }
//    return array;
//    
//    return nil;
//}
//
//@end
//*/
//
//
