/*!
	@header NDLaunchServicesObject
	@abstract Defines the interface for NDLaunchServicesObject.
	@discussion LauchServices is part of CoreFoundation and uses CoreFoundation types like CFURLRef and CFStringRef and so can be easily used straight from Cocoa.
 */

#import <Foundation/Foundation.h>

/*!
	@class NDLaunchServicesObject
	@abstract Cocoa interface to LaunchServices
	@discussion Provides a Cocoa interface to Apples LaunchServices.
 */
@interface NDLaunchServicesObject : NSObject
{
}

/*!
	@method defaultLaunchServices
	@abstract Returns the default instance of <tt>NDLaunchServicesObject</tt>.
	@discussion You can create your own instance of <tt>NDLaunchServicesObject</tt> with <tt>initWithFlags:</tt> but it provides no benifit.
	@result The default <tt>NDLaunchServicesObject</tt> instance.
 */
+ (NDLaunchServicesObject *)defaultLaunchServices;

/*!
	@method terminateDefault
	@abstract Terminate LaunchServices use.
	@discussion <tt>terminateDefault</tt> is depreciated. It does not need to be called.
  */
+ (void)terminateDefault;

/*!
	@method initWithFlags:
	@abstract Intialises the reciever <tt>NDLaunchServicesObject</tt>.
	@discussion The only publicly defined <tt>LSInitializeFlags</tt> is <tt>kLSInitializeDefaults</tt>. <tt>initWithFlags:</tt> is depreciated. <tt>init</tt> can be called with the same result..
	@param flags A <tt>LSInitializeFlags</tt> only value is <tt>kLSInitializeDefaults</tt>.
	@result Returns a <tt>NDLaunchServicesObject</tt> instance.
  */
- initWithFlags:(LSInitializeFlags)flags;

/*!
	@method copyItemInfo:forURL:outInfo:
	@abstract Return information about an item.
	@discussion Returns as much or as little information as requested about <tt>URL</tt>. Some information is available in a thread-safe manner, some is not.
	Possible values for the <tt>LSRequestedInfo</tt> parameter <tt>whichInfo</tt> are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th><tt>LSRequestedInfo</tt></th><th>Thread Safe</th><th>Description</th></tr></thead >
			<tr><td align = "center"><tt>kLSRequestExtension</tt></td><td align = "center">yes</td><td>file extension</td></tr>
			<tr><td align = "center"><tt>kLSRequestTypeCreator</tt></td><td align = "center">yes</td><td>file creator code</td></tr>
			<tr><td align = "center"><tt>kLSRequestBasicFlagsOnly</tt></td><td align = "center">yes</td><td>all but type of application and extension flags</td></tr>
			<tr><td align = "center"><tt>kLSRequestAppTypeFlags</tt></td><td align = "center">no</td><td>application type flags</td></tr>
			<tr><td align = "center"><tt>kLSRequestAllFlags</tt></td><td align = "center">no</td><td>all flags</td></tr>
			<tr><td align = "center"><tt>kLSRequestIconAndKind</tt></td><td align = "center">no</td><td>icon</td></tr>
			<tr><td align = "center"><tt>kLSRequestExtensionFlagsOnly</tt></td><td align = "center">yes</td><td>extension flags only</td></tr>
			<tr><td align = "center"><tt>kLSRequestAllInfo</tt></td><td align = "center">no</td><td>al information</td></tr>
		</table >
	</blockquote >
 
	The <tt>LSItemInfoRecord</tt> fields of the parameter <tt>outInfo</tt> are
	<blockquote>
		<table border = "1"  width = "50%">
			<thead><tr><th>type</th ><th>field</th ></tr></thead>
			<tr><td align = "center"><tt>LSItemInfoFlags</tt></td><td>flags</td></tr>
			<tr><td align = "center"><tt>OSType</tt></td><td>filetype</td></tr>
			<tr><td align = "center"><tt>OSType</tt></td><td>creator</td></tr>
			<tr><td align = "center"><tt>CFStringRef</tt></td><td>extension</td></tr>
			<tr><td align = "center"><tt>CFStringRef</tt></td><td>iconFileName</td></tr>
			<tr><td align = "center"><tt>LSKindID</tt></td><td>kindID</td></tr>
			</table ></blockquote >
			Possible values of <tt>LSItemInfoFlags</tt>, where they can be combined with a bitwise or, are
			<blockquote><table border = "1"  width = "90%">
			<thead><tr><th> flag </th ><th> Description </th ></tr></thead>
			<tr><td align = "center"><tt>kLSItemInfoIsPlainFile</tt></td><td>none of the following applies</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsPackage</tt></td><td>app, doc, or bundle package</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsApplication</tt></td><td>single-file or packaged application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsContainer</tt></td><td>folder or volume</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsAliasFile</tt></td><td>alias file (includes sym links)</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsSymlink</tt></td><td>UNIX sym link</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsInvisible</tt></td><td>invisible file, does not include '.' files or '.hidden' entries</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsNativeApp</tt></td><td>Carbon or Cocoa native application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsClassicApp</tt></td><td>CFM Classic application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppPrefersNative</tt></td><td>Carbon application that prefers to be launched natively</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppPrefersClassic</tt></td><td>Carbon application that prefers to be launched in Classic</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppIsScriptable</tt></td><td>Application that can be scripted</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsVolume</tt></td><td>item is a volume</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoExtensionIsHidden</tt></td><td>item has a hidden extension</td></tr>
		</table >
	</blockquote >
	@param whichInfo Flags indicating which information to return.
	@param URL The <tt>NSURL</tt> of the item about which information is requested.
	@param outInfo Information is returned in this structure. Must not be NULL
	@result Return <tt>YES</tt> if successful.
  */
