/*!
	@header NDResourceFork
	@abstract Defines the interface for the class <tt>NDResourceFork</tt>.
	@discussion <tt>NDResourceFork</tt> allows your cocoa application create, delete, open, read, modify, and write resources; get information about them. A resource is data of any kind stored in a defined format in a file's resource fork. On intialization, <tt>NDResourceFork</tt> open the resource fork and then closes the resource for when it is deallocated.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*!
	@class NDResourceFork
	@abstract A class to access manipulate resource forks from Cocoa.
	@discussion <tt>NDResourceFork</tt> allows your cocoa application create, delete, open, read, modify, and write resources; get information about them. A resource is data of any kind stored in a defined format in a file's resource fork. On intialization, <tt>NDResourceFork</tt> open the resource fork and then closes the resource for when it is deallocated.
 */
@interface NDResourceFork : NSObject
{
@private
	short int	fileReference;
}

/*!
@method resourceForkForReadingAtURL:
	@abstract Creates and initalises a <tt>NDResourceFork</tt>.
	@discussion Creates and intializes a <tt>NDResourceFork</tt> and opens a resource fork for reading using the file url.. The <tt>NDResourceFork</tt> resource fork is closed when the receiver is deallocated.
	@param URL A file url specifying the name and location of the file whose resource fork is to be opened.
	@result A <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForReadingAtURL:(NSURL *)URL;
/*!
	@method resourceForkForWritingAtURL:
	@abstract Creates and initalises a <tt>NDResourceFork</tt>.
	 @discussion Creates and intializes a <tt>NDResourceFork</tt> and opens a resource fork for writting, creating it before hand if it does not already exists, using the file url. The <tt>NDResourceFork</tt> resource fork is closed when the receiver is deallocated.
	 @param URL A file url specifying the name and location of the file whose resource fork is to be opened.
	@result A <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForWritingAtURL:(NSURL *)URL;
/*!
	@method resourceForkForReadingAtPath:
	 @abstract Creates and initalises a <tt>NDResourceFork</tt>.
	 @discussion Creates and intializes a <tt>NDResourceFork</tt> and opens a resource fork for reading using the path. The receivers resource fork is closed when the receiver is deallocated.
	 @param path A path specifying the name and location of the file whose resource fork is to be opened.
	@result A <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForReadingAtPath:(NSString *)path;
/*!
	@method resourceForkForWritingAtPath:
	@abstract Creates and initalises a <tt>NDResourceFork</tt>.
	@discussion Creates and intializes a <tt>NDResourceFork</tt>r and opens a resource fork for writting, creating it before hand if it does not already exists, using the path. The receivers resource fork is closed when the receiver is deallocated.
	@param path A path specifying the name and location of the file whose resource fork is to be opened.
	@result A <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or Create and initalise failed.
 */
+ (id)resourceForkForWritingAtPath:(NSString *)path;

/*!
	@method initForReadingAtURL:
	@abstract Initalises a <tt>NDResourceFork</tt>.
	@discussion Intializes the receiver and opens a resource fork for reading using the file url.
	@param URL A file url specifying the name and location of the file whose resource fork is to be opened. The receivers resource fork is closed when the receiver is deallocated.
	@result An initialized <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or initalization failed.
  */
- (id)initForReadingAtURL:(NSURL *)URL;
/*!
	@method initForReadingAtURL:
	 @abstract Initalises a <tt>NDResourceFork</tt>.
	 @discussion Intializes the receiver and opens a resource fork for writting, creating it before hand if it does not already exists, using the file url. The receivers resource fork is closed when the receiver is deallocated.
	 @param URL A file url specifying the name and location of the file whose resource fork is to be opened.
	 @result An initialized <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or initalization failed.
 */
- (id)initForWritingAtURL:(NSURL *)URL;
/*!
	@method initForReadingAtPath:
	 @abstract Initalises a <tt>NDResourceFork</tt>.
	 @discussion Intializes the receiver and opens a resource fork for reading using the path. The receivers resource fork is closed when the receiver is deallocated.
	 @param path A path specifying the name and location of the file whose resource fork is to be opened.
	 @result An initialized <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or initalization failed.
 */
