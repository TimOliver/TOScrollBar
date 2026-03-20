//
//  TOScrollBarDecelerationCoordinator.h
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
 Coordinates velocity tracking during scroll bar handle dragging and drives
 UIScrollView-style inertial deceleration on release. Tracks touch positions
 to compute handle velocity, scales it to the scroll view's content space,
 and animates via CADisplayLink with exponential decay.
 */
@interface TOScrollBarDecelerationCoordinator : NSObject

/** Whether a deceleration animation is currently in progress. */
@property (nonatomic, readonly) BOOL isDecelerating;

/** Called when deceleration finishes (either naturally or via stop). */
@property (nonatomic, copy, nullable) void (^completionHandler)(void);

/** Resets velocity tracking state. Call when a new drag gesture begins. */
- (void)beginTracking;

/** Records a touch position for velocity calculation. Call on each gesture move. */
- (void)trackTouchPoint:(CGFloat)touchY;

/**
 Ends tracking and starts deceleration if the handle was flicked.

 @param scrollView The scroll view whose contentOffset will be driven.
 @param trackHeight The total height of the scroll bar track.
 @param handleHeight The height of the scroll bar handle.
 @return YES if deceleration was started, NO if velocity was too low.
 */
- (BOOL)endTrackingWithScrollView:(UIScrollView *)scrollView
                      trackHeight:(CGFloat)trackHeight
                     handleHeight:(CGFloat)handleHeight;

/** Immediately stops any in-progress deceleration. */
- (void)stop;

@end

NS_ASSUME_NONNULL_END
