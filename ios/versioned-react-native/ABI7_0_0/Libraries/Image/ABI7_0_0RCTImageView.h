/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>
#import "ABI7_0_0RCTResizeMode.h"

@class ABI7_0_0RCTBridge;
@class ABI7_0_0RCTImageSource;

@interface ABI7_0_0RCTImageView : UIImageView

- (instancetype)initWithBridge:(ABI7_0_0RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

@property (nonatomic, assign) UIEdgeInsets capInsets;
@property (nonatomic, strong) UIImage *defaultImage;
@property (nonatomic, assign) UIImageRenderingMode renderingMode;
@property (nonatomic, strong) ABI7_0_0RCTImageSource *source;
@property (nonatomic, assign) CGFloat blurRadius;

@end
