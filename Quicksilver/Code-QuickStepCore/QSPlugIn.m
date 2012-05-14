//
// QSPlugInInfo.m
// Quicksilver
//
// Created by Alcor on 2/5/05.
// Copyright 2005 Blacktree. All rights reserved.
//

#import "QSPlugIn.h"
#import "QSRegistry.h"
#import "QSResourceManager.h"
#import "QSPlugInManager.h"
#import "QSFoundation.h"
#import "QSExecutor.h"
#import "QSLibrarian.h"
#import "QSNotifications.h"
#import "NSString+NDUtilities.h"
#import "NSException_TraceExtensions.h"
#import "QSPreferenceKeys.h"

//static
NSMutableDictionary *plugInBundlePaths = nil;

@implementation QSPlugIn

@synthesize status;

+ (void)initialize {
	plugInBundlePaths = [[NSMutableDictionary alloc] init];
	[self setKeys:[NSArray arrayWithObject:@"bundle"] triggerChangeNotificationsForDependentKey:@"smallIcon"];
}

- (NSString *)description {return [NSString stringWithFormat:@"<%@ %p>", [self name], self];}
- (id)initWithBundle:(NSBundle *)aBundle {
	id dup = [plugInBundlePaths valueForKey:[aBundle bundlePath]];
	if (dup) {
		[self release];
		return [dup retain];
	}
	if (self = [super init]) {
		[self setBundle:aBundle];
	}
	[self setStatus:@"Disabled"];
	return self;
}

- (id)initWithWebInfo:(NSDictionary *)webInfo {
	if (self = [super init]) {
		data = [webInfo retain];
		bundle = nil;
	}
	[self setStatus:@"Downloadable"];
	return self;
}

+ (id)plugInWithBundle:(NSBundle *)aBundle {
	return [[[QSPlugIn alloc] initWithBundle:aBundle] autorelease];
}

+ (id)plugInWithWebInfo:(NSDictionary *)webInfo {
	return [[[QSPlugIn alloc] initWithWebInfo:webInfo] autorelease];
}
/**
 Without loading the bundle, read bundle ID and version string
 @param      path			The path to the qsplugin on file system (eg: "/Users/paul/Downloads/Email Support.qsplugin")
 @param      version	A pointer to an \c NSString* that will be set to the version string of the plugin if present
 @result     An auto-released string with the bundle ID (eg: "com.blacktree.Quicksilver.QSEmailSupport")
 */
+ (NSString *)bundleIDForPluginAt:(NSString*)path andVersion:(NSString**)version {
  CFBundleRef bundle = CFBundleCreate(NULL, (CFURLRef)[NSURL fileURLWithPath:path]);
  if (!bundle) return nil;
  if (version) {
		*version = (NSString*)CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleVersionKey);
    [[*version retain] autorelease];
  }
  NSString *bundleIdent = (NSString *)CFBundleGetIdentifier(bundle);
  [[bundleIdent retain] autorelease];
  CFRelease(bundle);
  return bundleIdent;
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

- (void)install {
	installing = YES;
	[self setStatus:@"Installing"];
	NSString *identifier = [data objectForKey:@"CFBundleIdentifier"];
	[[QSPlugInManager sharedInstance] installPlugInsForIdentifiers:[NSArray arrayWithObject:identifier]];
	[self willChangeValueForKey:@"enabled"];
	[self didChangeValueForKey:@"enabled"];
	[self setStatus:@"Loaded"];
}

- (NSString *)shortName {
	NSString *name = (bundle) ? [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey] : [data objectForKey:(NSString *)kCFBundleNameKey];
	if ([name hasSuffix:@" Module"]) name = [name substringToIndex:[name length] -7];
	if ([name hasSuffix:@" Actions"]) name = [name substringToIndex:[name length] -8];
	return name;
}

