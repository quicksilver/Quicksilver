/*
 *  NDResourceFork.h
 *  AppleScriptObjectProject
 *
 *  Created by nathan on Wed Dec 05 2001.
 *  Copyright (c) 2001 Nathan Day. All rights reserved.
 */

/*!
	@header NDResourceFork
	@abstract Defines the interface for the class <TT>NDResourceFork</TT>.
	@discussion <TT>NDResourceFork</TT> has additional methods defined in categories of <TT>NDResourceFork</TT>.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*!
	@class NDResourceFork
	@abstract A class to access manipulate resource forks from Cocoa.
	@discussion <TT>NDResourceFork</TT> allows your cocoa application create, delete, open, read, modify, and write resources; get information about them. A resource is data of any kind stored in a defined format in a file's resource fork. On intialization, <TT>NDResourceFork</TT> open the resource fork and then closes the resource for when it is deallocated.
 */
@interface NDResourceFork : NSObject
{
@private
	short int	fileReference;
}

/*!
	@method resourceForkForReadingAtURL:
	@abstract Creates and initalises a <TT>NDResourceFork</TT>.
	@discussion Creates and intializes a <TT>NDResourceFork</TT> and opens a resource fork for reading using the file url.. The <TT>NDResourceFork</TT> resource fork is closed when the receiver is deallocated.
	@param aURL A file url specifying the name and location of the file whose resource fork is to be opened.
	@result A <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForReadingAtURL:(NSURL *)aURL;
/*!
	@method resourceForkForWritingAtURL:
	@abstract Creates and initalises a <TT>NDResourceFork</TT>.
	@discussion Creates and intializes a <TT>NDResourceFork</TT> and opens a resource fork for writting, creating it before hand if it does not already exists, using the file url. The <TT>NDResourceFork</TT> resource fork is closed when the receiver is deallocated.
	@param aURL A file url specifying the name and location of the file whose resource fork is to be opened.
	@result A <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForWritingAtURL:(NSURL *)aURL;
/*!
	@method resourceForkForReadingAtPath:
	@abstract Creates and initalises a <TT>NDResourceFork</TT>.
	@discussion Creates and intializes a <TT>NDResourceFork</TT> and opens a resource fork for reading using the path. The receivers resource fork is closed when the receiver is deallocated.
	@param aPath A path specifying the name and location of the file whose resource fork is to be opened.
	@result A <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForReadingAtPath:(NSString *)aPath;
/*!
	@method resourceForkForWritingAtPath:
	@abstract Creates and initalises a <TT>NDResourceFork</TT>.
	@discussion Creates and intializes a <TT>NDResourceFork</TT>r and opens a resource fork for writting, creating it before hand if it does not already exists, using the path. The receivers resource fork is closed when the receiver is deallocated.
	@param aPath A path specifying the name and location of the file whose resource fork is to be opened.
	@result A <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForWritingAtPath:(NSString *)aPath;

/*!
	@method initForReadingAtURL:
	@abstract Initalises a <TT>NDResourceFork</TT>.
	@discussion Intializes the receiver and opens a resource fork for reading using the file url.
	@param aURL A file url specifying the name and location of the file whose resource fork is to be opened. The receivers resource fork is closed when the receiver is deallocated.
	@result An initialized <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or initalization failed.
  */
- (id)initForReadingAtURL:(NSURL *)aURL;
/*!
	@method initForReadingAtURL:
	@abstract Initalises a <TT>NDResourceFork</TT>.
	@discussion Intializes the receiver and opens a resource fork for writting, creating it before hand if it does not already exists, using the file url. The receivers resource fork is closed when the receiver is deallocated.
	@param aURL A file url specifying the name and location of the file whose resource fork is to be opened.
	@result An initialized <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or initalization failed.
 */