- (BOOL)copyItemInfo:(LSRequestedInfo)whichInfo forURL:(NSURL *)URL outInfo:(LSItemInfoRecord *)outInfo;

/*!
	@method displayNameForURL:
	@abstract Get the display name for a <tt>NSURL</tt>.
	@discussion Return a copy of the display name for a <tt>NSURL</tt>. Takes into consideration whether this item has a hidden extension or not.
	@param URL The URL for which the display name is desired.
	@result The display name.
  */
- (NSString *)displayNameForURL:(NSURL *)URL;

/*!
	@method setExtensionHidden:forURL:
	@abstract Sets whether the extension for a CFURLRef is hidden or not.
	@discussion Sets the necessary file system state to indicate that the extension for <tt>URL</tt> is hidden, as in the Finder.
	@param hide <tt>YES</tt> to show extension, <tt>NO</tt> to hide extension.
	@param URL The <tt>NSURL</tt> for which the extension is to be hidden or shown.
	@result Return <tt>YES</tt> if successful.
  */
- (BOOL)setExtensionHidden:(BOOL)hide forURL:(NSURL *)URL;

/*!
	@method kindStringForURL:
	@abstract Get the kind string for an item.
	@discussion Returns the kind string as used in the Finder and elsewhere for <tt>URL</tt>.
	@param URL The item for which the kind string is requested.
	@result A kind string.
  */
- (NSString *)kindStringForURL:(NSURL *)URL;

/*!
	@method applicationForType:creator:extension:inRole:
	@abstract Return the application used to open items with particular data.
	@discussion Consults the binding tables to return the application that would be used to open items with type, creator, and/or extension as provided if they were double-clicked in the Finder. This application will be the default for items like this if one has been set. If no application is known to LaunchServices suitable for opening such items, kLSApplicationNotFoundErr will be returned. Not all three input parameters can be NULL at the same time nor can both output parameters be NULL at the same time.
	Possible values for roles are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Value</th><th>Description</th></tr></thead>
			<tr><td align = "center"><tt>kLSRolesNone</tt></td><td>no claim is made about support for this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesViewer</tt></td><td>claim to be able to view this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesEditor</tt></td><td>claim to be able to edit this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesAll</tt></td><td>claim to do it all</td></tr>
		</table >
	</blockquote >
	@param type The file type to consider. Can be <tt>kLSUnknownType</tt>.
	@param creator The file creator to consider. Can be <tt>kLSUnknownCreator</tt>.
	@param extension The file name extension to consider. Can be <tt>nil</tt>.
	@param role Whether to return the editor or viewer for inItemRef.
	@result The <tt>NSURL</tt> of the application if not <tt>nil</tt>.
  */
