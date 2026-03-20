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

// Bounce-back: two-phase overshoot + settle
static const CGFloat kRubberBandCoefficient = 0.25f;  // Tight overshoot (lower = less travel past boundary)
static const CGFloat kMaxOvershoot = 120.0f;            // Cap overshoot in points
static const CFTimeInterval kOvershootDuration = 0.15; // Phase 1: quick deceleration to peak
static const CFTimeInterval kSettleDuration = 0.55;    // Phase 2: slow ease back to boundary

// Velocity tracking state
struct TOScrollBarVelocityState {
    CGFloat lastTouchY;
    CFTimeInterval lastTouchTime;
    CGFloat velocity;
};
typedef struct TOScrollBarVelocityState TOScrollBarVelocityState;

// Bounce-back state
struct TOScrollBarBounceState {
    BOOL active;
    CGFloat boundary;         // The edge position to return to
    CGFloat peakOvershoot;    // Signed distance past boundary at peak
    CFTimeInterval startTime; // Timestamp when bounce phase began
};
typedef struct TOScrollBarBounceState TOScrollBarBounceState;

@interface TOScrollBarDecelerationCoordinator ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CGFloat contentVelocity;     // Scaled velocity in content points/sec
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, assign, readwrite) BOOL isDecelerating;
@property (nonatomic, assign) CGFloat topInset;            // Cached top inset from the scroll bar

@end

@implementation TOScrollBarDecelerationCoordinator {
    TOScrollBarVelocityState _velocityState;
    TOScrollBarBounceState _bounceState;
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
                         topInset:(CGFloat)topInset
{
    // If the finger rested before lifting, zero out the velocity
    CFTimeInterval timeSinceLastTouch = CACurrentMediaTime() - _velocityState.lastTouchTime;
    if (timeSinceLastTouch > kStaleThreshold) {
        _velocityState.velocity = 0.0f;
    }

    if (fabs(_velocityState.velocity) <= kMinimumHandleVelocity) {
        return NO;
    }

    self.topInset = topInset;
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

    CGFloat bottomInset = scrollView.adjustedContentInset.bottom;
    CGFloat scrollableHeight = (scrollView.contentSize.height + _topInset + bottomInset) - scrollView.frame.size.height;
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

    UIScrollView *scrollView = self.scrollView;
    if (scrollView == nil) {
        [self stop];
        return;
    }

    // Bounce-back phase: two-phase overshoot + settle
    // Both phases use a critically damped spring curve for fluid motion:
    // springEase(p, β) = (1 - exp(-β·p)·(1 + β·p)) / (1 - exp(-β)·(1 + β))
    if (_bounceState.active) {
        CFTimeInterval t = now - _bounceState.startTime;
        CGFloat x;

        if (t < kOvershootDuration) {
            // Phase 1: quick spring ease-out to peak overshoot
            CGFloat p = t / kOvershootDuration;
            CGFloat beta = 6.0;
            CGFloat eased = (1.0 - exp(-beta * p) * (1.0 + beta * p))
                          / (1.0 - exp(-beta) * (1.0 + beta));
            x = _bounceState.peakOvershoot * eased;
        } else {
            // Phase 2: slow spring ease-out back to boundary
            CGFloat settleT = t - kOvershootDuration;
            if (settleT >= kSettleDuration) {
                [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, _bounceState.boundary) animated:NO];
                [self stop];
                return;
            }
            CGFloat p = settleT / kSettleDuration;
            CGFloat beta = 5.0;
            CGFloat eased = (1.0 - exp(-beta * p) * (1.0 + beta * p))
                          / (1.0 - exp(-beta) * (1.0 + beta));
            x = _bounceState.peakOvershoot * (1.0 - eased);
        }

        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, _bounceState.boundary + x) animated:NO];
        return;
    }

    // Deceleration phase: exponential decay
    _contentVelocity *= pow(kDecelerationRate, dt * 1000.0);

    if (fabs(_contentVelocity) < kMinimumVelocity) {
        [self stop];
        return;
    }

    CGPoint offset = scrollView.contentOffset;
    offset.y += _contentVelocity * dt;

    // Check scrollable bounds — transition to bounce if crossed
    CGFloat minY = -_topInset;
    CGFloat maxY = scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - scrollView.frame.size.height;
    if (offset.y <= minY) {
        [self startBounceAtBoundary:minY inScrollView:scrollView atTime:now];
        return;
    } else if (offset.y >= maxY) {
        [self startBounceAtBoundary:maxY inScrollView:scrollView atTime:now];
        return;
    }

    [scrollView setContentOffset:offset animated:NO];
}

- (void)startBounceAtBoundary:(CGFloat)boundary inScrollView:(UIScrollView *)scrollView atTime:(CFTimeInterval)now
{
    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, boundary) animated:NO];

    // Calculate overshoot using rubber band formula, capped to kMaxOvershoot
    CGFloat dCoeff = 1000.0 * log(kDecelerationRate);
    CGFloat remainingDistance = fabs(-_contentVelocity / dCoeff);
    CGFloat viewHeight = scrollView.frame.size.height;
    CGFloat overshoot = (1.0 - (1.0 / ((remainingDistance * kRubberBandCoefficient / viewHeight) + 1.0))) * viewHeight;
    overshoot = fmin(overshoot, kMaxOvershoot);

    if (overshoot < 0.5) {
        [self stop];
        return;
    }

    // Sign matches scroll direction
    CGFloat sign = (_contentVelocity > 0) ? 1.0 : -1.0;

    _bounceState = (TOScrollBarBounceState){
        .active = YES,
        .boundary = boundary,
        .peakOvershoot = overshoot * sign,
        .startTime = now
    };
}

- (void)stop
{
    if (!_isDecelerating) { return; }

    [self.displayLink invalidate];
    self.displayLink = nil;
    self.contentVelocity = 0;
    self.isDecelerating = NO;
    _bounceState = (TOScrollBarBounceState){0};
}

@end