- (id)initForWritingAtURL:(NSURL *)aURL;
/*!
	@method initForReadingAtPath:
	@abstract Initalises a <TT>NDResourceFork</TT>.
	@discussion Intializes the receiver and opens a resource fork for reading using the path. The receivers resource fork is closed when the receiver is deallocated.
	@param aPath A path specifying the name and location of the file whose resource fork is to be opened.
	@result An initialized <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or initalization failed.
 */
- (id)initForReadingAtPath:(NSString *)aPath;
/*!
	@method initForWritingAtPath:
	@abstract Initalises a <TT>NDResourceFork</TT>.
	@discussion Intializes the receiver and opens a resource fork for writting, creating it before hand if it does not already exists, using the path. The receivers resource fork is closed when the receiver is deallocated.
	@param aPath A path specifying the name and location of the file whose resource fork is to be opened.
	@result An initialized <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or initalization failed.
 */
- (id)initForWritingAtPath:(NSString *)aPath;
/*!
	@method initForPermission:AtURL:
	@abstract Initalises a <TT>NDResourceFork</TT>.
	@discussion Intializes the receiver and opens a resource fork for reading and/or writting using the file url. If write permission is specified, then an empty resource fork created before hand if it does not already exists.  The receivers resource fork is closed when the receiver is deallocated.Possible permission values are as follows;
<TABLE BORDER=0 CELLPADDING=4>
 <TR><TD WIDTH=80 VALIGN=top><TT>fsCurPerm</TT></TD>
	<TD>Requests whatever permissions are currently allowed. If write access in unavailable (because the file is locked or the file is already open with write permission), then read permission is granted. Otherwise read/write permission is granted.</TD></TR>
 <TR><TD VALIGN=top><TT>fsRdPerm</TT></TD>
	<TD>Requests permission to read the file.</TD></TR>
 <TR><TD VALIGN=top><TT>fsWrPerm</TT></TD>
	<TD>Requests permission to write to the file. If write permission is granted, no other access paths are granted write permission. Note, however, that the File Manager does not support write-only access to a file. Thus, <TT>fsWrPerm</TT> is synonymous with <TT>fsRdWrPerm</TT> .</TD></TR>
 <TR><TD VALIGN=top><TT>fsRdWrPerm</TT></TD>
	<TD>Requests exclusive read and write permission. If exclusive read/ write permission is granted, no other users are granted permission to write to the file. Other users may, however, be granted permission to read the file.</TD></TR>
 <TR><TD VALIGN=top><TT>fsRdWrShPerm</TT></TD>
	<TD>Requests shared read and write permission. Shared read/ write permission allows mutliple access paths for reading and writing. This is safe only if there is some way of locking portions of the file before writing to them. Use the functions <TT>PBLockRangeSync</TT> and <TT>PBUnlockRangeSync</TT> to lock and unlock ranges of bytes within a file. On Mac OS 8 and 9, these functions are supported only on remotely mounted volumes, or on local volumes that are shareable on the network. You should check that range locking is available before requesting shared read/ write permission.  On Mac OS X, range locking is available on all volumes.</TD></TR>
 <TR><TD VALIGN=top><TT>fsRdDenyPerm</TT></TD>
	<TD>Requests that any other paths be prevented from having read access. A path cannot be opened if you request read permission (with the <TT>fsRdPerm</TT> constant) but some other path has requested deny-read access. Similarly, the path cannot be opened if you request deny-read permission, but some other path already has read access. This constant is used with the <TT>PBHOpenDenySync</TT> and <TT>PBHOpenRFDenySync</TT> functions.</TD></TR>
 <TR><TD VALIGN=top><TT>fsWrDenyPerm</TT></TD>
	<TD>Requests that any other paths be prevented from having write access. A path cannot be opened if you request write permission (with the <TT>fsWrPerm</TT> constant) but some other path has requested deny-write access. Similarly, the path cannot be opened if you request deny-write permission, but some other path already has write access. This constant is used with the <TT>PBHOpenDenySync</TT> and <TT>PBHOpenRFDenySync</TT> functions.</TD></TR>
</TABLE>
	@param aPermission read/write permissions for the opened resource fork.
	@param aURL A file url specifying the name and location of the file whose resource fork is to be opened.
	@result An initialized <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or initalization failed.
 */
