/*!
	@header NSAppleEventDescriptor+NDAppleScriptObject
	@abstract Declares the category <tt>NSAppleEventDescriptor (NDAppleScriptObject)</tt>
	@discussion Additional methods initially created for use with <tt>NDAppleScriptObject</tt> but could have other applications especially with Cocoa's <tt>NSAppleScript</tt>.
 */

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

/*!
	@category NSAppleEventDescriptor(NDAppleScriptObject)
	@abstract Category of <tt>NSAppleEventDescriptor</tt>.
	@discussion Add some methods for use with AppleScripts and AppleEvents.
 */
@interface NSAppleEventDescriptor (NDAppleScriptObject)

/*!
	@method descriptorWithAEDescNoCopy:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for the <tt>AEDesc</tt>.
	@discussion Allocates, initializes and returns an <tt>NSAppleEventDescriptor</tt> that takes ownership of the Carbon <tt>AEDesc</tt> structure pointed to by <tt>aeDesc</tt>. Returns <tt>nil</tt> if an error occurs. The initialized object takes responsibility for calling the <tt>AEDisposeDesc</tt> function on the <tt>AEDesc</tt> at object deallocation time.
	@param aeDesc A Carbon <tt>AEDesc</tt> structure.
	@result A <tt>NSAppleEventDescriptor</tt>
 */
+ (id)descriptorWithAEDescNoCopy:(const AEDesc *)aeDesc;

/*!
	@method descriptorWithAEDesc:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for the <tt>AEDesc</tt>.
	@discussion Allocates, initializes and returns an <tt>NSAppleEventDescriptor</tt> that copies the Carbon <tt>AEDesc</tt> structure pointed to by <tt>aeDesc</tt>. Returns <tt>nil</tt> if an error occurs.
	@param aeDesc A Carbon <tt>AEDesc</tt> structure
	@result A <tt>NSAppleEventDescriptor</tt>
 */
+ (id)descriptorWithAEDesc:(const AEDesc *)aeDesc;

/*!
	@method initWithAEDesc:
	@abstract Intializes a <tt>NSAppleEventDescriptor</tt> with a <tt>AEDesc</tt>.
	@discussion Initializes and returns an <tt>NSAppleEventDescriptor</tt> that copies the Carbon <tt>AEDesc</tt> structure pointed to by <tt>aeDesc</tt>. Returns <tt>nil</tt> if an error occurs.
	@param aeDesc A Carbon <tt>AEDesc</tt> structure
	@result A <tt>NSAppleEventDescriptor</tt>
 */
- (id)initWithAEDesc:(const AEDesc *)aeDesc;

/*!
	@method isTargetCurrentProcess
	@abstract Determines if target is current process.
	@discussion If the recevier is a AppleEvent that contains a target ProcessSerialNumber that is the current process (ie you application) then this method returns <tt>YES</tt>.
	@result Returns <tt>YES</tt> if the recevier is an AppleEvent for the current process.
 */
- (BOOL)isTargetCurrentProcess;

/*!
	@method getAEDesc:
	@abstract Get the receviers <tt>AEDesc</tt>.
	@discussion Copies the receviers <tt>AEDesc</tt> to the supplied <tt>AEDesc</tt>.
	@param aeDescPtr The address of an empty <tt>AEDesc</tt>.
	@result Returns <tt>YES</tt> if successful.
 */
- (BOOL)getAEDesc:(AEDesc *)aeDescPtr;

@end

/*!
	@category NSAppleEventDescriptor(NDConversion)
	@abstract Category of <tt>NSAppleEventDescriptor</tt>.
	@discussion <p>Adds methods for converting between AppleEvent types and Objective-C types.</p>
	<p>The following type conversions are supported in 'either direction' or 'both directions';
	<blockquote>
		<table border="1"  width="90%">
			<thead><tr>
				<th width="40%">Objective-C Type</th>
				<th>Descriptor Type</th>
			</tr></thead>
			<tr>
				<td align="center"><tt>nil</tt></td>
				<td align="center"><tt>typeNull</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;BOOL&gt;</tt></td>
				<td align="center"><tt>typeBoolean</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;short int&gt;<br>NSNumber&lt;char&gt;</tt></td>
				<td align="center"><tt>typeSInt16<br>typeShortInteger<br>typeSMInt</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;int&gt;<br>NSNumber&lt;long int&gt;</tt></td>
				<td align="center"><tt>typeSInt32<br>typeLongInteger<br>typeInteger</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;float&gt;</tt></td>
				<td align="center"><tt>typeIEEE32BitFloatingPoint<br>typeShortFloat<br>typeSMFloat</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;double&gt;</tt></td>
				<td align="center"><tt>typeIEEE64BitFloatingPoint<br>typeFloat<br>typeLongFloat</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;long double&gt;</tt></td>
				<td align="center"><tt>type128BitFloatingPoint</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;unsigned char&gt;<br>NSNumber&lt;unsigned short int&gt;<br>NSNumber&lt;unsigned int&gt;<br>NSNumber&lt;unsigned long int&gt;</tt></td>
				<td align="center"><tt>typeUInt32</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;unsigned long long&gt;<br>NSNumber&lt;long long&gt;</tt></td>
				<td align="center">no 64 bit unsigned<br><tt>typeSInt64</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSValue&lt;NSRange&gt;</tt></td>
				<td align="center"><tt>typeOSAErrorRange</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSString</tt></td>
				<td align="center"><tt>typeText<br>kTXNUnicodeTextData<br>
									typeAlias</tt><br>see <tt>aliasListDescriptorWithArray:</tt> and <tt>aliasDescriptorWithString:</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSArray</tt></td>
				<td align="center"><tt>typeAEList<br>typeAEList&lt;typeAlias&gt;</tt><br>see <tt>aliasListDescriptorWithArray:</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSDictionary</tt></td>
				<td align="center"><tt>typeAERecord</tt><br>see <tt>descriptorWithDictionary:</tt><br>
									<tt>typeAEList</tt><br>see <tt>userRecordDescriptorWithDictionary:</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSURL</tt></td>
				<td align="center"><tt>typeAlias<br>typeFileURL</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NDAppleScriptObject</tt></td>
				<td align="center"><tt>cScript</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>short int</tt></td>
				<td align="center"><tt>typeShortInteger</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>int</tt></td>
				<td align="center"><tt>typeInteger</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>unsigned int<br></tt></td>
				<td align="center"><tt>typeMagnitude</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>long int</tt></td>
				<td align="center"><tt>typeLongInteger</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>float</tt></td>
				<td align="center"><tt>typeShortFloat</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>double</tt></td>
				<td align="center"><tt>typeLongFloat</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>BOOL</tt></td>
				<td align="center"><tt>typeBoolean<br>typeTrue<br>typeFalse</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>char*</tt></td>
				<td align="center"><tt>typeText</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>id*</tt></td>
				<td align="center"><tt>typeAEList<br>typeAERecord</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>va_list</tt></td>
				<td align="center"><tt>typeAEList<br>typeAERecord</tt></td>
			</tr>
		</table>
	</blockquote></p> 
 */
@interface NSAppleEventDescriptor (NDConversion)

/*!
	@method currentProcessDescriptor
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for the current process.
	@discussion Returns a AppleEvent descriptor for the current process, ProcessSerialNumber { 0, kCurrentProcess }
	@result A <tt>NSAppleEventDescriptor</tt>.
 */
