/*
	NSString+NDUtilities.h

	Created by Nathan Day on 14.12.02 under a MIT-style license. 
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
	@header NSString+NDUtilities
	@abstract Defines the category <tt>NSString+NDUtilities</tt>
	@discussion Additonal useful methods for <tt>NSString</tt>, that can be used in general situations.
  */

#import <Foundation/Foundation.h>

/*!
	@category NSString(NDUtilities)
	@abstract Addition methods for <tt>NSString</tt>
	@discussion Additonal useful methods for <tt>NSString</tt>, that can be used in general situations. see also NSString(NDParsing), NSString(NDPathExtensions) and NSString(CarbonUtilitiesPaths).
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
	@discussion Returns <tt>YES</tt> if <tt><i>string</i></tt> case insensitive matches the ending characters of the receiver, <tt>NO</tt> otherwise. Returns <tt>NO</tt> if <tt><i>string</i></tt> is the <tt>nil</tt> string or empty. This method is a convenience for comparing strings using the <tt>NSAnchoredSearch</tt> and <tt>NSBackwardsSearch</tt> options. See "Strings" for more information.
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
				</table></blockquote>
 
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
	@method stringByQuoting
	@abstract Returns a quoted copy of a string.
	@discussion <tt>stringByQuoting</tt> returns a copy of the the reciever enclosed in double quote (") and any containing dounle quote (") or forward slash (\) escaped with a preceeding forward slash (\), the script is suitable for use in genrating source code for languages like c, c++, Objective-C, Java, JavaSccript, AppleScrips and problable many others.
	@result A new <tt>NSString</tt>
 */
- (NSString *)stringByQuoting;

/*!
	@method indexOfMatchingStringInList:defaultValue:
	@abstract Map a string value to a index value.
	@discussion <tt>indexOfMatchingStringInList:defaultValue:</tt> returns the index of first string equal to the revciever as determined by the method <tt>isEqualToString:</tt> in the <tt>nil</tt> terminated c array of <tt>NSString</tt>s, if no match is found then the value <tt><i>defaultValue</i></tt> is returned. <tt>indexOfMatchingStringInList:defaultValue:</tt> can be used to map <tt>NSString</tt>s to enumerated value.
	@param array The c array of strings to compare against.
	@param defaultValue The value returned if no match is found.
	@result The index of th matching value.
 */
- (unsigned int)indexOfMatchingStringInList:(NSString **)array defaultValue:(unsigned int)defaultValue;

enum
{
	simpleEnclosed,
	outerEnclosed,
	innerEnclosed
};

/*!
	@method rangeOfStringEnclosedIn:and:includeEncloseString:inner:
	@abstract Return a range for charcters enclode in a pair of strings.
	@discussion Returns the range of the first set of characters enclosed within the strings <tt><i>startString</i></tt> and <tt><i>endString</i></tt>. Whether the <tt><i>startString</i></tt> and <tt><i>endString</i></tt> is included with the range is determined by <tt><i>includeEnclose</i></tt>. The <tt><i>startString</i></tt> and <tt><i>endString</i></tt> can be bracketing value and so how nested bracketing values are handle is deermined by <tt><i>mode</i></tt>;
	<dl>
		<dt>simpleEnclosed</dt>
		<dd>The first <tt><i>startString</i></tt> found and first following <tt><i>endString</i></tt> are used. The returned range may contain more <tt><i>startString</i></tt> but will not contain any <tt><i>endString</i></tt></dd>
		<dt>outerEnclosed</dt>
		<dd>The first <tt><i>startString</i></tt> found and an <tt><i>endString</i></tt> so that the number of contained <tt><i>startString</i></tt> and <tt><i>endString</i></tt> are equal.</dd>
		<dt>innerEnclosed</dt>
		<dd>The first <tt><i>startString</i></tt> followed by an <tt><i>endString</i></tt> that does not contain any <tt><i>startString</i></tt> or <tt><i>endString</i></tt>.</dd>
	</dl>
	
	@param startString The start string to search for.
	@param endString The end string to search for.
	@param includeEnclose <tt>YES</tt> to include the matched <tt><i>startString</i></tt> and <tt><i>endString</i></tt> in the result range, <tt>NO</tt> to exclude the matched <tt><i>startString</i></tt> and <tt><i>endString</i></tt> from the result range
	@param mode A matching mode to determine who to handle balanced matches, either <tt>simpleEnclosed</tt>, <tt>outerEnclosed</tt> or <tt>innerEnclosed</tt>;
	@result The found range or a range with a location of UINT_MAX and a length of UINT_MAX if no range found.
 */