- (id)initForPermission:(char)aPermission AtURL:(NSURL *)aURL;
/*!
	@method initForPermission:AtPath:
	@abstract Initalises a <TT>NDResourceFork</TT>.
	@discussion Intializes the receiver and opens a resource fork for reading and/or writting using the path. If write permission is specified, then an empty resource fork created before hand if it does not already exists. The receivers resource fork is closed when the receiver is deallocated. Possible permission values are as follows;
	 <TABLE BORDER=0 CELLPADDING=4>
	 <TR><TD WIDTH=80 VALIGN=top><TT>fsCurPerm</TT></TD>
	 <TD>Requests whatever permissions are currently allowed. If write access in unavailable (because the file is locked or the file is already open with write permission), then read permission is granted. Otherwise read/write permission is granted.</TD></TR>
	 <TR><TD VALIGN=top><TT>fsRdPerm</TT></TD>
	 <TD>Requests permission to read the file.</TD></TR>
	 <TR><TD VALIGN=top><TT>fsWrPerm</TT></TD>
	 <TD>Requests permission to write to the file. If write permission is granted, no other access paths are granted write permission. Note, however, that the File Manager does not support write-only access to a file. Thus, <TT>fsWrPerm</TT> is synonymous with <TT>fsRdWrPerm</TT> .</TD></TR>
	 <TR><TD VALIGN=top><TT>fsRdWrPerm</TT></TD>
	 <TD>Requests exclusive read and write permission. If exclusive read/ write permission is granted, no other users are granted permission to write to the file. Other users may, however, be granted permission to read the file.</TD></TR>
	 <TR><TD VALIGN=top><TT>fsRdWrShPerm</TT></TD>
	 <TD>Requests shared read and write permission. Shared read/ write permission allows mutliple access paths for reading and writing. This is safe only if there is some way of locking portions of the file before writing to them. Use the functions <TT>PBLockRangeSync</TT> and <TT>PBUnlockRangeSync</TT> to lock and unlock ranges of bytes within a file. On Mac OS 8 and 9, these functions are supported only on remotely mounted volumes, or on local volumes that are shareable on the network. You should check that range locking is available before requesting shared read/ write permission.  On Mac OS X, range locking is available on all volumes.</TD></TR>
	 <TR><TD VALIGN=top><TT>fsRdDenyPerm</TT></TD>
	 <TD>Requests that any other paths be prevented from having read access. A path cannot be opened if you request read permission (with the <TT>fsRdPerm</TT> constant) but some other path has requested deny-read access. Similarly, the path cannot be opened if you request deny-read permission, but some other path already has read access. This constant is used with the <TT>PBHOpenDenySync</TT> and <TT>PBHOpenRFDenySync</TT> functions.</TD></TR>
	 <TR><TD VALIGN=top><TT>fsWrDenyPerm</TT></TD>
	 <TD>Requests that any other paths be prevented from having write access. A path cannot be opened if you request write permission (with the <TT>fsWrPerm</TT> constant) but some other path has requested deny-write access. Similarly, the path cannot be opened if you request deny-write permission, but some other path already has write access. This constant is used with the <TT>PBHOpenDenySync</TT> and <TT>PBHOpenRFDenySync</TT> functions.</TD></TR>
	 </TABLE>
	@param aPermission read/write permissions for the opened resource fork.
	@param aPath A path specifying the name and location of the file whose resource fork is to be opened.
	@result An initialized <TT>NDResourceFork</TT> for an opened resource fork, returns <TT>nil</TT> if the resource fork could not be opened or initalization failed.
 */
- (id)initForPermission:(char)aPermission AtPath:(NSString *)aPath;