+ (NSAppleEventDescriptor *)currentProcessDescriptor;

/*!
	@method targetProcessSerialNumber
	@abstract Returns the receviers target ProcessSerialNumber.
	@discussion If the recevier is a AppleEvent that contains a target ProcessSerialNumber, then this method will return it otherwise the result undefined.
	@result The target ProcessSerialNumber.
 */
- (ProcessSerialNumber)targetProcessSerialNumber;

/*!
	@method targetCreator
	@abstract Returns the receviers target Creator.
	@discussion If the recevier is a AppleEvent that contains a target Creator, then this method will return it otherwise the result value is garbage.
	@result The target type creator.
 */
- (OSType)targetCreator;

/*!
	@method aliasListDescriptorWithArray:
	@abstract Returns an list descriptor of alias descriptors.
	@discussion Takes a <tt>NSArray</tt> or file url <tt>NSURL</tt>s and/or path <tt>NSString</tt>s and returns a list descriptor of alias descriptors for all of the files.
	@param array A <tt>NSArray</tt> of file url <tt>NSURL</tt>s and/or path <tt>NSString</tt>s.
	@result A <tt>NSAppleEventDescriptor</tt> containing a list descriptor of alias descriptors.
 */
+ (NSAppleEventDescriptor *)aliasListDescriptorWithArray:(NSArray *)array;

/*!
	@method descriptorWithURL:
	@abstract Returns a url descriptor.
	@discussion Returns a new url descriptor from the supplied <tt>NSURL</tt>.
	@param URL A <tt>NSURL</tt> object.
	@result A <tt>NSAppleEventDescriptor</tt> containing a url descriptor.
 */
+ (id)descriptorWithURL:(NSURL *)URL;

/*!
	@method aliasDescriptorWithURL:
	@abstract Returns a alias descriptor.
	@discussion Returns a new alias descriptor from the supplied file url <tt>NSURL</tt>.
	@param URL A file url <tt>NSURL</tt> object.
	@result A <tt>NSAppleEventDescriptor</tt> containing a alias descriptor.
 */
+ (NSAppleEventDescriptor *)aliasDescriptorWithURL:(NSURL *)URL;

/*!
	@method aliasDescriptorWithString:
	@abstract Returns a alias descriptor.
	@discussion Returns a new alias descriptor from the supplied path<tt>NSString</tt>.
	@param path A file path.
	@result A <tt>NSAppleEventDescriptor</tt> containing a alias descriptor.
 */
+ (NSAppleEventDescriptor *)aliasDescriptorWithString:(NSString *)path;

/*!
	@method aliasDescriptorWithFile:
	@abstract Returns a alias descriptor.
	@discussion Returns a new alias descriptor from the supplied object which can be either a path <tt>NSString</tt> or a <tt>NSURL</tt>.
	@param aFile A file object of type <tt>NSString</tt> or <tt>NSURL</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> containing a alias descriptor.
 */
+ (NSAppleEventDescriptor *)aliasDescriptorWithFile:(id)aFile;

/*!
	@method descriptorWithTrueBoolean
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a true boolean descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</TT containing a descriptor of type <tt>typeTrue</tt>
	@result A <tt>NSAppleEventDescriptor</tt> containing a true boolean descriptor.
 */
+ (id)descriptorWithTrueBoolean;

/*!
	@method descriptorWithFalseBoolean
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a false boolean descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</TT containing a descriptor of type <tt>typeFalse</tt>
	@result A <tt>NSAppleEventDescriptor</tt> containing a false boolean descriptor.
 */
+ (id)descriptorWithFalseBoolean;

/*!
	@method descriptorWithShort:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a short integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</TT containing a descriptor of type <tt>typeShortInteger</tt>
	@param value The short int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a short integer descriptor.
 */
+ (id)descriptorWithShort:(short int)value;

/*!
	@method descriptorWithLong:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a long integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</TT containing a descriptor of type <tt>typeLongInteger</tt>
	@param value The long int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a lon integer descriptor.
 */
+ (id)descriptorWithLong:(long int)value;

/*!
	@method descriptorWithInt:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeInteger</tt>
	@param value The int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a int descriptor.
 */
+ (id)descriptorWithInt:(int)value;

/*!
	@method descriptorWithFloat:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a float descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeShortFloat</tt>
	@param value The float.
	@result A <tt>NSAppleEventDescriptor</tt> containing a float descriptor.
 */
+ (id)descriptorWithFloat:(float)value;

/*!
	@method descriptorWithDouble:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a double descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeLongFloat</tt>
	@param value The double.
	@result A <tt>NSAppleEventDescriptor</tt> containing a double descriptor.
 */
+ (id)descriptorWithDouble:(double)value;

/*!
	@method descriptorWithUnsignedInt:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a unsigned integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeMagnitude</tt>
	@param value The unsigned int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a unsigned integer descriptor.
 */
+ (id)descriptorWithUnsignedInt:(unsigned int)value;
/*!
	@method descriptorWithCString:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a string the c string..
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeText</tt> or <tt>typeChar</tt>
	@param aString A c string.
	@result A <tt>NSAppleEventDescriptor</tt> containing plain text.
 */
+ (id)descriptorWithCString:(const char *)aString;
/*!
	@method descriptorWithNumber:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a number descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor for the value contained within number. The value is determined by object-C type returned frome the method <tt>-[NSNumber objCType]</tt> with the following mappings;
	<blockquote><blockquote>
		<table border="1"  width="90%">
				<thead><tr><th>Objective-C Type</th><th>Descriptor Type</th></tr></thead>
				<tr><td align="center"><tt>float</tt></td><td align="center"><tt>typeIEEE32BitFloatingPoint</tt></td></tr>
				<tr><td align="center"><tt>double</tt></td><td align="center"><tt>typeIEEE64BitFloatingPoint</tt></td></tr>
				<tr><td align="center"><tt>long double</tt></td><td align="center"><tt>type128BitFloatingPoint</tt></td></tr>
				<tr><td align="center"><tt>unsigned char</tt></td><td align="center"><tt>typeUInt32</tt></td></tr>
				<tr><td align="center"><tt>char</tt></td><td align="center"><tt>typeSInt16</tt></td></tr>
				<tr><td align="center"><tt>unsigned short int</tt></td><td align="center"><tt>typeUInt32</tt></td></tr>
				<tr><td align="center"><tt>short int</tt></td><td align="center"><tt>typeSInt16</tt></td></tr>
				<tr><td align="center"><tt>unsigned int</tt></td><td align="center"><tt>typeUInt32</tt></td></tr>
				<tr><td align="center"><tt>int</tt></td><td align="center"><tt>typeSInt32</tt></td></tr>
				<tr><td align="center"><tt>unsigned long int</tt></td><td align="center"><tt>typeUInt32</tt></td></tr>
				<tr><td align="center"><tt>long int</tt></td><td align="center"><tt>typeSInt32</tt></td></tr>
				<tr><td align="center"><tt>unsigned long long</tt></td><td align="center"><tt>typeSInt64</tt></td></tr>
				<tr><td align="center"><tt>long long</tt></td><td align="center"><tt>typeSInt64</tt></td></tr>
				<tr><td align="center"><tt>BOOL</tt></td><td align="center"><tt>typeBoolean</tt></td></tr>
		</table>
	</blockquote></blockquote>
	@param number The <tt>NSNumber</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> containing a number.
 */