- (NSURL *)applicationForType:(OSType)type creator:(OSType)creator extension:(NSString *)extension inRole:(LSRolesMask)role;

/*!
	@method applicationForURL:inRole:
	@abstract Return the application used to open an item.
	@discussion Consults the binding tables to return the application that would be used to open inURL if it were double-clicked in the Finder. This application will be the user-specified override if appropriate or the default otherwise. If no application is known to LaunchServices suitable for opening this item.
	Possible values for roles are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Value</th><th>Description</th></tr></thead>
			<tr><td align = "center"><tt>kLSRolesNone</tt></td><td>no claim is made about support for this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesViewer</tt></td><td>claim to be able to view this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesEditor</tt></td><td>claim to be able to edit this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesAll</tt></td><td>claim to do it all</td></tr>
		</table >
	</blockquote >
	@param URL The <tt>NSURL</tt> of the item for which the application is requested.
	@param role Whether to return the editor or viewer. If you don't care which, use <tt>kLSRolesAll</tt>.
	@result The <tt>NSURL</tt> of the application if not <tt>nil</tt>.
  */
- (NSURL *)applicationForURL:(NSURL *)URL inRole:(LSRolesMask)role;

/*!
	@method findApplicationForCreator:bundleID:name:
	@abstract Locate a specific application.
	@discussion Returns the application with the corresponding input information. The registry of applications is consulted first in order of bundleID, then creator, then name. All comparisons are case insensitive and 'ties' are decided first by version, then by native vs. Classic.
	@param creator The file creator to consider. Can be <tt>kLSUnknownCreator</tt>.
	@param bundleID The bundle ID to consider. Can be <tt>nil</tt>.
	@param name The name to consider. Can be <tt>nil</tt>. Must include any extensions that are part of the file system name, e.g. '.app'.
	@result The <tt>NSURL</tt> of the application if not <tt>nil</tt>.
  */
- (NSURL *)findApplicationForCreator:(OSType)creator bundleID:(NSString *)bundleID name:(NSString *)name;

/*!
	@method canURL:acceptURL:inRole:acceptanceFlags:
	@abstract Determine whether an item can accept another item.
	@discussion Returns whether <tt>URL</tt> can accept <tt>targetURL</tt> as in a drag and drop operation for the given role, if you want the application for all roles then use <tt>kLSRolesAll</tt>.<br>
	Possible values for roles are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Value</th><th>Description</th></tr></thead>
			<tr><td align = "center"><tt>kLSRolesNone</tt></td><td>no claim is made about support for this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesViewer</tt></td><td>claim to be able to view this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesEditor</tt></td><td>claim to be able to edit this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesAll</tt></td><td>claim to do it all</td></tr>
		</table >
	</blockquote >
	@param URL <tt>NSURL</tt> of the potential target.
	@param targetURL <tt>NSURL</tt> of the item about which acceptance is requested.
	@param role The role(s) the target must claim in order to consider acceptance.
	@param flags Use <tt>kLSAcceptDefault</tt>.
	@result Returns the result.
  */
- (BOOL)canURL:(NSURL *)URL acceptURL:(NSURL *)targetURL inRole:(LSRolesMask)role acceptanceFlags:(LSAcceptanceFlags)flags;

