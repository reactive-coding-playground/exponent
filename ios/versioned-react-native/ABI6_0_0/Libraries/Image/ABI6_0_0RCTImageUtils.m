/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI6_0_0RCTImageUtils.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <tgmath.h>

#import "ABI6_0_0RCTLog.h"
#import "ABI6_0_0RCTUtils.h"

static CGFloat ABI6_0_0RCTCeilValue(CGFloat value, CGFloat scale)
{
  return ceil(value * scale) / scale;
}

static CGFloat ABI6_0_0RCTFloorValue(CGFloat value, CGFloat scale)
{
  return floor(value * scale) / scale;
}

static CGSize ABI6_0_0RCTCeilSize(CGSize size, CGFloat scale)
{
  return (CGSize){
    ABI6_0_0RCTCeilValue(size.width, scale),
    ABI6_0_0RCTCeilValue(size.height, scale)
  };
}

CGRect ABI6_0_0RCTTargetRect(CGSize sourceSize, CGSize destSize,
                     CGFloat destScale, ABI6_0_0RCTResizeMode resizeMode)
{
  if (CGSizeEqualToSize(destSize, CGSizeZero)) {
    // Assume we require the largest size available
    return (CGRect){CGPointZero, sourceSize};
  }

  CGFloat aspect = sourceSize.width / sourceSize.height;
  // If only one dimension in destSize is non-zero (for example, an Image
  // with `flex: 1` whose height is indeterminate), calculate the unknown
  // dimension based on the aspect ratio of sourceSize
  if (destSize.width == 0) {
    destSize.width = destSize.height * aspect;
  }
  if (destSize.height == 0) {
    destSize.height = destSize.width / aspect;
  }

  // Calculate target aspect ratio if needed (don't bother if resizeMode == stretch)
  CGFloat targetAspect = 0.0;
  if (resizeMode != UIViewContentModeScaleToFill) {
    targetAspect = destSize.width / destSize.height;
    if (aspect == targetAspect) {
      resizeMode = ABI6_0_0RCTResizeModeStretch;
    }
  }

  switch (resizeMode) {
    case ABI6_0_0RCTResizeModeStretch:

      return (CGRect){CGPointZero, ABI6_0_0RCTCeilSize(destSize, destScale)};

    case ABI6_0_0RCTResizeModeContain:

      if (targetAspect <= aspect) { // target is taller than content

        sourceSize.width = destSize.width = destSize.width;
        sourceSize.height = sourceSize.width / aspect;

      } else { // target is wider than content

        sourceSize.height = destSize.height = destSize.height;
        sourceSize.width = sourceSize.height * aspect;
      }
      return (CGRect){
        {
          ABI6_0_0RCTFloorValue((destSize.width - sourceSize.width) / 2, destScale),
          ABI6_0_0RCTFloorValue((destSize.height - sourceSize.height) / 2, destScale),
        },
        ABI6_0_0RCTCeilSize(sourceSize, destScale)
      };

    case ABI6_0_0RCTResizeModeCover:

      if (targetAspect <= aspect) { // target is taller than content

        sourceSize.height = destSize.height = destSize.height;
        sourceSize.width = sourceSize.height * aspect;
        destSize.width = destSize.height * targetAspect;
        return (CGRect){
          {ABI6_0_0RCTFloorValue((destSize.width - sourceSize.width) / 2, destScale), 0},
          ABI6_0_0RCTCeilSize(sourceSize, destScale)
        };

      } else { // target is wider than content

        sourceSize.width = destSize.width = destSize.width;
        sourceSize.height = sourceSize.width / aspect;
        destSize.height = destSize.width / targetAspect;
        return (CGRect){
          {0, ABI6_0_0RCTFloorValue((destSize.height - sourceSize.height) / 2, destScale)},
          ABI6_0_0RCTCeilSize(sourceSize, destScale)
        };
      }
  }
}

CGAffineTransform ABI6_0_0RCTTransformFromTargetRect(CGSize sourceSize, CGRect targetRect)
{
  CGAffineTransform transform = CGAffineTransformIdentity;
  transform = CGAffineTransformTranslate(transform,
                                         targetRect.origin.x,
                                         targetRect.origin.y);
  transform = CGAffineTransformScale(transform,
                                     targetRect.size.width / sourceSize.width,
                                     targetRect.size.height / sourceSize.height);
  return transform;
}

CGSize ABI6_0_0RCTTargetSize(CGSize sourceSize, CGFloat sourceScale,
                     CGSize destSize, CGFloat destScale,
                     ABI6_0_0RCTResizeMode resizeMode,
                     BOOL allowUpscaling)
{
  switch (resizeMode) {
    case ABI6_0_0RCTResizeModeStretch:

      if (!allowUpscaling) {
        CGFloat scale = sourceScale / destScale;
        destSize.width = MIN(sourceSize.width * scale, destSize.width);
        destSize.height = MIN(sourceSize.height * scale, destSize.height);
      }
      return ABI6_0_0RCTCeilSize(destSize, destScale);

    default: {

      // Get target size
      CGSize size = ABI6_0_0RCTTargetRect(sourceSize, destSize, destScale, resizeMode).size;
      if (!allowUpscaling) {
        // return sourceSize if target size is larger
        if (sourceSize.width * sourceScale < size.width * destScale) {
          return sourceSize;
        }
      }
      return size;
    }
  }
}