+ (id)descriptorWithNumber:(NSNumber *)number;

/*!
	@method descriptorWithValue:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a value descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor for the value contained within <tt><i>value</i></tt>. The value is determined by object-C type returned frome the method <tt>-[NSValue objCType]</tt> with the following mappings;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Objective-C Type</th><th>Descriptor Type</th></tr></thead>
			<tr><td align="center"><tt>NSRange</tt></td><td align="center"><tt>typeRangeDescriptor</tt></td></tr>
		</table>
	</blockquote></blockquote>
	@param value The <tt>NSValue</tt>
	@result A <tt>NSAppleEventDescriptor</tt> containing a value.
 */
+ (id)descriptorWithValue:(NSValue *)value;

/*!
	@method descriptorWithObject:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt>.
	@discussion <p><tt>descriptorWithObject:</tt> will return the best descriptor for the given the object using one of the other <tt>-[NSAppleEventDescriptor descriptorWithXXXX:]</tt> methods. <tt>descriptorWithObject:</tt> works recursivly so if <tt><i>object</i></tt> is of type <tt>NSArray</tt> or <tt>NSDictionary</tt> then the objects contained within <tt><i>object</i></tt> will also be converted to descriptors using the this method.</p>
	<p>The following type classes are supported;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr>
				<th>Objective-C Class</th>
				<th>Descriptor Type</th>
			</tr></thead>
			<tr>
				<td align="center"><tt>nil</tt></td>
				<td align="center"><tt>typeNull</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;BOOL&gt;</tt></td>
				<td align="center"><tt>typeBoolean</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;short int&gt;<br>
									NSNumber&lt;char&gt;</tt></td>
				<td align="center"><tt>typeSInt16<br>
									typeShortInteger<br>
									typeSMInt</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;int&gt;<br>
									NSNumber&lt;long int&gt;</tt></td>
				<td align="center"><tt>typeSInt32<br>
									typeLongInteger<br>
									typeInteger</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;float&gt;</tt></td>
				<td align="center"><tt>typeIEEE32BitFloatingPoint<br>
									typeShortFloat<br>
									typeSMFloat</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;double&gt;</tt></td>
				<td align="center"><tt>typeIEEE64BitFloatingPoint<br>
									typeFloat<br>
									typeLongFloat</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;long double&gt;</tt></td>
				<td align="center"><tt>type128BitFloatingPoint</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;unsigned char&gt;<br>
									NSNumber&lt;unsigned short int&gt;<br>
									NSNumber&lt;unsigned int&gt;<br>
									NSNumber&lt;unsigned long int&gt;</tt></td>
				<td align="center"><tt>typeUInt32</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSNumber&lt;unsigned long long&gt;<br>
									NSNumber&lt;long long&gt;</tt></td>
				<td align="center">no 64 bit unsigned<br>
								<tt>typeSInt64</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSValue&lt;NSRange&gt;</tt></td>
				<td align="center"><tt>typeOSAErrorRange</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSString</tt></td>
				<td align="center"><tt>typeText<br>
									kTXNUnicodeTextData<br></td>
			</tr>
			<tr>
				<td align="center"><tt>NSArray</tt></td>
				<td align="center"><tt>typeAEList</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSDictionary</tt></td>
				<td align="center"><tt>typeAERecord</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSURL</tt></td>
				<td align="center"><tt>typeAlias</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>NSAppleEventDescriptor</tt></td>
				<td align="center"><tt>[object typeCodeValue]</tt><br>returns <tt><i>object</i></tt> unmodified</td>
			</tr>
			<tr>
				<td align="center"><tt>NDAppleScriptObject</tt></td>
				<td align="center"><tt>cScript</tt></td>
			</tr>
		</table>
	</blockquote></blockquote></p>
	@param object An object that can be converted into a descriptor.
	@result A <tt>NSAppleEventDescriptor</tt>.
 */
+ (id)descriptorWithObject:(id)object;

/*!
	@method descriptorWithArray:
	@abstract Returns a list descriptor.
	@discussion <tt>descriptorWithArray:</tt> returns a list decriptor containing AppleEvent decriptors returned from the method <tt>descriptorWithObject:</tt> when passed each of <tt><i>array</i></tt>'s objects.
	@param array The array to create a <tt>NSAppleEventDescriptor</tt> from.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor.
 */
+ (id)descriptorWithArray:(NSArray *)array;

/*!
	@method listDescriptorWithObjects:...
	@abstract Returns a list descriptor.
	@discussion <tt>descriptorWithArray:</tt> returns a list decriptor containing AppleEvent decriptors returned from the method <tt>descriptorWithObject:</tt> when passed each of object arguments.
	@param firstObject The argument list terminated with <tt>nil</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor.
 */
+ (id)listDescriptorWithObjects:(id)firstObject, ...;

/*!
	@method listDescriptorWithObjects:arguments:
	@abstract Returns a list descriptor.
	@discussion <tt>descriptorWithArray:</tt> returns a list decriptor containing AppleEvent decriptors returned from the method <tt>descriptorWithObject:</tt> when passed each of object arguments.
	@param firstObject The first object of the argument list.
	@param argList The argument list.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor.
 */
+ (id)listDescriptorWithObjects:(id)object arguments:(va_list)argList;

/*!
	@method recordDescriptorWithObjects:keywords:count:
	@abstract Returns a record descriptor
	@discussion Returns a record descriptor with the supplied object and keys. The objects are converted into <tt>NSAppleEventDescriptor</tt> with the method <tt>descriptorWithObject:</tt>.
	@param objects A pointer to an array of objects.
	@param keywords A pointer to an array of keywords
	@param count The number of objects and keywords.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
 */
+ (NSAppleEventDescriptor *)recordDescriptorWithObjects:(id *)objects keywords:(AEKeyword *)keywords count:(unsigned int)count;

	/*!
	@method recordDescriptorWithDictionary:
	@abstract Returns a record descriptor
	@discussion The dictionary keys must be <tt>NSNumber</tt>, preferable <tt>NSNumber&lt;unsigned long int&gt;</tt>, representing <tt>AEKeyword</tt>. The values are converted to <tt>NSAppleEventDescriptor</tt>'s with the method <tt>descriptorWithObject:</tt>. If you are after a record as typically used in apple scripts then see the method <tt>descriptorWithDictionary:</tt>
	@param dictionary A dictionary where the keys are all <tt>NSNumber&lt;unsigned long int&gt;</tt>
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
 */
+ (NSAppleEventDescriptor *)recordDescriptorWithDictionary:(NSDictionary *)dictionary;

/*!
	@method descriptorWithDictionary:
	@abstract Returns a record descriptor
	@discussion Returns a record descriptor with one key value pair where the keyword is <tt>keyASUserRecordFields</tt> and the value is descriptor of the type typeAEList as returned from the method <tt>userRecordDescriptorWithDictionary:</tt>. This is how record types in AppleScript are represented using AppleEvents
	@param aDictionary A dictionary where the key can be represented as case insensitive strings.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
 */
