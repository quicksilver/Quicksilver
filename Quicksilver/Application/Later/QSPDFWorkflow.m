#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>


@protocol QSController
- (void)activateInterface:(id)sender;
- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard;
- (BOOL)putOnShelfFromPasteboard:(NSPasteboard *)pboard;
@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSLog(@"%s | %s | %s",argv[1],argv[2],argv[3]);
	
    id proxy =[NSConnection rootProxyForConnectionWithRegisteredName:@"Quicksilver Command Line Tool" host:nil];
    if (proxy){
        NSPasteboard * pboard = [NSPasteboard pasteboardWithUniqueName];
        
        int fileArgs=1;
        BOOL putOnShelf=NO;
		
		

		
		int i;
		NSMutableArray *filenames=[NSMutableArray arrayWithCapacity:argc-1];
		NSFileManager *manager=[NSFileManager defaultManager];
		NSString *currentPath=[manager currentDirectoryPath];
		//NSLog(currentPath);
		for (i=1;i<argc;i++){
			NSString *currentFile=[[NSString stringWithCString:argv[i]]stringByStandardizingPath];
			if (![currentFile hasPrefix:@"/"])
				currentFile=[currentPath stringByAppendingPathComponent:currentFile];
			if ([manager fileExistsAtPath:currentFile isDirectory:nil])
				[filenames addObject:currentFile];
		}       
		if ([filenames count]){
			[pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
			[pboard setPropertyList:filenames forType:NSFilenamesPboardType];
		}
        
        
        [proxy setProtocolForProxy:@protocol(QSController)];
        
        if (putOnShelf) [proxy putOnShelfFromPasteboard:pboard];
        else [proxy readSelectionFromPasteboard:pboard];
        
        
    }else{
        NSLog(@"Unable to connect to Quicksilver");
    }    
    
    [pool release];
    return 0;
}