- (id)initForReadingAtPath:(NSString *)path;
/*!
	@method initForWritingAtPath:
	 @abstract Initalises a <tt>NDResourceFork</tt>.
	 @discussion Intializes the receiver and opens a resource fork for writting, creating it before hand if it does not already exists, using the path. The receivers resource fork is closed when the receiver is deallocated.
	 @param path A path specifying the name and location of the file whose resource fork is to be opened.
	 @result An initialized <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or initalization failed.
 */
- (id)initForWritingAtPath:(NSString *)path;
/*!
	@method initForPermission:AtURL:
	@abstract Initalises a <tt>NDResourceFork</tt>.
	@discussion Intializes the receiver and opens a resource fork for reading and/or writting using the file url. If write permission is specified, then an empty resource fork created before hand if it does not already exists.  The receivers resource fork is closed when the receiver is deallocated.Possible permission values are as follows;
	<blockquote>
		<table border=0 cellpadding=4>
			<tr><td width=80 valign=top><tt>fsCurPerm</tt></td>
				<td>Requests whatever permissions are currently allowed. If write access in unavailable (because the file is locked or the file is already open with write permission), then read permission is granted. Otherwise read/write permission is granted.</td></tr>
			<tr><td valign=top><tt>fsRdPerm</tt></td>
				<td>Requests permission to read the file.</td></tr>
			<tr><td valign=top><tt>fsWrPerm</tt></td>
				<td>Requests permission to write to the file. If write permission is granted, no other access paths are granted write permission. Note, however, that the File Manager does not support write-only access to a file. Thus, <tt>fsWrPerm</tt> is synonymous with <tt>fsRdWrPerm</tt> .</td></tr>
			<tr><td valign=top><tt>fsRdWrPerm</tt></td>
				<td>Requests exclusive read and write permission. If exclusive read/ write permission is granted, no other users are granted permission to write to the file. Other users may, however, be granted permission to read the file.</td></tr>
			<tr><td valign=top><tt>fsRdWrShPerm</tt></td>
				<td>Requests shared read and write permission. Shared read/ write permission allows mutliple access paths for reading and writing. This is safe only if there is some way of locking portions of the file before writing to them. Use the functions <tt>PBLockRangeSync</tt> and <tt>PBUnlockRangeSync</tt> to lock and unlock ranges of bytes within a file. On Mac OS 8 and 9, these functions are supported only on remotely mounted volumes, or on local volumes that are shareable on the network. You should check that range locking is available before requesting shared read/ write permission.  On Mac OS X, range locking is available on all volumes.</td></tr>
			<tr><td valign=top><tt>fsRdDenyPerm</tt></td>
				<td>Requests that any other paths be prevented from having read access. A path cannot be opened if you request read permission (with the <tt>fsRdPerm</tt> constant) but some other path has requested deny-read access. Similarly, the path cannot be opened if you request deny-read permission, but some other path already has read access. This constant is used with the <tt>PBHOpenDenySync</tt> and <tt>PBHOpenRFDenySync</tt> functions.</td></tr>
			<tr><td valign=top><tt>fsWrDenyPerm</tt></td>
				<td>Requests that any other paths be prevented from having write access. A path cannot be opened if you request write permission (with the <tt>fsWrPerm</tt> constant) but some other path has requested deny-write access. Similarly, the path cannot be opened if you request deny-write permission, but some other path already has write access. This constant is used with the <tt>PBHOpenDenySync</tt> and <tt>PBHOpenRFDenySync</tt> functions.</td></tr>
		</table>
	</blockquote>
	@param permission read/write permissions for the opened resource fork.
	@param URL A file url specifying the name and location of the file whose resource fork is to be opened.
	@result An initialized <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or initalization failed.
 */
