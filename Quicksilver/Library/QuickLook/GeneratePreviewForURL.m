#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <Foundation/Foundation.h>

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options) {
  
  OSStatus status = noErr;
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[(NSURL *)url path]];
  NSDictionary *dataDict = [dictionary objectForKey:@"data"];
  
  NSArray *types = [NSArray arrayWithObjects: 
                    kUTTypeImage, kUTTypePNG, kUTTypeTIFF,
                    kUTTypePDF,
                    kUTTypeHTML,
                    kUTTypeXML,
                    kUTTypePlainText, kUTTypeUTF16PlainText,
                    kUTTypeRTF, 
                    kUTTypeMovie, 
                    kUTTypeAudio, nil];
  
  for (NSString *type in types) {
    NSData *data = [dataDict objectForKey:type];
    if (data) {
      QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)data, (CFStringRef)type, NULL);
      break;
    }
  }
  
  [pool release];
  return status;
  
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview)
{
    // implement only if supported
}
