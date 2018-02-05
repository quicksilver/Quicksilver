#pragma mark User Agent

#define kQSUserAgent [NSString stringWithFormat:@"Quicksilver/%@ (Macintosh; Intel Mac OS X %@; %@) (like Safari)",\
					 (__bridge NSString *)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey),\
					 [[NSApplication macOSXFullVersion] stringByReplacingOccurrencesOfString:@"." withString:@"_"],\
                     kLocale]

#define kLocale [NSString stringWithFormat:@"%@-%@", [[[NSBundle mainBundle] preferredLocalizations] objectAtIndex:0],\
                [[[NSLocale currentLocale] objectForKey:NSLocaleCountryCode] lowercaseString]]

#pragma mark Search URLs

#define QUERY_KEY @"***"

#pragma mark Syncrhonous Results

#define kQSResultArrayKey @"resultArray"

#pragma mark Bundle ID

#define kQSBundleID @"com.blacktree.Quicksilver"

#pragma mark Actions

// strings:
#define kActionClass                @"actionClass"
#define kActionProvider             @"actionProvider"
#define kActionSelector             @"actionSelector"
#define kActionSendMessageToClass   @"actionSendToClass"
#define kActionAlternate            @"alternateAction"
#define kActionScript               @"actionScript"
#define kActionHandler              @"actionHandler"
#define kActionEventClass           @"actionEventClass"
#define kActionEventID              @"actionEventID"
#define kActionArgument             @"argument"

#define kActionArgumentCount        @"argumentCount" // Number, if undefined, calculates from selector

// strings:
#define kActionIcon                 @"icon"
#define kActionName                 @"name"
#define kActionUserData             @"userData"
#define kActionIdentifier           @"id"

// arrays:
#define kActionDirectTypes          @"directTypes"
#define kActionDirectFileTypes      @"directFileTypes"
#define kActionIndirectTypes        @"indirectTypes"
#define kActionResultType           @"resultTypes" // Unused ?

// BOOLs:
#define kActionRunsInMainThread     @"runInMainThread"
#define kActionDisplaysResult       @"displaysResult"
#define kActionIndirectOptional     @"indirectOptional"
#define kActionReverseArguments     @"reverseArguments"
#define kActionSplitPluralArguments @"splitPlural"
#define kActionValidatesObjects     @"validatesObjects"
#define kActionInitialize           @"initialize"
#define kActionEnabled              @"enabled"
#define kActionResolvesProxy        @"resolvesProxy"
#define kActionCommandFormat        @"commandFormat"

// NSNumber (float) :
#define kActionPrecedence @"precedence"

// QSPlugin Requirements Dict (Info.plist)

/**
 *  Type: array
 *  A key to an array of dictionaries representing required bundles before the plugin can be installed
 */
#define kPluginRequirementsBundles @"bundles"

/**
 *  Type: string
 *  Name of this bundle that is requried (part of the dict specified for a bundle in a plugins Requirements dictionary)
 */
#define kPluginRequirementsBundleName @"name"

/**
 *  Type: string
 *  Bundle identifier of this required bundle (part of the dict specified for a bundle in a plugins Requirements dictionary)
 */
#define kPluginRequirementsBundleId @"id"

/**
 *  Type: string
 *  Required bundle version (part of the dict specified for a bundle in a plugins Requirements dictionary)
 */
#define kPluginRequirementsBundleVersion @"version"


/**
 *  Type: array
 *  A key to an array of dictionaries representing required LOADED frameworks before the plugin can be installed
 *  Each of these frameworks will be loaded in turn (if they exist) before the plugin is installed
 */
#define kPluginRequirementsFrameworks @"frameworks"

/**
 *  Type: string
 *  Name of this framework that is requried (part of the dict specified for a framework in a plugins Requirements dictionary)
 *  This is only used for display purposes, to show to the user
 */
#define kPluginRequirementsFrameworkName @"name"

/**
 *  Type: string
 *  Bundle identifier of this required bundle/framework (part of the dict specified for a framework in a plugins Requirements dictionary)
 *  This is only used for display purposes, to show to the user
 */
#define kPluginRequirementsFrameworkId @"id"

/**
 *  Type: string, array or dictionary
 *  A represention of the framework that is required and must be loaded before this plugin will work. (part of the dict specified for a framework in a plugins Requirements dictionary)
 *  Uses -[QSResourceManager pathWithLocatorInformation:] to resolve the resource
 */
#define kPluginRequirementsFrameworkResource @"resource"

/**
 *  Type: string
 *  Required bundle/framework version (part of the dict specified for a bundle or framework in a plugins Requirements dictionary)
 */
#define kPluginRequirementsFrameworkVersion @"version"

/**
 *  Type: array
 *  An array of paths that must be present on the
 *  Host computer before the plugin can be installed
 */
#define kPluginRequirementsPaths @"paths"

/**
 *  Type: string
 *  Key to the mininum required Quicksilver vertsion supported by this plugin
 *  This key is deprecated, and should be replaced with @"minHostVersion"
 *  (kPluginRequirementsMinHostVersion)
 */
#define kPluginRequirementsMinHostVersion__deprecated @"version"

/**
 *  Type: string
 *  Key to the mininum required Quicksilver vertsion supported by this plugin
 */
#define kPluginRequirementsMinHostVersion @"minHostVersion"

/**
 *  Type: string
 *  Key to the maximum Quicksilver vertsion supported by this plugin
 *  Any Quicksilver app with a higher version that this number will not
 *  load this plugin
 */
#define kPluginRequirementsMaxHostVersion @"maxHostVersion"
/**
 *  Type: string
 *  Key to the minimum version of OS X supported by this plugin
 */
#define kPluginRequirementsOSRequiredVersion @"osRequired"
/**
 *  Type: string
 *  Key to the first verison of OS X that no longer supports this plugin
 *  E.g. if 10.7 is specified, 10.6.8, 10.6.9... would all be supported
 */
#define kPluginRequirementsOSUnsupportedVersion @"osUnsupported"
/**
 *  Type: string
 *  Key to the reason the interface was hidden/deactivated
 */
#define kQSInterfaceDeactivatedReason @"deactivate reason"
