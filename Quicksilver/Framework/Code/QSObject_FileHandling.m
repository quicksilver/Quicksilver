

#import "QSObject_FileHandling.h"
#import "QSObject_Pasteboard.h"
#import "QSParser.h"
#import "QSComputerSource.h"
#import "QSResourceManager.h"
#import "QSLibrarian.h"
#import "QSTypes.h"

#import "NSImage_BLTRExtensions.h"
#import "NSGeometry_BLTRExtensions.h"


#import "QSPreferenceKeys.h"
#import "NDResourceFork.h"
#import "QSCatalogEntry.h"
#import "NDAlias.h"
#import "NDAlias+QSMods.h"
#import "QSUTI.h"
#import "QSExecutor.h"
#import "QSMacros.h"
#import "QSAction.h"

#import "QLPrivate.h"

#import "QSObject_PropertyList.h"

#import "NSAppleEventDescriptor+NDAppleScriptObject.h"

#include "QSLocalization.h"

NSString *identifierForPaths(NSArray *paths){
    
    if ([paths count]==1) return [[paths lastObject]stringByResolvingSymlinksInPath];
    return [paths componentsJoinedByString:@" "];
}


static NSDictionary *bundlePresetChildren;
static BOOL useSmallIcons=NO;
NSArray *recentDocumentsForBundle(NSString *bundleIdentifier){
  if (!bundleIdentifier) return nil;
    NSArray *recentDocuments=[(NSArray *) CFPreferencesCopyValue((CFStringRef) @"NSRecentDocumentRecords", (CFStringRef) bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)autorelease];
    
    NSFileManager *manager=[NSFileManager defaultManager];
    NSMutableArray *documentsArray=[NSMutableArray arrayWithCapacity:[recentDocuments count]];
    NSData *aliasData;
    NSString *path;
    for (id loopItem in recentDocuments){
        aliasData=[[loopItem objectForKey:@"_NSLocator"]objectForKey:@"_NSAlias"];
        path=[[NDAlias aliasWithData:aliasData]quickPath];
        
        
		// ***warning * eventually include aliases
        
        
        if (path && [manager fileExistsAtPath:path]) [documentsArray addObject:path];
    }
    return documentsArray;
}


@implementation QSFileSystemObjectHandler
// Object Handler Methods
+(void)initialize{
    useSmallIcons=[[NSUserDefaults standardUserDefaults] boolForKey:kUseSmallIcons];
}
- (id) init {
	self = [super init];
	if (self != nil) {
		applicationIcons=[[NSMutableDictionary alloc]init];
	}
	return self;
}
- (NSMutableDictionary *)applicationIcons{
	return applicationIcons;	
}
- (QSObject *)parentOfObject:(QSObject *)object{
    
    QSObject * parent=nil;
    
    if ([object singleFilePath]){
        if ([[object singleFilePath]isEqualToString:@"/"])parent=[QSComputerProxy sharedInstance];
        else parent=[QSObject fileObjectWithPath:[[object singleFilePath]stringByDeletingLastPathComponent]];
    }
    return parent;
}

- (id)dataForObject:(QSObject *)object pasteboardType:(NSString *)type{
	return [object arrayForType:type];	
	return nil;
}