- (NSString *)name {
	NSString *name = nil;
	if (bundle) name = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
	if (!name) name = [data objectForKey:(NSString *)kCFBundleNameKey];

#ifdef DEBUG
	if ([name hasSuffix:@" Module"]) name = [name substringToIndex:[name length] -7];
#endif
		
#ifdef DEBUG
	if (!data) {
		name = [name stringByAppendingFormat:@" - Private", 0x03B1];
	}
//	if (DEBUG && [self isUniversal]) {
//		name = [name stringByAppendingFormat:@" - U"];
//	}
    if ([self isSecret]) {
		name = [name stringByAppendingFormat:@" - Secret"];
	}
#endif

	return name;
}

- (NSString *)statusBullet {
	  if ([self isLoaded]) {
		  if ([bundle isLoaded])
			  return [NSString stringWithFormat:@"%C", 0x25C6];
		  else return [NSString stringWithFormat:@"%C", 0x25C7];
		  //BOOL selected = [[aTableView selectedRowIndexes] containsIndex:rowIndex];
		  //[aCell setTextColor:(! && !selected?[NSColor blueColor] :[NSColor blackColor])];
		  //

	  } else {
		  return @"";
	  }
	return @"*";
}

- (BOOL)isUniversal {
	if (![bundle executablePath])
        return NO;
    /* TODO: Use NSTask */
	NSString *str = [NSString stringWithFormat:@"/usr/bin/lipo -info \"%@\"", [bundle executablePath]];
	FILE *file = popen( [str UTF8String] , "r" );
	NSString *output = nil;
	NSMutableData *pipeData = [NSMutableData data];
	if ( file ) {
		char buffer[1024];
		size_t length;
		while (length = fread( buffer, 1, sizeof( buffer ), file ) )[pipeData appendBytes:buffer length:length];
		output = [[[NSString alloc] initWithData:pipeData encoding:NSUTF8StringEncoding] autorelease];
		pclose( file );
        return [output rangeOfString:@"i386"].location != NSNotFound;
	}

    return NO;
	//	NSLog(@"output%@", output);
	
}

- (NSDictionary *)info {
	if (bundle)
		return [bundle infoDictionary];
	else
		return data;
}

- (NSString *)author {
	return [[self info] valueForKeyPath:@"QSPlugIn.author"];

}

- (NSString *)byline {
	NSString *author = [self author];
	if (![author length] || [author isEqualToString:@"Blacktree, Inc."]) return @"";
	return [@"by " stringByAppendingString:author];
}

- (NSString *)helpPage {
	return [[self info] valueForKeyPath:@"QSPlugIn.helpPage"];
}

- (NSArray *)dependencies {
	return [[self info] valueForKeyPath:@"QSRequirements.plugins"];
}

- (NSSet *)obsoletes
{
	// a list of bundle IDs (as strings) for plug-ins made obsolete by this one
	if ([[self info] valueForKeyPath:@"QSRequirements.obsoletes"]) {
		return [NSSet setWithArray:[[self info] valueForKeyPath:@"QSRequirements.obsoletes"]];
	}
	return nil;
}

- (void)showHelp {
	NSString *urlString = [NSString stringWithFormat:kHelpSearchURL, [self helpPage]];
	NSLog(@"%@", urlString);
	if (urlString) 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[urlString stringByReplacing:@" " with:@"+"]]];
}

- (NSDate *)createdDate {
	return [NSDate date];
}
- (NSDate *)modifiedDate {
	NSDate *modifiedDate = [self installedDate];
	if (!modifiedDate) {
		modifiedDate = [self latestVersionDate];
	}
	return modifiedDate;
}

- (NSDate *)installedDate
{
	NSDate *buildDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[bundle executablePath] error:nil] fileModificationDate];
	if (!buildDate) {
		buildDate = [[[NSFileManager defaultManager] attributesOfItemAtPath:[bundle bundlePath] error:nil] fileModificationDate];
	}
	return buildDate;
}

- (NSDate *)latestVersionDate
{
	if (data) {
		return [NSDate dateWithString:[data valueForKeyPath:@"QSModifiedDate"]];
	}
	return nil;
}