/*!
	@method canURL:acceptURL:inRole:
	@abstract Determine whether an item can accept another item.
	@discussion Returns whether <tt>URL</tt> can accept <tt>targetURL</tt> as in a drag and drop operation. If <tt>role</tt> is other than <tt>kLSRolesAll</tt> then make sure <tt>URL</tt> claims to fulfill the requested role. Calls <tt>canURL:acceptURL:inRole:acceptanceFlags</tt> with acceptance flags value of <tt>kLSAcceptDefault</tt>.
	Possible values for roles are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Value</th><th>Description</th></tr></thead>
			<tr><td align = "center"><tt>kLSRolesNone</tt></td><td>no claim is made about support for this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesViewer</tt></td><td>claim to be able to view this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesEditor</tt></td><td>claim to be able to edit this type/scheme</td></tr>
			<tr><td align = "center"><tt>kLSRolesAll</tt></td><td>claim to do it all</td></tr>
		</table >
	</blockquote >
	@param URL <tt>NSURL</tt> of the potential target.
	@param targetURL <tt>NSURL</tt> of the item about which acceptance is requested.
	@param role The role(s) the target must claim in order to consider acceptance.
	@result Returns the result.
 */
- (BOOL)canURL:(NSURL *)URL acceptURL:(NSURL *)targetURL inRole:(LSRolesMask)role;

/*!
	@method openURL:
	@abstract Open an application, document, or folder.
	@discussion Opens applications, documents, and folders. Applications are opened via an 'oapp' or 'rapp' event. Documents are opened in their user-overridden or default applications as appropriate. Folders are opened in the Finder. Use the more specific <tt>openURLs:usingApplication:params:launchFlags:asyncRefCon:</tt> for more control over launching.
	@param URL The <tt>NSURL</tt> of the item to launch.
	@result The <tt>NSURL</tt> of the item actually launched. For <tt>URL</tt> that are documents, the result will be the application used to launch the document. Can be <tt>nil</tt>.
  */
- (NSURL *)openURL:(NSURL *)URL;

/*!
	@method openURLs:usingApplication:
	@abstract Opens an application or one or more documents or folders.
	@discussion Opens applications, documents, and folders.
	@param array A <tt>NSArray</tt> of <tt>NSURL</tt> of the items to launch.
	@param application The <tt>NSURL</tt> of the application to use, can be nil.
	@result The <tt>NSURL</tt> of the item actually launched. For <tt>NSURL</tt>s that are documents, the result will be the application used to launch the document. Can be <tt>nil</tt>.
  */
- (NSURL *)openURLs:(NSArray *)array usingApplication:(NSURL *)application;

/*!
	@method openURLs:usingApplication:params:launchFlags:asyncRefCon:
	@abstract Opens an application or one or more documents or folders.
	@discussion Opens applications, documents, and folders.
	Possible launch flags
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th>Value</th><th>Description</th></tr>
			<tr><td align = "center"><tt>kLSLaunchDefaults</tt></td><td>default = open, async, use Info.plist, start Classic</td></tr>
			<tr><td align = "center"><tt>kLSLaunchAndPrint</tt></td><td>print items instead of open them</td></tr>
			<tr><td align = "center"><tt>kLSLaunchInhibitBGOnly</tt></td><td>causes launch to fail if target is background-only.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchDontAddToRecents</tt></td><td>do not add application or documents to recents menus.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchDontSwitch</tt></td><td>don't bring new application to the foreground.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchNoParams</tt></td><td>Use Info.plist to determine launch parameters</td></tr>
			<tr><td align = "center"><tt>kLSLaunchAsync</tt></td><td>launch async; obtain results from kCPSNotifyLaunch.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchStartClassic</tt></td><td>start up Classic environment if required for app.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchInClassic</tt></td><td>force application to launch in Classic environment.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchNewInstance</tt></td><td>Instantiate application even if it is already running.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchAndHide</tt></td><td>Send child a "hide" request as soon as it checks in.</td></tr>
			<tr><td align = "center"><tt>kLSLaunchAndHideOthers</tt></td><td>Hide all other apps when child checks in.</td></tr>
		</table >
	</blockquote >
	@param array A <tt>NSArray</tt> of <tt>NSURL</tt> of the items to launch.
	@param application The <tt>NSURL</tt> of the application to use, can be nil.
	@param params Passed untouched to application as optional parameter.
	@param flags Launch Flags.
	@param asyncRefCon Used if you register for application birth/death notification through carbon events.
	@result The <tt>NSURL</tt> of the item actually launched. For <tt>NSURL</tt>s that are documents, the result will be the application used to launch the document. Can be <tt>nil</tt>.
  */