+ (id)descriptorWithDictionary:(NSDictionary *)aDictionary;

/*!
	@method descriptorWithObjectAndKeys:...
	@abstract Returns a record descriptor
	@discussion Returns a record descriptor with one key value pair where the keyword is <tt>keyASUserRecordFields</tt> and the value is descriptor of the type typeAEList as returned from the method <tt>userRecordDescriptorWithObjectAndKeys:arguments:</tt>. This is how record types in AppleScript are represented using AppleEvents
	@param object The first object is a list of object/key pairs terminated with <tt>nil</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
*/
+ (id)descriptorWithObjectAndKeys:(id)object, ...;


/*!
	@method descriptorWithObjectAndKeys:arguments:
	@abstract Returns a record descriptor
	@discussion Returns a record descriptor with one key value pair where the keyword is <tt>keyASUserRecordFields</tt> and the value is descriptor of the type typeAEList as returned from the method <tt>userRecordDescriptorWithObjectAndKeys:arguments:</tt>. This is how record types in AppleScript are represented using AppleEvents
	@param object The first object is a list of object/key pairs.
	@param argList The argument list.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
 */
+ (id)descriptorWithObjectAndKeys:(id)object arguments:(va_list)argList;


/*!
	@method userRecordDescriptorWithObjectAndKeys:...
	@abstract Returns a user record.
	@discussion Create a list descriptor that can be used as the value for the key <tt>keyASUserRecordFields</tt> in record descriptors of AppleEvents representing AppleScript subroutine calls, this is how records in AppleScripts represented. The resulting descriptor is identical to the descriptor returned from the method <tt>listDescriptorWithObjects:...</tt> if the keys and object are swap around and all of the keys are of type <tt>NSString</tt>. <tt>userRecordDescriptorWithObjectAndKeys:...</tt> has the advantage over <tt>listDescriptorWithObjects:...</tt> in that the keys are converted to <tt>NSString</tt> using the method <tt>-[NSObject description]</tt>.
	@param object A list of object and keys terminated with a <tt>nil</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor representing a user record.
 */
+ (id)userRecordDescriptorWithObjectAndKeys:(id)object, ...;

/*!
	@method userRecordDescriptorWithObjectAndKeys:arguments:
	@abstract Returns a user record.
	@discussion Create a list descriptor that can be used as the value for the key <tt>keyASUserRecordFields</tt> in record descriptors of AppleEvents representing AppleScript subroutine calls, this is how records in AppleScripts represented. The objects are converted to <tt>NSAppleEventDescriptor</tt> using the method <tt>descriptorWithObject:</tt>.
	@param object The first object in a list of objects and keys.
	@param argList The arguments list.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor representing a user record.
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithObjectAndKeys:(id)object arguments:(va_list)argList;

/*!
	@method userRecordDescriptorWithObjects:keys:count:
	@abstract Returns a user record.
	@discussion Create a list descriptor that can be used as the value for the key <tt>keyASUserRecordFields</tt> in record descriptors of AppleEvents representing AppleScript subroutine calls, this is how records in AppleScripts represented. The objects are converted to <tt>NSAppleEventDescriptor</tt> using the method <tt>descriptorWithObject:</tt>.
	@param objects A pointer to an array of objects.
	@param keys A pointer to an array of <tt>NSString</tt>s representing keys.
	@param count The number of objects and keys.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor representing a user record.
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithObjects:(id *)objects keys:(NSString **)keys count:(unsigned int)count;

	/*!
	@method userRecordDescriptorWithDictionary:
	@abstract Returns a user record descriptor.
	 @discussion Create a list descriptor that can be used as the value for the key <tt>keyASUserRecordFields</tt> in record descriptors of AppleEvents representing AppleScript subroutine calls, this is how records in AppleScripts represented. The objects are converted to <tt>NSAppleEventDescriptor</tt> using the method <tt>descriptorWithObject:</tt>.
	@param dictionary A dictionay where the keys are all <tt>NSString</tt>s
	 @result A <tt>NSAppleEventDescriptor</tt> for a list descriptor representing a user record.
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithDictionary:(NSDictionary *)dictionary;

/*!
	@method arrayValue
	@abstract Returns an <tt>NSArray</tt> for a list descriptor.
	@discussion Returns a <tt>NSArray</tt> if the receviers contains list descriptor with each element convert to an appropriate object as determined by the method <tt>-[NSAppleEventDescriptor objectValue]</tt>. If the recevier does not contain a list descriptor then an <tt>NSArray</tt> filled with garbage is returned.
	@result A <tt>NSArray</tt>.
 */
- (NSArray *)arrayValue;

/*!
	@method dictionaryValueFromRecordDescriptor
	@abstract Returns an <tt>NSDictionary</tt> for a record descriptor.
	@discussion Returns a <tt>NSDictionary</tt> if the receviers is a record descriptor with each element convert to an appropriate object as determined by the method <tt>-[NSAppleEventDescriptor objectValue]</tt> and the key converted to a <tt>NSNumbers</tt>. If the recevier does not contain a record descriptor then the resut is undefined.
	@result A <tt>NSDictionary</tt>.
 */
- (NSDictionary *)dictionaryValueFromRecordDescriptor;

/*!
	@method dictionaryValue
	@abstract Returns an <tt>NSDictionary</tt> for a record descriptor.
	@discussion Returns a <tt>NSDictionary</tt> if the receviers is a record descriptor with a list value for the key <tt>keyASUserRecordFields</tt>, this is how records from AppleScripts are represented. Each even numbered element of the list is converted in to an appropriate object as determined by the method <tt>-[NSAppleEventDescriptor objectValue]</tt> and each odd numbered element is used as the key and converted to a <tt>NSString</tt>. If the recevier is not a record descriptor that contains a list value for the key <tt>keyASUserRecordFields</tt> then the resut is undefined.
	@result A <tt>NSDictionary</tt> with keys all of type <tt>NSString</tt>
 */
- (NSDictionary *)dictionaryValue;

/*!
	@method urlValue
	@abstract Returns a <tt>NSURL</tt> for the recevier..
	@discussion Returns a file url <tt>NSURL</tt> for an alias descriptor. If the recevier does not contain an alias descriptor the <tt>nil</tt> is returned. Currently url descriptors are not handled.
	@result A <tt>NSURL</tt>.
 */
- (NSURL *)urlValue;

/*!
	@method unsignedIntValue
	@abstract Returns a unsigned int value for the recevier.
	@discussion Returns a unsigned int value if the recevier contains a unsigned integer descriptor, otherwise it returns <tt>0</tt>.
	@result An unsigned int value.
*/
- (unsigned int)unsignedIntValue;

/*!
	@method floatValue
	@abstract Returns a float value for the recevier.
	@discussion Returns a float value if the recevier contains a float descriptor, otherwise it returns <tt>0</tt>.
	@result An float value.
*/
- (float)floatValue;

/*!
	@method doubleValue
	@abstract Returns a double value for the recevier.
	@discussion Returns a double value if the recevier contains a double descriptor, otherwise it returns <tt>0</tt>.
	@result An double value.
*/
- (double)doubleValue;

