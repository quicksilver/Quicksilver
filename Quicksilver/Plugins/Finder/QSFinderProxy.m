

#import "QSFinderProxy.h"



@implementation QSFinderProxy
+ (id)sharedInstance{
    static id _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[[self class] allocWithZone:[self zone]] init];
    return _sharedInstance;
}

- (void)dealloc{
	[self setFinderScript:nil];
    [super dealloc];
}
- (NSImage *)icon{
    return [[NSWorkspace sharedWorkspace]iconForFile:@"/System/Library/CoreServices/Finder.app"];   
}

- (BOOL)revealFile:(NSString *)file{
	//  NSDictionary *errorDict=nil;
	//  NSArray *arguments=[NSArray arrayWithObject:[NSArray arrayWithObject:file]];
	//  NSAppleEventDescriptor *desc=[[self finderScript] executeSubroutine:@"reveal" arguments:[NSAppleEventDescriptor descriptorWithObject:arguments] error:&errorDict];
	//  if (errorDict){
	//      NSLog(@"Execute Error: %@",errorDict);
	[[NSWorkspace sharedWorkspace] selectFile:file inFileViewerRootedAtPath:@""];
	//  }
    return YES;
}

- (NSArray *)selection{
    NSDictionary *errorDict=nil;
    NSAppleEventDescriptor *desc=[[self finderScript] executeSubroutine:@"get_selection" arguments:nil error:&errorDict];
    if (errorDict)
      NSLog(@"Execute Error: %@",errorDict);
    NSMutableArray *files=[NSMutableArray arrayWithCapacity:[desc numberOfItems]];
    int i;
    for (i=0;i<[desc numberOfItems];i++)
        [files addObject:[[desc descriptorAtIndex:i+1]stringValue]];
    return files;
}

- (NSArray *)copyFiles:(NSArray *)files toFolder:(NSString *)destination{return [self moveFiles:files toFolder:destination shouldCopy:YES];}
- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination{return [self moveFiles:files toFolder:destination shouldCopy:NO];}
- (NSArray *)moveFiles:(NSArray *)files toFolder:(NSString *)destination shouldCopy:(BOOL)copy{
    NSDictionary *errorDict=nil;
    
    //NSLog(@"move %d",copy);
    NSArray *arguments=[NSArray arrayWithObjects:files,destination,nil];
    NSAppleEventDescriptor *desc=[[self finderScript] executeSubroutine:(copy?@"copy_items":@"move_items") arguments:[NSAppleEventDescriptor descriptorWithObject:arguments] error:&errorDict];
    if (!errorDict){
        return [desc objectValue]; //Should be an array of strings
    }else{
        NSLog(@"Execute Error: %@",errorDict);
        return nil;
    }
}

- (NSArray *)getInfoForFiles:(NSArray *)files{
    NSDictionary *errorDict=nil;
	// NSAppleEventDescriptor *desc=
	[[self finderScript] executeSubroutine:@"get_info" arguments:[NSArray arrayWithObject:files] error:&errorDict];
    if (errorDict)
		NSLog(@"Execute Error: %@",errorDict);
	return nil;
}


- (BOOL)openFile:(NSString *)file{
    return [[NSWorkspace sharedWorkspace] openFile:file];    
}
- (NSArray *)deleteFiles:(NSArray *)files{
    return nil;
}

/*
 bool trackForFile(NSString *filepath, AEDesc *replyDesc){
	 if (!filepath)return 0;
	 AppleEvent event, reply;
	 OSErr err;
	 OSType finderAdr = 'MACS';
	 FSRef fileRef;
	 AliasHandle fileAlias;
	 err = FSPathMakeRef([filepath fileSystemRepresentation], &fileRef, NULL);
	 if (err != noErr) return 0;
	 err = FSNewAliasMinimal(&fileRef, &fileAlias);
	 if (err != noErr) return 0;
	 err = AEBuildAppleEvent
		 ('core', 'clon', typeApplSignature, &finderAdr, sizeof(finderAdr),
		  kAutoGenerateReturnID, kAnyTransactionID, &event, NULL,
		  "'----':alis(@@)", fileAlias);
	 if (err != noErr) return 0;
	 err = AESend(&event, &reply, kAEWaitReply, kAENormalPriority,kAEDefaultTimeout, NULL, NULL);
	 
	 err = AEGetParamDesc(&reply, keyDirectObject, typeWildCard,replyDesc);
	 
	 AEDisposeDesc(&event);
	 AEDisposeDesc(&reply);
	 return 1;
 }
 */

