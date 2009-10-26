#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSLocalization.h"

NSString *gSysIconBundle = nil;
id QSRez;

@implementation QSResourceManager
#if 0
- (NSImage *)daedalusImage {
	static NSImage *daedalusImage = nil;
	if (!daedalusImage) {
		daedalusImage = [[NSImage alloc] initWithData:[[self imageNamed:@"FinderIcon"] TIFFRepresentation]];
		[daedalusImage setCacheMode:NSImageCacheNever];
		[daedalusImage setScalesWhenResized:NO];
		DRColorPermutator *perm = [[[DRColorPermutator alloc] init] autorelease];
		[perm rotateHueByDegrees:140 preservingLuminance:YES fromScratch:YES];
		[perm applyToBitmapImageRep:(NSBitmapImageRep *)[daedalusImage bestRepresentationForDevice:nil]];

		[daedalusImage lockFocus];
		[[NSColor whiteColor] set];
		NSRectFill(NSMakeRect(37, 84, 5, 13) );
		NSRectFill(NSMakeRect(82, 84, 5, 13) );
		[daedalusImage unlockFocus];

		[daedalusImage createIconRepresentations];
		//	NSLog(@"daed");
	}
	return daedalusImage;
}
#endif
+ (void)initialize {
	//[[NSImage imageNamed:@"DefaultBookmarkIcon"] setScalesWhenResized:YES];
	//SInt32 version;
	//Gestalt (gestaltSystemVersion, &version);
	//if (version < 0x1040)
	//	gSysIconBundle = @"/System/Library/CoreServices/SystemIcons.bundle";
	//else
	gSysIconBundle = @"/System/Library/CoreServices/CoreTypes.bundle";
	//	NSLog(@"Using %@", gSysIconBundle);
}

+ (id)sharedInstance {
	if (!QSRez) QSRez = [[[self class] allocWithZone:[self zone]] init];
	return QSRez;
}
+ (NSImage *)imageNamed:(NSString *)name {
	return [[self sharedInstance] imageNamed:name];
}