- (NSString *)version
{
	NSString *version = [self installedVersion];
	if (!version) {
		version = [self latestVersion];
	}
	return version;
}

- (NSString *)buildVersion {
	return (bundle) ? [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] : [data objectForKey:(NSString *)kCFBundleVersionKey];
}

- (NSString *)installedVersion
{
	if (bundle) {
		NSString *version = [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
		if (!version) {
			version = [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
		}
		return version;
	}
	return nil;
}

- (NSString *)latestVersion
{
	NSString *version = [data objectForKey:@"CFBundleShortVersionString"];
	if (!version) {
		version = [data objectForKey:(NSString *)kCFBundleVersionKey];
	}
	return version;
}

- (BOOL)isSecret {
	return [[[self info] valueForKeyPath:@"QSPlugIn.secret"] boolValue];
}

- (BOOL)isRecommended
{
	// explicitly recommended
	if ([[[self info] valueForKeyPath:@"QSPlugIn.recommended"] boolValue]) {
		return YES;
	}
	// corresponds to an installed application or other bundle
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSArray *related = [self relatedBundles];
	for(NSString *bundleID in related) {
		if ([ws absolutePathForAppBundleWithIdentifier:bundleID]) {
			return YES;
		}
	}
	// makes a loaded plug-in obsolete
	NSSet *currentlyLoaded = [NSSet setWithArray:[[[QSPlugInManager sharedInstance] loadedPlugIns] allKeys]];
	return [currentlyLoaded intersectsSet:[self obsoletes]];
}

- (BOOL)isObsolete
{
	return [[[[QSPlugInManager sharedInstance] obsoletePlugIns] allKeys] containsObject:[self identifier]];
}

- (BOOL)needsUpdate {
	if (!bundle) return NO;
	//if (VERBOSE) NSLog(@"%@, %@->%@", [self name] , [bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey] , [data objectForKey:(NSString *)kCFBundleVersionKey]);

	return[[data objectForKey:(NSString *)kCFBundleVersionKey] versionCompare:
		[bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]]>0;
}
- (NSArray *)categories {
	return [[self info] valueForKeyPath:@"QSPlugIn.categories"];
}

- (NSString *)categoriesAsString
{
	return [[self categories] componentsJoinedByString:@", "];
}

- (NSArray *)relatedBundles {
	return [[self info] valueForKeyPath:@"QSPlugIn.relatedBundles"];
}
- (NSArray *)recommendations {
	return [[self info] valueForKeyPath:@"QSPlugIn.recommendations"];
}

- (NSString *)shortDescription {
	NSDictionary *plist = [self info];
	return [plist valueForKeyPath:@"QSPlugIn.description"];
}
- (NSString *)infoHTML {
	NSDictionary *plist = [self info];
	NSString *text = [plist valueForKeyPath:@"QSPlugIn.extendedDescription"];
	if (![text length]) text = [plist valueForKeyPath:@"QSPlugIn.description"];
	if (![text length]) text = @"<span style='color: #CCC'>No documentation available</span>";
	return [NSString stringWithFormat:@"<html><link rel=\"stylesheet\" href=\"resource:QSStyle.css\"><body>%@</body></html>", text];
}

- (BOOL)hasExtendedDescription
{
	return ([[[self info] valueForKeyPath:@"QSPlugIn.extendedDescription"] length] > 0);
}

- (NSComparisonResult) compare:(id)other {
	return [[self name] compare:[other name]];
}

- (NSString *)text {
	return [self name];
}
- (NSImage *)image {
	return [self icon];
}
- (NSData *)attributedDescription {
	//return nil; //[NSAttributedString attributedStringWithAttachment:;

//	static NSDictionary *attributes = nil;
//	if (!attributes) attributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]], 	NSFontAttributeName, nil];
	NSDictionary *plist = [self info];

	NSString *text = [plist valueForKeyPath:@"QSPlugIn.extendedDescription"];
	if (![text length]) text = [plist valueForKeyPath:@"QSPlugIn.description"];
	if (!text) text = @"";

	//	NSLog(@"plist %@", text); re
	text = [NSString stringWithFormat:@"<font face=\"Lucida Grande\">%@</font>", text];
	NSMutableAttributedString *info = [[[NSMutableAttributedString alloc] initWithHTML:[text dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil] autorelease];

	//	NSLog(@"plist %@", info);
	//	[info addAttributes:attributes range:NSMakeRange(0, [info length])];
	//	NSAttributedString *attribInfo = [[[NSAttributedString alloc] initWithString:text?text:@"" attributes:nil] autorelease];
	if (!info) return [NSData data];
	return [info RTFFromRange:NSMakeRange(0, [info length]) documentAttributes:nil]; ;
	//		[[plugInText textStorage] setAttributedString:attribInfo];

	return nil;
}
- (void)clearWebData {
	[self setData:nil];
}

- (NSImage *)icon {
	if (!icon) {
		NSDictionary *pDict = [[self info] objectForKey:@"QSPlugIn"];
		NSString *text = [pDict objectForKey:@"icon"];
		// make sure an icon set in plugin's .plist
		if(text != nil) {
			icon = [QSResourceManager imageNamed:text inBundle:bundle];
		}
		if (!icon)
		{
			icon = [QSResourceManager imageNamed:@"QSPlugIn"];
		}
		[icon setSize:QSSize32];
		[icon retain];
	}
	return icon;
}

- (NSImage *)smallIcon {
	if (!smallIcon) {
		smallIcon = [[[self icon] copy] autorelease];
		[smallIcon shrinkToSize:QSSize16];
		[smallIcon retain];
	}
	return smallIcon;
}

- (int) isInstalled {
	if (bundle) return 1;
	else if (installing) return -1;
	else return 0;
}

- (BOOL)shouldInstall {
	return shouldInstall;
}
- (void)setShouldInstall:(BOOL)flag {
	shouldInstall = flag;
}

- (BOOL)isHidden {
	if (bundle == [NSBundle mainBundle]) return YES;
	return [[[self info] valueForKeyPath:@"QSPlugIn.hidden"] boolValue];
}

- (int) isLoaded {return loaded;}
#define disabledPlugIns [[NSUserDefaults standardUserDefaults] arrayForKey:@"QSDisabledPlugIns"]
- (NSColor *)enabledColor {
	return [self isInstalled] ?[NSColor blackColor] :[NSColor grayColor];
}
- (NSString *)identifier {return [[self info] valueForKey:(NSString *)kCFBundleIdentifierKey];}
- (NSString *)bundleIdentifier {return [bundle bundleIdentifier];}
- (NSString *)path {return [bundle bundlePath];}
- (NSString *)bundlePath {return [bundle bundlePath];}

- (int) enabled {
	if (!bundle)
		return installing?-1:0;
	return ![disabledPlugIns containsObject:[bundle bundleIdentifier]];
}
- (void)setEnabled:(BOOL)flag {

	if (bundle) {
		NSString *identifier = [bundle bundleIdentifier];

		NSMutableSet *disabledPlugInsSet = [[NSMutableSet alloc] init];
		[disabledPlugInsSet addObjectsFromArray:disabledPlugIns];

		if (flag) {
			[disabledPlugInsSet removeObject:identifier];
			[self setStatus:@"Loaded"];
		} else {
			[disabledPlugInsSet addObject:identifier];
			[self setStatus:@"Disabled"];
		}

		[[NSUserDefaults standardUserDefaults] setObject:[disabledPlugInsSet allObjects] forKey:@"QSDisabledPlugIns"];
        
        [disabledPlugInsSet release];

		if (flag) {
			[[QSPlugInManager sharedInstance] liveLoadPlugIn:self];
			[[QSPlugInManager sharedInstance] checkForUnmetDependencies];
			[[QSPlugInManager sharedInstance] removeObsoletePlugIns];
		}
	} else if (![self isInstalled]) {
		[self install];
	}

}

- (BOOL)canBeDisabled {
	//	NSLog(@"%@ path", [bundle bundlePath]);
	return ![[bundle bundlePath] hasPrefix:[[NSBundle mainBundle] bundlePath]];

}

- (BOOL)reveal {
	return [[NSWorkspace sharedWorkspace] selectFile:[bundle bundlePath]
						  inFileViewerRootedAtPath:@""];
}
- (BOOL)delete {
	NSString *ident, *path;
	if (bundle) {
		ident = [bundle bundleIdentifier];
		path = [bundle bundlePath];
	} else {
		ident = [data objectForKey:@"CFBundleIdentifier"];
		path = nil;
	}
	id manager = [QSPlugInManager sharedInstance];
	[[manager localPlugIns] removeObjectForKey:ident];
	[[manager knownPlugIns] removeObjectForKey:ident];
	[[manager loadedPlugIns] removeObjectForKey:ident];
	NSFileManager *fm = [NSFileManager defaultManager];
	if ([fm fileExistsAtPath:path]) {
		return [fm removeItemAtPath:path error:nil];
	} else {
		return NO;
	}
	return YES;
}

//------------------------

- (NSBundle *)bundle { return bundle;  }
- (void)setBundle:(NSBundle *)newBundle {
	if ([newBundle isKindOfClass:[QSPlugIn class]]) {
		NSBeep();
	}
	[icon release];icon = nil;
	[smallIcon release];smallIcon = nil;
	[self retain];
	if (bundle) {
		[self retain];
		[plugInBundlePaths removeObjectForKey:[bundle bundlePath]];
		[bundle autorelease];
	}
	bundle = [newBundle retain];
	if (bundle) {
		[[[plugInBundlePaths objectForKey:[bundle bundlePath]] retain] autorelease]; // old plugin needs to be retained, because it will be released once it's replaced in plugInBundlePaths-list
		[plugInBundlePaths setObject:self forKey:[bundle bundlePath]];
		[self release];
	}
	[self release];
}

- (NSMutableDictionary *)data { return data;  }
- (void)setData:(NSMutableDictionary *)newData {
	if(newData != data){
		[data release];
		data = [newData retain];
	}
}

- (NSString *)loadError { return loadError;  }
- (void)setLoadError:(NSString *)newLoadError {
	[loadError autorelease];
	loadError = [newLoadError retain];
	[self setStatus:[NSString stringWithFormat:@"Error (%@) ", loadError]];
}

@end

@implementation QSPlugIn (Registry)
- (NSArray *)unmetDependencies {
	NSArray *plugIns = [self dependencies];
	NSMutableArray *unmet = [NSMutableArray array];
	for(NSDictionary * plugInDict in plugIns) {
		NSString *identifier = [plugInDict objectForKey:@"id"];

		if (![[[QSPlugInManager sharedInstance] loadedPlugIns] objectForKey:identifier]) {
			//	NSString *name = [plugInDict objectForKey:@"id"];
			//if (error) *error = [NSString stringWithFormat:@"Requires PlugIn '%@'", name?name:identifier];
			//NSLog(@"%@ requires %@", [self name] , name);
			[unmet addObject:plugInDict];
		}
	}
	return unmet;
}

- (BOOL)meetsRequirements:(NSString **)error {
	NSDictionary *requirementsDict = [bundle dictionaryForFileOrPlistKey:@"QSRequirements"];

	*error = nil;
	//NSString *ident = [self bundleIdentifier];
	//	NSString *restriction = [[self restrictionsDict] objectForKey:ident];
	//	if (restriction) {
	//		NSString *curVersion = [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
	//		if ([curVersion versionCompare:restriction] <0) {
	//			if (error) *error = [NSString stringWithFormat:@"Newer Version Required: %@ (%@) %d", restriction, curVersion, [curVersion versionCompare:restriction]];
	//			return NO;
	//		}
	//	}

	if (requirementsDict) {
		NSArray *bundles = [requirementsDict objectForKey:@"bundles"];
		if (![[NSUserDefaults standardUserDefaults] boolForKey:@"QSIgnorePlugInBundleRequirements"]) {
			for(NSDictionary * bundleDict in bundles) {
				break;
				NSString *identifier = [bundleDict objectForKey:@"id"];
				NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:identifier];
				if (!path) {
					NSString *name = [bundleDict objectForKey:@"name"];
					if (error) *error = [NSString stringWithFormat:@"Requires Bundle '%@'", name?name:identifier];
					return NO;
				}
#warning add support for version checking
			}
		}

		 {
			NSArray *frameworks = [requirementsDict objectForKey:@"frameworks"];
			for(NSDictionary * frameworkDict in frameworks) {
				NSString *identifier = [frameworkDict objectForKey:@"id"];
				NSString *resource = [frameworkDict objectForKey:@"resource"];
				NSString *path = [[QSResourceManager sharedInstance] pathWithLocatorInformation:resource];
				//path = @"/Volumes/Lore/Applications/Colloquy.app/Contents/Frameworks/AGRegex.framework";
				NSBundle *pathBundle = [NSBundle bundleWithPath:path];
				[pathBundle load];
				//CFBundleRef b = CFBundleCreate(NULL, [NSURL fileURLWithPath:path]);
				//int err = CFBundleLoadExecutable(b);
				NSLog(@"path %@ %@ %@", path, resource, pathBundle);

				if (!path) {
					NSString *name = [frameworkDict objectForKey:@"name"];
					if (error) *error = [NSString stringWithFormat:@"Requires Framework '%@'", name?name:identifier];
					return NO;
				}
			}
		}

		NSArray *paths = [requirementsDict objectForKey:@"paths"];
		for(NSString * path in paths) {
			if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath]]) {
				if (error) *error = [NSString stringWithFormat:@"Path not found: '%@'", path];
				return NO;
			}
		}

		NSString *qsVersion = [requirementsDict objectForKey:@"version"];
		if (qsVersion) {
			NSComparisonResult sorting = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] versionCompare:qsVersion];
			if (sorting<0) {
				if (error) *error = [NSString stringWithFormat:@"Requires Quicksiver Build %@", qsVersion];
				return NO;
			}
		}
	}
	return YES;
}