/*
 { 1 } 'aevt':  core/clon (ppc ){
	 return id: 249626630 (0xee10006)
	 transaction id: 0 (0x0)
	 interaction level: 64 (0x40)
	 reply required: 1 (0x1)
remote: 0 (0x0)
target:
 { 2 } 'psn ':  8 bytes {
 { 0x0, 0x11c0001 } (Finder)
 }
	 optional attributes:
 { 1 } 'reco':  - 2 items {
	 key 'subj' - 
 { -1 } 'null':  null descriptor
	 key 'csig' - 
 { 1 } 'magn':  4 bytes {
	 65536l (0x10000)
 }
 }
	 
	 event data:
 { 1 } 'aevt':  - 2 items {
	 key 'insh' - 
 { 1 } 'furl':  29 bytes {
000: 6669 6c65  3a2f 2f6c  6f63 616c  686f 7374     file://localhost
001: 2f56 6f6c  756d 6573  2f4c 6f72  65            /Volumes/Lore   
	 
 }
	 key '----' - 
 { 1 } 'furl':  85 bytes {
000: 6669 6c65  3a2f 2f6c  6f63 616c  686f 7374     file://localhost
001: 2f56 6f6c  756d 6573  2f4c 6f72  652f 4465     /Volumes/Lore/De
002: 736b 746f  702f 5379  6c76 6961  2532 304b     sktop/Sylvia%20K
003: 6f65 6e69  672d 5361  6c6f 6e25  3230 3132     oenig-Salon%2012
004: 312d 3132  3125 3230  2e74 6578  7443 6c69     1-121%20.textCli
005: 7070 696e  67                                  pping           
	 
 }
 }
 }
 */

- (BOOL)loadChildrenForObject:(QSObject *)object{
	NSArray *newChildren=[QSObject fileObjectsWithPathArray:[self selection]];
	[object setChildren:newChildren];
	return YES;   	
}

- (NSAppleScript *)finderScript { 	
	if (!finderScript){
		NSString *path=[[NSBundle bundleForClass:[QSFinderProxy class]]pathForResource:@"Finder" ofType:@"scpt"];
		if (path)
			finderScript=[[NSAppleScript alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
	}
	[self performSelector:@selector(setFinderScript:) withObject:nil afterDelay:10*MINUTES extend:YES];
	return finderScript;
}

- (void)setFinderScript:(NSAppleScript *)aFinderScript {
    if (finderScript != aFinderScript) {
        [finderScript release];
        finderScript = [aFinderScript retain];
    }
}


-(id)resolveProxyObject:(id)proxy{
	//	NSLog(@"provide");
	//com.apple.finder
	return [QSObject fileObjectWithArray:[self selection]];
}
-(NSArray *)typesForProxyObject:(id)proxy{
	return [NSArray arrayWithObject:QSFilePathType];
}


- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	// Trash Object
	NSMutableArray *array=[NSMutableArray array];
	[array addObject:[QSAction actionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     self,          kActionProvider,
                                                     @"openTrash:", kActionSelector,
                                                     nil]
										 identifier:@"FinderOpenTrashAction"
                                             bundle:[NSBundle bundleForClass:[self class]]]];
	[array addObject:[QSAction actionWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                                     self,          kActionProvider,
                                                     @"emptyTrash:",kActionSelector,
                                                     nil]
										 identifier:@"FinderEmptyTrashAction"
                                             bundle:[NSBundle bundleForClass:[self class]]]];
    
	id handler = [self handlerForObject:dObject];
	if ([handler respondsToSelector:@selector(actionsForDirectObject:indirectObject:)])
		return [handler actionsForDirectObject:dObject indirectObject:nil];
	return [NSMutableArray array];
}

@end