+ (NSImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
	return [[self sharedInstance] imageNamed:name inBundle:bundle];
}
- (id)init {
	if (self = [super init]) {
		resourceDict = [[NSMutableDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ResourceLocations" ofType:@"plist"]]retain];

		resourceOverrideList = nil;

		NSFileManager *fm = [NSFileManager defaultManager];
		resourceOverrideFolder = QSApplicationSupportSubPath(@"Resources", NO);
		if ([fm fileExistsAtPath:resourceOverrideFolder]) {
			[resourceOverrideFolder retain];
			NSArray *contents = [[fm contentsOfDirectoryAtPath:resourceOverrideFolder error:nil] pathsMatchingExtensions:[NSImage imageFileTypes]];
			resourceOverrideList = [[NSDictionary dictionaryWithObjects:contents forKeys:[contents valueForKey:@"stringByDeletingPathExtension"]]retain];
		} else {
			resourceOverrideFolder = nil;
		}

	}
	return self;
}

- (NSImage *)sysIconNamed:(NSString *)name {
	NSString *path = [[NSBundle bundleWithPath:gSysIconBundle] pathForResource:name ofType:@"icns"];
	if (!path) return nil;
	return [[[NSImage alloc] initByReferencingFile:path] autorelease];
}
- (NSString *)resourceNamed:(NSString *)name inBundle:(NSBundle *)bundle {
	return nil;
}
- (NSString *)pathForImageNamed:(NSString *)name {
	id locator = [resourceDict objectForKey:name];
	return [self pathWithLocatorInformation:locator];
}

- (NSImage *)imageWithExactName:(NSString *)name {
	NSImage *image = [NSImage imageNamed:name];
	if (!image && resourceOverrideList) {
		NSString *file = [resourceOverrideList objectForKey:name];
		if (file)
			image = [[[NSImage alloc] initByReferencingFile:[resourceOverrideFolder stringByAppendingPathComponent:file]]autorelease];
		[image setName:name];

	}

	id locator = [resourceDict objectForKey:name];
	if ([locator isKindOfClass:[NSNull class]]) return nil;
	if (locator)
		image = [self imageWithLocatorInformation:locator];
	return image;
}

- (NSImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {

	if (!name) return nil;

	NSImage *image = [NSImage imageNamed:name];
	if (!image && resourceOverrideList) {
		NSString *file = [resourceOverrideList objectForKey:name];
		if (file)
			image = [[[NSImage alloc] initByReferencingFile:[resourceOverrideFolder stringByAppendingPathComponent:file]] autorelease];
		[image setName:name];

	}
	if (!image && bundle) image = [bundle imageNamed:name];
	if (image) return image;

	id locator = [resourceDict objectForKey:name];
	if ([locator isKindOfClass:[NSNull class]]) return nil;
	if (locator)
		image = [self imageWithLocatorInformation:locator];
    else if (!image && ([name hasPrefix:@"/"] || [name hasPrefix:@"~"]) ) { // !!! Andre Berg 20091007: Try iconForFile first if name looks like ordinary path
        NSString *path = [name stringByStandardizingPath];
        if ([[NSImage imageUnfilteredFileTypes] containsObject:[path pathExtension]])
            image = [[[NSImage alloc] initByReferencingFile:path] autorelease];
        else
            image = [[NSWorkspace sharedWorkspace] iconForFile:path];        
    } else {// Try the systemicons bundle
		image = [self sysIconNamed:name];
        if (!image) // Try by bundle id
			image = [self imageWithLocatorInformation:[NSDictionary dictionaryWithObjectsAndKeys:name, @"bundle", nil]];

// !!! Andre Berg 20091007: commented out because we use it as case in if/else above
// 		if (!image && ([name hasPrefix:@"/"] || [name hasPrefix:@"~"]) ) {
// 			NSString *path = [name stringByStandardizingPath];
// 			if ([[NSImage imageUnfilteredFileTypes] containsObject:[path pathExtension]])
// 				image = [[[NSImage alloc] initByReferencingFile:path] autorelease];
// 			else
// 				image = [[NSWorkspace sharedWorkspace] iconForFile:path];
// 		}

		// NSLog(@"iconbundle %@ %@", name, image);
	}
	if (!image && [locator isKindOfClass:[NSString class]]) {
		image = [self imageNamed:locator];
	}

	SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@Image", name]);
	if ([self respondsToSelector:selector])
		image = [self performSelector:selector];

	if (0 && !image) {
		if (VERBOSE) NSLog(@"Searching for image: %@", name);

		NSEnumerator *bundEnumer = [[NSBundle allBundles] objectEnumerator];
		NSBundle *bundle;
		while (bundle = [bundEnumer nextObject]) {
			NSString *path = [bundle pathForImageResource:name];
			if (path) {
				image = [[[NSImage alloc] initByReferencingFile:path] autorelease];
			}
		}
	}

	if (!image) {
	 // if (VERBOSE) NSLog(@"Image Not Found: %@", name);
		if (!image) [resourceDict setObject:[NSNull null] forKey:name];

		return nil;
	} else {
		[image setName:name];

		if (![image representationOfSize:NSMakeSize(32, 32)])
			[image createRepresentationOfSize:NSMakeSize(32, 32)];
		if (![image representationOfSize:NSMakeSize(16, 16)])
			[image createRepresentationOfSize:NSMakeSize(16, 16)];
		return image;
	}
}

- (NSImage *)imageNamed:(NSString *)name {
	return [self imageNamed:name inBundle:nil];
}

- (NSString *)pathWithLocatorInformation:(id)locator {
	NSString *path = nil;
	if ([locator isKindOfClass:[NSString class]]) {
		if (![locator length]) return nil;
		if ([locator hasPrefix:@"["]) {
			NSArray *components = [[locator substringFromIndex:1] componentsSeparatedByString:@"] :"];
			if ([components count] >1)
				return [self pathWithLocatorInformation:[NSDictionary dictionaryWithObjectsAndKeys:
					[components objectAtIndex:0] , @"bundle",
					[components objectAtIndex:1] , @"resource",
					nil]];
		} else {
			return locator;
		}
	} else if ([locator isKindOfClass:[NSArray class]]) {
		int i;
		for (i = 0; i<[locator count]; i++) {
			path = [self pathWithLocatorInformation:[locator objectAtIndex:i]];
			if (path) break;
		}
	} else if ([locator isKindOfClass:[NSDictionary class]]) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSString *bundleID = [locator objectForKey:@"bundle"];
		NSBundle *bundle = [QSReg bundleWithIdentifier:bundleID];
		if (!bundle)
			bundle = [NSBundle bundleWithPath:[workspace absolutePathForAppBundleWithIdentifier:bundleID]];

		NSString *resourceName = [locator objectForKey:@"resource"];
		//NSString *type = [locator objectForKey:@"type"];
		NSString *subPath = [locator objectForKey:@"path"];

		NSString *basePath = [bundle bundlePath];
		// NSString *basePath = [workspace absolutePathForAppBundleWithIdentifier:bundle];
		//  NSLog(@"loc %@ %@", locator, path);

		if (resourceName) {
			path = [bundle pathForResource:[resourceName stringByDeletingPathExtension]
								 ofType:[resourceName pathExtension]];
		} else if (subPath) {
			path = [basePath stringByAppendingPathComponent:subPath]; ;
		}

	}
	return path;

}

- (NSImage *)imageWithLocatorInformation:(id)locator {
	NSImage *image = nil;
	if ([locator isKindOfClass:[NSArray class]]) {
		int i;
		for (i = 0; i<[locator count]; i++) {
			image = [self imageWithLocatorInformation:[locator objectAtIndex:i]];
			if (image) break;
		}
	} else {
		image = [[[NSImage alloc] initWithContentsOfFile:[self pathWithLocatorInformation:locator]] autorelease];
	}

	if (!image && [locator isKindOfClass:[NSDictionary class]]) {
		NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
		NSString *bundleID = [locator objectForKey:@"bundle"];
		NSBundle *bundle = [QSReg bundleWithIdentifier:bundleID];

		if (!bundle)
			bundle = [NSBundle bundleWithPath:[workspace absolutePathForAppBundleWithIdentifier:bundleID]];
        
        if(bundle != nil) {
            image = [workspace iconForFile:[bundle bundlePath]];
        } else {
            image = [workspace iconForFileType:[locator objectForKey:@"type"]];
        }
        if(!image && DEBUG)
            NSLog(@"Unable to locate bundle with identifier %@, using locator %@", bundleID, locator);
	}
	return image;
}

- (void)addResourcesFromDictionary:(NSDictionary *)dict {
	[resourceDict addEntriesFromDictionary:dict];
}

@end

@implementation QSResourceManager (QSPlugInInfo)
- (BOOL)handleInfo:(id)info ofType:(NSString *)type fromBundle:(NSBundle *)bundle {
	if ([type isEqualToString:@"QSResourceAdditions"]) {
		[self addResourcesFromDictionary:info]; // inBundle:bundle];
    } else {
			if (QSIsLocalized)
				[NSBundle registerLocalizationBundle:bundle forLanguage:info];
		}
	return YES;
}
@end
