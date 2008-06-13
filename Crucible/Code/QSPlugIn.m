//
//  QSPlugInInfo.m
//  Quicksilver
//
//  Created by Alcor on 2/5/05.

//

#import "QSPlugIn.h"

#import "QSResourceManager.h"
#import "QSPlugInManager.h"
#import "QSFoundation.h"
#import "QSExecutor.h"
#import "QSLibrarian.h"

#import "QSNotifications.h"


#import "NSString+NDUtilities.h"

#import "NSException_TraceExtensions.h"

//#include <mach-o/dyld_debug.h>
//#include <mach-o/dyld.h>
// char *dyld_framework_path __attribute__((weak_import));

//static
NSMutableDictionary *plugInBundlePaths = nil;

@implementation QSPlugIn

+ (void) initialize {
	plugInBundlePaths = [[NSMutableDictionary alloc] init];
	[self setKeys:[NSArray arrayWithObject:@"bundle"] triggerChangeNotificationsForDependentKey:@"smallIcon"];
}

- (NSString *) description {
    return [NSString stringWithFormat:@"<%@ %p>", [self name], self];
}

- (id) initWithBundle:(NSBundle *)aBundle {
	id dup = [plugInBundlePaths valueForKey:[aBundle bundlePath]];
    
	if (dup) {
        if(DEBUG) QSLog( @"Duplicate plugin, ignoring" );
		[self release];
		return [dup retain];
	}
	if ((self = [super init])) {
		[self setBundle:aBundle];
	}
	return self;
}

- (id) initWithWebInfo:(NSDictionary *)webInfo {
	if ((self = [super init])) {
		data = [webInfo retain];
		bundle = nil;
	}
	return self;
}

+ (id) plugInWithBundle:(NSBundle *)aBundle {
	return [[[QSPlugIn alloc] initWithBundle:aBundle] autorelease];	
}

+ (id) plugInWithWebInfo:(NSDictionary *)webInfo {
	return [[[QSPlugIn alloc] initWithWebInfo:webInfo] autorelease];	
}

- (void)dealloc {
	[self setBundle:nil];
	[bundle release];
	[data release];
	[super dealloc];
}

- (void)downloadFailed {
	installing = NO;
	[self willChangeValueForKey:@"enabled"];
	[self didChangeValueForKey:@"enabled"];
}

- (NSURL *)downloadURL {
	return [NSURL URLWithString:[[QSPlugInManager sharedInstance] urlStringForPlugIn:[self identifier] version:nil]];
}

- (void) install {
	installing = YES;
	NSString *identifier = [[self info] objectForKey:@"CFBundleIdentifier"];
	[[QSPlugInManager sharedInstance] installPlugInsForIdentifiers:[NSArray arrayWithObject:identifier]];
	[self willChangeValueForKey:@"enabled"];
	[self didChangeValueForKey:@"enabled"];
}

- (NSString *) shortName {
	NSString *name = nil;
	if (bundle) name = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
	if (!name)name = [data objectForKey:(NSString *)kCFBundleNameKey];
	if ([name hasSuffix:@" Module"]) name = [name substringToIndex:[name length] - 7];
	if ([name hasSuffix:@" Actions"]) name = [name substringToIndex:[name length] - 8];
	return name;
}

- (NSString *) name {
	NSString *name = nil;
	if (bundle) name = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
	if (!name) name = [data objectForKey:(NSString *)kCFBundleNameKey];
    
	int feature = [[[self info] valueForKeyPath:@"QSRequirements.feature"] intValue];
	if (feature == 1) {
		name = [name stringByAppendingFormat:@" (+)" , 0x25B8];
	} else if (feature == 2) {
		name = [name stringByAppendingFormat:@" (%C)", 0x03B2];
	} else if (feature > 2) {
		name = [name stringByAppendingFormat:@" (%C)", 0x03B1];
	}
	if (DEBUG && !data)
		name = [name stringByAppendingFormat:@" - Private", 0x03B1];
//	if (DEBUG && [self isUniversal]){
//		name=[name stringByAppendingFormat:@" - U"];	
//	}
    if (DEBUG && [self isSecret]) {
		name = [name stringByAppendingFormat:@" - Secret"];	
	}
	
	return name;
}

