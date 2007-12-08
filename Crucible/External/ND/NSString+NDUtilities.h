/*!
	@header NSString+NDUtilities.h
	@abstract Defines the category <tt>NSString+NDUtilities</tt>
	@discussion Additonal useful methods for <tt>NSString</tt>, that can be used in general situations.
 
	Created by Nathan Day on Sun Dec 14 2003.
	Copyright &#169; 2003 Nathan Day. All rights reserved.
 */

#import <Foundation/Foundation.h>

/*!
	@category NSString(NDUtilities)
	@abstract Addition methods for <tt>NSString</tt>
	@discussion Additonal useful methods for <tt>NSString</tt>, that can be used in general situations. see also NSString(NDContainsCharacterExtension), NSString(NDPathExtensions) and NSString(CarbonUtilitiesPaths).
 */
@interface NSString (NDUtilities)

/*!
	@method stringWithNonLossyASCIIString:
	@abstract Create a <tt>NSString</tt>.
	@discussion Creates a <tt>NSString</tt> from <tt>NSNonLossyASCIIStringEncoding</tt> encoding, a 7-bit verbose ASCII to represent all Unicode characters
	@param ASCIIString A 7 bit ASCII string in <tt>NSNonLossyASCIIStringEncoding</tt> encoding.
	@result A new <tt>NSString</tt>
 */
+ (id)stringWithNonLossyASCIIString:(const char *)ASCIIString;

/*!
	@method stringWithFormat:arguments:
	@abstract Create a <tt>NSString</tt>.
	@discussion Creates a new string object, using <tt><i>format</i></tt> as a template into which the following <tt><i>argList</i></tt> values are substituted. Raises an <tt>NSInvalidArgumentException</tt> if <tt><i>format</i></tt> is <tt>nil</tt>.
	@param format The template string.
	@param argList The arguments to be inserted into <tt><i>format</i></tt>
	@result A new <tt>NSString</tt>
 */
+ (id)stringWithFormat:(NSString *)format arguments:(va_list)argList;

/*!
	@method initWithNonLossyASCIIString:
	@abstract Intialise a <tt>NSString</tt>.
	@discussion Initialises a <tt>NSString</tt> from <tt>NSNonLossyASCIIStringEncoding</tt> encoding, a 7-bit verbose ASCII to represent all Unicode characters.
	@param ASCIIString A 7 bit ASCII string in <tt>NSNonLossyASCIIStringEncoding</tt> encoding.
	@result A initialised <tt>NSString</tt>.
 */
- (id)initWithNonLossyASCIIString:(const char *)ASCIIString;

/*!
	@method nonLossyASCIIString
	@abstract Get a 7 bit ASCII representation of a <tt>NSString</tt> containing Unicode characters.
	@discussion Returns a c string using <tt>NSNonLossyASCIIStringEncoding</tt> encoding, a 7-bit verbose ASCII to represent all Unicode characters. The returned C string will be automatically freed just as a returned object would be released; your code should copy the C string, if it needs to store the C string outside of the autorelease context in which the C string is created.
	@result A c string with <tt>NSNonLossyASCIIStringEncoding</tt> encoding.
 */
- (const char *)nonLossyASCIIString;

/*!
	@method isCaseInsensitiveEqualToString:
	@abstract Test if a string is case insensitive equivelent.
	@discussion Returns <tt>YES</tt> if string is case insensitive equivalent to the receiver (if they have the same <tt>id</tt> or if they are <tt>NSOrderedSame</tt> in a litereral, case insensitive comparison), <tt>NO</tt> otherwise. .
	@param string The string to compare with.
	@result Returns <tt>YES</tt> string are equivelent <tt>NO</tt>.
 */
- (BOOL)isCaseInsensitiveEqualToString:(NSString *)string;

/*!
	@method hasCaseInsensitivePrefix:
	@abstract Test prefix.
	@discussion Returns <tt>YES</tt> if <tt><i>string</i></tt> case insensitive matches the beginning characters of the receiver, <tt>NO</tt> otherwise. Returns <tt>NO</tt> if <tt><i>string</i></tt> is the <tt>nil</tt> string or empty. This method is a convenience for comparing strings using the <tt>NSAnchoredSearch</tt> option. See "Strings" for more information.
	@param string The string to check for.
	@result Returns <tt>YES</tt> if has case insensitive prefix <tt><i>string</i></tt>.
 */
- (BOOL)hasCaseInsensitivePrefix:(NSString *)string;