- (BOOL)drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped{
	if(NSWidth(rect)<=32) return NO;
	NSString *path=[object singleFilePath];
	
	
	//icon
	//	cache? - use
	//	loader? 
	//	
	//	
	if (0 && [[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:nil]){
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication){
			NSString *bundleIdentifier=[[NSBundle bundleWithPath:path]bundleIdentifier];
			
			NSString *handlerName=[[QSReg elementsForPointID:@"QSBundleDrawingHandlers"]objectForKey:bundleIdentifier];
			if (handlerName){
				id handler=[QSReg getClassInstance:handlerName];
				if (handler){
					if ([handler respondsToSelector:@selector(drawIconForObject:inRect:flipped:)])
						return [handler drawIconForObject:(QSObject *)object inRect:(NSRect)rect flipped:(BOOL)flipped];
					return NO;
				}
			}
		}
	}
	
	
	if (!path || [[path pathExtension]caseInsensitiveCompare:@"prefpane"]!=NSOrderedSame) return NO;
	
	NSImage *image=[NSImage imageNamed:@"PrefPaneTemplate"];
	
	[image setSize:[[image bestRepresentationForSize:rect.size] size]];
	//[image adjustSizeToDrawAtSize:rect.size];
	[image setFlipped:flipped];
	[image drawInRect:rect fromRect:rectFromSize([image size]) operation:NSCompositeSourceOver fraction:1.0f];
	
	if ([object iconLoaded]){
		NSImage *cornerBadge=[object icon];
		if (cornerBadge!=image){
			[cornerBadge setFlipped:flipped]; 
			
			NSRect badgeRect=NSMakeRect(16+48+rect.origin.x,16+36+rect.origin.y,32,32);
			NSImageRep *bestBadgeRep=[cornerBadge bestRepresentationForSize:badgeRect.size];    
			
			[cornerBadge setSize:[bestBadgeRep size]];
			
			[[NSColor colorWithDeviceWhite:1.0 alpha:0.8]set];
			//NSRectFillUsingOperation(NSInsetRect(badgeRect,-14,-14),NSCompositeSourceOver);
			NSBezierPath *path=[NSBezierPath bezierPath];
			[path appendBezierPathWithRoundedRectangle:NSInsetRect(badgeRect,-10,-10) withRadius:4];
			
			
			[[NSColor colorWithDeviceWhite:1.0 alpha:1.0]setFill];
			[[NSColor colorWithDeviceWhite:0.75 alpha:1.0]setStroke];
			[path fill];
			[path stroke];
			
			NSFrameRectWithWidth(NSInsetRect(badgeRect,-5,-5),2);
			
			[[NSGraphicsContext currentContext]setImageInterpolation:NSImageInterpolationNone];
			[cornerBadge drawInRect:badgeRect fromRect:rectFromSize([cornerBadge size]) operation:NSCompositeSourceOver fraction:1.0];
			[[NSGraphicsContext currentContext]setImageInterpolation:NSImageInterpolationHigh];
			
		}
	}
	return YES;
	
	
}

- (NSString *)kindOfObject:(QSObject *)object{
	NSString *path=[object singleFilePath];
	LSItemInfoRecord infoRec;
	LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
	if (infoRec.flags & kLSItemInfoIsApplication){
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication){
			return @"QSKindApplication";
		}
	}
	
	return nil;	
}
- (NSString *)detailsOfObject:(id <QSObject>)object{
    NSArray *theFiles=[object arrayForType:QSFilePathType];
	if ([theFiles count]==1){
		NSString *path=[theFiles lastObject];
		
		NSFileManager *manager=[NSFileManager defaultManager];

		if(QSIsLocalized){
			return [[manager componentsToDisplayForPath:path]componentsJoinedByString:@":"];
		}else if ([path hasPrefix:NSTemporaryDirectory()]){
			return [@"(Quicksilver)" stringByAppendingPathComponent:[path lastPathComponent]];
		}else{
			return [path stringByAbbreviatingWithTildeInPath];
		}
	}
	else  if ([theFiles count]>1){
		return [[theFiles arrayByPerformingSelector:@selector(lastPathComponent)]componentsJoinedByString:@", "];
	}
	return nil;
}

- (void)setQuickIconForObject:(QSObject *)object{
    NSFileManager *manager=[NSFileManager defaultManager];
    NSString *path=[object singleFilePath];
    BOOL isDirectory;
    [manager fileExistsAtPath:path isDirectory:&isDirectory];
    if (isDirectory){
        if ([[path pathExtension]isEqualToString:@"app"] || [[NSArray arrayWithObjects:@"'APPL'",nil]containsObject: NSHFSTypeOfFile(path)])
            [object setIcon:[QSResourceManager imageNamed:@"GenericApplicationIcon"]];
        else
            [object setIcon:[QSResourceManager imageNamed:@"GenericFolderIcon"]];
    }else{
        [object setIcon:[QSResourceManager imageNamed:@"UnknownFSObjectIcon"]];
    }
}

