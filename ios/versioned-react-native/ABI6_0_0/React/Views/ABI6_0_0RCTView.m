/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "ABI6_0_0RCTView.h"

#import "ABI6_0_0RCTAutoInsetsProtocol.h"
#import "ABI6_0_0RCTBorderDrawing.h"
#import "ABI6_0_0RCTConvert.h"
#import "ABI6_0_0RCTLog.h"
#import "ABI6_0_0RCTUtils.h"
#import "UIView+ReactABI6_0_0.h"

@implementation UIView (ABI6_0_0RCTViewUnmounting)

- (void)ReactABI6_0_0_remountAllSubviews
{
  // Normal views don't support unmounting, so all
  // this does is forward message to our subviews,
  // in case any of those do support it

  for (UIView *subview in self.subviews) {
    [subview ReactABI6_0_0_remountAllSubviews];
  }
}

- (void)ReactABI6_0_0_updateClippedSubviewsWithClipRect:(CGRect)clipRect relativeToView:(UIView *)clipView
{
  // Even though we don't support subview unmounting
  // we do support clipsToBounds, so if that's enabled
  // we'll update the clipping

  if (self.clipsToBounds && self.subviews.count > 0) {
    clipRect = [clipView convertRect:clipRect toView:self];
    clipRect = CGRectIntersection(clipRect, self.bounds);
    clipView = self;
  }

  // Normal views don't support unmounting, so all
  // this does is forward message to our subviews,
  // in case any of those do support it

  for (UIView *subview in self.subviews) {
    [subview ReactABI6_0_0_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
  }
}

- (UIView *)ReactABI6_0_0_findClipView
{
  UIView *testView = self;
  UIView *clipView = nil;
  CGRect clipRect = self.bounds;
  // We will only look for a clipping view up the view hierarchy until we hit the root view.
  BOOL passedRootView = NO;
  while (testView && !passedRootView) {
    if (testView.clipsToBounds) {
      if (clipView) {
        CGRect testRect = [clipView convertRect:clipRect toView:testView];
        if (!CGRectContainsRect(testView.bounds, testRect)) {
          clipView = testView;
          clipRect = CGRectIntersection(testView.bounds, testRect);
        }
      } else {
        clipView = testView;
        clipRect = [self convertRect:self.bounds toView:clipView];
      }
    }
    if ([testView isReactABI6_0_0RootView]) {
      passedRootView = YES;
    }
    testView = testView.superview;
  }
  return clipView ?: self.window;
}

@end

static NSString *ABI6_0_0RCTRecursiveAccessibilityLabel(UIView *view)
{
  NSMutableString *str = [NSMutableString stringWithString:@""];
  for (UIView *subview in view.subviews) {
    NSString *label = subview.accessibilityLabel;
    if (label) {
      [str appendString:@" "];
      [str appendString:label];
    } else {
      [str appendString:ABI6_0_0RCTRecursiveAccessibilityLabel(subview)];
    }
  }
  return str;
}

@implementation ABI6_0_0RCTView
{
  NSMutableArray<UIView *> *_ReactABI6_0_0Subviews;
  UIColor *_backgroundColor;
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    _borderWidth = -1;
    _borderTopWidth = -1;
    _borderRightWidth = -1;
    _borderBottomWidth = -1;
    _borderLeftWidth = -1;
    _borderTopLeftRadius = -1;
    _borderTopRightRadius = -1;
    _borderBottomLeftRadius = -1;
    _borderBottomRightRadius = -1;
    _borderStyle = ABI6_0_0RCTBorderStyleSolid;
    _hitTestEdgeInsets = UIEdgeInsetsZero;

    _backgroundColor = super.backgroundColor;
  }

  return self;
}

ABI6_0_0RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:unused)

- (NSString *)accessibilityLabel
{
  if (super.accessibilityLabel) {
    return super.accessibilityLabel;
  }
  return ABI6_0_0RCTRecursiveAccessibilityLabel(self);
}

