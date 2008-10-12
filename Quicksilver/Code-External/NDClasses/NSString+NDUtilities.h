/*!
	@header NSString+NDUtilities
	@abstract Defines the category <tt>NSString+NDUtilities</tt>
	@discussion Additonal useful methods for <tt>NSString</tt>, that can be used in general situations.
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
	@method uniquePath
	@abstract Get a unique path.
	@discussion Returns a unique path based on the recieved, if the receiver it's self does not exist then it is returned.
	@result A path that is guaranteed not to exist yet.
 */
- (NSString *)uniquePath;


@end