/*!
	@method value
	@abstract Returns a <tt>NSValue</tt> object for the recevier.
	@discussion Returns a <tt>NSValue</tt> object for the recevier if it contains a any value or number type descriptor, otherwise it returns <tt>nil</tt>. For most values <tt>value</tt> is identical to <tt>numberValue</tt>.
	@result An <tt>NSValue</tt> object.
*/
- (NSValue *)value;

/*!
	@method numberValue
	@abstract Returns a <tt>NSNumber</tt> object for the recevier.
	@discussion Returns a <tt>NSNumber</tt> object for the recevier if it contains a any number type descriptor, otherwise it returns <tt>nil</tt>.
	@result An <tt>NSNumber</tt> object.
*/
- (NSNumber *)numberValue;

/*!
	@method objectValue
	@abstract Returns a object for the recevier.
	@discussion <p>Returns a subclass of <tt>NSObject</tt> by determining the type of the receviers descriptor and converting it into the appropriate instance of a Objective-C class.</p>
	<p>Descriptor types are mapped to classes in the following ways.
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Descriptor Type</th><th>Objective-C Class</th></tr></thead>
			<tr>
				<td align="center"><tt>typeNull</tt></td>
				<td align="center"><tt>NSNull</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>typeBoolean<br>
									typeShortInteger<br>
									typeSMInt<br>
									typeLongInteger<br>
									typeInteger<br>
									typeIEEE32BitFloatingPoint<br>
									typeShortFloat<br>
									typeSMFloat<br>
									typeIEEE64BitFloatingPoint<br>
									typeFloat<br>
									typeLongFloat<br>
									typeExtended<br>
									typeComp<br>
									typeMagnitude<br>
									typeTrue<br>
									typeFalse</tt></td>
				<td align="center"><tt>NSNumber</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>typeChar</tt></td>
				<td align="center"><tt>NSString</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>typeAEList</tt></td>
				<td align="center"><tt>NSArray</tt></td></tr>
			<tr>
				<td align="center"><tt>typeAERecord</tt></td>
				<td align="center"><tt>NSDictionary</tt></td>
			</tr>
			<tr>
				<td align="center"><tt><tt>typeAlias<br>
										typeFileURL</tt></td>
				<td align="center"><tt>NSULR</tt></td>
			</tr>
			<tr>
				<td align="center"><tt>cScript</tt></td>
				<td align="center"><tt>NDAppleScriptObject</tt> <i>if available.</i><br><tt>NSAppleEventDescriptor</tt> <i>otherwise.</i></td>
			</tr>
			<tr>
				<td align="center"><tt>cEventIdentifier</tt></td>
				<td align="center"><tt>NSNumber</tt></td>
			</tr>
			<tr>
				<td align="center">All Other Types</td>
				<td align="center"><tt>NSAppleEventDescriptor</tt></td>
			</tr>
		</table>
	</blockquote></blockquote></p>
	@result A subclass of <tt>NSObject</tt>
 */
- (id)objectValue;

@end

/*!
	@category NSAppleEventDescriptor(NDCompleteEvents)
	@abstract Category of <tt>NSAppleEventDescriptor</tt>.
	@discussion Adds methods for creating complete AppleEvents.
 */
@interface NSAppleEventDescriptor (NDCompleteEvents)


	/*!
	@method openEventDescriptorWithTargetDescriptor:
	@abstract Get a <tt>NSAppleEventDescriptor</tt> for an open event.
	@discussion Creates a <tt>NSAppleEventDescriptor</tt> for an open application event, <tt>kAEOpenApplication</tt>.
	@param targetDescriptor an <tt>NSAppleEventDescriptor</tt> that identifies the target application for the Apple event.
	@result A <tt>NSAppleEventDescriptor</tt> containing an open application event descriptor.
 */
+ (NSAppleEventDescriptor *)openEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)targetDescriptor;
/*!
	@method openEventDescriptorWithTargetDescriptor:array:
	@abstract Get a <tt>NSAppleEventDescriptor</tt> for an open event.
	@discussion Creates a <tt>NSAppleEventDescriptor</tt> for an open document event, <tt>kAEOpenDocuments</tt>. The objects within <tt>array</tt> have to be <tt>NSString</tt> paths or file <tt>NSULR</tt>s, which are converted into <tt>typeAlias</tt>.
	@param targetDescriptor an <tt>NSAppleEventDescriptor</tt> that identifies the target application for the Apple event.
	@param array A <tt>NSArray</tt> of file url <tt>NSURL</tt>s and/or path <tt>NSString</tt>s.
	@result A <tt>NSAppleEventDescriptor</tt> containing an open application event or an open documents event descriptor.
 */
+ (NSAppleEventDescriptor *)openEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)targetDescriptor array:(NSArray *)array;
/*!
	@method quitEventDescriptorWithTargetDescriptor:
	@abstract Get a <tt>NSAppleEventDescriptor</tt> for a quit event.
	@discussion Creates a <tt>NSAppleEventDescriptor</tt> for an quit event, <tt>kAEQuitApplication</tt>.
	@param targetDescriptor an <tt>NSAppleEventDescriptor</tt> that identifies the target application for the Apple event.
	@result A <tt>NSAppleEventDescriptor</tt> containing a quit event descriptor.
 */
+ (NSAppleEventDescriptor *)quitEventDescriptorWithTargetDescriptor:(NSAppleEventDescriptor *)targetDescriptor;
/*!
	@method descriptorWithSubroutineName:argumentsListDescriptor:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling AppleScript routines.
	@discussion AppleScript routines can be called by name, <tt>descriptorWithSubroutineName:argumentsDescriptor:</tt> returns a <tt>NSAppleEventDescriptor</tt> to do so. The <tt><i>routineName</i></tt> is the name of the routine to be called, AppleScript routines are case insensitive, <tt><i>routineName</i></tt> is converted to all lower case.
	@param routineName The rountine name to be called. 
	@param param The parameters descriptors.
	@result A <tt>NSAppleEventDescriptor</tt>
 */
+ (id)descriptorWithSubroutineName:(NSString *)routineName argumentsListDescriptor:(NSAppleEventDescriptor *)param;

/*!
	@method descriptorWithSubroutineName:argumentsArray:
	 @abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript subroutine with positional arguments.
	@discussion <tt>descriptorWithSubroutineName:argumentsDescriptor:</tt> returns a <tt>NSAppleEventDescriptor</tt> to call a AppleScript subroutine with positional arguments. AppleScript routines are case insensitive so <tt><i>routineName</i></tt> is converted to all lower case.
	@param routineName The rountine name to be called.
	@param paramArray A <tt>NSArray</tt> of Objective-C class that are converted into <tt>NSAppleEventDescriptor</tt> using the function <tt>descriptorWithObject:</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with positional arguments.
 */
+ (id)descriptorWithSubroutineName:(NSString *)routineName argumentsArray:(NSArray *)paramArray;
/*!
	@method descriptorWithSubroutineName:arguments:...
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript subroutine with positional arguments.
	@discussion <tt>descriptorWithSubroutineName:arguments:</tt> returns a <tt>NSAppleEventDescriptor</tt> to call a AppleScript subroutine with positional arguments. AppleScript routines are case insensitive so <tt><i>routineName</i></tt> is converted to all lower case.
	@param routineName The rountine name to be called.
	@param firstArg The first object of a nil terminated list of objects that are converted into <tt>NSAppleEventDescriptor</tt> using the function <tt>descriptorWithObject:</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with positional arguments.
 */