/*!
	@method addData:type:Id:name:
	@abstract Adds a resource to the receivers resource file.
	@discussion <TT>addData:type:name:</TT> doesn't verify whether the resource ID you pass in the parameter <TT><I>anID</I></TT> is already assigned to another resource of the same type. You should use the methods <TT>addData:type:name:</TT> or <TT>dataForType:named:</TT> to get a unique resource ID when adding a resource . <TT>addData:type:Id:named:</TT> returns <TT>YES</TT> on success
	@param aData An <TT>NSData</TT> object containing the data to be added as a resource to the receivers resource file. 
	@param aType The resource type of the resource to be added.
	@param anID The resource ID of the resource to be added.
	@param aName The name of the resource to be added. 
	@result Returns <TT>YES</TT> if the resource was successfully added, otherwise it returns <TT>NO</TT>.
 */
- (BOOL)addData:(NSData *)aData type:(ResType)aType Id:(short int)anID name:(NSString *)aName;
/*!
	@method addData:type:name:
	@abstract Adds a resource to the receivers resource file.
	@discussion <TT>addData:type:name:</TT> uses an unique resource ID when adding a resource . <TT>addData:type:Id:named:</TT> returns <TT>YES</TT> on success
	@param aData An <TT>NSData</TT> object containing the data to be added as a resource to the receivers resource file.
	@param aType The resource type of the resource to be added.
	@param aName The name of the resource to be added.
	@result Returns <TT>YES</TT> if the resource was successfully added, otherwise it returns <TT>NO</TT>.
 */
- (BOOL)addData:(NSData *)aData type:(ResType)aType name:(NSString *)aName;
/*!
	@method dataForType:Id:
	@abstract Gets resource data for a resource in the receivers resource file.
	@discussion <TT>dataForType:Id:</TT> searches the receivers resource file's resource map in memory for the specified resource.
	@param aType The resource type of the resource which you wish to retrieve data.
	@param anID An integer that uniquely identifies the resource which you wish to retrieve data.
	@result Returns an <TT>NSData</TT> object if successful otherwise returns nil.
  */
- (NSData *)dataForType:(ResType)aType Id:(short int)anID;
/*!
	@method dataForType:named:
	@abstract Gets resource data for a resource in the receivers resource file.
	@discussion <TT>dataForType:Id:</TT> searches the receivers resource file's resource map in memory for the specified resource.
	@param aType The resource type of the resource which you wish to retrieve data.
	@param aName A name that uniquely identifies the resource which you wish to retrieve data. Strings passed in this parameter are case-sensitive.
	@result Returns an <TT>NSData</TT> object if successful otherwise returns nil.
 */
- (NSData *)dataForType:(ResType)aType named:(NSString *)aName;

/*!
	@method removeType:Id:
	@abstract Removes a resource's entry from the receivers resource file.
	@discussion If the <TT>resProtected</TT> attribute for the resource is set, <TT>removeType:Id:</TT> does nothing, and returns <TT>NO</TT>.
	@param aType The resource type of the resource which you wish to remove.
	@param anID An integer that uniquely identifies the resource which you wish to remove.
	@result Returns <TT>YES</TT> if the resource was successfully removed, otherwise if returns <TT>NO</TT>.
  */
- (BOOL)removeType:(ResType)aType Id:(short int)anID;

/*!
	@method nameOfResourceType:Id:
	@abstract Gets a resource's resource name.
	@discussion Returns a resources name as an <TT>NSString</TT>.
	@param aType The resource type of the resource for which you wish to retrieve the name.
	@param anID An integer that uniquely identifies the resource for which you wish to retrieve the name.
	@result An <TT>NSString</TT> containing the resources name.
  */
- (NSString *)nameOfResourceType:(ResType)aType Id:(short int)anID;
/*!
	@method getId:ofResourceType:named:
	@abstract Gets a named resource's resource id.
	@discussion Returns a resources id in a pointer to a <TT>short int</TT> and returns <TT>YES</TT> if retrieval of the id is succeeded. If <TT>getId:ofResourceType:named:</TT> returns <TT>NO</TT> then the value returned through the pointer <TT><I>anId</I></TT> is garabage.
	@param anID A pointer to an <TT>short int</TT> that on return contains the resources id, if the returned value is <TT>YES</TT>.
	@param aType The resource type of the resource for which you wish to retrieve the id.
	@param aName The resource name of the resource for which you wish to retrieve the id.
	@result A <TT>YES</TT> if retrieval was successful.
 */
