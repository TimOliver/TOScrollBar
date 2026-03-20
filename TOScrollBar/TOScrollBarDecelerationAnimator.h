//
//  TOScrollBarDecelerationAnimator.h
//
//  Copyright 2016-2026 Timothy Oliver. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to
//  deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
//  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Drives UIScrollView-style inertial deceleration on a scroll view's content offset.
 Takes a velocity from the scroll bar handle (in handle points/sec), scales it to
 the scroll view's content space, and animates via CADisplayLink with exponential decay.
 */
@interface TOScrollBarDecelerationAnimator : NSObject

/** Whether a deceleration animation is currently in progress. */
@property (nonatomic, readonly) BOOL isDecelerating;

/** Called when deceleration finishes (either naturally or via stop). */
@property (nonatomic, copy, nullable) void (^completionHandler)(void);

/**
 Start a deceleration animation on the given scroll view.

 @param scrollView The scroll view whose contentOffset will be driven.
 @param handleVelocity The velocity of the scroll bar handle in points/sec (handle coordinate space).
 @param trackHeight The total height of the scroll bar track.
 @param handleHeight The height of the scroll bar handle.
 */
- (void)startWithScrollView:(UIScrollView *)scrollView
             handleVelocity:(CGFloat)handleVelocity
                trackHeight:(CGFloat)trackHeight
               handleHeight:(CGFloat)handleHeight;

/** Immediately stops the deceleration animation. */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
