#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
  OSStatus status = noErr;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[(NSURL *)url path]];
  NSDictionary *dataDict = [dictionary objectForKey:@"data"];
  
  
  NSArray *types = [NSArray arrayWithObjects: 
                    (id)kUTTypeImage, kUTTypePNG, kUTTypeTIFF,
                    nil];
  
  for (NSString *type in types) {
    NSData *imageData = [dataDict objectForKey:type];
    if (imageData) {
      NSDictionary *properties = [NSDictionary dictionaryWithObject:type 
                                                             forKey:(NSString *)kCGImageSourceTypeIdentifierHint];
      
      QLThumbnailRequestSetImageWithData(thumbnail, (CFDataRef)imageData, (CFDictionaryRef)properties);
      break;
    }
  }
 

  [pool release];
  return status;

}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail)
{
    // implement only if supported
}