- (void)setPointerEvents:(ABI6_0_0RCTPointerEvents)pointerEvents
{
  _pointerEvents = pointerEvents;
  self.userInteractionEnabled = (pointerEvents != ABI6_0_0RCTPointerEventsNone);
  if (pointerEvents == ABI6_0_0RCTPointerEventsBoxNone) {
    self.accessibilityViewIsModal = NO;
  }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  BOOL canReceiveTouchEvents = ([self isUserInteractionEnabled] && ![self isHidden]);
  if(!canReceiveTouchEvents) {
    return nil;
  }

  // `hitSubview` is the topmost subview which was hit. The hit point can
  // be outside the bounds of `view` (e.g., if -clipsToBounds is NO).
  UIView *hitSubview = nil;
  BOOL isPointInside = [self pointInside:point withEvent:event];
  BOOL needsHitSubview = !(_pointerEvents == ABI6_0_0RCTPointerEventsNone || _pointerEvents == ABI6_0_0RCTPointerEventsBoxOnly);
  if (needsHitSubview && (![self clipsToBounds] || isPointInside)) {
    // The default behaviour of UIKit is that if a view does not contain a point,
    // then no subviews will be returned from hit testing, even if they contain
    // the hit point. By doing hit testing directly on the subviews, we bypass
    // the strict containment policy (i.e., UIKit guarantees that every ancestor
    // of the hit view will return YES from -pointInside:withEvent:). See:
    //  - https://developer.apple.com/library/ios/qa/qa2013/qa1812.html
    for (UIView *subview in [self.subviews reverseObjectEnumerator]) {
      CGPoint convertedPoint = [subview convertPoint:point fromView:self];
      hitSubview = [subview hitTest:convertedPoint withEvent:event];
      if (hitSubview != nil) {
        break;
      }
    }
  }

  UIView *hitView = (isPointInside ? self : nil);

  switch (_pointerEvents) {
    case ABI6_0_0RCTPointerEventsNone:
      return nil;
    case ABI6_0_0RCTPointerEventsUnspecified:
      return hitSubview ?: hitView;
    case ABI6_0_0RCTPointerEventsBoxOnly:
      return hitView;
    case ABI6_0_0RCTPointerEventsBoxNone:
      return hitSubview;
    default:
      ABI6_0_0RCTLogError(@"Invalid pointer-events specified %zd on %@", _pointerEvents, self);
      return hitSubview ?: hitView;
  }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
  if (UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero)) {
    return [super pointInside:point withEvent:event];
  }
  CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, self.hitTestEdgeInsets);
  return CGRectContainsPoint(hitFrame, point);
}

- (BOOL)accessibilityActivate
{
  if (_onAccessibilityTap) {
    _onAccessibilityTap(nil);
    return YES;
  } else {
    return NO;
  }
}

- (BOOL)accessibilityPerformMagicTap
{
  if (_onMagicTap) {
    _onMagicTap(nil);
    return YES;
  } else {
    return NO;
  }
}

- (NSString *)description
{
  NSString *superDescription = super.description;
  NSRange semicolonRange = [superDescription rangeOfString:@";"];
  NSString *replacement = [NSString stringWithFormat:@"; ReactABI6_0_0Tag: %@;", self.ReactABI6_0_0Tag];
  return [superDescription stringByReplacingCharactersInRange:semicolonRange withString:replacement];
}

#pragma mark - Statics for dealing with layoutGuides

+ (void)autoAdjustInsetsForView:(UIView<ABI6_0_0RCTAutoInsetsProtocol> *)parentView
                 withScrollView:(UIScrollView *)scrollView
                   updateOffset:(BOOL)updateOffset
{
  UIEdgeInsets baseInset = parentView.contentInset;
  CGFloat previousInsetTop = scrollView.contentInset.top;
  CGPoint contentOffset = scrollView.contentOffset;

  if (parentView.automaticallyAdjustContentInsets) {
    UIEdgeInsets autoInset = [self contentInsetsForView:parentView];
    baseInset.top += autoInset.top;
    baseInset.bottom += autoInset.bottom;
    baseInset.left += autoInset.left;
    baseInset.right += autoInset.right;
  }
  scrollView.contentInset = baseInset;
  scrollView.scrollIndicatorInsets = baseInset;

  if (updateOffset) {
    // If we're adjusting the top inset, then let's also adjust the contentOffset so that the view
    // elements above the top guide do not cover the content.
    // This is generally only needed when your views are initially laid out, for
    // manual changes to contentOffset, you can optionally disable this step
    CGFloat currentInsetTop = scrollView.contentInset.top;
    if (currentInsetTop != previousInsetTop) {
      contentOffset.y -= (currentInsetTop - previousInsetTop);
      scrollView.contentOffset = contentOffset;
    }
  }
}