- (BOOL)getId:(short int *)anId ofResourceType:(ResType)aType named:(NSString *)aName;

/*!
	@method getAttributeFlags:forResourceType:Id:
	@abstract Gets a resource's attributes.
	@discussion Returns the attributes for a resource in a pointer  to a <TT>short int</TT> and returns <TT>YES</TT> if retrieval of the attributes is succeeded. If <TT>getAttributeFlags:forResourceType:Id:</TT> returns <TT>NO</TT> then the value returned through the pointer <TT><I>attributes</I></TT> is garabage.
	@param attributes A pointer to an <TT>short int</TT> that on return contains the resources attributes, if the returned value is <TT>YES</TT>.
	@param aType The resource type of the resource for which you wish to retrieve the attributes.
	@param anId An integer that uniquely identifies the resource for which you wish to retrieve the attributes.
	@result A <TT>YES</TT> if retrieval was successful.
  */
- (BOOL)getAttributeFlags:(short int*)attributes forResourceType:(ResType)aType Id:(short int)anId;
/*!
	@method setAttributeFlags:forResourceType:Id:
	@abstract Sets a resource's attributes.
	@discussion «Discussion»
	@param attributes A <TT>short int</TT> that contains the resources attributes to be set.
	@param aType The resource type of the resource for which you wish to set the attributes.
	@param anId An integer that uniquely identifies the resource for which you wish to set the attributes.
	@result A <TT>YES</TT> if <TT>setAttributeFlags:forResourceType:Id:</TT> was successful in setting the resources attributes.
  */
- (BOOL)setAttributeFlags:(short int)attributes forResourceType:(ResType)aType Id:(short int)anId;

/*!
	@method resourceTypeEnumerator
	@abstract Get a enumerator for every resource type.
	@discussion Returns a <TT>NSEnumerator</TT> which will return a <TT>NSNumber</TT> resource type.
	@result The <TT>NSEnumerator</TT>.
  */
- (NSEnumerator *)resourceTypeEnumerator;
/*!
	@method everyResourceType
	@abstract Gets every resource type available in the receivers resource file.
	@discussion <TT>everyResourceType</TT> returns an <TT>NSArray</TT> of <TT>NSNumber</TT>s each containing a <TT>unsigned long</TT>  or <TT>ResType</TT>s.
	@result A <TT>NSArray</TT> of <TT>NSNumber</TT>s containing <TT>ResType</TT>s.
  */
- (NSArray *)everyResourceType;
/*!
	@method dataForEntireResourceFork
	@abstract Reads the receivers entire resource data.
	@discussion <TT>dataForEntireResourceFork</TT> returns a <TT>NSData</TT> object that contains the entire contents of the resource fork. <TT>dataForEntireResourceFork</TT> and it's conpanion method <TT>writeEntireResourceFork</TT> can be used for duplicating the resource fork for on file to the resource fork of another. <TT>dataForEntireResourceFork</TT> can also be used to convert a resource stored in a files resource fork into a resource stored in a data fork, simple by using the <TT>NSData</TT> methods <TT>writeToFile:atomically:</TT> or <TT>writeToURL:atomically:</TT>.
	@result A <TT>NSData</TT> object containing the resources data.
  */