- (id)initForPermission:(char)permission AtURL:(NSURL *)URL;
/*!
	@method initForPermission:AtPath:
	@abstract Initalises a <tt>NDResourceFork</tt>.
	@discussion Intializes the receiver and opens a resource fork for reading and/or writting using the path. If write permission is specified, then an empty resource fork created before hand if it does not already exists. The receivers resource fork is closed when the receiver is deallocated. Possible permission values are as follows;
	<blockquote>
		<table border=0 cellpadding=4>
			<tr><td width=80 valign=top><tt>fsCurPerm</tt></td>
			<td>Requests whatever permissions are currently allowed. If write access in unavailable (because the file is locked or the file is already open with write permission), then read permission is granted. Otherwise read/write permission is granted.</td></tr>
			<tr><td valign=top><tt>fsRdPerm</tt></td>
			<td>Requests permission to read the file.</td></tr>
			<tr><td valign=top><tt>fsWrPerm</tt></td>
			<td>Requests permission to write to the file. If write permission is granted, no other access paths are granted write permission. Note, however, that the File Manager does not support write-only access to a file. Thus, <tt>fsWrPerm</tt> is synonymous with <tt>fsRdWrPerm</tt> .</td></tr>
			<tr><td valign=top><tt>fsRdWrPerm</tt></td>
			<td>Requests exclusive read and write permission. If exclusive read/ write permission is granted, no other users are granted permission to write to the file. Other users may, however, be granted permission to read the file.</td></tr>
			<tr><td valign=top><tt>fsRdWrShPerm</tt></td>
			<td>Requests shared read and write permission. Shared read/ write permission allows mutliple access paths for reading and writing. This is safe only if there is some way of locking portions of the file before writing to them. Use the functions <tt>PBLockRangeSync</tt> and <tt>PBUnlockRangeSync</tt> to lock and unlock ranges of bytes within a file. On Mac OS 8 and 9, these functions are supported only on remotely mounted volumes, or on local volumes that are shareable on the network. You should check that range locking is available before requesting shared read/ write permission.  On Mac OS X, range locking is available on all volumes.</td></tr>
			<tr><td valign=top><tt>fsRdDenyPerm</tt></td>
			<td>Requests that any other paths be prevented from having read access. A path cannot be opened if you request read permission (with the <tt>fsRdPerm</tt> constant) but some other path has requested deny-read access. Similarly, the path cannot be opened if you request deny-read permission, but some other path already has read access. This constant is used with the <tt>PBHOpenDenySync</tt> and <tt>PBHOpenRFDenySync</tt> functions.</td></tr>
			<tr><td valign=top><tt>fsWrDenyPerm</tt></td>
			<td>Requests that any other paths be prevented from having write access. A path cannot be opened if you request write permission (with the <tt>fsWrPerm</tt> constant) but some other path has requested deny-write access. Similarly, the path cannot be opened if you request deny-write permission, but some other path already has write access. This constant is used with the <tt>PBHOpenDenySync</tt> and <tt>PBHOpenRFDenySync</tt> functions.</td></tr>
		</table>
	</blockquote>
	 @param permission read/write permissions for the opened resource fork.
	 @param path A path specifying the name and location of the file whose resource fork is to be opened.
	 @result An initialized <tt>NDResourceFork</tt> for an opened resource fork, returns <tt>nil</tt> if the resource fork could not be opened or initalization failed.
 */
- (id)initForPermission:(char)permission AtPath:(NSString *)path;

/*!
	@method addData:type:Id:name:
	@abstract Adds a resource to the receivers resource file.
	@discussion <tt>addData:type:name:</tt> doesn't verify whether the resource ID you pass in the parameter <tt><i>ID</i></tt> is already assigned to another resource of the same type. You should use the methods <tt>addData:type:name:</tt> or <tt>dataForType:named:</tt> to get a unique resource ID when adding a resource . <tt>addData:type:Id:named:</tt> returns <tt>YES</tt> on success
	@param data An <tt>NSData</tt> object containing the data to be added as a resource to the receivers resource file. 
	@param type The resource type of the resource to be added.
	@param ID The resource ID of the resource to be added.
	@param name The name of the resource to be added. 
	@result Returns <tt>YES</tt> if the resource was successfully added, otherwise it returns <tt>NO</tt>.
 */