- (NSRange)rangeOfStringEnclosedIn:(NSString *)startString and:(NSString *)endString includeEncloseString:(BOOL)includeEnclose mode:(int)mode;

/*!
	@method stringFromDictionary:withFormat:
	@abstract Returns a string created by using a given format string as a template into which values from a dictionary are substituted.
	@discussion <tt>stringWithFormat:fromKeys:withDictionary:</tt> takes a format string just like other format string function but instead of using following the following arguments a list of keys is supplied which is used to fetch the value from a dictionary. For example
	<pre>
		NSDictionary		* <i>theDictionary</i> = [NSDictionary dictionaryWithObjectsAndKeys:@"<span style="color:blue">substution A</span>", @"<span style="color:blue">valueA</span>", @"<span style="color:green">substution B</span>", @"<span style="color:green">valueB</span>", nil];
 [NSString <b>stringWithFormat:</b>@"Test string with %@, %@ and %@" <b>fromDictionary:</b><i>theDictionary</i>, <span style="color:blue">@"valueA"</span>, <span style="color:green">@"valueB"</span>, <span style="color:blue">@"valueA"</span>];
	</pre>
	will create the string
	<pre>
		Test string with <span style="color:blue">substution A</span>, <span style="color:green">substution B</span> and <span style="color:blue">substution A</span>
	</pre>
 
	@param format <#description#>
	@param dictionary <#description#>
	@param keys <#description#>
	@result <#description#>
 */
+ (NSString *)stringFromDictionary:(NSDictionary *)aDictionary withFormat:(NSString *)aFormat, ...;
+ (NSString *)stringFromDictionary:(NSDictionary *)aDictionary withFormat:(NSString *)aFormat arguments:(va_list)anArguments;

- (unsigned int)indexOfCharacater:(unichar)aChar;
- (unsigned int)indexOfCharacater:(unichar)aChar options:(NSStringCompareOptions)mask;
/*!
	@method indexOfCharacater:
	@abstract Find the index of a chartacter.
	@discussion Returns the index of the first occurance of the unichar character <tt><i>char</i></tt> within the given range <tt><i>range</i></tt>, if the character can not be found then <tt>NSNotFound</tt> is returned. the <tt><i>mask</i></tt> parameter can be used to change the way comparisons are performed and can be the union of any of the following values.
	<table>
		<tr><th>Value</th><th></th>Description</tr>
		<tr><td><tt>NSCaseInsensitiveSearch</tt></td>
			<td>A case-insensitive search.</td></tr>
		<tr><td><tt>NSLiteralSearch</tt></td>
			<td>Exact character-by-character equivalence.</td></tr>
		<tr><td><tt>NSBackwardsSearch</tt></td>
			<td>Search from end of source string.</td></tr>
		<tr><td><tt>NSAnchoredSearch</tt></td>
			<td>Search is limited to start (or end, if <tt>NSBackwardsSearch<tt>) of source string.</td></tr>
		<tr><td><tt>NSNumericSearch</tt></td>
			<td>Numbers within strings are compared using numeric value, that is, Foo2.txt &lt; Foo7.txt &lt; Foo25.txt.<br />This option only applies to compare methods, not find.</td></tr>
		<tr><td><tt>NSDiacriticInsensitiveSearch</tt></td>
			<td>Search ignores diacritic marks.<br />For example, ‘ö’ is equal to ‘o’.</td></tr>
		<tr><td><tt>NSWidthInsensitiveSearch</tt></td>
			<td>Search is ignores width differences ().<br />For example, ‘a’ is equal to UFF41.</td></tr>
		<tr><td><tt>NSForcedOrderingSearch</tt></td>
			<td>Comparisons are forced to return either NSOrderedAscending or NSOrderedDescending if the strings are equivalent but not strictly equal.<br />This option gives stability when sorting. For example, “aaa” is greater than "AAA” if NSCaseInsensitiveSearch is specified.</td></tr>
	 </table>
	@param char The unichar character to search for.
	@param mask The unichar character to search for.
	@param range range The range to contrain the search to.
	@result The index of the character or <tt>NSNotFound</tt> if the character</tt>
 */