+ (id)descriptorWithSubroutineName:(NSString *)routineName arguments:(id)firstArg, ...;

/*!
	@method descriptorWithSubroutineName:labels:argumentObjects:count:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript routine with labeled arguments.
	@discussion <p><tt>descriptorWithSubroutineName:argumentsDescriptor:</tt> returns a <tt>NSAppleEventDescriptor</tt> to call a AppleScript subroutine with labeled arguments. AppleScript routines are case insensitive so <tt><i>routineName</i></tt> is converted to all lower case. <tt><i>paramArray</i></tt> is an array of objective-C types that are converted into <tt>NSAppleEventDescriptor</tt> using the function <tt>descriptorWithObject:</tt>.</p>
	<p>The possible keywords are;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Key Word</th><th>AppleScript key word</th></tr></thead>
			<tr><td align="center"><tt>keyASPrepositionAbout</tt></td><td align="center"><tt>about</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAbove</tt></td><td align="center"><tt>above</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAgainst</tt></td><td align="center"><tt>against</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionApartFrom</tt></td><td align="center"><tt>apart from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAround</tt></td><td align="center"><tt>around</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAsideFrom</tt></td><td align="center"><tt>aside from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAt</tt></td><td align="center"><tt>at</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBelow</tt></td><td align="center"><tt>below</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeneath</tt></td><td align="center"><tt>beneath</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeside</tt></td><td align="center"><tt>beside</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBetween</tt></td><td align="center"><tt>between</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBy</tt></td><td align="center"><tt>by</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFor</tt></td><td align="center"><tt>for</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFrom</tt></td><td align="center"><tt>from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionGiven</tt></td><td align="center"><tt>given</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionIn</tt></td><td align="center"><tt>in</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInsteadOf</tt></td><td align="center"><tt>instead of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInto</tt></td><td align="center"><tt>into</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOn</tt></td><td align="center"><tt>on</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOnto</tt></td><td align="center"><tt>onto</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOutOf</tt></td><td align="center"><tt>out of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOver</tt></td><td align="center"><tt>over</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionSince</tt></td><td align="center"><tt>since</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThrough</tt></td><td align="center"><tt>through</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThru</tt></td><td align="center"><tt>thru</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionTo</tt></td><td align="center"><tt>to</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUnder</tt></td><td align="center"><tt>under</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUntil</tt></td><td align="center"><tt>until</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWith</tt></td><td align="center"><tt>with</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWithout</tt></td><td align="center"><tt>without</tt></td></tr>
			<tr><td align="center"><tt>keyASUserRecordFields</tt></td><td align="center">key for a list descriptor of user record fields</td></tr>
		</table>
	</blockquote></blockquote></p>
	<p>To find out the rules for use of the key words see the AppleScript language documentation.</p>
	@param routineName The rountine name to be called.
	@param labels A c array of keywords
	@param objects A c array of Objective-C class that are converted into <tt>NSAppleEventDescriptor</tt> using the function <tt>descriptorWithObject:</tt>.
	@param count The number of labels and objects
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with labled arguments.
 */
+ (id)descriptorWithSubroutineName:(NSString *)routineName labels:(AEKeyword*)labels argumentObjects:(id *)objects count:(unsigned int)count;

/*!
	@method descriptorWithSubroutineName:labels:argumentDescriptors:count:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript routine with labeled arguments.
	@discussion <p><tt>descriptorWithSubroutineName:labels:argumentDescriptors:count:</tt> returns a <tt>NSAppleEventDescriptor</tt> to call a AppleScript subroutine with labeled arguments. AppleScript routines are case insensitive so <tt><i>routineName</i></tt> is converted to all lower case. If <tt>keyASUserRecordFields</tt> is used as a keyword then the <tt>NSAppleEventDescriptor</tt> should be a list descriptor alternating between keys and parameter begining with a key, as returned from one of the  <tt>userRecordDescriptorWith...</tt> methods.</p>
	<p>The possible keywords are;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Key Word</th><th>AppleScript key word</th></tr></thead>
			<tr><td align="center"><tt>keyASPrepositionAbout</tt></td><td align="center"><tt>about</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAbove</tt></td><td align="center"><tt>above</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAgainst</tt></td><td align="center"><tt>against</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionApartFrom</tt></td><td align="center"><tt>apart from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAround</tt></td><td align="center"><tt>around</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAsideFrom</tt></td><td align="center"><tt>aside from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAt</tt></td><td align="center"><tt>at</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBelow</tt></td><td align="center"><tt>below</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeneath</tt></td><td align="center"><tt>beneath</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeside</tt></td><td align="center"><tt>beside</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBetween</tt></td><td align="center"><tt>between</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBy</tt></td><td align="center"><tt>by</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFor</tt></td><td align="center"><tt>for</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFrom</tt></td><td align="center"><tt>from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionGiven</tt></td><td align="center"><tt>given</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionIn</tt></td><td align="center"><tt>in</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInsteadOf</tt></td><td align="center"><tt>instead of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInto</tt></td><td align="center"><tt>into</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOn</tt></td><td align="center"><tt>on</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOnto</tt></td><td align="center"><tt>onto</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOutOf</tt></td><td align="center"><tt>out of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOver</tt></td><td align="center"><tt>over</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionSince</tt></td><td align="center"><tt>since</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThrough</tt></td><td align="center"><tt>through</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThru</tt></td><td align="center"><tt>thru</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionTo</tt></td><td align="center"><tt>to</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUnder</tt></td><td align="center"><tt>under</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUntil</tt></td><td align="center"><tt>until</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWith</tt></td><td align="center"><tt>with</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWithout</tt></td><td align="center"><tt>without</tt></td></tr>
			<tr><td align="center"><tt>keyASUserRecordFields</tt></td><td align="center">key for a list descriptor of user record fields</td></tr>
		</table>
	</blockquote></blockquote></p>
	To find out the rules for use of the key words see the AppleScript language documentation.
	@param routineName The rountine name to be called.
	@param labels A c array of keyword labels.
	@param params A c array of <tt>NSAppleEventDescriptor</tt> for the parameters.
	@param count The number of keywords and parameters.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with labled arguments.
 */
+ (id)descriptorWithSubroutineName:(NSString *)routineName labels:(AEKeyword*)labels argumentDescriptors:(NSAppleEventDescriptor **)params count:(unsigned int)count;