- (NSString *) status {
	
	NSString *error = [self loadError];
	NSString *status = nil;
	
	if (!bundle) {
		if (installing)
			return @"Downloading";
		else
			return @"Downloadable";
	}
	if ([self isLoaded]) {
		if ( [bundle isLoaded]) {
			int fileSize = [[[[NSFileManager defaultManager] fileAttributesAtPath:[bundle executablePath] traverseLink:YES] objectForKey:NSFileSize] intValue];
			
			status = [NSString stringWithFormat:@"Loaded (%dk)", fileSize / 1024];
		} else {
			status = @"Loaded";
		}
	} else if (error) {
		status = [NSString stringWithFormat:@"Error (%@)", error];
	} else {
		status = @"Disabled";
	}
	return status;
}

- (NSString *) statusBullet {
    if ([self isLoaded])
        return [NSString stringWithFormat:@"%C", ([bundle isLoaded] ? 0x25C6 : 0x25C7)];
        
#warning FIXME: return "" or "*" ?
    return @"";
	return @"*";
}

- (BOOL) isUniversal {
	if (![bundle executablePath])
        return NO;
    
	NSString *str = [NSString stringWithFormat:@"/usr/bin/lipo -info \"%@\"", [bundle executablePath]];
	FILE *file = popen( [str UTF8String], "r" );
	NSString *output = nil;
	NSMutableData *pipeData = [NSMutableData data];
    
	if( file )
	{
		char buffer[1024];
		size_t length;
		while ((length = fread( buffer, 1, sizeof( buffer ), file )))
            [pipeData appendBytes:buffer length:length];
		output = [[[NSString alloc] initWithData:pipeData encoding:NSUTF8StringEncoding] autorelease];
		pclose( file );
	} 
	
	//QSLog(@"output%@", output);
	return [output containsString:@"i386" options:0];
}

- (NSDictionary *) info {
    return (bundle ? [bundle infoDictionary] : data);
}

- (NSString *) author {
	return [[self info] valueForKeyPath:@"QSPlugIn.author"];	
}

- (NSString *) byline {
	NSString *author = [self author];
	if (![author length] || [author isEqualToString:@"Blacktree, Inc."])
        return @"";
	return [@"by " stringByAppendingString:author];
}




- (NSString *) helpPage {
	return [[self info] valueForKeyPath:@"QSPlugIn.helpPage"];	
}

- (NSArray *) dependencies {
	return [[self info] valueForKeyPath:@"QSRequirements.plugins"];	
}

- (void) showHelp {
	NSString *urlString = [NSString stringWithFormat:@"http://docs.blacktree.com/?page=%@", [self helpPage]];
	if (urlString)
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[urlString stringByReplacing:@" " with:@"+"]]];
}

- (NSDate *) createdDate {
    // FIXME
	return [NSDate date];
}
    
- (NSDate *) modifiedDate {
	if (data) {
		return [NSDate dateWithString:[data valueForKeyPath:@"QSModifiedDate"]];
	} else if (bundle) {
		NSDate *buildDate = [[[NSFileManager defaultManager] fileAttributesAtPath:[bundle executablePath]
                                                                     traverseLink:YES] fileModificationDate];
		if (!buildDate)
			buildDate = [[[NSFileManager defaultManager] fileAttributesAtPath:[bundle bundlePath]
                                                                 traverseLink:YES] fileModificationDate];
		
		return buildDate;
	}
	return nil;
}
    
- (NSString *) version {
	if (bundle) {
		NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		if (!version)
            version = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
		return version;
	}
    
	NSString *version = [data objectForKey:@"CFBundleShortVersionString"];
	if (!version) version = [data objectForKey:(NSString *)kCFBundleVersionKey];
	return version;
	
}

