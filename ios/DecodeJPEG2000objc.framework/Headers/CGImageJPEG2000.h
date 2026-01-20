#ifndef CGImageJPEG2000_h
#define CGImageJPEG2000_h

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#include <DecodeJPEG2000objc/openjpeg.h>

@interface CGImageJPEG2000 : NSObject

// Function to create a CGImageRef from opj_image_t
- (CGImageRef)createCGImageWithJPEG2000Image:(opj_image_t *)image;

@end
#endif /* CGImageJPEG2000_h */