/*!
	@method descriptorWithSubroutineName:labelsAndArguments:...
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript routine with labeled arguments.
	@discussion <p><tt>descriptorWithSubroutineName:labelsAndArguments:...</tt> returns a <tt>NSAppleEventDescriptor</tt> to call a AppleScript subroutine with labeled arguments. AppleScript routines are case insensitive so <tt><i>routineName</i></tt> is converted to all lower case. If <tt>keyASPrepositionGiven</tt> is used as a keyword then the arguments following it are passed to the method <tt>userRecordDescriptorWithObjectAndKeys:</tt>. and resulting descriptor is given the key <tt>keyASUserRecordFields</tt></p>
	<p>For example to get a subroutine descriptor to call the AppleScript subroutine
	<blockquote>
		<pre><font color="#660000">foo</font> <font color="#000066">for</font> <font color="#660000"><i>arg1</i></font> <font color="#000066"><b>given</b></font> <font color="#005500">argument</font>:<font color="#660000"><i>arg2</i></font> </pre>
	</blockquote>
	you would do the following
	<blockquote>
		<pre>theSubroutine = [NSAppleEventDescriptor descriptorWithSubroutineName:&#64;"<font color="#660000">foo</font>"
		&#9;&#9;labelsAndArguments:<font color="#000066">keyASPrepositionFor</font>, <font color="#660000"><i>arg1</i></font>,
		&#9;&#9;<font color="#000066"><b>keyASPrepositionGiven</b></font>, <font color="#660000"><i>arg2</i></font>, &#64;"<font color="#005500">argument</font>", nil];</pre>
	</blockquote>
	which is equivalent to
	<blockquote>
		<pre>theSubroutine = [NSAppleEventDescriptor descriptorWithSubroutineName:&#64;"<font color="#660000">foo</font>"
		&#9;&#9;labelsAndArguments:<font color="#000066">keyASPrepositionFor</font>, <font color="#660000"><i>arg1</i></font>, <font color="#000066"><b>keyASUserRecordFields</b></font>,
		&#9;&#9;[NSAppleEventDescriptor userRecordDescriptorWithObjectAndKeys:<font color="#660000"><i>arg2</i></font>, &#64;"<font color="#005500">argument</font>", nil],
		&#9;&#9;(AEKeyword)0];</pre>
	</blockquote></p>
	<p>The possible keywords are;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Key Word</th><th>AppleScript key word</th></tr></thead>
			<tr><td align="center"><tt>keyASPrepositionAbout</tt></td><td align="center"><tt>about</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAbove</tt></td><td align="center"><tt>above</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAgainst</tt></td><td align="center"><tt>against</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionApartFrom</tt></td><td align="center"><tt>apart from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAround</tt></td><td align="center"><tt>around</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAsideFrom</tt></td><td align="center"><tt>aside from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAt</tt></td><td align="center"><tt>at</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBelow</tt></td><td align="center"><tt>below</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeneath</tt></td><td align="center"><tt>beneath</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeside</tt></td><td align="center"><tt>beside</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBetween</tt></td><td align="center"><tt>between</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBy</tt></td><td align="center"><tt>by</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFor</tt></td><td align="center"><tt>for</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFrom</tt></td><td align="center"><tt>from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionGiven</tt></td><td align="center"><tt>given</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionIn</tt></td><td align="center"><tt>in</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInsteadOf</tt></td><td align="center"><tt>instead of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInto</tt></td><td align="center"><tt>into</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOn</tt></td><td align="center"><tt>on</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOnto</tt></td><td align="center"><tt>onto</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOutOf</tt></td><td align="center"><tt>out of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOver</tt></td><td align="center"><tt>over</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionSince</tt></td><td align="center"><tt>since</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThrough</tt></td><td align="center"><tt>through</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThru</tt></td><td align="center"><tt>thru</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionTo</tt></td><td align="center"><tt>to</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUnder</tt></td><td align="center"><tt>under</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUntil</tt></td><td align="center"><tt>until</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWith</tt></td><td align="center"><tt>with</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWithout</tt></td><td align="center"><tt>without</tt></td></tr>
			<tr><td align="center"><tt>keyASUserRecordFields</tt></td><td align="center">key for a list descriptor of user record fields</td></tr>
		</table>
	</blockquote></blockquote></p>
	<p>To find out the rules for use of the key words see the AppleScript language documentation.</p>
	@param routineName The subroutine name.
	@param keyWord The first label of a list of labels and objects terminated with a <tt>0</tt> keyword or a <tt>nil</tt> if the end arguments follow the keyword <tt>keyASPrepositionGiven</tt>
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with labled arguments.
 */
+ (id)descriptorWithSubroutineName:(NSString *)routineName labelsAndArguments:(AEKeyword)keyWord, ...;

/*!
	@method initWithSubroutineName:argumentsDescriptor:
	@abstract Initialises a <tt>NSAppleEventDescriptor</tt> for calling AppleScript routines.
	@discussion AppleScript routines can be called by name, <tt>initWithSubroutineName:argumentsDescriptor:</tt> returns a <tt>NSAppleEventDescriptor</tt> to do so. The <tt><i>routineName</i></tt> is the name of the routine to be called, AppleScript routines are case insensitive, <tt><i>routineName</i></tt> is converted to all lower case.
	@param routineName The rountine name to be called.
	@param param The parameters descriptors.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with positional arguments.
 */
- (id)initWithSubroutineName:(NSString *)routineName argumentsListDescriptor:(NSAppleEventDescriptor *)param;

/*!
	@method initWithSubroutineName:argumentsArray:
	@abstract Initialises a <tt>NSAppleEventDescriptor</tt> for calling AppleScript routines.
	@discussion AppleScript routines can be called by name, <tt>initWithSubroutineName:argumentsDescriptor:</tt> returns a <tt>NSAppleEventDescriptor</tt> to do so. The <tt><i>routineName</i></tt> is the name of the routine to be called, AppleScript routines are case insensitive, <tt><i>routineName</i></tt> is converted to all lower case. <tt><i>paramArray</i></tt> is an array of objective-C types that can be converted into AppleScript types.
	@param routineName The rountine name to be called.
	@param paramArray The parameters.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with positional arguments.
 */
- (id)initWithSubroutineName:(NSString *)routineName argumentsArray:(NSArray *)paramArray;

/*!
	@method initWithSubroutineName:labels:argumentDescriptors:count:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript routine with labeled arguments.
	@discussion <p><tt>initWithSubroutineName:labels:argumentDescriptors:count:</tt> inirializes a <tt>NSAppleEventDescriptor</tt> with a AppleScript subroutine descriptors with labeled arguments. The keyword label <tt>keyASUserRecordFields</tt> must be for a list descriptor similar to that returned from the one of the  <tt>userRecordDescriptorWithXXX:</tt> methods.</p>
	<p>The possible keywords are;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Key Word</th><th>AppleScript key word</th></tr></thead>
			<tr><td align="center"><tt>keyASPrepositionAbout</tt></td><td align="center"><tt>about</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAbove</tt></td><td align="center"><tt>above</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAgainst</tt></td><td align="center"><tt>against</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionApartFrom</tt></td><td align="center"><tt>apart from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAround</tt></td><td align="center"><tt>around</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAsideFrom</tt></td><td align="center"><tt>aside from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAt</tt></td><td align="center"><tt>at</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBelow</tt></td><td align="center"><tt>below</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeneath</tt></td><td align="center"><tt>beneath</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeside</tt></td><td align="center"><tt>beside</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBetween</tt></td><td align="center"><tt>between</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBy</tt></td><td align="center"><tt>by</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFor</tt></td><td align="center"><tt>for</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFrom</tt></td><td align="center"><tt>from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionGiven</tt></td><td align="center"><tt>given</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionIn</tt></td><td align="center"><tt>in</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInsteadOf</tt></td><td align="center"><tt>instead of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInto</tt></td><td align="center"><tt>into</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOn</tt></td><td align="center"><tt>on</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOnto</tt></td><td align="center"><tt>onto</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOutOf</tt></td><td align="center"><tt>out of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOver</tt></td><td align="center"><tt>over</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionSince</tt></td><td align="center"><tt>since</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThrough</tt></td><td align="center"><tt>through</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThru</tt></td><td align="center"><tt>thru</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionTo</tt></td><td align="center"><tt>to</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUnder</tt></td><td align="center"><tt>under</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUntil</tt></td><td align="center"><tt>until</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWith</tt></td><td align="center"><tt>with</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWithout</tt></td><td align="center"><tt>without</tt></td></tr>
			<tr><td align="center"><tt>keyASUserRecordFields</tt></td><td align="center">key for a list descriptor of user record fields</td></tr>
		</table>
	</blockquote></blockquote></p>
	<p>To find out the rules for use of the key words see the AppleScript language documentation.</p>
	@param routineName The rountine name to be called.
	@param labels A c array of AEKeywords.
	@param param A c array of <tt>NSAppleEventDescriptors</tt>
	@param count The number of keywords and <tt>NSAppleEventDescriptors</tt>
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with labeled arguments.
 */