- (NSString *) buildVersion {
    return (bundle
            ? [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]
            : [data objectForKey:(NSString *)kCFBundleVersionKey] );
}

- (BOOL) isSecret {
	return [[[self info] valueForKeyPath:@"QSPlugIn.secret"] boolValue];
}


- (BOOL) isRecommended {
	if ([[[self info] valueForKeyPath:@"QSPlugIn.recommended"] boolValue])
        return YES;
	if ([self isInstalled] > 0)
        return NO;
	if (![self meetsFeature])
        return NO;

	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSArray *related = [self relatedBundles];

	foreach(bundleID, related) {
		if([ws absolutePathForAppBundleWithIdentifier:bundleID])
            return YES;
	}
	return NO;
}

- (BOOL) needsUpdate {	
	if (!bundle) return NO;
	//if (VERBOSE) QSLog(@"%@, %@->%@", [self name], [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey],[data objectForKey:(NSString *)kCFBundleVersionKey]);
	
    id dataVersion = [data objectForKey:(NSString *)kCFBundleVersionKey];
    id bundleVersion = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
    
	return [dataVersion versionCompare:bundleVersion] > 0;
}
- (NSArray *) categories {
	return [[self info] valueForKeyPath:@"QSPlugIn.categories"];
}

- (NSArray *) relatedBundles {
	return [[self info] valueForKeyPath:@"QSPlugIn.relatedBundles"];
}

- (NSArray *) recommendations {
	return [[self info] valueForKeyPath:@"QSPlugIn.recommendations"];
}

- (NSString *) shortDescription {
	NSDictionary *plist = [self info];
	return [plist valueForKeyPath:@"QSPlugIn.description"];
}

- (NSString *)infoHTML {
	
	static NSDictionary *attributes = nil;
	if (!attributes)
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      [NSFont systemFontOfSize:[NSFont smallSystemFontSize]],	NSFontAttributeName,
                      nil];
	NSDictionary *plist = [self info];
	
	NSString *text = [plist valueForKeyPath:@"QSPlugIn.extendedDescription"];
	if (![text length])
        text = [plist valueForKeyPath:@"QSPlugIn.description"];
	if (!text)
        text = @"";
	
	//	QSLog(@"plist %@",text);
	
	text = [NSString stringWithFormat:@"<html><link rel=\"stylesheet\" href=\"resource:QSStyle.css\"><body>%@</body></html>", text];
	return text;
}

- (NSComparisonResult) compare:(id)other {
	return [[self name] compare:[other name]];	
}

- (NSString *) text {
	return [self name];
}

- (NSImage *) image {
	return [self icon];
}
    
- (NSData *) attributedDescription {
	
	static NSDictionary *attributes = nil;
	if (!attributes)
        attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                      [NSFont systemFontOfSize:[NSFont smallSystemFontSize]],	NSFontAttributeName,
                      nil];
	NSDictionary *plist = [self info];
	
	NSString *text = [plist valueForKeyPath:@"QSPlugIn.extendedDescription"];
	if (![text length])
        text = [plist valueForKeyPath:@"QSPlugIn.description"];
	if (!text)
        text = @"";
	
	//	QSLog(@"plist %@",text);re
	text = [NSString stringWithFormat:@"<font face=\"Lucida Grande\">%@</font>", text];
	NSMutableAttributedString *info = [[[NSMutableAttributedString alloc] initWithHTML:[text dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil] autorelease];
	
	//	QSLog(@"plist %@",info);
    
	if (!info)
        return [NSData data];	
	return [info RTFFromRange:NSMakeRange(0,[info length]) documentAttributes:nil];
}
    
- (void) clearWebData {
	[self setData:nil];
}

- (NSImage *) icon {
	if (!icon) {
		NSDictionary *pDict = [[self info] objectForKey:@"QSPlugIn"];
		NSString *text = [pDict objectForKey:@"icon"];	
		
        icon = [QSResourceManager imageNamed:text];
        
		if (!icon)
            icon = [QSResourceManager imageNamed:@"QSPlugIn"];
		[icon setSize:QSSize32];
		[icon retain];
	}
	return icon;
}