- (NSURL *)openURLs:(NSArray *)array usingApplication:(NSURL *)application params:(NSAppleEventDescriptor *)params launchFlags:(LSLaunchFlags)flags asyncRefCon:(void *)asyncRefCon;

/*!
	@method filetypeOfURL:
	@abstract File type of item.
	@discussion Returns the 4 char file type code for the supplied <tt>NSURL</tt>.
	@param URL The <tt>NSURL</tt> for which the file type is desired.
	@result Returns the file type or 0 if the file does not have a file type.
  */
- (OSType)filetypeOfURL:(NSURL *)URL;

/*!
	@method creatorOfURL:
	@abstract Creator code of item.
	@discussion Returns the 4 char creator code for the supplied <tt>NSURL</tt>.
	@param URL The <tt>NSURL</tt> for which the creator code is desired.
	@result Returns the creator code or 0 if the file does not have a creator code.
  */
- (OSType)creatorOfURL:(NSURL *)URL;

/*!
	@method extensionOfURL:
	@abstract File name extension of item.
	@discussion Returns the file name extension for the supplied <tt>NSURL</tt>.
	@param URL The <tt>NSURL</tt> for which the file name extension is desired.
	@result Returns a <tt>NSString</tt> for file name extension, if the fiel does not have a extension then the result may be an empty <tt>NSString</tt> or <tt>nil</tt>.
  */
- (NSString *)extensionOfURL:(NSURL *)URL;


@end

/*!
	@category NDLaunchServicesObject(LSItemInfoFlags)
	@abstract Category of <tt>NDLaunchServicesObject</tt>, methods for getting item info.
	@discussion Convience methods used to get the information for <tt>LSItemInfoFlags</tt>
 */
@interface NDLaunchServicesObject (LSItemInfoFlags)

/*!
	@method isPlainFileAtURL:
	@abstract Test file info flag.
	@discussion Is the file of no type.
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
  */
- (BOOL)isPlainFileAtURL:(NSURL *)URL;
/*!
	@method isPackageAtURL:
	@abstract Test file info flag.
	@discussion application, document, or bundle package
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
  */