+ (UIEdgeInsets)contentInsetsForView:(UIView *)view
{
  while (view) {
    UIViewController *controller = view.ReactABI6_0_0ViewController;
    if (controller) {
      return (UIEdgeInsets){
        controller.topLayoutGuide.length, 0,
        controller.bottomLayoutGuide.length, 0
      };
    }
    view = view.superview;
  }
  return UIEdgeInsetsZero;
}

#pragma mark - View unmounting

- (void)ReactABI6_0_0_remountAllSubviews
{
  if (_ReactABI6_0_0Subviews) {
    NSUInteger index = 0;
    for (UIView *view in _ReactABI6_0_0Subviews) {
      if (view.superview != self) {
        if (index < self.subviews.count) {
          [self insertSubview:view atIndex:index];
        } else {
          [self addSubview:view];
        }
        [view ReactABI6_0_0_remountAllSubviews];
      }
      index++;
    }
  } else {
    // If ReactABI6_0_0_subviews is nil, we must already be showing all subviews
    [super ReactABI6_0_0_remountAllSubviews];
  }
}

- (void)remountSubview:(UIView *)view
{
  // Calculate insertion index for view
  NSInteger index = 0;
  for (UIView *subview in _ReactABI6_0_0Subviews) {
    if (subview == view) {
      [self insertSubview:view atIndex:index];
      break;
    }
    if (subview.superview) {
      // View is mounted, so bump the index
      index++;
    }
  }
}