- (NSData *)dataForEntireResourceFork;
/*!
	@method writeEntireResourceFork:
	@abstract Writes complete resource data to the receivers resource fork.
	@discussion <TT>writeEntireResourceFork:</TT> writes the data in the <TT>NSData</TT> object out the the recievers resource fork. <TT>writeEntireResourceFork</TT> and it's conpanion method <TT>dataForEntireResourceFork</TT> can be used for duplicating the resource fork for on file to the resource fork of another. <TT>writeEntireResourceFork:</TT> can also be used to convert a resource stored in a files data fork into a resource stored in a files resource fork, simple by creating the <TT>NSData</TT> object with the methods <TT>dataWithContentsOfFile</TT> or <TT>dataWithContentsOfURL:</TT>.
	@param aData The complete resource data in a <TT>NSData</TT> object. 
	@result Returns <TT>YES</TT> if writting was successful, returns <TT>NO</TT> otherwise.
  */
- (BOOL)writeEntireResourceFork:(NSData *)aData;

@end

/*!
    @category NSData(NDResourceFork)
    @abstract Category of <tt>NSData</tt> fro creating <tt>NSData</tt> instances from the contents resource.
    @discussion The main benifit of theses methods over the equivelent methods of <tt>NDResourceFork</tt> is these methods create autoreased <tt>NSData</tt> instances without leaving any resources forks open by leaving any autoreleased <tt>NDResourceFork</tt> forks open.
*/
@interface NSData (NDResourceFork)

/*!
	@method dataWithResourceForkContentsOfURL:type:Id:
	@abstract Create a <tt>NSData</tt> instance.
	@discussion <#Discussion#>
	@param URL <#disc#>
	@param type The resource type of the resource which you wish to read data.
	@param ID An integer that uniquely identifies the resource which you wish to read data.
	@result <#result#>
 */
+ (NSData *)dataWithResourceForkContentsOfURL:(NSURL *)URL type:(ResType)type Id:(short int)ID;

/*!
	@method dataWithResourceForkContentsOfURL:type:named:
	@abstract Create a <tt>NSData</tt> instance.
	@discussion <#Discussion#>
	@param URL <#disc#>
	@param type The resource type of the resource which you wish to read data.
	@param name A name that uniquely identifies the resource which you wish to read data. Strings passed in this parameter are case-sensitive.
	@result <#result#>
 */
+ (NSData *)dataWithResourceForkContentsOfURL:(NSURL *)URL type:(ResType)type named:(NSString *)name;

/*!
	@method dataWithResourceForkContentsOfFile:type:Id:
	@abstract Create a <tt>NSData</tt> instance.
	@discussion <#Discussion#>
	@param path <#disc#>
	@param type The resource type of the resource which you wish to read data.
	@param ID An integer that uniquely identifies the resource which you wish to read data.
	@result <#result#>
 */
+ (NSData *)dataWithResourceForkContentsOfFile:(NSString *)path type:(ResType)type Id:(short int)ID;

/*!
	@method dataWithResourceForkContentsOfFile:type:named:
	@abstract Create a <tt>NSData</tt> instance.
	@discussion <#Discussion#>
	@param path <#disc#>
	@param type The resource type of the resource which you wish to read data.
	@param name A name that uniquely identifies the resource which you wish to read data. Strings passed in this parameter are case-sensitive.
	@result <#result#>
 */
+ (NSData *)dataWithResourceForkContentsOfFile:(NSString *)path type:(ResType)type named:(NSString *)name;

/*!
	@method writeToResourceForkURL:type:Id:name:
	@abstract write a <tt>NSData</tt> instance to a resource fork.
	@discussion <#Discussion#>
	@param URL <#disc#>
	@param type <#disc#>
	@param Id <#disc#>
	@param name <#disc#>
	@result <#result#>
 */
- (BOOL)writeToResourceForkURL:(NSURL *)URL type:(ResType)type Id:(int)Id name:(NSString *)name;

/*!
	@method writeToResourceForkFile:type:Id:name:
	@abstract write a <tt>NSData</tt> instance to a resource fork.
	@discussion <#Discussion#>
	@param path <#disc#>
	@param type <#disc#>
	@param Id <#disc#>
	@param name <#disc#>
	@result <#result#>
 */
- (BOOL)writeToResourceForkFile:(NSString *)path type:(ResType)type Id:(int)Id name:(NSString *)name;

@end

