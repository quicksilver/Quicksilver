#import "QSResourceManager.h"
#import "QSRegistry.h"
#import "QSLocalization.h"
#import "QSGCD.h"

#define gSysIconBundle @"/System/Library/CoreServices/CoreTypes.bundle"

QSResourceManager * QSRez;

@implementation QSResourceManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        QSRez = [[self alloc] init];
    });
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
		NSMutableDictionary *locations = [NSMutableDictionary dictionaryWithContentsOfFile: [[NSBundle mainBundle] pathForResource:@"ResourceLocations" ofType:@"plist"]];
        resourceDict = [[QSThreadSafeMutableDictionary alloc] init];
        [resourceDict setDictionary:locations];

		resourceOverrideList = nil;

		NSFileManager *fm = [NSFileManager defaultManager];
		resourceOverrideFolder = QSApplicationSupportSubPath(@"Resources", NO);
		if ([fm fileExistsAtPath:resourceOverrideFolder]) {
			NSArray *contents = [[fm contentsOfDirectoryAtPath:resourceOverrideFolder error:nil] pathsMatchingExtensions:[NSImage imageTypes]];
			resourceOverrideList = [NSDictionary dictionaryWithObjects:contents forKeys:[contents valueForKey:@"stringByDeletingPathExtension"]];
		} else {
			resourceOverrideFolder = nil;
		}
        resourceQueue = dispatch_queue_create("QSResourceManagerQueue", DISPATCH_QUEUE_SERIAL);
        slashNames = [NSMutableSet set];
	}
	return self;
}

- (NSImage *)sysIconNamed:(NSString *)name {
    __block NSString *path;
    QSGCDQueueSync(resourceQueue, ^{
        path = [[NSBundle bundleWithPath:gSysIconBundle] pathForResource:name ofType:@"icns"];
    });
	if (!path) return nil;
	return [[NSImage alloc] initByReferencingFile:path];
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
            image = [[NSImage alloc] initByReferencingFile:[resourceOverrideFolder stringByAppendingPathComponent:file]];
        [image setName:name];
        
    }
    
    id locator = [resourceDict objectForKey:name];
    if ([locator isKindOfClass:[NSNull class]]) return nil;
    if (locator)
        image = [self imageWithLocatorInformation:locator];
    return image;
}

- (NSImage *)imageNamed:(NSString *)name {
	return [self imageNamed:name inBundle:nil];
}

- (NSImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle {
    if (!name) {
        return nil;
    }
    
    __block NSImage *image = [NSImage imageNamed:name];
    if (image) {
        return image;
    }
    
    if (!image && resourceOverrideList) {
        NSString *file = [resourceOverrideList objectForKey:name];
        if (file) {
            image = [[NSImage alloc] initByReferencingFile:[resourceOverrideFolder stringByAppendingPathComponent:file]];
        }
        [image setName:name];
    }
    
    QSGCDQueueSync(resourceQueue, ^{
        if (!image && bundle) { image = [bundle imageNamed:name]; }
    });
    
    if (image) { return image; }
    
    id locator = [resourceDict objectForKey:name];
    if ([locator isKindOfClass:[NSNull class]]) { return nil; }
    if (locator) {
        image = [self imageWithLocatorInformation:locator];
    } else if (!image && ([name hasPrefix:@"/"] || [name hasPrefix:@"~"])) { // !!! Andre Berg 20091007: Try iconForFile first if name looks like ordinary path
        NSString *path = [name stringByStandardizingPath];
        if ([[NSImage imageUnfilteredTypes] containsObject:[path pathExtension]]) {
            image = [[NSImage alloc] initByReferencingFile:path];
        } else {
            image = [[NSWorkspace sharedWorkspace] iconForFile:path];
        }
    } else {// Try the systemicons bundle
        image = [self sysIconNamed:name];
        if (!image) { // Try by bundle id
            image = [self imageWithLocatorInformation:[NSDictionary dictionaryWithObjectsAndKeys:name, @"bundle", nil]];
        }
    }
    if (!image && [locator isKindOfClass:[NSString class]]) {
        image = [self imageNamed:locator];
    }
    
    if(!image) {
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@Image", name]);
        if ([self respondsToSelector:selector]) {
            image = ((NSImage* (*)(id, SEL))[self methodForSelector:selector])(self, selector);
        }
    }
    
    if (!image) {
        [resourceDict setObject:[NSNull null] forKey:name];
    } else {
        [image setName:name];
    }
    return image;
}

- (NSString *)pathWithLocatorInformation:(id)locator {
	__block NSString *path = nil;
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
		NSUInteger i;
		for (i = 0; i < [(NSArray *)locator count]; i++) {
			path = [self pathWithLocatorInformation:[locator objectAtIndex:i]];
			if (path) break;
		}
	} else if ([locator isKindOfClass:[NSDictionary class]]) {
        QSGCDQueueSync(resourceQueue, ^{
            NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
            NSString *bundleID = [locator objectForKey:@"bundle"];
            NSBundle *bundle = [QSReg bundleWithIdentifier:bundleID];
            if (!bundle)
                bundle = [NSBundle bundleWithPath:[workspace absolutePathForAppBundleWithIdentifier:bundleID]];
            
            NSString *resourceName = [locator objectForKey:@"resource"];
            // NSString *type = [locator objectForKey:@"type"];
            NSString *subPath = [locator objectForKey:@"path"];
            
            NSString *basePath = [bundle bundlePath];
            // NSString *basePath = [workspace absolutePathForAppBundleWithIdentifier:bundle];
            // NSLog(@"loc %@ %@", locator, path);
            
            if (resourceName) {
                path = [bundle pathForResource:[resourceName stringByDeletingPathExtension]
                                        ofType:[resourceName pathExtension]];
            } else if (subPath) {
                path = [basePath stringByAppendingPathComponent:subPath]; ;
            }
        });
	}
	return path;
}

- (NSImage *)imageWithLocatorInformation:(id)locator {
	__block NSImage *image = nil;
	if ([locator isKindOfClass:[NSArray class]]) {
		NSUInteger i;
		for (i = 0; i<[(NSArray *)locator count]; i++) {
			image = [self imageWithLocatorInformation:[locator objectAtIndex:i]];
			if (image) break;
		}
	} else {
		image = [[NSImage alloc] initWithContentsOfFile:[self pathWithLocatorInformation:locator]];
	}

	if (!image && [locator isKindOfClass:[NSDictionary class]]) {
        QSGCDQueueSync(resourceQueue, ^{
            NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
            NSString *bundleID = [locator objectForKey:@"bundle"];
            NSBundle *bundle = [QSReg bundleWithIdentifier:bundleID];
            
            if (!bundle) {
                bundle = [NSBundle bundleWithPath:[workspace absolutePathForAppBundleWithIdentifier:bundleID]];
            }
            if(bundle != nil) {
                image = [workspace iconForFile:[bundle bundlePath]];
            } else {
                // try and find an icon for the file type
                if ([locator objectForKey:@"type"]) {
                    image = [workspace iconForFileType:[locator objectForKey:@"type"]];
                }
            }
            
#ifdef DEBUG
            if(!image) {
                NSLog(@"Unable to locate bundle with identifier %@, using locator %@", bundleID, locator);
            }
#endif
        });
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
        if (QSGetLocalizationStatus())
            QSGCDQueueSync(resourceQueue, ^{
                [NSBundle registerLocalizationBundle:bundle forLanguage:info];
            });
        }
	return YES;
}
@end
