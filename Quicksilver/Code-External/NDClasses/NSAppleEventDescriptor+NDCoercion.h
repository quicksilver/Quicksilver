/*
	NSAppleEventDescriptor+NDCoercion.h

	Created by Nathan Day on 27.04.04 under a MIT-style license. 
	Copyright (c) 2008 Nathan Day

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
 */

/*!
	@header NSAppleEventDescriptor+NDCoercion
	@abstract Declares the category <tt>NSAppleEventDescriptor (NDCoercion)</tt>
	@discussion Additional methods initially created for use with <tt>NDScriptData</tt> but could have other applications especially with Cocoa's <tt>NSAppleScript</tt>.
	@version 2.0.0
 */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

extern NSString		* NDAppleEventDescriptorCoercionError,
							* NDAppleEventDescriptorCoercionObject;

@class		NDScriptData;

/*!
	@category NSAppleEventDescriptor(NDCoercion)
	@abstract Category of <tt>NSAppleEventDescriptor</tt>.
	@discussion Add some methods for use with AppleScripts and AppleEvents.
 */
@interface NSAppleEventDescriptor (NDCoercion)

/*!
	@method descriptorWithAEDescNoCopy:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for the <tt>AEDesc</tt>.
	@discussion Allocates, initializes and returns an <tt>NSAppleEventDescriptor</tt> that takes ownership of the Carbon <tt>AEDesc</tt> structure pointed to by <tt>aeDesc</tt>. Returns <tt>nil</tt> if an error occurs. The initialized object takes responsibility for calling the <tt>AEDisposeDesc</tt> function on the <tt>AEDesc</tt> at object deallocation time.
	@param aeDesc A Carbon <tt>AEDesc</tt> structure.
	@result A <tt>NSAppleEventDescriptor</tt>
 */
+ (NSAppleEventDescriptor *)descriptorWithAEDescNoCopy:(const AEDesc *)aeDesc;

/*!
	@method descriptorWithAEDesc:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for the <tt>AEDesc</tt>.
	@discussion Allocates, initializes and returns an <tt>NSAppleEventDescriptor</tt> that copies the Carbon <tt>AEDesc</tt> structure pointed to by <tt>aeDesc</tt>. Returns <tt>nil</tt> if an error occurs.
	@param aeDesc A Carbon <tt>AEDesc</tt> structure
	@result A <tt>NSAppleEventDescriptor</tt>
 */
+ (NSAppleEventDescriptor *)descriptorWithAEDesc:(const AEDesc *)aeDesc;

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
				<td align="center"><tt>NDScriptData</tt></td>
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
+ (NSAppleEventDescriptor *)descriptorWithURL:(NSURL *)URL;

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
+ (NSAppleEventDescriptor *)descriptorWithTrueBoolean;

/*!
	@method descriptorWithFalseBoolean
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a false boolean descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</TT containing a descriptor of type <tt>typeFalse</tt>
	@result A <tt>NSAppleEventDescriptor</tt> containing a false boolean descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithFalseBoolean;

/*!
	@method descriptorWithShort:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a short integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</TT containing a descriptor of type <tt>typeShortInteger</tt>
	@param value The short int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a short integer descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithShort:(short int)value;

/*!
	@method descriptorWithLong:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a long integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</TT containing a descriptor of type <tt>typeLongInteger</tt>
	@param value The long int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a lon integer descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithLong:(long int)value;

/*!
	@method descriptorWithInt:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeInteger</tt>
	@param value The int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a int descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithInt:(int)value;

/*!
	@method descriptorWithFloat:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a float descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeShortFloat</tt>
	@param value The float.
	@result A <tt>NSAppleEventDescriptor</tt> containing a float descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithFloat:(float)value;

/*!
	@method descriptorWithDouble:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a double descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeLongFloat</tt>
	@param value The double.
	@result A <tt>NSAppleEventDescriptor</tt> containing a double descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithDouble:(double)value;

/*!
	@method descriptorWithUnsignedInt:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a unsigned integer descriptor.
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeMagnitude</tt>
	@param value The unsigned int.
	@result A <tt>NSAppleEventDescriptor</tt> containing a unsigned integer descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithUnsignedInt:(UInt32)value;
/*!
	@method descriptorWithCString:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a string the c string..
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeText</tt> or <tt>typeChar</tt>
	@param aString A c string.
	@result A <tt>NSAppleEventDescriptor</tt> containing plain text.
 */