- (BOOL)loadIconForObject:(QSObject *)object{
  NSImage *theImage=nil;
  NSArray *theFiles=[object arrayForType:QSFilePathType];
  if (!theFiles) return NO;
  NSString *firstFile=[theFiles objectAtIndex:0];  
	NSFileManager *manager=[NSFileManager defaultManager];
  if ([theFiles count]==1){
    NSString *path=[theFiles lastObject];
    if ([manager fileExistsAtPath:path]){
      LSItemInfoRecord infoRec;
      //OSStatus status=
      LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
			
      if (infoRec.flags & kLSItemInfoIsPackage){
        NSBundle *bundle=[NSBundle bundleWithPath:firstFile];
        NSString *bundleImageName=nil;
        if ([[firstFile pathExtension]isEqualToString:@"prefPane"]){
          bundleImageName=[[bundle infoDictionary] objectForKey:@"NSPrefPaneIconFile"];
					
					if (!bundleImageName) bundleImageName=[[bundle infoDictionary] objectForKey:@"CFBundleIconFile"];
					if (bundleImageName){
						NSString *bundleImagePath=[bundle pathForResource:bundleImageName ofType:nil];
						theImage=[[[NSImage alloc]initWithContentsOfFile:bundleImagePath]autorelease];
					}
				}
      }
      if (!theImage && 1) {
        
        NSURL *fileURL = [NSURL fileURLWithPath:path];
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger: 128] 
                                                            forKey:kQLThumbnailOptionIconModeKey];
        CGSize iconSize = {256.0, 256.0};
        
        QLThumbnailRef thumbnail = QLThumbnailCreate(NULL, (CFURLRef)fileURL, iconSize, (CFDictionaryRef)options);
        if (thumbnail) {
          CGImageRef cgImage = QLThumbnailCopyImage(thumbnail);
          if (cgImage) {
            NSBitmapImageRep *rep = [[[NSBitmapImageRep alloc] initWithCGImage:cgImage] autorelease];
            theImage = [[[NSImage alloc] init] autorelease];
            [theImage addRepresentation:rep];
            CFRelease(cgImage);
          }
          CFRelease(thumbnail);
        }
        
      }
      if (!theImage && [[NSUserDefaults standardUserDefaults] boolForKey:@"QSLoadImagePreviews"]){
        NSString *type=[manager typeOfFile:path];
        
        
        if ([[NSImage imageUnfilteredFileTypes] containsObject:type]) {
          theImage=[[[NSImage alloc]initWithContentsOfFile:path]autorelease];
        } else {
          id provider=[QSReg instanceForKey:type inTable:@"QSFSFileTypePreviewers"];
          //QSLog(@"provider %@",[QSReg elementsForPointID:@"QSFSFileTypePreviewers"]);
          theImage=[provider iconForFile:path ofType:type];
        }
      }
      if (!theImage)
        theImage=[[NSWorkspace sharedWorkspace] iconForFile:path];
			
      
			// ***warning * This caused a crash?
    }
    
  }else{
		NSMutableSet *set=[NSMutableSet set];
		NSWorkspace *w=[NSWorkspace sharedWorkspace];
		NSString *theFile;
		for (theFile in theFiles){
			NSString *type=[manager typeOfFile:theFile];
			
			[set addObject:type?type:@"'msng'"];
			
		}
		
		//QSLog(@"%@, set",set);
		if ([set containsObject:@"'fold'"]){
			[set removeObject:@"'fold'"];
			[set addObject:@"'fldr'"];
			
			
		}
		if ([set count]==1)
			theImage=[w iconForFileType:[set anyObject]];
		else
			theImage=[w iconForFiles:theFiles];
    }
    
    if (theImage){
        [theImage createRepresentationOfSize:NSMakeSize(32,32)];
		[theImage createRepresentationOfSize:NSMakeSize(16,16)];
    }
    if (QSMaxIconSize.width<128){ 
		// ***warning * use this better
		//if (VERBOSE) QSLog(@"stripping maxsize for object %@",object);
        [theImage removeRepresentation:[theImage representationOfSize:NSMakeSize(128,128)]];
        
    }
    //  QSLog(@"Reps for %@\r%@",[object name],[theImage representations]);
    //[theImage setScalesWhenResized:YES];
    if (!theImage)theImage=[QSResourceManager imageNamed:@"GenericQuestionMarkIcon"];
    
    
    [object setIcon:theImage];
    return YES;
}