- (BOOL)isPackageAtURL:(NSURL *)URL;
/*!
	@method isApplicationAtURL:
	@abstract Test file info flag.
	@discussion Single-file or packaged application.
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isApplicationAtURL:(NSURL *)URL;
/*!
	@method isContainerAtURL:
	@abstract Test file info flag.
	@discussion Folder or volume
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isContainerAtURL:(NSURL *)URL;
/*!
	@method isAliasFileAtURL:
	@abstract Test file info flag.
	@discussion Alias file (includes sym links)
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isAliasFileAtURL:(NSURL *)URL;
/*!
	@method isSymlinkAtURL:
	@abstract Test file info flag.
	@discussion UNIX symbolic link
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isSymlinkAtURL:(NSURL *)URL;
/*!
	@method isInvisibleAtURL:
	@abstract Test file info flag.
	@discussion Does not include '.' files or '.hidden' entries
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isInvisibleAtURL:(NSURL *)URL;
/*!
	@method isNativeAppAtURL:
	@abstract Test file info flag.
	@discussion Carbon or Cocoa native app
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isNativeAppAtURL:(NSURL *)URL;
/*!
	@method isClassicAppAtURL:
	@abstract Test file info flag.
	@discussion CFM Classic app
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isClassicAppAtURL:(NSURL *)URL;
/*!
	@method doesAppPrefersNativeAtURL:
	@abstract Test file info flag.
	@discussion Carbon application that prefers to be launched natively.
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)doesAppPrefersNativeAtURL:(NSURL *)URL;
/*!
	@method doesAppPrefersClassicAtURL:
	@abstract Test file info flag.
	@discussion Carbon application that prefers to be launched in Classic.
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)doesAppPrefersClassicAtURL:(NSURL *)URL;
/*!
	@method isAppIsScriptableAtURL:
	@abstract Test file info flag.
	@discussion Application can be scripted.
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isAppIsScriptableAtURL:(NSURL *)URL;
/*!
	@method isVolumeAtURL:
	@abstract Test file info flag.
	@discussion Item is a volume
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isVolumeAtURL:(NSURL *)URL;
/*!
	@method isExtensionIsHiddenAtURL:
	@abstract Test file info flag.
	@discussion Item has a hidden extension.
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (BOOL)isExtensionIsHiddenAtURL:(NSURL *)URL;

/*!
	@method itemInfoFlagAtURL:whichInfo:
	@abstract Test file info flag.
	@discussion All possible flags, NOT SAFE to use from threads
	Possible values of <tt>LSItemInfoFlags</tt>, where they can be combined with a bitwise or, are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th> flag </th ><th> Description </th ></tr></thead>
			<tr><td align = "center"><tt>kLSItemInfoIsPlainFile</tt></td><td>none of the following applies</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsPackage</tt></td><td>app, doc, or bundle package</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsApplication</tt></td><td>single-file or packaged application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsContainer</tt></td><td>folder or volume</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsAliasFile</tt></td><td>alias file (includes sym links)</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsSymlink</tt></td><td>UNIX sym link</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsInvisible</tt></td><td>invisible file, does not include '.' files or '.hidden' entries</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsNativeApp</tt></td><td>Carbon or Cocoa native application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsClassicApp</tt></td><td>CFM Classic application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppPrefersNative</tt></td><td>Carbon application that prefers to be launched natively</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppPrefersClassic</tt></td><td>Carbon application that prefers to be launched in Classic</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppIsScriptable</tt></td><td>Application that can be scripted</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsVolume</tt></td><td>item is a volume</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoExtensionIsHidden</tt></td><td>item has a hidden extension</td></tr>
		</table >
	</blockquote >
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (LSItemInfoFlags)itemInfoFlagAtURL:(NSURL *)URL whichInfo:(LSRequestedInfo)whichInfo;
/*!
	@method basicItemInfoFlagAtURL:
	@abstract Test file info flag.
	@discussion All but type of application and extension flags - safe to use from threads
	Possible values of <tt>LSItemInfoFlags</tt>, where they can be combined with a bitwise or, are
	<blockquote>
		<table border = "1"  width = "90%">
			<thead><tr><th> flag </th ><th> Description </th ></tr></thead>
			<tr><td align = "center"><tt>kLSItemInfoIsPlainFile</tt></td><td>none of the following applies</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsPackage</tt></td><td>app, doc, or bundle package</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsApplication</tt></td><td>single-file or packaged application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsContainer</tt></td><td>folder or volume</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsAliasFile</tt></td><td>alias file (includes sym links)</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsSymlink</tt></td><td>UNIX sym link</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsInvisible</tt></td><td>invisible file, does not include '.' files or '.hidden' entries</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsNativeApp</tt></td><td>Carbon or Cocoa native application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsClassicApp</tt></td><td>CFM Classic application</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppPrefersNative</tt></td><td>Carbon application that prefers to be launched natively</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppPrefersClassic</tt></td><td>Carbon application that prefers to be launched in Classic</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoAppIsScriptable</tt></td><td>Application that can be scripted</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoIsVolume</tt></td><td>item is a volume</td></tr>
			<tr><td align = "center"><tt>kLSItemInfoExtensionIsHidden</tt></td><td>item has a hidden extension</td></tr>
		</table >
	</blockquote >
	@param URL The <tt>NSURL</tt> for which the file info is desired.
	@result Returns the result.
 */
- (LSItemInfoFlags)basicItemInfoFlagAtURL:(NSURL *)URL;

@end

