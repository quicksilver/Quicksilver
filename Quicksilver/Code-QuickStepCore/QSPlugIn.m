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
#import "QSPreferenceKeys.h"
#import "SUStandardVersionComparator.h"

//static
NSMutableDictionary *plugInBundlePaths = nil;

@implementation QSPlugIn

@synthesize status, data;

+ (void)initialize {
	plugInBundlePaths = [[NSMutableDictionary alloc] init];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

    if ([key isEqualToString:@"smallIcon"]) {
        keyPaths = [keyPaths setByAddingObject:@"bundle"];
    }
    return keyPaths;
}

- (NSString *)description {return [NSString stringWithFormat:@"<%@ %p>", [self name], self];}
- (id)initWithBundle:(NSBundle *)aBundle {
	id dup = [plugInBundlePaths valueForKey:[aBundle bundlePath]];
	if (dup) {
		return dup;
	}
	if (self = [super init]) {
		[self setBundle:aBundle];
	}
	[self setStatus:@"Disabled"];
	return self;
}

- (id)initWithWebInfo:(NSDictionary *)webInfo {
	if (self = [super init]) {
		data = [webInfo mutableCopy];
		bundle = nil;
	}
	[self setStatus:@"Downloadable"];
	return self;
}

+ (id)plugInWithBundle:(NSBundle *)aBundle {
	return [[QSPlugIn alloc] initWithBundle:aBundle];
}

+ (id)plugInWithWebInfo:(NSDictionary *)webInfo {
	return [[QSPlugIn alloc] initWithWebInfo:webInfo];
}
/**
 Without loading the bundle, read bundle ID and version string
 @param      path			The path to the qsplugin on file system (eg: "/Users/paul/Downloads/Email Support.qsplugin")
 @param      version	A pointer to an \c NSString* that will be set to the version string of the plugin if present
 @result     An auto-released string with the bundle ID (eg: "com.blacktree.Quicksilver.QSEmailSupport")
 */
+ (NSString *)bundleIDForPluginAt:(NSString*)path andVersion:(NSString**)version {
  CFBundleRef bundle = CFBundleCreate(NULL, (__bridge CFURLRef)[NSURL fileURLWithPath:path]);
  if (!bundle) return nil;
  if (version) {
		*version = (__bridge NSString*)CFBundleGetValueForInfoDictionaryKey(bundle, kCFBundleVersionKey);
  }
  NSString *bundleIdent = (__bridge NSString *)CFBundleGetIdentifier(bundle);
  CFRelease(bundle);
  return bundleIdent;
}

- (void)dealloc {
	[self setBundle:nil];
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
		name = [name stringByAppendingFormat:@" - Private"];
	}
    if ([self isSecret]) {
		name = [name stringByAppendingFormat:@" - Secret"];
	}
#endif

	return name;
}

- (NSString *)statusBullet {
	  if ([self isLoaded]) {
		  if ([bundle isLoaded])
			  return [NSString stringWithFormat:@"%C", (unichar)0x25C6];
		  else return [NSString stringWithFormat:@"%C", (unichar)0x25C7];
		  //BOOL selected = [[aTableView selectedRowIndexes] containsIndex:rowIndex];
		  //[aCell setTextColor:(! && !selected?[NSColor blueColor] :[NSColor blackColor])];
		  //

	  } else {
		  return @"";
	  }
	return @"*";
}

- (BOOL)isSupported
{
	static NSNumber *myArch = nil;
	if (myArch == nil) {
		NSRunningApplication *Quicksilver = [NSRunningApplication currentApplication];
		myArch = [NSNumber numberWithInteger:[Quicksilver executableArchitecture]];
	}
	return (![bundle executableArchitectures] || [[bundle executableArchitectures] containsObject:myArch]);
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
	// a list of bundle IDs (as strings) for plugins made obsolete by this one
	if ([[self info] valueForKeyPath:@"QSRequirements.obsoletes"]) {
		return [NSSet setWithArray:[[self info] valueForKeyPath:@"QSRequirements.obsoletes"]];
	}
	return nil;
}

- (void)showHelp {
	NSString *urlString = [NSString stringWithFormat:kHelpSearchURL, [self helpPage]];
	NSLog(@"%@", urlString);
	if (urlString) 	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[urlString stringByReplacingOccurrencesOfString:@" " withString:@"+"]]];
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

- (NSString *)releaseNotes
{
    return [data objectForKey:@"QSPluginChanges"];
}

- (BOOL)isSecret {
	return [[[self info] valueForKeyPath:@"QSPlugIn.secret"] boolValue];
}

- (BOOL)isRecommended
{
    // don't recommend if obsolete
    if ([self isObsolete]) {
        return NO;
    }
	// explicitly recommended
	if ([[[self info] valueForKeyPath:@"QSPlugIn.recommended"] boolValue]) {
		return YES;
	}
	// a related file or directory exists on the system
	for (NSString *path in [self relatedPaths]) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
			return YES;
		}
	}
	// corresponds to an installed application or other bundle
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSArray *related = [self relatedBundles];
	for(NSString *bundleID in related) {
		if ([ws absolutePathForAppBundleWithIdentifier:bundleID]) {
			return YES;
		}
	}
	// makes a loaded plugin obsolete
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

	return ([[data objectForKey:(NSString *)kCFBundleVersionKey] versionCompare:
		[bundle objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey]] > 0);
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