- (BOOL)addData:(NSData *)data type:(ResType)type Id:(short int)ID name:(NSString *)name;
/*!
	@method addData:type:name:
	 @abstract Adds a resource to the receivers resource file.
	 @discussion <tt>addData:type:name:</tt> uses an unique resource ID when adding a resource . <tt>addData:type:Id:named:</tt> returns <tt>YES</tt> on success
	 @param data An <tt>NSData</tt> object containing the data to be added as a resource to the receivers resource file.
	 @param type The resource type of the resource to be added.
	 @param name The name of the resource to be added.
	 @result Returns <tt>YES</tt> if the resource was successfully added, otherwise it returns <tt>NO</tt>.
 */
- (BOOL)addData:(NSData *)data type:(ResType)type name:(NSString *)name;
/*!
	@method dataForType:Id:
	@abstract Gets resource data for a resource in the receivers resource file.
	@discussion <tt>dataForType:Id:</tt> searches the receivers resource file's resource map in memory for the specified resource.
	@param type The resource type of the resource which you wish to retrieve data.
	@param ID An integer that uniquely identifies the resource which you wish to retrieve data.
	@result Returns an <tt>NSData</tt> object if successful otherwise returns nil.
  */
- (NSData *)dataForType:(ResType)type Id:(short int)ID;
/*!
	@method dataForType:named:
	 @abstract Gets resource data for a resource in the receivers resource file.
	 @discussion <tt>dataForType:Id:</tt> searches the receivers resource file's resource map in memory for the specified resource.
	 @param type The resource type of the resource which you wish to retrieve data.
	 @param name A name that uniquely identifies the resource which you wish to retrieve data. Strings passed in this parameter are case-sensitive.
	 @result Returns an <tt>NSData</tt> object if successful otherwise returns nil.
 */
- (NSData *)dataForType:(ResType)type named:(NSString *)name;

/*!
	@method removeType:Id:
	@abstract Removes a resource's entry from the receivers resource file.
	@discussion If the <tt>resProtected</tt> attribute for the resource is set, <tt>removeType:Id:</tt> does nothing, and returns <tt>NO</tt>.
	@param type The resource type of the resource which you wish to remove.
	@param ID An integer that uniquely identifies the resource which you wish to remove.
	@result Returns <tt>YES</tt> if the resource was successfully removed, otherwise if returns <tt>NO</tt>.
  */
- (BOOL)removeType:(ResType)type Id:(short int)ID;

/*!
	@method everyResourceType
	@abstract Gets every resource type available in the receivers resource file.
	@discussion <tt>everyResourceType</tt> returns an <tt>NSArray</tt> of <tt>NSNumber</tt>s each containing a <tt>unsigned long</tt>  or <tt>ResType</tt>s.
	@result A <tt>NSArray</tt> of <tt>NSNumber</tt>s containing <tt>ResType</tt>s.
  */
- (NSArray *)everyResourceType;

/*!
	@method nameOfResourceType:Id:
	@abstract Gets a resource's resource name.
	@discussion Returns a resources name as an <tt>NSString</tt>.
	@param type The resource type of the resource for which you wish to retrieve the name.
	@param ID An integer that uniquely identifies the resource for which you wish to retrieve the name.
	@result An <tt>NSString</tt> containing the resources name.
  */