//- (BOOL)liveLoadPlugIn:(NSBundle *)bundle {
//	NSArray *disabledBundles = [[NSUserDefaults standardUserDefaults] objectForKey:@"QSDisabledPlugIns"];
//
//	if ([disabledBundles containsObject:[self bundleIdentifier]]) return YES;
//	if (![[QSPlugInManager sharedInstance] shouldLoadPlugIn:self inGroup:nil]) return NO;
//#warning this should be implemented internally
//	return [self registerPlugIn];
//}

//- (BOOL)loadOldActionProviders:(NSArray *)providerClasses {
//	NSEnumerator *e = [providerClasses objectEnumerator];
//	NSString *className;
//	while(className = [e nextObject]) {
//		id instance = [QSReg getClassInstance:className];
//		[QSExec registerActions:instance];
//	}
//	return YES;
//}

- (void)registerPlugInFrameworks {
	return;
	NSFileManager *fm = [NSFileManager defaultManager];

	NSString *frameworksPath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Frameworks"];

	if ([fm fileExistsAtPath:frameworksPath]) {
		char *var = getenv("DYLD_FRAMEWORK_PATH");
		NSString *frameworkVar = var?[NSString stringWithUTF8String:var] :@"";
		frameworkVar = [frameworkVar stringByAppendingFormat:@":%@", frameworksPath];
		setenv("DYLD_FRAMEWORK_PATH", [frameworkVar UTF8String] , YES);
		NSLog(@"Adding Framework Search Path: %@", frameworksPath);

		//	NSString *testpath = [frameworksPath stringByAppendingPathComponent:[[fm contentsOfDirectoryAtPath:frameworksPath error:nil] lastObject]];

		//	NSLog(@"bund %@", [NSBundle bundleWithPath:testpath]);
		//[[NSBundle bundleWithPath:testpath] load];
		//		NSLog(@"%s", getenv("DYLD_FRAMEWORK_PATH") );

	}

	NSString *librariesPath = [[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Libraries"];
	if ([fm fileExistsAtPath:librariesPath]) {
		char *var = getenv("DYLD_FRAMEWORK_PATH");
		NSString *libraryVar = var?[NSString stringWithUTF8String:getenv("DYLD_FRAMEWORK_PATH")] :@"";
		libraryVar = [libraryVar stringByAppendingFormat:@":%@", librariesPath];
		setenv("DYLD_FRAMEWORK_PATH", [libraryVar UTF8String] , YES);
		NSLog(@"Adding Library Search Path:\r%@", librariesPath);
	}

	//NSLog(@"DYLD %s", dyld_framework_path);
}

- (BOOL)_registerPlugIn {
	if (!bundle) return NO;
    
#ifdef DEBUG
	if (DEBUG_PLUGINS)
		NSLog(@"Loading PlugIn: %@ (%@) ", [[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension] , [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]);
#endif
	
	[QSReg registerBundle:bundle];
	[self registerPlugInFrameworks];

	if ([[bundle objectForInfoDictionaryKey:@"NSAppleScriptEnabled"] boolValue])
		[[NSScriptSuiteRegistry sharedScriptSuiteRegistry] loadSuitesFromBundle:bundle];

	BOOL loadNow = ![QSReg handleRegistration:bundle];

	id value;
	id handler;

	foreachkey(key, handlerClass, [QSReg tableNamed:kQSPlugInInfoHandlers]) {
		value = [bundle dictionaryForFileOrPlistKey:key];
		if (!value) continue;
		//NSLog(@"----> Registering %@ for %@", key, [self name]);
		handler = [QSReg getClassInstance:handlerClass];
		if ([handler respondsToSelector:@selector(handleInfo:ofType:fromBundle:)])
			[handler handleInfo:value ofType:key fromBundle:[self bundle]];
	}

	loadNow |= [[bundle objectForInfoDictionaryKey:@"QSLoadImmediately"] boolValue];

	Class currPrincipalClass;
	if (loadNow) {
		currPrincipalClass = [bundle principalClass];
		if (currPrincipalClass) {
			
#ifdef DEBUG
			if (DEBUG_PLUGINS) NSLog(@"Forcing Load of Class %@", currPrincipalClass);
#endif

			if ([currPrincipalClass respondsToSelector:@selector(loadPlugIn)])
				[currPrincipalClass loadPlugIn];
		}
	}

	//if (complete)
	[[NSNotificationCenter defaultCenter] postNotificationName:QSPlugInLoadedNotification object:self];
	loaded = YES;
	[self setStatus:@"Loaded"];
	return YES;
}

- (BOOL)registerPlugIn {
	
	// Used for crash purposes, save the current plugin being loaded incase it crashes QS
	NSDictionary *state = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [[self info] objectForKey:@"CFBundleName"], kQSPluginCausedCrashAtLaunch,
                                  [[self bundle] bundlePath], kQSFaultyPluginPath, nil];
	[state writeToFile:pStateLocation atomically:NO];
	
	@try {
		[self _registerPlugIn];
    } @catch (NSException *exc) {
		NSString *errorMessage = [NSString stringWithFormat:@"An error ocurred while loading plug-in \"%@\": %@", self, exc];
#ifdef DEBUG
		if (VERBOSE) {
			NSLog(@"%@", errorMessage);
			[exc printStackTrace];
		}
#endif
		[self setLoadError:[exc reason]];
	}
    // write an empty file to the state location since QS launched fine

    [[NSDictionary dictionary] writeToFile:pStateLocation atomically:NO];
	return YES;
}

@end