- (BOOL)objectHasChildren:(QSObject *)object{
  if (!object) return NO;
  BOOL isDirectory;
	NSString *path=[object singleFilePath];
  
  
  if ([[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:&isDirectory]){
		
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
		
    if (infoRec.flags & kLSItemInfoIsAliasFile) return YES;
		
		if (infoRec.flags & kLSItemInfoIsApplication){
			NSString *bundleIdentifier=[[NSBundle bundleWithPath:path]bundleIdentifier];
			//CFBundleRef bundle=CFBundleCreate (NULL,(CFURLRef)[NSURL fileURLWithPath:path]);
			//NSString *bundleIdentifier=CFBundleGetIdentifier(bundle);
			
			if (!bundleIdentifier) return NO;
  		NSString *handlerName=[QSReg elementForPointID:@"QSBundleChildHandlers" withID:bundleIdentifier];
			if (handlerName) return YES;
			
			NSArray *recentDocuments=(NSArray *) CFPreferencesCopyValue((CFStringRef) @"NSRecentDocumentRecords", (CFStringRef) bundleIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			[recentDocuments autorelease];
			if (recentDocuments) return YES;
		}
		
		
		
		
		return isDirectory && !(infoRec.flags & kLSItemInfoIsPackage);
	}
  return NO;
  
}
- (BOOL)objectHasValidChildren:(QSObject *)object{
    if ([object fileCount]==1){
        NSString *path=[object singleFilePath];
		
		
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication){
			NSString *bundleIdentifier=[[NSBundle bundleWithPath:path]bundleIdentifier];
			
			id handler = [QSReg instanceForPointID:@"QSBundleChildHandlers" withID:bundleIdentifier];
			
			if (handler){
				if ([handler respondsToSelector:@selector(objectHasValidChildren:)])
					return [handler objectHasValidChildren:object];
				return NO;
			}
			
			return YES;
		}
		
		
		
		
		
        NSTimeInterval modDate=[[[[NSFileManager defaultManager] fileAttributesAtPath:path traverseLink:NO]fileModificationDate]timeIntervalSinceReferenceDate];
        if (modDate>[object childrenLoadedDate]) return NO;
    }
    return YES;
    
}



- (NSDragOperation)operationForDrag:(id <NSDraggingInfo>)sender ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject{
    if (![iObject arrayForType:QSFilePathType])return nil;
	if([dObject fileCount]>1)return NSDragOperationGeneric;
    
    NSDragOperation sourceDragMask = [sender draggingSourceOperationMask];
    if ([dObject isApplication]){
		return NSDragOperationPrivate;
        if(sourceDragMask&NSDragOperationPrivate)return NSDragOperationPrivate;
    }else if ([dObject isFolder]){
        NSFileManager *manager=[NSFileManager defaultManager];
        NSDragOperation defaultOp=[manager defaultDragOperationForMovingPaths:[dObject validPaths] toDestination:[(QSObject *)iObject singleFilePath]];
        if (defaultOp==NSDragOperationMove){
            if (sourceDragMask&NSDragOperationMove) return NSDragOperationMove;
            if (sourceDragMask&NSDragOperationCopy) return NSDragOperationCopy;
        }else if  (defaultOp==NSDragOperationCopy){
            return NSDragOperationCopy;
        }
    }
    return sourceDragMask&NSDragOperationGeneric;
}
- (NSString *)actionForDragMask:(NSDragOperation)operation ontoObject:(QSObject *)dObject withObject:(QSBasicObject *)iObject{
	if([dObject fileCount]>1)return nil;
    
    NSDragOperation sourceDragMask = operation;
    if ([dObject isApplication]){
        //if (sourceDragMask&NSDragOperationPrivate)
		return  @"FileOpenWithAction";
    }else if ([dObject isFolder]){
        //  NSFileManager *manager=[NSFileManager defaultManager];
        if (sourceDragMask&NSDragOperationMove)
            return @"FileMoveToAction";
        else if (sourceDragMask&NSDragOperationCopy)
            return @"FileCopyToAction";
        
    }
    return nil;
}

- (NSAppleEventDescriptor *)AEDescriptorForObject:(QSObject *)object{
	return [NSAppleEventDescriptor aliasListDescriptorWithArray:[object validPaths]];
}

- (NSString *)identifierForObject:(id <QSObject>)object{
    return identifierForPaths([object arrayForType:QSFilePathType]);
}
- (BOOL)loadChildrenForObject:(QSObject *)object{
    NSArray *newChildren=nil;
    NSArray *newAltChildren=nil;
	
    if ([object fileCount]==1){
        NSString *path=[object singleFilePath];
        if (![path length])return NO;
        BOOL isDirectory;
        NSFileManager *manager=[NSFileManager defaultManager];
        
        LSItemInfoRecord infoRec;
        LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestAllInfo, &infoRec);
        
        if (infoRec.flags & kLSItemInfoIsAliasFile){
            path=[manager resolveAliasAtPath:path];
            if([manager fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory){
                [object setChildren:[NSArray arrayWithObject:[QSObject fileObjectWithPath:path]]];
				return YES;
			}
            
        }
		
		
		
		NSMutableArray *fileChildren=[NSMutableArray arrayWithCapacity:1];
		NSMutableArray *visibleFileChildren=[NSMutableArray arrayWithCapacity:1];
		
		NSString *file;
		NSEnumerator *enumerator = [[manager directoryContentsAtPath:path] objectEnumerator];
		while (file = [enumerator nextObject]){
			file=[path stringByAppendingPathComponent:file];
			[fileChildren addObject:file];
			if ([manager isVisible:file])
				[visibleFileChildren addObject:file];
		}
		
		newChildren=[QSObject fileObjectsWithPathArray:visibleFileChildren];
		newAltChildren=[QSObject fileObjectsWithPathArray:fileChildren];
		
		if (newAltChildren)[object setAltChildren:newAltChildren];
		
		if (infoRec.flags & kLSItemInfoIsApplication){
			// ***warning * omit other types of bundles
			//newChildren=nil;
			
			NSString *bundleIdentifier=[[NSBundle bundleWithPath:path]bundleIdentifier];
			id handler=[QSReg instanceForPointID:@"QSBundleChildHandlers" withID:bundleIdentifier];
	
			
			
			if (handler){
				return [handler loadChildrenForObject:object];
			}else{
				if (!bundlePresetChildren){
					bundlePresetChildren=[QSReg elementsByIDForPointID:@"QSBundleChildPresets"];
					//[[NSDictionary dictionaryWithContentsOfFile:
					//	[[NSBundle mainBundle]pathForResource:@"BundleChildPresets" ofType:@"plist"]]retain];
				}
				
				NSString *childPreset=[bundlePresetChildren objectForKey:bundleIdentifier];
				if (childPreset){
					if (VERBOSE) QSLog(@"using preset %@",childPreset);
					QSCatalogEntry *theEntry=[QSLib entryForID:childPreset];
					newChildren=[theEntry contentsScanIfNeeded:YES];
				}else{
					NSArray *recentDocuments=recentDocumentsForBundle(bundleIdentifier);
					newChildren=[QSObject fileObjectsWithPathArray:recentDocuments];
				
					foreach(child,newChildren){
						[child setObject:bundleIdentifier forMeta:@"QSPreferredApplication"];
					}
				}
			}
			
		}else if ((infoRec.flags & kLSItemInfoIsPackage) || !(infoRec.flags & kLSItemInfoIsContainer)){
			//NSString *type=[[NSFileManager defaultManager]typeOfFile:path];
			
			NSString *uti=QSUTIWithLSInfoRec(path,&infoRec);
			//QSUTIForExtensionOrType((NSString *)infoRec.extension,infoRec.filetype);
			
			//QSLog(@"uti %@ %@",uti,UTTypeCopyDescription(uti));
			
			id handler=[QSReg instanceForKey:uti inTable:@"QSFSFileTypeChildHandlers"];
			if (handler)
				return [handler loadChildrenForObject:object];
			
			id <QSParser> parser=[QSReg instanceForKey:uti inTable:@"QSFSFileTypeParsers"];
			NSArray *children=[parser objectsFromPath:path withSettings:nil];
			if (children){
				[object setChildren:children];
				return YES;
			}
			
			
		}
		
	}else{
		newChildren=[QSObject fileObjectsWithPathArray:[object arrayForType:QSFilePathType]];
	}
	
	if (newChildren)[object setChildren:newChildren];
	
	return YES;
}

- (NSArray *)actionsForDirectObject:(QSObject *)dObject indirectObject:(QSObject *)iObject{
	NSString *path=[dObject objectForType:QSFilePathType];
	if ([[NSFileManager defaultManager]fileExistsAtPath:path isDirectory:nil]){
		LSItemInfoRecord infoRec;
		LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
		if (infoRec.flags & kLSItemInfoIsApplication){
			NSMutableArray *actions=(NSMutableArray *)[QSExec validActionsForDirectObject:dObject indirectObject:iObject];
		//	NSString *bundleIdentifier=[[NSBundle bundleWithPath:path]bundleIdentifier];
			
			//QSLog(@"actions %d",[actions count]);
			
			// TODO FIXME
//			NSDictionary *appActions=[[QSReg elementsForPointID:@"QSApplicationActions"]objectForKey:bundleIdentifier];
//			foreachkey(actionID,actionDict,appActions){
//				[actions addObject:[QSAction actionWithDictionary:actionDict
//													   identifier:actionID bundle:nil]];
//			}
			//	QSLog(@"actions %d",[actions count]);
			
			return actions;
			
		}
	}
	return nil;
}
@end








@implementation QSBasicObject (FileHandling)

- (NSString *)singleFilePath{return [self objectForType:QSFilePathType];
}

- (NSString *)validSingleFilePath{
    NSString *path=[self objectForType:QSFilePathType];
    if (path && [[NSFileManager defaultManager] fileExistsAtPath:path])
		return path;
	return nil;
}

- (NSArray *)validPaths{return [self validPathsResolvingAliases:NO];}
- (NSArray *)validPathsResolvingAliases:(BOOL)resolve{
    NSArray *paths=[self arrayForType:QSFilePathType];
    NSFileManager *manager=[NSFileManager defaultManager];
    BOOL exists=[manager filesExistAtPaths:(NSArray *)paths];
    if (exists) return paths;
    
    if ([paths count]==1){
        NSString *aliasFile=[self objectForType:QSAliasFilePathType];
        if ([manager fileExistsAtPath:aliasFile]){
            if (VERBOSE) QSLog(@"Using original alias file:%@",aliasFile);
            return [NSArray arrayWithObject:aliasFile];
        }
    } 
    return nil;
}

- (int)fileCount{
    return [[self arrayForType:QSFilePathType] count];
}

@end



#define clippingTypes [NSSet setWithObjects:@"textClipping",@"pictClipping", @"'clpp'",@"textClipping", @"'clpt'",@"webloc", @"inetloc", @"'ilht'",@"'ilaf'",nil]

@implementation QSObject (FileHandling)


+ (QSObject *)fileObjectWithPath:(NSString *)path{
    if (![path length]) return nil;
	//QSLog(@"Path %@",path);
    path=[[path stringByStandardizingPath]stringByResolvingSymlinksInPath];
	
	//QSLog(@"Path %@",path);
	
	// ***warning * should this only resolve simlinks of ancestors?
    
    if ([[path pathExtension] isEqualToString:@"silver"])
		return [QSObject objectWithDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    
    QSObject *newObject=[QSObject objectWithIdentifier:path];    
    if (!newObject){
		//	QSLog(@"creating for %@",path);
		newObject=[[[QSObject alloc]initWithArray:[NSArray arrayWithObject:path]]autorelease];
    }
    NSString *type=[[NSFileManager defaultManager]typeOfFile:path];
    if ([clippingTypes containsObject:type])
		[newObject performSelectorOnMainThread:@selector(addContentsOfClipping:) withObject:path waitUntilDone:YES];
	return newObject;
}

+ (QSObject *)fileObjectWithArray:(NSArray *)paths{
    QSObject *newObject=[QSObject objectWithIdentifier:identifierForPaths(paths)];
    //  QSLog(@"object:%@",newObject);
    if (!newObject){
        if ([paths count]>1)
            newObject=[[[QSObject alloc]initWithArray:paths]autorelease];
        else if ([paths count]==0)
            return nil;
        else
            newObject=[QSObject fileObjectWithPath:[paths lastObject]];
    }    
    return newObject;
}

+ (NSArray *)fileObjectsWithPathArray:(NSArray *)pathArray{
    NSMutableArray *fileObjectArray=[NSMutableArray arrayWithCapacity:1];
	id object;
    for (id loopItem in pathArray){
		if (object=[QSObject fileObjectWithPath:loopItem])
			[fileObjectArray addObject:object];
	}
    return fileObjectArray;
}

+ (NSMutableArray *)fileObjectsWithURLArray:(NSArray *)pathArray{
    NSMutableArray *fileObjectArray=[NSMutableArray arrayWithCapacity:1];
    for (id loopItem in pathArray){
        //QSLog(@"path %@",[[pathArray objectAtIndex:i]path]);
        [fileObjectArray addObject:[QSObject fileObjectWithPath:[loopItem path]]];
        
    }
    return fileObjectArray;
}


- (id)initWithArray:(NSArray *)paths { //**this function could create dups
    if (self = [self init]){
        NSString *thisIdentifier=identifierForPaths(paths);
		
        if ([paths count]==1){
			NSString *path=[paths lastObject];
            [[self dataDictionary] setObject:path forKey:QSFilePathType]; 
			NSString *uti=QSUTIOfFile(path);
			id handler=[QSReg instanceForKey:uti inTable:@"QSFileObjectCreationHandlers"];
			//QSLog(@"handler %@ %@",uti,handler);
			if (handler)
				return [handler initFileObject:self ofType:uti];
			
        }else{
			[[self dataDictionary] setObject:paths forKey:QSFilePathType];
		}
		
        [QSObject registerObject:self withIdentifier:thisIdentifier];
        [self setPrimaryType:QSFilePathType];
        [self getNameFromFiles];
    }
    return self;
}

- (BOOL)isApplication{
    NSString *path=[self singleFilePath];
    
    LSItemInfoRecord infoRec;
    LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
    
    return (infoRec.flags & kLSItemInfoIsApplication);
    //  return ([self isFolder] && ([[path pathExtension]isEqualToString:@"app"] || [[NSArray arrayWithObjects:@"'APPL'",nil]containsObject: NSHFSTypeOfFile(path)]));
    
}
- (BOOL)isFolder{
    BOOL isDirectory;
    NSString *path=[self singleFilePath];
    NSFileManager *manager=[NSFileManager defaultManager];
    if ([manager fileExistsAtPath:path isDirectory:&isDirectory])
        return isDirectory;
    return NO;
}
- (NSString *)localizedPrefPaneKind{
	static NSString *prefPaneKindString=nil;
	if (!prefPaneKindString)
		prefPaneKindString=[[[NSBundle bundleWithPath:[[NSWorkspace sharedWorkspace]absolutePathForAppBundleWithIdentifier:@"com.apple.systempreferences"]]
                    localizedStringForKey:@"PREF_PANE" value:@" Preferences" table:nil]retain];
	return prefPaneKindString;
}
- (NSString *)descriptiveNameForPackage:(NSString *)path withKindSuffix:(BOOL)includeKind{
		//NSBundle *bundle=nil;
		CFBundleRef bundleRef=CFBundleCreate(kCFAllocatorDefault,(CFURLRef)[NSURL fileURLWithPath:path]);
		NSString *bundleName=(NSString *)CFBundleGetValueForInfoDictionaryKey(bundleRef,kCFBundleNameKey);
		[[bundleName retain]autorelease];
		CFRelease(bundleRef);
		
		NSString *kind=nil;
		
		if (includeKind){
			if ( ![[path pathExtension] caseInsensitiveCompare:@"prefPane"]){
				kind=QSIsLocalized?[self localizedPrefPaneKind]:@"Preference Pane";
			} else{
				LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:path],(CFStringRef *)&kind);  
				[kind autorelease];
			}
			if (bundleName && [kind length])
				return [NSString stringWithFormat:@"%@ %@",bundleName,kind];	
		}
		return bundleName;
}