- (unsigned int)indexOfCharacater:(unichar)aChar options:(NSStringCompareOptions)mask range:(NSRange)range;

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


/*!
	@method stringByReplacingString:withString:
	@abstract Create a new string by search and replace.
	@discussion <tt>stringByReplacingString:withString:</tt> creates a new string from the reciever by replacing all occurances of <tt><i>searchString</i></tt> with the string <tt><i>replaceString</i></tt>. If the string <tt><i>searchString</i></tt> is not found then the string returned will be identical to the reciever.
	@deprecated in version 10.5
	@param searchString The string to replace in the reciever.
	@param replaceString The string to replace <tt><i>searchString</i></tt> with.
	@result A new string.
 */
- (NSString *)stringByReplacingString:(NSString *)searchString withString:(NSString *)replaceString AVAILABLE_MAC_OS_X_VERSION_10_2_AND_LATER_BUT_DEPRECATED;

/*!
	@method stringByReplacingCharacterRunsFromSet:withString:
	@abstract Create a new string by replacing character runs.
	@discussion A new string is created by replacing all continuous runs of characters in set <tt><i>set</i></tt> with the string <tt><i>replacement</i></tt>. For example by using <tt>[NSCharacterSet whitespaceAndNewlineCharacterSet] for <tt><i>set</i</tt> and the string <tt>@" "</tt> for <tt><i>replaceString</i></tt> the whitespace within a string can be normalized replacing all runs of whitespace with a single space.
	@param set Set of characters to replace.
	@param replacement A string to replace all runs of characters <tt><i>set</i></tt>
	@result New string.
 */
- (NSString *)stringByReplacingCharacterRunsFromSet:(NSCharacterSet *)set withString:(NSString *)replacement;

/*!
	@method rangeOfCharacterRunFromSet:
	@abstract Find range of first occurance of character run of character set.
	@discussion Calls <tt>rangeOfCharacterRunFromSet:options:range:</tt> with options value of 0 and a range including the entire string.
	@param set Character set the characters within the rune belong to.
	@result <tt>NSRange</tt> of character run or <tt>NSRange</tt> equal to {NSNotFound,0};
 */
- (NSRange)rangeOfCharacterRunFromSet:(NSCharacterSet *)set;
/*!
	@method rangeOfCharacterRunFromSet:options:
	@abstract Find range of first occurance of character run of character set.
	@discussion Calls <tt>rangeOfCharacterRunFromSet:options:range:</tt> with a range including the entire string.
	@param set Character set the characters within the rune belong to.
	@param mask A mask specifying search options. The following options may be specified by combining them with the C bitwise OR operator: NSCaseInsensitiveSearch, NSLiteralSearch, NSBackwardsSearch.
	@result <tt>NSRange</tt> of character run or <tt>NSRange</tt> equal to {NSNotFound,0};
 */
- (NSRange)rangeOfCharacterRunFromSet:(NSCharacterSet *)set options:(NSStringCompareOptions)mask;
/*!
	@method rangeOfCharacterRunFromSet:options:range:
	@abstract Find range of first occurance of character run of character set.
	@discussion Using the Apple function <tt>rangeOfCharacterFromSet:options:range:</tt> to find the first character within <tt><i>set</i></tt> and the first following charater within <tt><i>[set invertedSet]</i></tt> and return a <tt>NSRange</tt> created from the two locations. If the there is no following charater within <tt><i>[set invertedSet]</i></tt> then then returned range extends to the end of the <tt>NSRange</tt> <tt><i>range</i></tt>.
	@param set Character set the characters within the rune belong to.
	@param mask A mask specifying search options. The following options may be specified by combining them with the C bitwise OR operator: NSCaseInsensitiveSearch, NSLiteralSearch, NSBackwardsSearch.
	@param range The range in which to search. aRange must not exceed the bounds of the receiver.
	@result <tt>NSRange</tt> of character run or <tt>NSRange</tt> equal to {NSNotFound,0};
 */
- (NSRange)rangeOfCharacterRunFromSet:(NSCharacterSet *)set options:(NSStringCompareOptions)mask range:(NSRange)range;

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