- (void)mountOrUnmountSubview:(UIView *)view withClipRect:(CGRect)clipRect relativeToView:(UIView *)clipView
{
  if (view.clipsToBounds) {

    // View has cliping enabled, so we can easily test if it is partially
    // or completely within the clipRect, and mount or unmount it accordingly

    if (!CGRectIsEmpty(CGRectIntersection(clipRect, view.frame))) {

      // View is at least partially visible, so remount it if unmounted
      if (view.superview == nil) {
        [self remountSubview:view];
      }

      // Then test its subviews
      if (CGRectContainsRect(clipRect, view.frame)) {
        [view ReactABI6_0_0_remountAllSubviews];
      } else {
        [view ReactABI6_0_0_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
      }

    } else if (view.superview) {

      // View is completely outside the clipRect, so unmount it
      [view removeFromSuperview];
    }

  } else {

    // View has clipping disabled, so there's no way to tell if it has
    // any visible subviews without an expensive recursive test, so we'll
    // just add it.

    if (view.superview == nil) {
      [self remountSubview:view];
    }

    // Check if subviews need to be mounted/unmounted
    [view ReactABI6_0_0_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
  }
}

- (void)ReactABI6_0_0_updateClippedSubviewsWithClipRect:(CGRect)clipRect relativeToView:(UIView *)clipView
{
  // TODO (#5906496): for scrollviews (the primary use-case) we could
  // optimize this by only doing a range check along the scroll axis,
  // instead of comparing the whole frame

  if (_ReactABI6_0_0Subviews == nil) {
    // Use default behavior if unmounting is disabled
    return [super ReactABI6_0_0_updateClippedSubviewsWithClipRect:clipRect relativeToView:clipView];
  }

  if (_ReactABI6_0_0Subviews.count == 0) {
    // Do nothing if we have no subviews
    return;
  }

  if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
    // Do nothing if layout hasn't happened yet
    return;
  }

  // Convert clipping rect to local coordinates
  clipRect = [clipView convertRect:clipRect toView:self];
  clipView = self;
  if (self.clipsToBounds) {
    clipRect = CGRectIntersection(clipRect, self.bounds);
  }

  // Mount / unmount views
  for (UIView *view in _ReactABI6_0_0Subviews) {
    [self mountOrUnmountSubview:view withClipRect:clipRect relativeToView:clipView];
  }
}

- (void)setRemoveClippedSubviews:(BOOL)removeClippedSubviews
{
  if (removeClippedSubviews && !_ReactABI6_0_0Subviews) {
    _ReactABI6_0_0Subviews = [self.subviews mutableCopy];
  } else if (!removeClippedSubviews && _ReactABI6_0_0Subviews) {
    [self ReactABI6_0_0_remountAllSubviews];
    _ReactABI6_0_0Subviews = nil;
  }
}

- (BOOL)removeClippedSubviews
{
  return _ReactABI6_0_0Subviews != nil;
}

- (void)insertReactABI6_0_0Subview:(UIView *)view atIndex:(NSInteger)atIndex
{
  if (_ReactABI6_0_0Subviews == nil) {
    [self insertSubview:view atIndex:atIndex];
  } else {
    [_ReactABI6_0_0Subviews insertObject:view atIndex:atIndex];

    // Find a suitable view to use for clipping
    UIView *clipView = [self ReactABI6_0_0_findClipView];
    if (clipView) {

      // If possible, don't add subviews if they are clipped
      [self mountOrUnmountSubview:view withClipRect:clipView.bounds relativeToView:clipView];

    } else {

      // Fallback if we can't find a suitable clipView
      [self remountSubview:view];
    }
  }
}

- (void)removeReactABI6_0_0Subview:(UIView *)subview
{
  [_ReactABI6_0_0Subviews removeObject:subview];
  [subview removeFromSuperview];
}

- (NSArray<UIView *> *)ReactABI6_0_0Subviews
{
  // The _ReactABI6_0_0Subviews array is only used when we have hidden
  // offscreen views. If _ReactABI6_0_0Subviews is nil, we can assume
  // that [self ReactABI6_0_0Subviews] and [self subviews] are the same

  return _ReactABI6_0_0Subviews ?: self.subviews;
}

- (void)updateClippedSubviews
{
  // Find a suitable view to use for clipping
  UIView *clipView = [self ReactABI6_0_0_findClipView];
  if (clipView) {
    [self ReactABI6_0_0_updateClippedSubviewsWithClipRect:clipView.bounds relativeToView:clipView];
  }
}

- (void)layoutSubviews
{
  // TODO (#5906496): this a nasty performance drain, but necessary
  // to prevent gaps appearing when the loading spinner disappears.
  // We might be able to fix this another way by triggering a call
  // to updateClippedSubviews manually after loading

  [super layoutSubviews];

  if (_ReactABI6_0_0Subviews) {
    [self updateClippedSubviews];
  }
}

#pragma mark - Borders

- (UIColor *)backgroundColor
{
  return _backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
  if ([_backgroundColor isEqual:backgroundColor]) {
    return;
  }

  _backgroundColor = backgroundColor;
  [self.layer setNeedsDisplay];
}

- (UIEdgeInsets)bordersAsInsets
{
  const CGFloat borderWidth = MAX(0, _borderWidth);

  return (UIEdgeInsets) {
    _borderTopWidth >= 0 ? _borderTopWidth : borderWidth,
    _borderLeftWidth >= 0 ? _borderLeftWidth : borderWidth,
    _borderBottomWidth >= 0 ? _borderBottomWidth : borderWidth,
    _borderRightWidth  >= 0 ? _borderRightWidth : borderWidth,
  };
}

- (ABI6_0_0RCTCornerRadii)cornerRadii
{
  // Get corner radii
  const CGFloat radius = MAX(0, _borderRadius);
  const CGFloat topLeftRadius = _borderTopLeftRadius >= 0 ? _borderTopLeftRadius : radius;
  const CGFloat topRightRadius = _borderTopRightRadius >= 0 ? _borderTopRightRadius : radius;
  const CGFloat bottomLeftRadius = _borderBottomLeftRadius >= 0 ? _borderBottomLeftRadius : radius;
  const CGFloat bottomRightRadius = _borderBottomRightRadius >= 0 ? _borderBottomRightRadius : radius;

  // Get scale factors required to prevent radii from overlapping
  const CGSize size = self.bounds.size;
  const CGFloat topScaleFactor = ABI6_0_0RCTZeroIfNaN(MIN(1, size.width / (topLeftRadius + topRightRadius)));
  const CGFloat bottomScaleFactor = ABI6_0_0RCTZeroIfNaN(MIN(1, size.width / (bottomLeftRadius + bottomRightRadius)));
  const CGFloat rightScaleFactor = ABI6_0_0RCTZeroIfNaN(MIN(1, size.height / (topRightRadius + bottomRightRadius)));
  const CGFloat leftScaleFactor = ABI6_0_0RCTZeroIfNaN(MIN(1, size.height / (topLeftRadius + bottomLeftRadius)));

  // Return scaled radii
  return (ABI6_0_0RCTCornerRadii){
    topLeftRadius * MIN(topScaleFactor, leftScaleFactor),
    topRightRadius * MIN(topScaleFactor, rightScaleFactor),
    bottomLeftRadius * MIN(bottomScaleFactor, leftScaleFactor),
    bottomRightRadius * MIN(bottomScaleFactor, rightScaleFactor),
  };
}

- (ABI6_0_0RCTBorderColors)borderColors
{
  return (ABI6_0_0RCTBorderColors){
    _borderTopColor ?: _borderColor,
    _borderLeftColor ?: _borderColor,
    _borderBottomColor ?: _borderColor,
    _borderRightColor ?: _borderColor,
  };
}

- (void)ReactABI6_0_0SetFrame:(CGRect)frame
{
  // If frame is zero, or below the threshold where the border radii can
  // be rendered as a stretchable image, we'll need to re-render.
  // TODO: detect up-front if re-rendering is necessary
  CGSize oldSize = self.bounds.size;
  [super ReactABI6_0_0SetFrame:frame];
  if (!CGSizeEqualToSize(self.bounds.size, oldSize)) {
    [self.layer setNeedsDisplay];
  }
}

- (void)displayLayer:(CALayer *)layer
{
  if (CGSizeEqualToSize(layer.bounds.size, CGSizeZero)) {
    return;
  }

  ABI6_0_0RCTUpdateShadowPathForView(self);

  const ABI6_0_0RCTCornerRadii cornerRadii = [self cornerRadii];
  const UIEdgeInsets borderInsets = [self bordersAsInsets];
  const ABI6_0_0RCTBorderColors borderColors = [self borderColors];

  BOOL useIOSBorderRendering =
  !ABI6_0_0RCTRunningInTestEnvironment() &&
  ABI6_0_0RCTCornerRadiiAreEqual(cornerRadii) &&
  ABI6_0_0RCTBorderInsetsAreEqual(borderInsets) &&
  ABI6_0_0RCTBorderColorsAreEqual(borderColors) &&
  _borderStyle == ABI6_0_0RCTBorderStyleSolid &&

  // iOS draws borders in front of the content whereas CSS draws them behind
  // the content. For this reason, only use iOS border drawing when clipping
  // or when the border is hidden.

  (borderInsets.top == 0 || CGColorGetAlpha(borderColors.top) == 0 || self.clipsToBounds);

  // iOS clips to the outside of the border, but CSS clips to the inside. To
  // solve this, we'll need to add a container view inside the main view to
  // correctly clip the subviews.

  if (useIOSBorderRendering) {
    layer.cornerRadius = cornerRadii.topLeft;
    layer.borderColor = borderColors.left;
    layer.borderWidth = borderInsets.left;
    layer.backgroundColor = _backgroundColor.CGColor;
    layer.contents = nil;
    layer.needsDisplayOnBoundsChange = NO;
    layer.mask = nil;
    return;
  }

  UIImage *image = ABI6_0_0RCTGetBorderImage(_borderStyle,
                                     layer.bounds.size,
                                     cornerRadii,
                                     borderInsets,
                                     borderColors,
                                     _backgroundColor.CGColor,
                                     self.clipsToBounds);

  layer.backgroundColor = NULL;

  if (image == nil) {
    layer.contents = nil;
    layer.needsDisplayOnBoundsChange = NO;
    return;
  }

  CGRect contentsCenter = ({
    CGSize size = image.size;
    UIEdgeInsets insets = image.capInsets;
    CGRectMake(
      insets.left / size.width,
      insets.top / size.height,
      1.0 / size.width,
      1.0 / size.height
    );
  });

  if (ABI6_0_0RCTRunningInTestEnvironment()) {
    const CGSize size = self.bounds.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    [image drawInRect:(CGRect){CGPointZero, size}];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    contentsCenter = CGRectMake(0, 0, 1, 1);
  }

  layer.contents = (id)image.CGImage;
  layer.contentsScale = image.scale;
  layer.needsDisplayOnBoundsChange = YES;
  layer.magnificationFilter = kCAFilterNearest;

  const BOOL isResizable = !UIEdgeInsetsEqualToEdgeInsets(image.capInsets, UIEdgeInsetsZero);
  if (isResizable) {
    layer.contentsCenter = contentsCenter;
  } else {
    layer.contentsCenter = CGRectMake(0.0, 0.0, 1.0, 1.0);
  }

  [self updateClippingForLayer:layer];
}

static BOOL ABI6_0_0RCTLayerHasShadow(CALayer *layer)
{
  return layer.shadowOpacity * CGColorGetAlpha(layer.shadowColor) > 0;
}

- (void)ReactABI6_0_0SetInheritedBackgroundColor:(UIColor *)inheritedBackgroundColor
{
  // Inherit background color if a shadow has been set, as an optimization
  if (ABI6_0_0RCTLayerHasShadow(self.layer)) {
    self.backgroundColor = inheritedBackgroundColor;
  }
}

static void ABI6_0_0RCTUpdateShadowPathForView(ABI6_0_0RCTView *view)
{
  if (ABI6_0_0RCTLayerHasShadow(view.layer)) {
    if (CGColorGetAlpha(view.backgroundColor.CGColor) > 0.999) {

      // If view has a solid background color, calculate shadow path from border
      const ABI6_0_0RCTCornerRadii cornerRadii = [view cornerRadii];
      const ABI6_0_0RCTCornerInsets cornerInsets = ABI6_0_0RCTGetCornerInsets(cornerRadii, UIEdgeInsetsZero);
      CGPathRef shadowPath = ABI6_0_0RCTPathCreateWithRoundedRect(view.bounds, cornerInsets, NULL);
      view.layer.shadowPath = shadowPath;
      CGPathRelease(shadowPath);

    } else {

      // Can't accurately calculate box shadow, so fall back to pixel-based shadow
      view.layer.shadowPath = nil;

      ABI6_0_0RCTLogWarn(@"View #%@ of type %@ has a shadow set but cannot calculate "
                 "shadow efficiently. Consider setting a background color to "
                 "fix this, or apply the shadow to a more specific component.",
                 view.ReactABI6_0_0Tag, [view class]);
    }
  }
}

- (void)updateClippingForLayer:(CALayer *)layer
{
  CALayer *mask = nil;
  CGFloat cornerRadius = 0;

  if (self.clipsToBounds) {

    const ABI6_0_0RCTCornerRadii cornerRadii = [self cornerRadii];
    if (ABI6_0_0RCTCornerRadiiAreEqual(cornerRadii)) {

      cornerRadius = cornerRadii.topLeft;

    } else {

      CAShapeLayer *shapeLayer = [CAShapeLayer layer];
      CGPathRef path = ABI6_0_0RCTPathCreateWithRoundedRect(self.bounds, ABI6_0_0RCTGetCornerInsets(cornerRadii, UIEdgeInsetsZero), NULL);
      shapeLayer.path = path;
      CGPathRelease(path);
      mask = shapeLayer;
    }
  }

  layer.cornerRadius = cornerRadius;
  layer.mask = mask;
}

#pragma mark Border Color

#define setBorderColor(side)                                \
  - (void)setBorder##side##Color:(CGColorRef)color          \
  {                                                         \
    if (CGColorEqualToColor(_border##side##Color, color)) { \
      return;                                               \
    }                                                       \
    CGColorRelease(_border##side##Color);                   \
    _border##side##Color = CGColorRetain(color);            \
    [self.layer setNeedsDisplay];                           \
  }

setBorderColor()
setBorderColor(Top)
setBorderColor(Right)
setBorderColor(Bottom)
setBorderColor(Left)

#pragma mark - Border Width

#define setBorderWidth(side)                    \
  - (void)setBorder##side##Width:(CGFloat)width \
  {                                             \
    if (_border##side##Width == width) {        \
      return;                                   \
    }                                           \
    _border##side##Width = width;               \
    [self.layer setNeedsDisplay];               \
  }

setBorderWidth()
setBorderWidth(Top)
setBorderWidth(Right)
setBorderWidth(Bottom)
setBorderWidth(Left)

#pragma mark - Border Radius

#define setBorderRadius(side)                     \
  - (void)setBorder##side##Radius:(CGFloat)radius \
  {                                               \
    if (_border##side##Radius == radius) {        \
      return;                                     \
    }                                             \
    _border##side##Radius = radius;               \
    [self.layer setNeedsDisplay];                 \
  }

setBorderRadius()
setBorderRadius(TopLeft)
setBorderRadius(TopRight)
setBorderRadius(BottomLeft)
setBorderRadius(BottomRight)

#pragma mark - Border Style

#define setBorderStyle(side)                           \
  - (void)setBorder##side##Style:(ABI6_0_0RCTBorderStyle)style \
  {                                                    \
    if (_border##side##Style == style) {               \
      return;                                          \
    }                                                  \
    _border##side##Style = style;                      \
    [self.layer setNeedsDisplay];                      \
  }

setBorderStyle()

- (void)dealloc
{
  CGColorRelease(_borderColor);
  CGColorRelease(_borderTopColor);
  CGColorRelease(_borderRightColor);
  CGColorRelease(_borderBottomColor);
  CGColorRelease(_borderLeftColor);
}

@end
