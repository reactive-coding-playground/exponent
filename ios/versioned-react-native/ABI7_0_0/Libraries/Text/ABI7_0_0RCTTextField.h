/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#import "ABI7_0_0RCTComponent.h"

@class ABI7_0_0RCTEventDispatcher;

@interface ABI7_0_0RCTTextField : UITextField

@property (nonatomic, assign) BOOL caretHidden;
@property (nonatomic, assign) BOOL autoCorrect;
@property (nonatomic, assign) BOOL selectTextOnFocus;
@property (nonatomic, assign) BOOL blurOnSubmit;
@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, strong) UIColor *placeholderTextColor;
@property (nonatomic, assign) NSInteger mostRecentEventCount;
@property (nonatomic, strong) NSNumber *maxLength;
@property (nonatomic, assign) BOOL textWasPasted;

@property (nonatomic, copy) ABI7_0_0RCTDirectEventBlock onSelectionChange;

- (instancetype)initWithEventDispatcher:(ABI7_0_0RCTEventDispatcher *)eventDispatcher NS_DESIGNATED_INITIALIZER;

- (void)textFieldDidChange;
- (void)sendKeyValueForString:(NSString *)string;
- (BOOL)textFieldShouldEndEditing:(ABI7_0_0RCTTextField *)textField;

@end