/*!
	@method hasCaseInsensitiveSuffix:
	@abstract Test suffix.
	@discussion Returns <tt>YES</tt> if <tt><i>string</i></tt> case insensitive matches the ending characters of the receiver, <tt>NO</tt otherwise. Returns <tt>NO</tt if <tt><i>string</i></tt> is the <tt>nil</tt> string or empty. This method is a convenience for comparing strings using the <tt>NSAnchoredSearch</tt> and <tt>NSBackwardsSearch</tt> options. See "Strings" for more information.
	@param string The string to check for.
	@result Returns <tt>YES</tt> if has case insensitive suffix <tt><i>string</i></tt>.
 */
- (BOOL)hasCaseInsensitiveSuffix:(NSString *)string;

/*!
	@method containsString:
	@abstract Test if a string contains a substring.
	@discussion Invokes <tt>containsString:options:</tt> with no options. Raises an <tt>NSInvalidArgumentException</tt> if string is <tt>nil</tt>.
	@param subString The string to search for.
	@result Returns <tt>YES</tt> if substring found otherwise <tt>NO</tt>.
 */
- (BOOL)containsString:(NSString *)subString;

/*!
	@method containsString:options:
	@abstract Test if a string contains a substring.
	@discussion Invokes <tt>containsString:options:range:</tt> with the options specified by <tt><i>mask</i></tt> and the entire extent of the receiver as the range. Raises an <tt>NSInvalidArgumentException</tt> if any of the arguments are <tt>nil</tt>.
	@param subString The string to search for.
	@param mask Mask values determining how to search.
	@result Returns <tt>YES</tt> if substring found otherwise <tt>NO</tt>.
 */
- (BOOL)containsString:(NSString *)subString options:(unsigned)mask;

/*!
	@method containsString:options:range:
	@abstract Test if a string contains a substring.
	@discussion Returns <tt>YES</tt> if <tt><i>subString</i></tt> occurs within range in the receiver. If <tt><i>subString</i></tt> isn't found, returns a <tt>NO</tt>. The following options may be specified in <tt><i>mask</i></tt> by combining them with the C bitwise OR operator:
				<blockquote><table border = "1" width = "90%">
					<thead><tr><th>Search Option</th><th>Effect</th></tr></thead>
					<tr><td align = "center"><tt>NSCaseInsensitiveSearch</tt></td><td>Ignores case distinctions among characters.</td></tr>
					<tr><td align = "center"><tt>NSLiteralSearch</tt></td><td>Performs a byte-for-byte comparison. Differing literal sequences (such as composed character sequences) that would otherwise be considered equivalent are considered not to match. Using this option can speed some operations dramatically.</td></tr>
					<tr><td align = "center"><tt>NSBackwardsSearch</tt></td><td>Performs searching from the end of the range toward the beginning.</td></tr>
					<tr><td align = "center"><tt>NSAnchoredSearch</tt></td><td>Performs searching only on characters at the beginning or end of the range. No match at the beginning or end means nothing is found, even if a matching sequence of characters occurs elsewhere in the string.</td></tr>
				</table ></blockquote >
 
			Raises an NSRangeException if any part of range lies beyond the end of the string.
	@param subString The string to search for.
	@param mask Mask values determining how to search.
	@param range The range within the string to search.
	@result Returns <tt>YES</tt> if substring found otherwise <tt>NO</tt>.
 */

- (BOOL)containsString:(NSString *)subString options:(unsigned)mask range:(NSRange)range;

/*!
	@method indexOfCharacter:range:
	@abstract Get the index of a character.
	@discussion Returns the index of the first occurance of the character <tt><i>character</i></tt> within the range <tt><i>range</i></tt>, if the receiver does not contain the character within the range then <tt>NSNotFound</tt> is return.
	@param character The character to look for.
	@param range The range to limit the search to.
	@result Returns the index of the character or <tt>NSNotFound</tt> if not found.
 */
- (unsigned int)indexOfCharacter:(unichar)character range:(NSRange)range;


/*!
	@method indexOfCharacter:
	@abstract Get the index of a character.
	@discussion Returns the index of the first occurance of the character <tt><i>character</i></tt>, if the receiver does not contain the character then <tt>NSNotFound</tt> is return.
	@param character The character to look for.
	@result Returns the index of the character or <tt>NSNotFound</tt> if not found.
 */
- (unsigned int)indexOfCharacter:(unichar)character;

/*!
	@method containsCharacter:
	@abstract Test if a string contains a character.
	@discussion Returns <tt>YES</tt> if the receiver contains the character <tt><i>character</i></tt>, otherwise returns <tt>NO</tt>.
	@param character The character to look for.
	@result Returns <tt>YES</tt> if the receiver contains the character.
 */
- (BOOL)containsCharacter:(unichar)character;