+ (NSAppleEventDescriptor *)descriptorWithCString:(const char *)aString;
/*!
	@method descriptorWithDescriptorType:string:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a string the c string..
	@discussion Returns a <tt>NSAppleEventDescriptor</tt> containing a descriptor of type <tt>typeText</tt> or <tt>typeChar</tt>
	@param descriptorType The descriptor type used for the string.
	@param string A string objects.
	@result A <tt>NSAppleEventDescriptor</tt> containing plain text.
 */
+ (NSAppleEventDescriptor *)descriptorWithDescriptorType:(DescType)descriptorType string:(NSString *)string;
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
+ (NSAppleEventDescriptor *)descriptorWithNumber:(NSNumber *)number;

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
+ (NSAppleEventDescriptor *)descriptorWithValue:(NSValue *)value;

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
				<td align="center"><tt>NDScriptData</tt></td>
				<td align="center"><tt>cScript</tt></td>
			</tr>
		</table>
	</blockquote></blockquote></p>
	@param object An object that can be converted into a descriptor.
	@result A <tt>NSAppleEventDescriptor</tt>.
 */
+ (NSAppleEventDescriptor *)descriptorWithObject:(id)object;

/*!
	@method descriptorWithArray:
	@abstract Returns a generic data storage descriptor.
	@discussion <tt>descriptorWithData:</tt> returns a decriptor of type <tt>typeOSAGenericStorage</tt>.
	@param array The array to create a <tt>NSAppleEventDescriptor</tt> from.
	@result A <tt>NSAppleEventDescriptor</tt> for a generic data storage descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithData:(NSData *)aData;
/*!
	@method descriptorWithArray:
	@abstract Returns a list descriptor.
	@discussion <tt>descriptorWithArray:</tt> returns a list decriptor containing AppleEvent decriptors returned from the method <tt>descriptorWithObject:</tt> when passed each of <tt><i>array</i></tt>'s objects.
	@param array The array to create a <tt>NSAppleEventDescriptor</tt> from.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithArray:(NSArray *)array;

/*!
	@method listDescriptorWithObjects:...
	@abstract Returns a list descriptor.
	@discussion <tt>descriptorWithArray:</tt> returns a list decriptor containing AppleEvent decriptors returned from the method <tt>descriptorWithObject:</tt> when passed each of object arguments.
	@param firstObject The argument list terminated with <tt>nil</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor.
 */
+ (NSAppleEventDescriptor *)listDescriptorWithObjects:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;

/*!
	@method listDescriptorWithObjects:arguments:
	@abstract Returns a list descriptor.
	@discussion <tt>descriptorWithArray:</tt> returns a list decriptor containing AppleEvent decriptors returned from the method <tt>descriptorWithObject:</tt> when passed each of object arguments.
	@param firstObject The first object of the argument list.
	@param argList The argument list.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor.
 */
+ (NSAppleEventDescriptor *)listDescriptorWithObjects:(id)object arguments:(va_list)argList;

/*!
	@method descriptorWithEventClass:eventID:
	@abstract Returns a AppleEvent descriptor.
	@discussion <#Discussion#>
	@param eventClass The AppleEvent class
	@param eventID The AppleEvent ID
	@result A <tt>NSAppleEventDescriptor</tt> for a AppleEvent descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithEventClass:(AEEventClass)eventClass eventID:(AEEventID)eventID;
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
	@method descriptorWithDictionary:
	@abstract Returns a record descriptor
	@discussion Returns a record descriptor. Any keys that are not NSNumber&lt;unsigned long&gt; are converted to <tt>NSString</tt>s by there method <tt>-desccription</tt> and placed withing a list descriptor with there value, the array is then inserted into the record decriptor with the key <tt>keyASUserRecordFields</tt>; any keys that are NSNumber&lt;unsigned long&gt; are converted to <tt>AEKeyword</tt> with its method <tt>-unsignedIntValue</tt>. This is how record types in AppleScript are represented using AppleEvents
	@param aDictionary A dictionary where the key can be represented as case insensitive strings.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithDictionary:(NSDictionary *)aDictionary;

/*!
	@method descriptorWithScriptObjectSpecifier:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> containing a object specifier
	@discussion Returns a AppleEvent descriptor for an object specifier that can be passed in AppleEvents to AppleScripts.
	@param objectSpecifier The object specifier.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithScriptObjectSpecifier:(NSScriptObjectSpecifier *)objectSpecifier;

/*!
	@method descriptorWithObjectAndKeys:...
	@abstract Returns a record descriptor
	@discussion Returns a record descriptor with one key value pair where the keyword is <tt>keyASUserRecordFields</tt> and the value is descriptor of the type typeAEList as returned from the method <tt>userRecordDescriptorWithObjectAndKeys:arguments:</tt>. This is how record types in AppleScript are represented using AppleEvents
	@param object The first object is a list of object/key pairs terminated with <tt>nil</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
*/
+ (NSAppleEventDescriptor *)descriptorWithObjectAndKeys:(id)object, ... NS_REQUIRES_NIL_TERMINATION;