- (id)initWithSubroutineName:(NSString *)routineName labels:(AEKeyword*)labels argumentDescriptors:(NSAppleEventDescriptor **)aParam count:(unsigned int)count;
/*!
	@method initWithSubroutineName:labels:arguments:count:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript routine with labeled arguments.
	@discussion <p><tt>initWithSubroutineName:labels:arguments:count:</tt> initializes a <tt>NSAppleEventDescriptor</tt> with a AppleScript subroutine descriptor with labeled arguments. If the the keyword <tt>keyASPrepositionGiven</tt> is used it should be the last label and have a argument of kind <tt>NSDictionary</tt> or <tt>NSAppleEventDescriptor</tt> as return from one of the <tt>userRecordDescriptorWithXXXX:</tt>.</p>
	<p>The possible keywords are;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Key Word</th><th>AppleScript key word</th></tr></thead>
			<tr><td align="center"><tt>keyASPrepositionAbout</tt></td><td align="center"><tt>about</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAbove</tt></td><td align="center"><tt>above</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAgainst</tt></td><td align="center"><tt>against</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionApartFrom</tt></td><td align="center"><tt>apart from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAround</tt></td><td align="center"><tt>around</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAsideFrom</tt></td><td align="center"><tt>aside from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAt</tt></td><td align="center"><tt>at</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBelow</tt></td><td align="center"><tt>below</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeneath</tt></td><td align="center"><tt>beneath</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeside</tt></td><td align="center"><tt>beside</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBetween</tt></td><td align="center"><tt>between</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBy</tt></td><td align="center"><tt>by</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFor</tt></td><td align="center"><tt>for</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFrom</tt></td><td align="center"><tt>from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionGiven</tt></td><td align="center"><tt>given</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionIn</tt></td><td align="center"><tt>in</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInsteadOf</tt></td><td align="center"><tt>instead of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInto</tt></td><td align="center"><tt>into</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOn</tt></td><td align="center"><tt>on</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOnto</tt></td><td align="center"><tt>onto</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOutOf</tt></td><td align="center"><tt>out of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOver</tt></td><td align="center"><tt>over</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionSince</tt></td><td align="center"><tt>since</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThrough</tt></td><td align="center"><tt>through</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThru</tt></td><td align="center"><tt>thru</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionTo</tt></td><td align="center"><tt>to</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUnder</tt></td><td align="center"><tt>under</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUntil</tt></td><td align="center"><tt>until</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWith</tt></td><td align="center"><tt>with</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWithout</tt></td><td align="center"><tt>without</tt></td></tr>
			<tr><td align="center"><tt>keyASUserRecordFields</tt></td><td align="center">key for a list descriptor of user record fields</td></tr>
		</table>
	</blockquote></blockquote></p>
	<p>To find out the rules for use of the key words see the AppleScript language documentation.</p>
	@param routineName The rountine name to be called.
	@param labels A c array of keywords
	@param objects A c array of objects that can be converted to <tt>NSAppleEventDescriptor</tt> with the method <tt>descriptorWithObject:</tt>
	@param count The number of keywords and objects.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with labeled arguments.
 */
- (id)initWithSubroutineName:(NSString *)routineName labels:(AEKeyword*)labels arguments:(id *)objects count:(unsigned int)count;

/*!
	@method initWithSubroutineName:labelsAndArguments:arguments:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript routine with labeled arguments.
	@discussion <p><tt>initWithSubroutineName:labelsAndArguments:arguments:</tt> initializes a <tt>NSAppleEventDescriptor</tt> with an AppleScript subroutine with labeled arguments, if the keyword <tt>keyASPrepositionGiven</tt> is found the remaining arguments will be passed to the method <tt>userRecordDescriptorWithObjectAndKeys:arguments:</tt> and the result is given the keyword <tt>keyASUserRecordFields</tt>.</p>
	<p>The possible keywords are;
	<blockquote><blockquote>
		<table border="1"  width="90%">
			<thead><tr><th>Key Word</th><th>AppleScript key word</th></tr></thead>
			<tr><td align="center"><tt>keyASPrepositionAbout</tt></td><td align="center"><tt>about</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAbove</tt></td><td align="center"><tt>above</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAgainst</tt></td><td align="center"><tt>against</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionApartFrom</tt></td><td align="center"><tt>apart from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAround</tt></td><td align="center"><tt>around</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAsideFrom</tt></td><td align="center"><tt>aside from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionAt</tt></td><td align="center"><tt>at</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBelow</tt></td><td align="center"><tt>below</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeneath</tt></td><td align="center"><tt>beneath</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBeside</tt></td><td align="center"><tt>beside</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBetween</tt></td><td align="center"><tt>between</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionBy</tt></td><td align="center"><tt>by</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFor</tt></td><td align="center"><tt>for</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionFrom</tt></td><td align="center"><tt>from</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionGiven</tt></td><td align="center"><tt>given</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionIn</tt></td><td align="center"><tt>in</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInsteadOf</tt></td><td align="center"><tt>instead of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionInto</tt></td><td align="center"><tt>into</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOn</tt></td><td align="center"><tt>on</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOnto</tt></td><td align="center"><tt>onto</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOutOf</tt></td><td align="center"><tt>out of</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionOver</tt></td><td align="center"><tt>over</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionSince</tt></td><td align="center"><tt>since</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThrough</tt></td><td align="center"><tt>through</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionThru</tt></td><td align="center"><tt>thru</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionTo</tt></td><td align="center"><tt>to</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUnder</tt></td><td align="center"><tt>under</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionUntil</tt></td><td align="center"><tt>until</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWith</tt></td><td align="center"><tt>with</tt></td></tr>
			<tr><td align="center"><tt>keyASPrepositionWithout</tt></td><td align="center"><tt>without</tt></td></tr>
			<tr><td align="center"><tt>keyASUserRecordFields</tt></td><td align="center">key for a list descriptor of user record fields</td></tr>
		</table>
	</blockquote></blockquote></p>
	<p>To find out the rules for use of the key words see the AppleScript language documentation.</p>
	<p>See <tt>descriptorWithSubroutineName:labelsAndArguments:...</tt> for more details</p>
	@param routineName The rountine name to be called.
	@param label The first keyword of a list of labels and objects.
	@param argList The argument list struct.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with labeled arguments.
 */
- (id)initWithSubroutineName:(NSString *)routineName labelsAndArguments:(AEKeyword)label arguments:(va_list)argList;
@end
