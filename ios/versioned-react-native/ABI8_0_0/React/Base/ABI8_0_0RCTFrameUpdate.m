/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/CADisplayLink.h>

#import "ABI8_0_0RCTFrameUpdate.h"

#import "ABI8_0_0RCTUtils.h"

@implementation ABI8_0_0RCTFrameUpdate

ABI8_0_0RCT_NOT_IMPLEMENTED(- (instancetype)init)

- (instancetype)initWithDisplayLink:(CADisplayLink *)displayLink
{
  if ((self = [super init])) {
    _timestamp = displayLink.timestamp;
    _deltaTime = displayLink.duration;
  }
  return self;
}

@end