- (NSArray *)relatedPaths
{
	NSArray *rawRelatedPaths = [[self info] valueForKeyPath:@"QSPlugIn.relatedPaths"];
	return [rawRelatedPaths arrayByPerformingSelector:@selector(stringByStandardizingPath)];
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
	return [NSString stringWithFormat:@"<html><link rel=\"stylesheet\" href=\"QSStyle.css\"><body><div id=\"content\">%@</div></body></html>", text];
}

- (BOOL)hasExtendedDescription
{
	return ([[[self info] valueForKeyPath:@"QSPlugIn.extendedDescription"] length] > 0);
}

- (NSComparisonResult) compare:(QSPlugIn *)other {
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
	NSMutableAttributedString *info = [[NSMutableAttributedString alloc] initWithHTML:[text dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil];

	//	NSLog(@"plist %@", info);
	//	[info addAttributes:attributes range:NSMakeRange(0, [info length])];
	//	NSAttributedString *attribInfo = [[[NSAttributedString alloc] initWithString:text?text:@"" attributes:nil] autorelease];
	if (!info) return [NSData data];
	return [info RTFFromRange:NSMakeRange(0, [info length]) documentAttributes:@{}];
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
	}
	return icon;
}

- (NSImage *)smallIcon {
	if (!smallIcon) {
		smallIcon = [[self icon] copy];
		[smallIcon shrinkToSize:QSSize16];
	}
	return smallIcon;
}