- (NSImage *) smallIcon {
	if (!smallIcon) {
		smallIcon = [[[self icon] copy] autorelease];
		[smallIcon shrinkToSize:QSSize16];
		[smallIcon retain];
	}
	return smallIcon;
}

- (int) isInstalled {
    return (bundle ? (installing ? -1 : 1) : 0);
}


- (BOOL) shouldInstall {
	return shouldInstall;
}
    
- (void) setShouldInstall:(BOOL)flag {
	shouldInstall = flag;
}

- (BOOL) isHidden {
	if (bundle == [NSBundle mainBundle])
        return YES;
	return [[[self info] valueForKeyPath:@"QSPlugIn.hidden"] boolValue];
}
    
- (BOOL) meetsFeature{
	return [[[self info] valueForKeyPath:@"QSRequirements.feature"] intValue] <= [NSApp featureLevel];
}

- (BOOL) isLoaded {
    return loaded;
}

#define disabledPlugIns [[NSUserDefaults standardUserDefaults]arrayForKey:@"QSDisabledPlugIns"]
    
- (NSColor *) enabledColor {
	return ([self isInstalled] ? [NSColor blackColor] : [NSColor grayColor]);
}
    
- (NSString *) identifier {
    return [[self info] valueForKey:(NSString *)kCFBundleIdentifierKey];
}

- (NSString *) bundleIdentifier {
    return [bundle bundleIdentifier];
}
    
- (NSString *) path {
    return [bundle bundlePath];
}

- (NSString *) bundlePath {
    return [bundle bundlePath];
}

- (int) enabled {
	if (!bundle)
        return (installing ? NSMixedState : NSOffState);
	return ![disabledPlugIns containsObject:[bundle bundleIdentifier]];
}
    
- (void) setEnabled:(BOOL)flag {
	if (![self isInstalled]) {
		[self install];	
	} else if (bundle) {
		NSString *identifier = [bundle bundleIdentifier];
		
		NSMutableSet *disabledPlugInsSet = [[NSMutableSet alloc] init];
		[disabledPlugInsSet addObjectsFromArray:disabledPlugIns];
		
		if (flag) {
			[disabledPlugInsSet removeObject:identifier];
		} else {
			[disabledPlugInsSet addObject:identifier];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[disabledPlugInsSet allObjects] forKey:@"QSDisabledPlugIns"];
		
		if (flag) {
			[[QSPlugInManager sharedInstance] liveLoadPlugIn:self];
			[[QSPlugInManager sharedInstance] checkForUnmetDependencies];
		} else {
#warning TODO: Unloading !
        }
	}
}


- (BOOL) canBeDisabled {
	//	QSLog(@"%@ path",[bundle bundlePath]);
	return ![[bundle bundlePath] hasPrefix:[[NSBundle mainBundle] bundlePath]];
	
}

- (BOOL) reveal {
	return [[NSWorkspace sharedWorkspace] selectFile:[bundle bundlePath]
                            inFileViewerRootedAtPath:@""];
}

- (BOOL) delete {
    return [[QSPlugInManager sharedInstance] deletePlugin:self];
}

- (NSBundle *) bundle {
    return [[bundle retain] autorelease];
}

- (void) setBundle:(NSBundle *)newBundle {
    // FIXME: Debug ?
	if ([newBundle isKindOfClass:[QSPlugIn class]]) {
		NSBeep();
	}
    
	[icon release];
	icon = nil;
	[smallIcon release];
	smallIcon = nil;
	[self retain];
	if (bundle) {
		[self retain];
		[plugInBundlePaths removeObjectForKey:[bundle bundlePath]];
		[bundle autorelease];
	}
	bundle = [newBundle retain];
	if (bundle) {
		[plugInBundlePaths setObject:self forKey:[bundle bundlePath]];
		[self release];
	}
	[self release];
}

- (NSMutableDictionary *) data {
    return [[data retain] autorelease];
}