- (NSString *)nameOfResourceType:(ResType)type Id:(short int)ID;
/*!
	@method getId:ofResourceType:named:
	@abstract Gets a named resource's resource id.
	@discussion Returns a resources id in a pointer to a <tt>short int</tt> and returns <tt>YES</tt> if retrieval of the id is succeeded. If <tt>getId:ofResourceType:named:</tt> returns <tt>NO</tt> then the value returned through the pointer <tt><i>ID</i></tt> is garabage.
	@param ID A pointer to an <tt>short int</tt> that on return contains the resources id, if the returned value is <tt>YES</tt>.
	@param type The resource type of the resource for which you wish to retrieve the id.
	@param name The resource name of the resource for which you wish to retrieve the id.
	@result A <tt>YES</tt> if retrieval was successful.
 */
- (BOOL)getId:(short int *)ID ofResourceType:(ResType)type named:(NSString *)name;

/*!
	@method getAttributeFlags:forResourceType:Id:
	@abstract Gets a resource's attributes.
	@discussion Returns the attributes for a resource in a pointer  to a <tt>short int</tt> and returns <tt>YES</tt> if retrieval of the attributes is succeeded. If <tt>getAttributeFlags:forResourceType:Id:</tt> returns <tt>NO</tt> then the value returned through the pointer <tt><i>attributes</i></tt> is garabage.
	@param attributes A pointer to an <tt>short int</tt> that on return contains the resources attributes, if the returned value is <tt>YES</tt>.
	@param type The resource type of the resource for which you wish to retrieve the attributes.
	@param ID An integer that uniquely identifies the resource for which you wish to retrieve the attributes.
	@result A <tt>YES</tt> if retrieval was successful.
  */
- (BOOL)getAttributeFlags:(short int*)attributes forResourceType:(ResType)type Id:(short int)ID;
/*!
	@method setAttributeFlags:forResourceType:Id:
	@abstract Sets a resource's attributes.
	@discussion Set the attributes for a resource in <tt><i>attributes</i></tt> and returns <tt>YES</tt> if setting of the attributes is succeeded.
	@param attributes A <tt>short int</tt> that contains the resources attributes to be set.
	@param type The resource type of the resource for which you wish to set the attributes.
	@param ID An integer that uniquely identifies the resource for which you wish to set the attributes.
	@result A <tt>YES</tt> if <tt>setAttributeFlags:forResourceType:Id:</tt> was successful in setting the resources attributes.
  */
- (BOOL)setAttributeFlags:(short int)attributes forResourceType:(ResType)type Id:(short int)ID;

/*!
	@method dataForEntireResourceFork
	@abstract Reads the receivers entire resource data.
	@discussion <tt>dataForEntireResourceFork</tt> returns a <tt>NSData</tt> object that contains the entire contents of the resource fork. <tt>dataForEntireResourceFork</tt> and it's conpanion method <tt>writeEntireResourceFork</tt> can be used for duplicating the resource fork for on file to the resource fork of another. <tt>dataForEntireResourceFork</tt> can also be used to convert a resource stored in a files resource fork into a resource stored in a data fork, simple by using the <tt>NSData</tt> methods <tt>writeToFile:atomically:</tt> or <tt>writeToURL:atomically:</tt>.
	@result A <tt>NSData</tt> object containing the resources data.
  */
- (NSData *)dataForEntireResourceFork;
/*!
	@method writeEntireResourceFork:
	@abstract Writes complete resource data to the receivers resource fork.
	@discussion <tt>writeEntireResourceFork:</tt> writes the data in the <tt>NSData</tt> object out the the recievers resource fork. <tt>writeEntireResourceFork</tt> and it's conpanion method <tt>dataForEntireResourceFork</tt> can be used for duplicating the resource fork for on file to the resource fork of another. <tt>writeEntireResourceFork:</tt> can also be used to convert a resource stored in a files data fork into a resource stored in a files resource fork, simple by creating the <tt>NSData</tt> object with the methods <tt>dataWithContentsOfFile</tt> or <tt>dataWithContentsOfURL:</tt>.
	@param data The complete resource data in a <tt>NSData</tt> object. 
	@result Returns <tt>YES</tt> if writting was successful, returns <tt>NO</tt> otherwise.
  */
- (BOOL)writeEntireResourceFork:(NSData *)data;

@end