- (NSInteger) isInstalled {
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

- (NSInteger) isLoaded {return loaded;}
#define disabledPlugIns [[NSUserDefaults standardUserDefaults] arrayForKey:@"QSDisabledPlugIns"]
- (NSColor *)enabledColor {
	return [self isInstalled] ?[NSColor blackColor] :[NSColor grayColor];
}
- (NSString *)identifier {return [[self info] valueForKey:(NSString *)kCFBundleIdentifierKey];}
- (NSString *)bundleIdentifier {return [bundle bundleIdentifier];}
- (NSString *)path {return [bundle bundlePath];}
- (NSString *)bundlePath {return [bundle bundlePath];}

- (NSInteger) enabled {
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
	icon = nil;
	smallIcon = nil;
	if (bundle) {
		[plugInBundlePaths removeObjectForKey:[bundle bundlePath]];
	}
	bundle = newBundle;
	if (bundle) {
		[plugInBundlePaths objectForKey:[bundle bundlePath]]; // old plugin needs to be retained, because it will be released once it's replaced in plugInBundlePaths-list
		[plugInBundlePaths setObject:self forKey:[bundle bundlePath]];
	}
}

- (NSString *)loadError { return loadError;  }
- (void)setLoadError:(NSString *)newLoadError {
	loadError = newLoadError;
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
	if (requirementsDict) {
		if (![[NSUserDefaults standardUserDefaults] boolForKey:@"QSIgnorePlugInBundleRequirements"]) {
			for (NSDictionary *bundleDict in requirementsDict[kPluginRequirementsBundles]) {
				NSString *identifier = bundleDict[kPluginRequirementsBundleId];
                NSString *name = bundleDict[kPluginRequirementsBundleName];
                NSString *path = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:identifier];
				if (!path) {
                    if (error) {
                        NSString *localizedErrorFormat = NSLocalizedString(@"Requires installation of %@", nil);
                        *error = [NSString stringWithFormat:localizedErrorFormat, name?name:identifier];
                    }
					return NO;
				}
                NSString *requiredVersion = bundleDict[kPluginRequirementsBundleVersion];
                if (requiredVersion) {
                    // check bundle's version
                    NSDictionary *details = [[NSBundle bundleWithPath:path] infoDictionary];
                    NSString *version = [details objectForKey:@"CFBundleShortVersionString"] ? [details objectForKey:@"CFBundleShortVersionString"] : [details objectForKey:@"CFBundleVersion"];
                    if ([version isLessThan:requiredVersion]) {
                        if (error) {
                            NSString *localizedErrorFormat = NSLocalizedString(@"Requires version %@ of %@", nil);
                            *error = [NSString stringWithFormat:localizedErrorFormat, requiredVersion, name?name:identifier];
                        }
                        return NO;
                    }
                }
			}
		}

        NSArray *frameworks = requirementsDict[kPluginRequirementsFrameworks];
        for(NSDictionary * frameworkDict in frameworks) {
            NSString *identifier = frameworkDict[kPluginRequirementsFrameworkId];
            NSString *resource = frameworkDict[kPluginRequirementsFrameworkResource];
            NSString *name = frameworkDict[kPluginRequirementsFrameworkName];
            NSString *path = [[QSResourceManager sharedInstance] pathWithLocatorInformation:resource];
            NSBundle *pathBundle = [NSBundle bundleWithPath:path];
            // try and load the framework
            [pathBundle load];
            
            if (!path) {
                if (error) {
                    NSString *localizedErrorFormat = NSLocalizedString(@"Requires Framework '%@'", nil);
                    *error = [NSString stringWithFormat:localizedErrorFormat, name?name:identifier];
                }
                return NO;
            } else if (![pathBundle isLoaded]) {
                if (error) {
                    NSString *localizedErrorFormat = NSLocalizedString(@"Framework '%@' could not be loaded", nil);
                    *error = [NSString stringWithFormat:localizedErrorFormat, name?name:identifier];
                }
                return NO;
            }
        }

		NSArray *paths = requirementsDict[kPluginRequirementsPaths];
		for(NSString * path in paths) {
			if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByStandardizingPath]]) {
				if (error) {
                    NSString *localizedErrorFormat = NSLocalizedString(@"Path not found: %@", nil);
                    *error = [NSString stringWithFormat:localizedErrorFormat, path];
                }
				return NO;
			}
		}

		NSString *qsVersion = requirementsDict[kPluginRequirementsMinHostVersion];
        if (!qsVersion) {
            qsVersion = requirementsDict[kPluginRequirementsMinHostVersion__deprecated];
        }
		if (qsVersion) {
			NSComparisonResult sorting = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] versionCompare:qsVersion];
			if (sorting<0) {
				if (error) {
                    NSString *localizedErrorFormat = NSLocalizedString(@"Requires Quicksiver Build %@", nil);
                    *error = [NSString stringWithFormat:localizedErrorFormat, qsVersion];
                }
				return NO;
			}
		}
		NSString *qsMaxVersion = requirementsDict[kPluginRequirementsMaxHostVersion];
		if (qsMaxVersion) {
			NSComparisonResult sorting = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] versionCompare:qsMaxVersion];
			if (sorting>0) {
				if (error) {
                    NSString *localizedErrorFormat = NSLocalizedString(@"Requires Quicksiver Build %@ or lower", nil);
                    *error = [NSString stringWithFormat:localizedErrorFormat, qsMaxVersion];
                }
				return NO;
			}
		}
        SUStandardVersionComparator *comparator = [SUStandardVersionComparator defaultComparator];
        NSString *osRequired = requirementsDict[kPluginRequirementsOSRequiredVersion];
        if (osRequired) {
            if ([comparator compareVersion:[NSApplication macOSXFullVersion] toVersion:osRequired] == NSOrderedAscending) {
                if (error) {
                    NSString *localizedErrorFormat = NSLocalizedString(@"Requires Mac OS X %@ or later", nil);
                    *error = [NSString stringWithFormat:localizedErrorFormat, osRequired];
                }
                return NO;
            }
        }
        NSString *osUnsupported = requirementsDict[kPluginRequirementsOSUnsupportedVersion];
        if (osUnsupported) {
            NSComparisonResult versionComparison = [comparator compareVersion:[NSApplication macOSXFullVersion] toVersion:osUnsupported];
            if (versionComparison == NSOrderedSame || versionComparison == NSOrderedDescending) {
                if (error) {
                    NSString *localizedErrorFormat = NSLocalizedString(@"Unsupported on Mac OS X %@ or later", nil);
                    *error = [NSString stringWithFormat:localizedErrorFormat, osUnsupported];
                }
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

- (BOOL)_registerPlugIn {
    if (![self isSupported]) {
        NSString *unsupportedFolder = @"PlugIns (disabled)";
        NSString *pluginFileName = [[self path] lastPathComponent];
        NSString *destination = [QSApplicationSupportSubPath(unsupportedFolder, YES) stringByAppendingPathComponent:pluginFileName];
        NSLog(@"Moving unsupported plugin '%@' to %@. Quicksilver only supports 64-bit plugins. i386 and PPC plugins are being disabled to avoid repeated warnings.", [self name], unsupportedFolder);
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm moveItemAtPath:[self path] toPath:destination error:nil];
        //[NSException raise:@"QSWrongPluginArchitecture" format:@"Current architecture unsupported"];
        return NO;
    }
    
	if (!bundle) return NO;
    
#ifdef DEBUG
	if (DEBUG_PLUGINS)
		NSLog(@"Loading PlugIn: %@ (%@) ", [[[bundle bundlePath] lastPathComponent] stringByDeletingPathExtension] , [bundle objectForInfoDictionaryKey:@"CFBundleVersion"]);
#endif
	
	[QSReg registerBundle:bundle];

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
        NSString *errorMessage = [NSString stringWithFormat:@"An error ocurred while loading plugin \"%@\": %@", self, exc];
        NSLog(@"%@", errorMessage);
		[self setLoadError:[exc reason]];
	}
    // write an empty file to the state location since QS launched fine

    [[NSDictionary dictionary] writeToFile:pStateLocation atomically:NO];
	return YES;
}

@end
