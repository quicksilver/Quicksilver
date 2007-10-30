
// ----- CaseInsensitiveStringKey.m 

#import "QSCaseInsensitiveStringKey.h" 

@implementation QSCaseInsensitiveStringKey 

+ (QSCaseInsensitiveStringKey *) fromString:(NSString *) originalString { 
	QSCaseInsensitiveStringKey *instance; 
	instance = [[QSCaseInsensitiveStringKey alloc] init]; 
	[instance setString:originalString]; 
	return [instance autorelease]; 
} 

- (id)copyWithZone:(NSZone *)zone { 
	return [self retain]; 
} 

- (void) dealloc { 
	if (original != NULL) { 
		[original release]; 
	} 
	[super dealloc]; 
} 

- (void) setString: (NSString *) originalString { 
	[originalString retain]; 
	[original release]; 
	original = originalString; 
} 


- (NSString *) string { 
	return original; 
	// Or, you could say (but why?) 
	// return [[original copy] autorelease]; 
} 


- (NSString *) lowercaseString { 
	return [original lowercaseString]; 
} 

- (BOOL) isEqual: (id)anObject { 
	return [[self lowercaseString] isEqualToString:[anObject 
        lowercaseString]]; 
} 

- (unsigned) hash { 
	return [[self lowercaseString] hash]; 
} 

@end 



@implementation NSString (QSCaseInsensitiveStringKey)
- (QSCaseInsensitiveStringKey *)insensitiveKey{
    return [QSCaseInsensitiveStringKey fromString:self];
}
@end