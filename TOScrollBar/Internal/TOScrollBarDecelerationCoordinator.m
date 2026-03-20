//
//  TOScrollBarDecelerationCoordinator.m
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

#import "TOScrollBarDecelerationCoordinator.h"
#import <QuartzCore/QuartzCore.h>

// Matches UIScrollViewDecelerationRateNormal (~0.998 per ms, which is ~0.92 per frame at 60fps)
static const CGFloat kDecelerationRate = 0.998f;
static const CGFloat kMinimumVelocity  = 1.0f;   // Stop threshold in content points/sec
static const CGFloat kMinimumHandleVelocity = 0.1f; // Minimum handle velocity to trigger deceleration
static const CFTimeInterval kStaleThreshold = 0.05;  // If finger rested this long before lifting, no deceleration

// Velocity tracking state
struct TOScrollBarVelocityState {
    CGFloat lastTouchY;
    CFTimeInterval lastTouchTime;
    CGFloat velocity;
};
typedef struct TOScrollBarVelocityState TOScrollBarVelocityState;

@interface TOScrollBarDecelerationCoordinator ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat contentVelocity;     // Scaled velocity in content points/sec
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, assign, readwrite) BOOL isDecelerating;

@end

@implementation TOScrollBarDecelerationCoordinator {
    TOScrollBarVelocityState _velocityState;
}

- (void)dealloc
{
    [_displayLink invalidate];
}

#pragma mark - Velocity Tracking -

- (void)beginTracking
{
    [self stop];
    _velocityState = (TOScrollBarVelocityState){0};
}

- (void)trackTouchPoint:(CGFloat)touchY
{
    CFTimeInterval now = CACurrentMediaTime();
    if (_velocityState.lastTouchTime > 0) {
        CFTimeInterval dt = now - _velocityState.lastTouchTime;
        if (dt > 0) {
            _velocityState.velocity = (touchY - _velocityState.lastTouchY) / dt;
        }
    }
    _velocityState.lastTouchY = touchY;
    _velocityState.lastTouchTime = now;
}

- (BOOL)endTrackingWithScrollView:(UIScrollView *)scrollView
                      trackHeight:(CGFloat)trackHeight
                     handleHeight:(CGFloat)handleHeight
{
    // If the finger rested before lifting, zero out the velocity
    CFTimeInterval timeSinceLastTouch = CACurrentMediaTime() - _velocityState.lastTouchTime;
    if (timeSinceLastTouch > kStaleThreshold) {
        _velocityState.velocity = 0.0f;
    }

    if (fabs(_velocityState.velocity) <= kMinimumHandleVelocity) {
        return NO;
    }

    [self startWithScrollView:scrollView
               handleVelocity:_velocityState.velocity
                  trackHeight:trackHeight
                 handleHeight:handleHeight];
    return _isDecelerating;
}

#pragma mark - Deceleration Animation -

- (void)startWithScrollView:(UIScrollView *)scrollView
             handleVelocity:(CGFloat)handleVelocity
                trackHeight:(CGFloat)trackHeight
               handleHeight:(CGFloat)handleHeight
{
    self.scrollView = scrollView;

    // Scale velocity from handle space to scroll view content space.
    // The handle traverses (trackHeight - handleHeight) points while the content
    // traverses its full scrollable range, so the ratio between them is the scale factor.
    CGFloat handleRange = trackHeight - handleHeight;
    if (handleRange < 1.0f) { return; }

    UIEdgeInsets inset = scrollView.adjustedContentInset;
    CGFloat scrollableHeight = (scrollView.contentSize.height + inset.top + inset.bottom) - scrollView.frame.size.height;
    if (scrollableHeight < 1.0f) { return; }

    CGFloat scale = scrollableHeight / handleRange;
    self.contentVelocity = handleVelocity * scale;

    // Don't bother if the scaled velocity is tiny
    if (fabs(self.contentVelocity) < kMinimumVelocity) { return; }

    self.isDecelerating = YES;
    self.lastTimestamp = 0;

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)displayLink
{
    // Use the first frame just to capture the timestamp
    if (_lastTimestamp == 0) {
        _lastTimestamp = displayLink.timestamp;
        return;
    }

    CFTimeInterval now = displayLink.timestamp;
    CFTimeInterval dt = now - _lastTimestamp;
    _lastTimestamp = now;

    // Apply exponential decay: v *= rate^(dt*1000)
    // This makes deceleration frame-rate independent
    _contentVelocity *= pow(kDecelerationRate, dt * 1000.0);

    // Stop when velocity is negligible
    if (fabs(_contentVelocity) < kMinimumVelocity) {
        [self stop];
        return;
    }

    UIScrollView *scrollView = self.scrollView;
    if (scrollView == nil) {
        [self stop];
        return;
    }

    // Compute new content offset
    UIEdgeInsets inset = scrollView.adjustedContentInset;
    CGPoint offset = scrollView.contentOffset;
    offset.y += _contentVelocity * dt;

    // Clamp to scrollable bounds
    CGFloat minY = -inset.top;
    CGFloat maxY = scrollView.contentSize.height + inset.bottom - scrollView.frame.size.height;
    if (offset.y <= minY) {
        offset.y = minY;
        [self stop];
    } else if (offset.y >= maxY) {
        offset.y = maxY;
        [self stop];
    }

    [scrollView setContentOffset:offset animated:NO];
}

- (void)stop
{
    if (!_isDecelerating) { return; }

    [self.displayLink invalidate];
    self.displayLink = nil;
    self.contentVelocity = 0;
    self.isDecelerating = NO;

    if (self.completionHandler) {
        self.completionHandler();
    }
}

@end