/*!
	@method containsCharacter:range:
	@abstract Test if a string contains a character.
	@discussion Returns <tt>YES</tt> if the receiver contains the character <tt><i>character</i></tt> within the range <tt><i>range</i></tt>, otherwise returns <tt>NO</tt>.
	@param character The character to look for.
	@param range The range to limit the search to.
	@result Returns <tt>YES</tt> if the receiver contains the character.
 */
- (BOOL)containsCharacter:(unichar)character range:(NSRange)range;

/*!
	@method containsAnyCharacterFromSet:
	@abstract Test if a string contains a character from a set.
	@discussion Returns <tt>YES</tt> if the receiver contains any character within <tt><i>set</i></tt>, otherwise returns <tt>NO</tt>.
	@param set The set of characters to look for.
	@result Returns <tt>YES</tt> if the receiver contains any of the characters.
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)set;

/*!
	@method containsAnyCharacterFromSet:options:
	@abstract Test if a string contains a character from a set.
	@discussion Returns <tt>YES</tt> if the receiver contains any character within <tt><i>set</i></tt> within the range <tt><i>range</i></tt>, otherwise returns <tt>NO</tt>. The following options may be specified in <tt><i>mask</i></tt> by combining them with the C bitwise OR operator:
	<blockquote><blockquote><table border = "1" width = "90%">
		<thead>
			<th>Search Option</th>
			<th>Effect</th>
		</thead>
		<tr>
			<td align = "center"><tt>NSCaseInsensitiveSearch</tt></td>
			<td>Ignores case distinctions among characters.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSLiteralSearch</tt></td>
			<td>Performs a byte-for-byte comparison. Differing literal sequences (such as composed character sequences) that would otherwise be considered equivalent are considered not to match. Using this option can speed some operations dramatically.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSBackwardsSearch</tt></td>
			<td>Performs searching from the end of the range toward the beginning.</td>
		</tr>
	</table></blockquote></blockquote>
	See "Strings" for details on these options. Raises an <tt>NSInvalidArgumentException</tt> if any of the arguments are <tt>nil</tt>.
	@param set The set of characters to look for.
	@param mask Mask values determining how to search.
	@result Returns <tt>YES</tt> if the receiver contains any of the characters.
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)set options:(unsigned int)mask;

/*!
	@method containsAnyCharacterFromSet:options:range
	@abstract Test if a string contains a character from a set.
	@discussion Returns <tt>YES</tt> if the receiver contains any character within <tt><i>set</i></tt> within the range <tt><i>range</i></tt>, otherwise returns <tt>NO</tt>. The following options may be specified in <tt><i>mask</i></tt> by combining them with the C bitwise OR operator:
	<blockquote><blockquote><table border = "1" width = "90%">
		<thead>
			<th>Search Option</th>
			<th>Effect</th>
		</thead>
		<tr>
			<td align = "center"><tt>NSCaseInsensitiveSearch</tt></td>
			<td>Ignores case distinctions among characters.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSLiteralSearch</tt></td>
			<td>Performs a byte-for-byte comparison. Differing literal sequences (such as composed character sequences) that would otherwise be considered equivalent are considered not to match. Using this option can speed some operations dramatically.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSBackwardsSearch</tt></td>
			<td>Performs searching from the end of the range toward the beginning.</td>
		</tr>
	</table></blockquote></blockquote>
	See "Strings" for details on these options. Raises an <tt>NSInvalidArgumentException</tt> if any of the arguments are <tt>nil</tt>. Raises an <tt>NSRangeException</tt> if any part of <tt><i>range</i></tt> lies beyond the end of the string.
	@param set The set of characters to look for.
	@param mask Mask values determining how to search.
	@param range The range to limit the search to.
	@result Returns <tt>YES</tt> if the receiver contains any of the characters.
 */
- (BOOL)containsAnyCharacterFromSet:(NSCharacterSet *)set options:(unsigned int)mask range:(NSRange)range;

