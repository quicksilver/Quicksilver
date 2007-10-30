#include <CoreFoundation/CoreFoundation.h>
#include "dyld-interposing.h"

// This little snippet of code is used to force LSUIElement to FALSE on Leopard.
// It allows you to have an app launch as a LSUIElement. This does not work
// on Tiger.
const void *GDLSUICFDictionaryGetValue(CFDictionaryRef theDict, const void *key) {
  if (CFDictionaryContainsKey(theDict, CFSTR("CFBundleExecutable"))) {
    if (CFStringCompare(key, CFSTR("LSUIElement"), 0) == kCFCompareEqualTo) {
      return kCFBooleanFalse;
    }
  }
  return CFDictionaryGetValue(theDict, key);
}

DYLD_INTERPOSE(GDLSUICFDictionaryGetValue,CFDictionaryGetValue);