- (void)getNameFromFiles{
    NSFileManager *manager=[NSFileManager defaultManager];
    NSString *newName=nil;
    NSString *newLabel=nil;
    if ([self count]>1){
		NSArray *paths=[self arrayForType:QSFilePathType];
        NSString *container=[self filesContainer];
        NSString *type=[self filesType];
        BOOL onDesktop=[container isEqualToString:[@"~/Desktop/" stringByStandardizingPath]];
        newName=[NSString stringWithFormat:@"%d %@ %@ \"%@\"",[paths count],type, onDesktop?@"on":@"in",[container lastPathComponent]];
    }else{
        NSString *path=[self objectForType:QSFilePathType];
        
        LSItemInfoRecord infoRec;
        LSCopyItemInfoForURL((CFURLRef)[NSURL fileURLWithPath:path],kLSRequestBasicFlagsOnly, &infoRec);
        
        if (infoRec.flags & kLSItemInfoIsPackage){
			newLabel=[self descriptiveNameForPackage:(NSString *)path withKindSuffix:!(infoRec.flags & kLSItemInfoIsApplication)];
			if ([newLabel isEqualToString:newName])newLabel=nil;
        }
		if (!newName){
            newName=[path lastPathComponent];
         //   if (infoRec.flags & kLSItemInfoExtensionIsHidden) newName=[newName stringByDeletingPathExtension];
        }
        if (!newLabel && ![self label]){
            newLabel=[manager displayNameAtPath:path];
            if ([newName isEqualToString:newLabel]) newLabel=nil;
        }
        if ([path isEqualToString:@"/"]) newLabel=[manager displayNameAtPath:path];
    }
    [self setName:newName]; 
    [self setLabel:newLabel]; 
}