/*!
	@method containsOnlyCharactersFromSet:
	@abstract Test if a string contains only the characters from a set.
	@discussion Returns <tt>YES</tt> if the receiver contains only characters in <tt><i>set</i></tt> within <tt><i>set</i></tt>, otherwise returns <tt>NO</tt>.
	@param set The set of characters to look for.
	@result Returns <tt>YES</tt> if the receiver contains only the characters.
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)set;

/*!
	@method containsOnlyCharactersFromSet:options:
	@abstract Test if a string contains only the characters from a set.
	@discussion Returns <tt>YES</tt> if the receiver contains only character from <tt><i>set</i></tt>, otherwise returns <tt>NO</tt>. The following options may be specified in <tt><i>mask</i></tt> by combining them with the C bitwise OR operator:
	<blockquote><blockquote><table border = "1" width = "90%">
		<thead>
			<th>Search Option</th>
			<th>Effect</th>
		</thead>
		<tr>
			<td align = "center"><tt>NSCaseInsensitiveSearch</tt></td>
			<td>Ignores case distinctions among characters.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSLiteralSearch</tt></td>
			<td>Performs a byte-for-byte comparison. Differing literal sequences (such as composed character sequences) that would otherwise be considered equivalent are considered not to match. Using this option can speed some operations dramatically.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSBackwardsSearch</tt></td>
			<td>Performs searching from the end of the range toward the beginning.</td>
		</tr>
	</table></blockquote></blockquote>
	See "Strings" for details on these options. Raises an <tt>NSInvalidArgumentException</tt> if any of the arguments are <tt>nil</tt>. Raises an <tt>NSRangeException</tt> if any part of <tt><i>range</i></tt> lies beyond the end of the string.
	@param set The set of characters to look for.
	@param mask Mask values determining how to search.
	@result Returns <tt>YES</tt> if the receiver contains only the characters.
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)set options:(unsigned int)mask;

/*!
	@method containsOnlyCharactersFromSet:options:range:
	@abstract Test if a string contains only the characters from a set.
	@discussion Returns <tt>YES</tt> if the receiver contains only character from <tt><i>set</i></tt> within the range <tt><i>range</i></tt>, otherwise returns <tt>NO</tt>. The following options may be specified in <tt><i>mask</i></tt> by combining them with the C bitwise OR operator:
	<blockquote><blockquote><table border = "1" width = "90%">
		<thead>
			<th>Search Option</th>
			<th>Effect</th>
		</thead>
		<tr>
			<td align = "center"><tt>NSCaseInsensitiveSearch</tt></td>
			<td>Ignores case distinctions among characters.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSLiteralSearch</tt></td>
			<td>Performs a byte-for-byte comparison. Differing literal sequences (such as composed character sequences) that would otherwise be considered equivalent are considered not to match. Using this option can speed some operations dramatically.</td>
		</tr>
		<tr>
			<td align = "center"><tt>NSBackwardsSearch</tt></td>
			<td>Performs searching from the end of the range toward the beginning.</td>
		</tr>
	</table></blockquote></blockquote>
	See "Strings" for details on these options. Raises an <tt>NSInvalidArgumentException</tt> if any of the arguments are <tt>nil</tt>. Raises an <tt>NSRangeException</tt> if any part of <tt><i>range</i></tt> lies beyond the end of the string.
	@param set The set of characters to look for.
	@param mask Mask values determining how to search.
	@param range The range to limit the search to.
	@result Returns <tt>YES</tt> if the receiver contains only the characters.
 */
- (BOOL)containsOnlyCharactersFromSet:(NSCharacterSet *)set options:(unsigned int)mask range:(NSRange)range;


/*!
	@method componentsSeparatedByString:withOpeningQuote:closingQuote:singleQuote:
	@abstract Get an array of string componets.
	@discussion Returns an <tt>NSArray</tt> containing substrings from the receiver that have been divided by separator. The substrings in the array appear in the order they did in the receiver.
	@param separator The delimeter used to seperate the strings.
	@param openingQuote The string used to begin a quoted component, a component where the delimiter is ignored.
	@param closingQuote The string used to end a quoted component, a component where the delimiter is ignored.
	@param singleQuote The string used to quote a single character.
	@param flag Set to true if empty string are wanted. 
	@result A <tt>NSArray</tt> of components.
 */
- (NSArray *)componentsSeparatedByString:(NSString *)separator withOpeningQuote:(NSString *)openingQuote closingQuote:(NSString *)closingQuote singleQuote:(NSString *)singleQuote includeEmptyComponents:(BOOL)flag;

@end


/*!
	@category NSMutableString(NDUtilities)
	@abstract Addition methods for <tt>NSString</tt>
	@discussion Additonal useful methods for <tt>NSMutableString</tt>, that can be used in general situations.
 */
@interface NSMutableString (NDUtilities)

/*!
	@method prependString:
	@abstract Prepend a string.
	@discussion Adds the characters of <tt><i>string</i></tt> to the beginning of the receiver. <tt><i>string</i></tt> may not be <tt>nil</tt>. 
	@param string The string to append. 
  */
- (void)prependString:(NSString *)string;

/*!
	@method prependFormat:
	@abstract Prepend a string format.
	@discussion Adds a constructed string to the beginning of the receiver. Creates the new string using <tt>NSString</tt>'s  <tt>stringWithFormat:</tt> method with the arguments listed. Raises an <tt>NSInvalidArgumentException</tt> if <tt><i>format</i></tt> is <tt>nil</tt>.
	@param format The format string to append, followed by values to insert. 
  */
- (void)prependFormat:(NSString *)format, ...;

@end