/*!
	@method descriptorWithObjectAndKeys:arguments:
	@abstract Returns a record descriptor
	@discussion Returns a record descriptor with one key value pair where the keyword is <tt>keyASUserRecordFields</tt> and the value is descriptor of the type typeAEList as returned from the method <tt>userRecordDescriptorWithObjectAndKeys:arguments:</tt>. This is how record types in AppleScript are represented using AppleEvents
	@param object The first object is a list of object/key pairs.
	@param argList The argument list.
	@result A <tt>NSAppleEventDescriptor</tt> for a record descriptor.
 */
+ (NSAppleEventDescriptor *)descriptorWithObjectAndKeys:(id)object arguments:(va_list)argList;


/*!
	@method userRecordDescriptorWithObjectAndKeys:...
	@abstract Returns a user record.
	@discussion Create a list descriptor that can be used as the value for the key <tt>keyASUserRecordFields</tt> in record descriptors of AppleEvents representing AppleScript subroutine calls, this is how records in AppleScripts represented. The resulting descriptor is identical to the descriptor returned from the method <tt>listDescriptorWithObjects:...</tt> if the keys and object are swap around and all of the keys are of type <tt>NSString</tt>. <tt>userRecordDescriptorWithObjectAndKeys:...</tt> has the advantage over <tt>listDescriptorWithObjects:...</tt> in that the keys are converted to <tt>NSString</tt> using the method <tt>-[NSObject description]</tt>.
	@param object A list of object and keys terminated with a <tt>nil</tt>.
	@result A <tt>NSAppleEventDescriptor</tt> for a list descriptor representing a user record.
 */
+ (NSAppleEventDescriptor *)userRecordDescriptorWithObjectAndKeys:(id)object, ... NS_REQUIRES_NIL_TERMINATION;

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
	@method dictionaryValue
	@abstract Returns an <tt>NSDictionary</tt> for a record descriptor.
	@discussion Returns a <tt>NSDictionary</tt> if the receviers is a record descriptor with each element convert to an appropriate object as determined by the method <tt>-[NSAppleEventDescriptor objectValue]</tt> and the key converted to a <tt>NSNumbers</tt> or <tt>NSString</tt>. If the recevier does not contain a record descriptor then the resut is undefined.
	@result A <tt>NSDictionary</tt>.
 */
- (NSDictionary *)dictionaryValue;

/*!
	@method dictionaryValueFromUserRecordDescriptor
	@abstract Returns an <tt>NSDictionary</tt> for a user record fields descriptor.
	@discussion Returns a <tt>NSDictionary</tt> from a value with the key <tt>keyASUserRecordFields</tt>
	@result A <tt>NSDictionary</tt> with keys all of type <tt>NSString</tt>
 */
- (NSDictionary *)dictionaryValueFromUserRecordDescriptor;

/*!
	@method urlValue
	@abstract Returns a <tt>NSURL</tt> for the recevier..
	@discussion Returns a file url <tt>NSURL</tt> for an alias descriptor. If the recevier does not contain an alias descriptor the <tt>nil</tt> is returned. Currently url descriptors are not handled.
	@result A <tt>NSURL</tt>.
 */
- (NSURL *)urlValue;

/*!
	@method intValue
	@abstract Returns a int value for the recevier.
	@discussion Returns a int value if the recevier contains a integer descriptor, otherwise it returns an undefined value.
	@result An int value.
 */
- (int)intValue;

/*!
	@method unsignedIntValue
	@abstract Returns a unsigned int value for the recevier.
	@discussion Returns a unsigned int value if the recevier contains a unsigned integer descriptor, otherwise it returns an undefined value.
	@result An unsigned int value.
 */
- (unsigned int)unsignedIntValue;