- (NSString *)filesContainer{
    NSArray *paths=[self arrayForType:QSFilePathType];
    
    NSString *commonPath=[[[paths objectAtIndex:0]stringByStandardizingPath]stringByDeletingLastPathComponent];
    for (id loopItem in paths){
        NSString *thisPath=[loopItem stringByStandardizingPath];
        while (commonPath && ![thisPath hasPrefix:commonPath])
            commonPath=[commonPath stringByDeletingLastPathComponent];
    }
    return commonPath;    
}

- (NSString *)singleFileType{
	return [[NSFileManager defaultManager]typeOfFile:[self singleFilePath]];
}


- (NSString *)filesType{
    BOOL appsOnly=YES;
    BOOL foldersOnly=YES;
    BOOL filesOnly=YES;
    
    NSString *kind=nil;
    NSArray *paths=[self arrayForType:QSFilePathType];
    
    for (id loopItem in paths){
        NSString *thisPath=[loopItem stringByStandardizingPath];
        NSString *type=[[NSFileManager defaultManager]typeOfFile:thisPath];
        
        //QSLog(@"type %@",type);
        if ([type isEqualToString:@"'fold'"]){
            filesOnly=NO;
            appsOnly=NO;
        } else if ([type isEqualToString:@"app"]||[type isEqualToString:@"'APPL'"]){
            foldersOnly=NO;
            filesOnly=NO;
        } else {
            appsOnly=NO;
            foldersOnly=NO;
			
			if (!kind){
				kind=[self kindOfFile:thisPath];
			}else if (![kind isEqualToString:[self kindOfFile:thisPath]]){
				kind=@"";
			}
			
			
        }
    }
    
	if (appsOnly) return @"Applications";
    if (foldersOnly) return @"Folders";
    if (filesOnly){
		if ([kind length])return [NSString stringWithFormat:@"[%@]",kind];
		return @"Files";
	}	
	return @"Items";
}

-(NSString *)kindOfFile:(NSString *)path{
	if (!path)return nil;
	NSString *kind;
	OSStatus err=LSCopyKindStringForURL((CFURLRef)[NSURL fileURLWithPath:path],(CFStringRef *)&kind);
	if (!err) return [kind autorelease];
	return nil;
}

- (QSObject *)fileObjectByMergingWith:(QSObject *)mergeObject{
    // NSArray *moreFiles=[[mergeObject dataDictionary]objectForKey:QSFilePathType;
    return nil;
    
}




@end