BOOL ABI6_0_0RCTUpscalingRequired(CGSize sourceSize, CGFloat sourceScale,
                          CGSize destSize, CGFloat destScale,
                          ABI6_0_0RCTResizeMode resizeMode)
{
  if (CGSizeEqualToSize(destSize, CGSizeZero)) {
    // Assume we require the largest size available
    return YES;
  }

  // Precompensate for scale
  CGFloat scale = sourceScale / destScale;
  sourceSize.width *= scale;
  sourceSize.height *= scale;

  // Calculate aspect ratios if needed (don't bother if resizeMode == stretch)
  CGFloat aspect = 0.0, targetAspect = 0.0;
  if (resizeMode != UIViewContentModeScaleToFill) {
    aspect = sourceSize.width / sourceSize.height;
    targetAspect = destSize.width / destSize.height;
    if (aspect == targetAspect) {
      resizeMode = ABI6_0_0RCTResizeModeStretch;
    }
  }

  switch (resizeMode) {
    case ABI6_0_0RCTResizeModeStretch:

      return destSize.width > sourceSize.width || destSize.height > sourceSize.height;

    case ABI6_0_0RCTResizeModeContain:

      if (targetAspect <= aspect) { // target is taller than content

        return destSize.width > sourceSize.width;

      } else { // target is wider than content

        return destSize.height > sourceSize.height;
      }

    case ABI6_0_0RCTResizeModeCover:

      if (targetAspect <= aspect) { // target is taller than content

        return destSize.height > sourceSize.height;

      } else { // target is wider than content

        return destSize.width > sourceSize.width;
      }
  }
}

UIImage *__nullable ABI6_0_0RCTDecodeImageWithData(NSData *data,
                                           CGSize destSize,
                                           CGFloat destScale,
                                           ABI6_0_0RCTResizeMode resizeMode)
{
  CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
  if (!sourceRef) {
    return nil;
  }

  // Get original image size
  CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
  if (!imageProperties) {
    CFRelease(sourceRef);
    return nil;
  }
  NSNumber *width = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelWidth);
  NSNumber *height = CFDictionaryGetValue(imageProperties, kCGImagePropertyPixelHeight);
  CGSize sourceSize = {width.doubleValue, height.doubleValue};
  CFRelease(imageProperties);

  if (CGSizeEqualToSize(destSize, CGSizeZero)) {
    destSize = sourceSize;
    if (!destScale) {
      destScale = 1;
    }
  } else if (!destScale) {
    destScale = ABI6_0_0RCTScreenScale();
  }

  if (resizeMode == UIViewContentModeScaleToFill) {
    // Decoder cannot change aspect ratio, so ABI6_0_0RCTResizeModeStretch is equivalent
    // to ABI6_0_0RCTResizeModeCover for our purposes
    resizeMode = ABI6_0_0RCTResizeModeCover;
  }

  // Calculate target size
  CGSize targetSize = ABI6_0_0RCTTargetSize(sourceSize, 1, destSize, destScale, resizeMode, NO);
  CGSize targetPixelSize = ABI6_0_0RCTSizeInPixels(targetSize, destScale);
  CGFloat maxPixelSize = fmax(fmin(sourceSize.width, targetPixelSize.width),
                              fmin(sourceSize.height, targetPixelSize.height));

  NSDictionary<NSString *, NSNumber *> *options = @{
    (id)kCGImageSourceShouldAllowFloat: @YES,
    (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
    (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
    (id)kCGImageSourceThumbnailMaxPixelSize: @(maxPixelSize),
  };

  // Get thumbnail
  CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
  CFRelease(sourceRef);
  if (!imageRef) {
    return nil;
  }

  // Return image
  UIImage *image = [UIImage imageWithCGImage:imageRef
                                       scale:destScale
                                 orientation:UIImageOrientationUp];
  CGImageRelease(imageRef);
  return image;
}

NSDictionary<NSString *, id> *__nullable ABI6_0_0RCTGetImageMetadata(NSData *data)
{
  CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
  if (!sourceRef) {
    return nil;
  }
  CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, NULL);
  CFRelease(sourceRef);
  return (__bridge_transfer id)imageProperties;
}

NSData *__nullable ABI6_0_0RCTGetImageData(CGImageRef image, float quality)
{
  NSDictionary *properties;
  CGImageDestinationRef destination;
  CFMutableDataRef imageData = CFDataCreateMutable(NULL, 0);
  if (ABI6_0_0RCTImageHasAlpha(image)) {
    // get png data
    destination = CGImageDestinationCreateWithData(imageData, kUTTypePNG, 1, NULL);
  } else {
    // get jpeg data
    destination = CGImageDestinationCreateWithData(imageData, kUTTypeJPEG, 1, NULL);
    properties = @{(NSString *)kCGImageDestinationLossyCompressionQuality: @(quality)};
  }
  CGImageDestinationAddImage(destination, image, (__bridge CFDictionaryRef)properties);
  if (!CGImageDestinationFinalize(destination))
  {
    CFRelease(imageData);
    imageData = NULL;
  }
  CFRelease(destination);
  return (__bridge_transfer NSData *)imageData;
}

UIImage *__nullable ABI6_0_0RCTTransformImage(UIImage *image,
                                      CGSize destSize,
                                      CGFloat destScale,
                                      CGAffineTransform transform)
{
  if (destSize.width <= 0 | destSize.height <= 0 || destScale <= 0) {
    return nil;
  }

  BOOL opaque = !ABI6_0_0RCTImageHasAlpha(image.CGImage);
  UIGraphicsBeginImageContextWithOptions(destSize, opaque, destScale);
  CGContextRef currentContext = UIGraphicsGetCurrentContext();
  CGContextConcatCTM(currentContext, transform);
  [image drawAtPoint:CGPointZero];
  UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return result;
}

BOOL ABI6_0_0RCTImageHasAlpha(CGImageRef image)
{
  switch (CGImageGetAlphaInfo(image)) {
    case kCGImageAlphaNone:
    case kCGImageAlphaNoneSkipLast:
    case kCGImageAlphaNoneSkipFirst:
      return NO;
    default:
      return YES;
  }
}