/*!
	@method longValue
	@abstract Returns a long value for the recevier.
	@discussion Returns a long value if the recevier contains a long integer descriptor, otherwise it returns an undefined value.
	@result An long value.
 */
- (long)longValue;

/*!
	@method unsignedLongValue
	@abstract Returns a unsigned long value for the recevier.
	@discussion Returns a unsigned long value if the recevier contains a unsigned long integer descriptor, otherwise it returns an undefined value.
	@result An unsigned long value.
 */
- (unsigned long)unsignedLongValue;

/*!
	@method fourCharCodeValue
	@abstract Returns a <tt>FourCharCode</tt> value for the recevier.
	@discussion Returns a <tt>FourCharCode</tt> value if the recevier contains a unsigned integer descriptor, otherwise it returns <tt>0</tt>. <tt>FourCharCode</tt> is the base type that all Apple four char code values are based on included <tt>DescType</tt>, <tt>AEEventClass</tt> and <tt>AEEventID</tt>
	@result An <tt>FourCharCode</tt> value.
 */
- (FourCharCode)fourCharCodeValue;

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
	@method scriptObjectSpecifierValue
	@abstract Returns a <tt>NSScriptObjectSpecifier</tt> object for the recevier.
	@discussion Returns a <tt>NSScriptObjectSpecifier</tt> object for the recevier if it contains a script object specifier type descriptor, otherwise it returns <tt>nil</tt>.
	@result An <tt>NSNumber</tt> object.
 */
- (NSScriptObjectSpecifier *)scriptObjectSpecifierValue;

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
				<td align="center"><tt>NDScriptData</tt> <i>if available.</i><br><tt>NSAppleEventDescriptor</tt> <i>otherwise.</i></td>
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
+ (NSAppleEventDescriptor *)descriptorWithSubroutineName:(NSString *)routineName argumentsListDescriptor:(NSAppleEventDescriptor *)param;

/*!
	@method descriptorWithSubroutineName:argumentsArray:
	@abstract Returns a <tt>NSAppleEventDescriptor</tt> for calling an AppleScript subroutine with positional arguments.
	@discussion <tt>descriptorWithSubroutineName:argumentsDescriptor:</tt> returns a <tt>NSAppleEventDescriptor</tt> to call a AppleScript subroutine with positional arguments. AppleScript routines are case insensitive so <tt><i>routineName</i></tt> is converted to all lower case.
	@param routineName The rountine name to be called.
	@param paramArray A <tt>NSArray</tt> of Objective-C class that are converted into <tt>NSAppleEventDescriptor</tt> using the function <tt>descriptorWithObject:</tt.
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with positional arguments.
 */
+ (NSAppleEventDescriptor *)descriptorWithSubroutineName:(NSString *)routineName argumentsArray:(NSArray *)paramArray;

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
	@param objects A c array of Objective-C class that are converted into <tt>NSAppleEventDescriptor</tt> using the function <tt>descriptorWithObject:</tt.
	@param count The number of labels and objects
	@result A <tt>NSAppleEventDescriptor</tt> for a subroutine with labled arguments.
 */
+ (NSAppleEventDescriptor *)descriptorWithSubroutineName:(NSString *)routineName labels:(AEKeyword*)labels argumentObjects:(id *)objects count:(unsigned int)count;

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
+ (NSAppleEventDescriptor *)descriptorWithSubroutineName:(NSString *)routineName labels:(AEKeyword*)labels argumentDescriptors:(NSAppleEventDescriptor **)params count:(unsigned int)count;

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
+ (NSAppleEventDescriptor *)descriptorWithSubroutineName:(NSString *)routineName labelsAndArguments:(AEKeyword)keyWord, ... NS_REQUIRES_NIL_TERMINATION;

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