- (void) setData:(NSMutableDictionary *)newData {
    [data autorelease];
    data = [newData retain];
}

- (NSString *) loadError {
    return [[loadError retain] autorelease];
}

- (void) setLoadError:(NSString *)newLoadError {
    [loadError autorelease];
    loadError = [newLoadError retain];
}
@end

@implementation QSPlugIn (Registry)
- (NSArray *) unmetDependencies {
	NSArray *plugIns = [self dependencies];
	NSMutableArray *unmet = [NSMutableArray array];
	foreach(plugInDict, plugIns) {
		NSString *identifier = [plugInDict objectForKey:@"id"];
		
		if (![[[QSPlugInManager sharedInstance] loadedPlugIns] objectForKey:identifier]) {
			//	NSString *name=[plugInDict objectForKey:@"id"];
			//if (error) *error=[NSString stringWithFormat:@"Requires PlugIn '%@'",name?name:identifier];
			//QSLog(@"%@ requires %@",[self name],name);
			[unmet addObject:plugInDict];
		}
	}
	return unmet;
}

- (BOOL) meetsRequirements:(NSString **)error {
	NSDictionary *requirementsDict = [bundle dictionaryForFileOrPlistKey:@"QSRequirements"];
	
	*error = nil;
    
	if (requirementsDict) {
		NSArray *bundles = [requirementsDict objectForKey:@"bundles"];
        
		if (![[NSUserDefaults standardUserDefaults] boolForKey:@"QSIgnorePlugInBundleRequirements"]) {
			foreach(bundleDict, bundles) {
                // FIXME
				break;
				NSString *identifier = [bundleDict objectForKey:@"id"];
				NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:identifier];
				if (!path) {
					NSString *name = [bundleDict objectForKey:@"name"];
					if (error)
                        *error = [NSString stringWithFormat:@"Requires Bundle '%@'", (name ? name : identifier)];
					return NO;
				}
#warning add support for version checking
			}
            
			NSArray *frameworks = [requirementsDict objectForKey:@"frameworks"];
			foreach(frameworkDict, frameworks) {
				NSString *identifier = [frameworkDict objectForKey:@"id"];
				NSString *resource = [frameworkDict objectForKey:@"resource"];
				NSString *path = [[QSResourceManager sharedInstance] pathWithLocatorInformation:resource];
                
				NSBundle *pathBundle = [NSBundle bundleWithPath:path];
                
				[pathBundle load];
                
				QSLog(@"path %@ %@ %@", path, resource, pathBundle);
				
				if (!path) {
					NSString *name = [frameworkDict objectForKey:@"name"];
					if (error)
                        *error = [NSString stringWithFormat:@"Requires Framework '%@'", (name ? name : identifier)];
					return NO;
				}
			}
		}	
		
		NSArray *paths = [requirementsDict objectForKey:@"paths"];
		foreach(path, paths) {
			if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath]]){
				if (error)
                    *error = [NSString stringWithFormat:@"Path not found: '%@'", path];
				return NO;
			}
		}
		
		NSString *qsVersion = [requirementsDict objectForKey:@"version"];
		if (qsVersion) {
			NSComparisonResult sorting = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] versionCompare:qsVersion];
			if (sorting < 0) {
				if (error)
                    *error = [NSString stringWithFormat:@"Requires Quicksiver Build %@", qsVersion];
				return NO;
			}
		}
    }
		
//		int feature=[[requirementsDict objectForKey:@"feature"]intValue];
//		if (feature>[NSApp featureLevel]){
//			if (error) *error=@"Feature Level not Met";
//			return NO;
//		}
    return YES;
}

//- (BOOL)liveLoadPlugIn:(NSBundle *)bundle{
//	NSArray *disabledBundles=[[NSUserDefaults standardUserDefaults] objectForKey:@"QSDisabledPlugIns"];
//	
//	if ([disabledBundles containsObject:[self bundleIdentifier]])return YES;
//	if (![[QSPlugInManager sharedInstance] shouldLoadPlugIn:self inGroup:nil]) return NO;
//#warning this should be implemented internally
//	return [self registerPlugIn];
//}


