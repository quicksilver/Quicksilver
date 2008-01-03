#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h> 
#include <Cocoa/Cocoa.h>

/* -----------------------------------------------------------------------------
   Step 1
   Set the UTI types the importer supports
  
   Modify the CFBundleDocumentTypes entry in Info.plist to contain
   an array of Uniform Type Identifiers (UTI) for the LSItemContentTypes 
   that your importer can handle
  
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 2 
   Implement the GetMetadataForFile function
  
   Implement the GetMetadataForFile function below to scrape the relevant
   metadata from your document and return it as a CFDictionary using standard keys
   (defined in MDItem.h) whenever possible.
   ----------------------------------------------------------------------------- */

/* -----------------------------------------------------------------------------
   Step 3 (optional) 
   If you have defined new attributes, update the schema.xml file
  
   Edit the schema.xml file to include the metadata keys that your importer returns.
   Add them to the <allattrs> and <displayattrs> elements.
  
   Add any custom types that your importer requires to the <attributes> element
  
   <attribute name="com_mycompany_metadatakey" type="CFString" multivalued="true"/>
  
   ----------------------------------------------------------------------------- */



/* -----------------------------------------------------------------------------
    Get metadata attributes from file
   
   This function's job is to extract useful information your file format supports
   and return it as a dictionary
   ----------------------------------------------------------------------------- */

Boolean GetMetadataForFile(void* thisInterface, 
			   CFMutableDictionaryRef attrs, 
			   CFStringRef contentTypeUTI,
			   CFStringRef pathToFile)
{
  /* Pull any available metadata from the file at the specified path */
  /* Return the attribute keys and attribute values in the dict */
  /* Return TRUE if successful, FALSE if there was no data provided */
  NSMutableDictionary *attributes = (NSMutableDictionary *)attrs;
  id value;
  Boolean success=NO;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDictionary *tempDict = [[NSDictionary alloc] initWithContentsOfFile:(NSString *)pathToFile];
  if (tempDict) {
    NSDictionary *metadata = [tempDict objectForKey:@"metadata"];
    [attributes addEntriesFromDictionary:metadata];
    
    NSDictionary *dataDict = [tempDict objectForKey:@"data"];
    
    // set the kMDItemTitle attribute to the Title
    if ((value = [metadata objectForKey:@"QSObjectName"]))
      [attributes setObject:value forKey:(NSString *)kMDItemTitle];
   
    
    [(NSMutableDictionary *)attributes setObject:[NSArray arrayWithObject:@"test"]
                                          forKey:(NSString *)@"kMDItemContentTypeTree"];
    
    if ((value = [dataDict objectForKey:(NSString*)kMDItemContentType])) {
 
      NSMutableArray *array = [NSMutableArray array];
      while (value) {
        [array addObject:value];
        NSDictionary *declaration = [(NSDictionary*)UTTypeCopyDeclaration((CFStringRef)value) autorelease];
        NSArray *parents = [declaration objectForKey:(NSString*)kUTTypeConformsToKey];
        if (![parents count]) break;
        value = [parents lastObject];
      }
      
 
      [(NSMutableDictionary *)attributes setObject:array
                                            forKey:(NSString *)@"kMDItemContentTypeTree"];
    }
    
    if ((value = [dataDict objectForKey:NSURLPboardType])) {
      [attributes setObject:[NSArray arrayWithObject:value]
                     forKey:(NSString *)kMDItemWhereFroms];
    }

    if ((value = [dataDict objectForKey:NSStringPboardType])) {
      [(NSMutableDictionary *)attributes setObject:value
                                            forKey:(NSString *)kMDItemTextContent];
    }
    // return YES so that the attributes are imported
    success=YES;
    
    // release the loaded document
    [tempDict release];
  }
  [pool release];
  return success;
}