/*!
	 @method sendWithSendMode:sendPriority:timeOutInTicks:idleProc:filterProc:
	 @abstract <#Abstract#>
	 @discussion <#Discussion#>
	 @param sendMode Specifies various options for how the server application should handle the Apple event. To obtain a value for this parameter, you add together constants to set bits that specify the reply mode, the interaction level, the application switch mode, the reconnection mode, and the return receipt mode. Possible values are;
	 <dl>
	 <dt><tt>kAENoReply</tt></dt>
	 <dd>The reply preference—your application does not want a reply Apple event. If you set the bit specified by this constant, the server processes the Apple event as soon as it has the opportunity.</dd>
	 <dt><tt>kAEQueueReply</tt></dt>
	 <dd>The reply preference—your application wants a reply Apple event. If you set the bit specified by this constant, the reply appears in your event queue as soon as the server has the opportunity to process and respond to your Apple event.</dd>
	 <dt><tt>kAEWaitReply</tt></dt>
	 <dd>The reply preference—your application wants a reply Apple event and is willing to give up the processor while waiting for the reply. For example, if the server application is on the same computer as your application, your application yields the processor to allow the server to respond to your Apple event.<br><br>
	 If you set the bit specified by this constant, you must provide an idle function. This function should process any update events, null events, operating-system events, or activate events that occur while your application is waiting for a reply. For more information on idle routines, see AEInteractWithUser.</dd>
	 <dt><tt>kAEDontReconnect</tt></dt>
	 <dd>The reconnection preference—the Apple Event Manager must not automatically try to reconnect if it receives a sessClosedErr result code from the PPC Toolbox. If you don’t set this flag, the Apple Event Manager automatically attempts to reconnect and reestablish the session.</dd>
	 <dt><tt>kAEWantReceipt</tt></dt>
	 <dd>The return receipt preference—the sender wants to receive a return receipt for this Apple event from the Event Manager. (A return receipt means only that the receiving application accepted the Apple event the Apple event may or may not be handled successfully after it is accepted.) If the receiving application does not send a return receipt before the request times out, AESend returns errAETimeout as its function result.</dd>
	 <dt><tt>kAENeverInteract</tt></dt>
	 <dd>The user interaction preference—the server application should never interact with the user in response to the Apple event. If you set the bit specified by this constant, the AEInteractWithUser function (when called by the server) returns the errAENoUserInteraction result code. When you send an Apple event to a remote application, the default is to set this bit.</dd>
	 <dt><tt>kAECanInteract</tt></dt>
	 <dd>The user interaction preference—the server application can interact with the user in response to the Apple event. By convention, you set the bit specified by this constant if the user needs to supply information to the server. If you set the bit and the server allows interaction, the AEInteractWithUser function either brings the server application to the foreground or posts a notification request. When you send an Apple event to a local application, the default is to set this bit.</dd>
	 <dt><tt>kAEAlwaysInteract</tt></dt>
	 <dd>The user interaction preference—the server application should always interact with the user in response to the Apple event. By convention, you set the bit specified by this constant whenever the server application normally asks a user to confirm a decision or interact in any other way, even if no additional information is needed from the user. If you set the bit specified by this constant, the AEInteractWithUser function either brings the server application to the foreground or posts a notification request.</dd>
	 <dt><tt>kAECanSwitchLayer</tt></dt>
	 <dd>The application switch preference—if both the client and server allow interaction, and if the client application is the active application on the local computer and is waiting for a reply (that is, it has set the kAEWaitReply flag), AEInteractWithUser brings the server directly to the foreground. Otherwise, AEInteractWithUser uses the Notification Manager to request that the user bring the server application to the foreground.<br><br>
	 You should specify the kAECanSwitchLayer flag only when the client and server applications reside on the same computer. In general, you should not set this flag if it would be confusing or inconvenient to the user for the server application to come to the front unexpectedly. This flag is ignored if you are sending an Apple event to a remote computer.</dd>
	 <dt><tt>kAEDontRecord</tt></dt>
	 <dd>The recording preference—your application is sending an event to itself but does not want the event recorded. When Apple event recording is on, the Apple Event Manager records a copy of every event your application sends to itself except for those events for which this flag is set.</dd>
	 <dt><tt>kAEDontExecute</tt></dt>
	 <dd>The execution preference—your application is sending an Apple event to itself for recording purposes only—that is, you want the Apple Event Manager to send a copy of the event to the recording process but you do not want your application actually to receive the event.</dd>
	 <dt><tt>kAEProcessNonReplyEvents</tt></dt>
	 <dd>Allow processing of non-reply Apple events while awaiting a synchronous Apple event reply (you specified kAEWaitReply for the reply preference).</dd>
	 </dl>
	 @param sendPriority A value that specifies the priority for processing the Apple event. You can specify normal or high priority, using these constants;
	 <dl>
	 <dt><tt>kAENormalPriority</tt></dt>
	 <dd>The Apple Event Manager posts the event at the end of the event queue of the server process and the server processes the Apple event as soon as it has the opportunity.</dd>
	 <dt><tt>kAEHighPriority</tt></dt>
	 <dd>The Apple Event Manager posts the event at the beginning of the event queue of the server process.</dd>
	 </dl>
	 @param timeOutInTicks If the reply mode specified in the sendMode parameter is kAEWaitReply, or if a return receipt is requested, this parameter specifies the length of time (in ticks) that the client application is willing to wait for the reply or return receipt from the server application before timing out. Most applications should use the kAEDefaultTimeout constant, which tells the Apple Event Manager to provide an appropriate timeout duration. If the value of this parameter is kNoTimeOut, the Apple event never times out.
	 <dl>
	 <dt><tt>kAEDefaultTimeout</tt></dt>
	 <dd>The timeout value is determined by the Apple Event Manager. The default timeout value is about one minute.</dd>
	 <dt><tt>kNoTimeOut</tt></dt>
	 <dd>Your application is willing to wait indefinitely. Most commonly, you instead provide a timeout value (in ticks) that will provide a reasonable amount of time for the current operation.</dd>
	 </dl>
	 @param idleProc A universal procedure pointer to a function that handles events (such as update, operating-system, activate, and null events) that your application receives while waiting for a reply. Your idle function can also perform other tasks (such as displaying a wristwatch or spinning beach ball cursor) while waiting for a reply or a return receipt. 
	 If your application specifies the kAEWaitReply flag in the sendMode parameter and you wish your application to get periodic time while waiting for the reply to return, you must provide an idle function. Otherwise, you can pass a value of NULL for this parameter. The function should be more of the form
	 <blockquote>
	 <code>Boolean MyAEIdleCallback( EventRecord * event, SInt32 * sleepTime, RgnHandle * mouseRgn );</code>
	 <dl>
	 <h5>Parameter Descriptions</h5>
	 <dt><tt>event</tt></dt>
	 <dd>A pointer to the event record of the event to process.</dd>
	 <dt><tt>sleepTime</tt></dt>
	 <dd>A pointer to a value that specifies the amount of time (in ticks) your application is willing to relinquish the processor if no events are pending.</dd>
	 <dt><tt>mouseRgn</tt></dt>
	 <dd>A pointer to a value that specifies a screen region that determines the conditions under which your application is to receive notice of mouse-moved events.</dd>
	 <dt><tt>function result</tt></dt>
	 <dd>Your idle routine returns TRUE if your application is no longer willing to wait for a reply from the server or for the user to bring the application to the front. It returns FALSE if your application is still willing to wait.</dd>
	 </dl>
	 <blockquote>
	 @param filterProc A universal procedure pointer to a function that determines which incoming Apple events should be received while the handler waits for a reply or a return receipt. If your application doesn’t need to filter Apple events, you can pass a value of NULL for this parameter. If you do so, no application-oriented Apple events are processed while waiting. For more information on the filter function, see AEFilterProcPtr.
	 <blockquote>
	 <code>Boolean MyAEFilterCallback ( EventRecord * event, SInt32 returnID, SInt32 transactionID, const AEAddressDesc * sender );</code>
	 <dl>
	 <h5>Parameter Descriptions</h5>
	 <dt><tt>event</tt></dt>
	 <dd>A pointer to the event record for a high-level event. The next three parameters contain valid information only if the event is an Apple event.</dd>
	 <dt><tt>returnID</tt></dt>
	 <dd>Return ID for the Apple event.</dd>
	 <dt><tt>transactionID</tt></dt>
	 <dd>Transaction ID for the Apple event.</dd>
	 <dt><tt>sender</tt></dt>
	 <dd>A pointer to the address of the process that sent the Apple event.</dd>
	 <dt><tt>function result</tt></dt>
	 <dd>Your filter routine returns TRUE to accept the Apple event or FALSE to filter it out.</dd>
	 </dl>
	 @result The reply Apple event from the server application, if you specified the kAEWaitReply flag in the sendMode parameter. If you specify the kAEQueueReply flag in the sendMode parameter, you receive the reply Apple event in your event queue. If you specify kAENoReply flag, the reply Apple event is a null descriptor record.
 */
- (NSAppleEventDescriptor *)sendWithSendMode:(AESendMode)sendMode sendPriority:(AESendPriority)sendPriority timeOutInTicks:(SInt32)timeOutInTicks idleProc:(AEIdleUPP)idleProc filterProc:(AEFilterUPP)filterProc;

/*!
 @method send
 @abstract <#Abstract#>
 @discussion <#Discussion#>
 @result <#result#>
 */
- (NSAppleEventDescriptor *)send;

@end