//- (BOOL)loadOldActionProviders:(NSArray *)providerClasses{
//	NSEnumerator *e=[providerClasses objectEnumerator];
//	NSString *className;
//	while((className=[e nextObject])){
//		id instance=[QSReg getClassInstance:className];
//		[QSExec registerActions:instance];
//	}	
//	return YES;
//}

- (void) registerPlugInFrameworks {
    // FIXME
	return;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *frameworksPath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Frameworks"];
	
	if ([fm fileExistsAtPath:frameworksPath]) {
		char *var = getenv("DYLD_FRAMEWORK_PATH");
		NSString *frameworkVar = (var ? [NSString stringWithUTF8String:var] : @"");
		frameworkVar = [frameworkVar stringByAppendingFormat:@":%@", frameworksPath];
		setenv("DYLD_FRAMEWORK_PATH", [frameworkVar UTF8String], YES);
		QSLog(@"Adding Framework Search Path: %@", frameworksPath);
	}
	
	NSString *librariesPath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Libraries"];
	if ([fm fileExistsAtPath:librariesPath]) {
		char *var = getenv("DYLD_FRAMEWORK_PATH");
		NSString *libraryVar = (var ? [NSString stringWithUTF8String:var] : @"");
		libraryVar = [libraryVar stringByAppendingFormat:@":%@", librariesPath];
		setenv("DYLD_FRAMEWORK_PATH", [libraryVar UTF8String], YES);
		QSLog(@"Adding Library Search Path:\r%@", librariesPath);
	}	
	
	//QSLog(@"DYLD %s",dyld_framework_path);
}

- (BOOL) _registerPlugIn {
	if (!bundle)
        return NO;
	
	[QSReg registerBundle:bundle];
	[self registerPlugInFrameworks];
	
	if ([[bundle objectForInfoDictionaryKey:@"NSAppleScriptEnabled"] boolValue])
		[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];
	
	if (DEBUG_PLUGINS)
		QSLog(@"Loading PlugIn: %@ (%@)", [[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension], [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]);		
	BOOL loadNow = ![QSReg handleRegistration:bundle]; 
	
	id value;
	id handler;
	
	foreachkey(key, handlerClass, [QSReg elementsByIDForPointID:kQSPlugInInfoHandlers]) {
		value = [bundle dictionaryForFileOrPlistKey:key];
		if (!value)
            continue;
		//QSLog(@"----> Registering %@ for %@",key, [self name]);
		handler = [QSReg getClassInstance:handlerClass];
		if ([handler respondsToSelector:@selector(handleInfo:ofType:fromBundle:)])
			[handler handleInfo:value ofType:key fromBundle:[self bundle]];
	}
	
	loadNow |= [[bundle objectForInfoDictionaryKey:@"QSLoadImmediately"] boolValue];
	
	Class currPrincipalClass;
	if (loadNow) {
		currPrincipalClass = [bundle principalClass];
		if (currPrincipalClass) {
			if (DEBUG_PLUGINS) QSLog(@"Forcing Load of Class %@", currPrincipalClass);
			
			if ([currPrincipalClass respondsToSelector:@selector(loadPlugIn)])
				[currPrincipalClass loadPlugIn];
		}
	}
#warning FIXME: We are saying we are loaded even if we are not ?
	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInLoadedNotification object:self];
	loaded = YES;
	return YES;
}


- (BOOL) registerPlugIn {
    [QSPlugInManager sharedInstance];
    
	NS_DURING
		[self _registerPlugIn];
	NS_HANDLER
		NSString *errorMessage = [NSString stringWithFormat:@"An error ocurred while loading plug-in \"%@\": %@",self, localException];
		if (VERBOSE) {
			QSLog(errorMessage);
			[localException printStackTrace];
		}
		[self setLoadError:[localException reason]];
	NS_ENDHANDLER
	return YES;
}

@end
