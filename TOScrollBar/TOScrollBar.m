//
//  TOScrollBar.m
//
//  Copyright 2016 Timothy Oliver. All rights reserved.
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

#import "TOScrollBar.h"

/** Default values for the scroll bar */
static const CGFloat kTOScrollBarTrackWidth     = 2.0f;     // The default width of the scrollable space indicator
static const CGFloat kTOScrollBarHandleWidth    = 4.0f;     // The default width of the handle control
static const CGFloat kTOScrollBarDefaultEdgeInset      = 8.0f;     // The distance from the edge of the view to the center of the track
static const CGFloat kTOScrollBarHandleMinDefaultHeight = 64.0f;   // The minimum usable size to which the handle can shrink
static const CGFloat kTOScrollBarHandleMinScrollHeight = 6.0f;     // The minimum size the handle may shrink when rubber banding
static const CGFloat kTOScrollBarWidth          = 44.0f;    // The width of this control (44 is minimum recommended tapping space)
static const CGFloat kTOScrollBarVerticalPadding = 20.0f;   // The default padding at the top and bottom of the view

/************************************************************************/

// A struct to hold the scroll view's previous state before this bar was applied
struct TOScrollBarScrollViewState {
    BOOL showsVerticalScrollIndicator;
};
typedef struct TOScrollBarScrollViewState TOScrollBarScrollViewState;

/************************************************************************/

@interface TOScrollBar () <UIGestureRecognizerDelegate> {
    TOScrollBarScrollViewState _scrollViewState;
}

@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, strong) UIImageView *trackView;  // The track indicating the scrollable distance
@property (nonatomic, strong) UIImageView *handleView; // The handle that may be dragged in the scroll bar

@property (nonatomic, assign, readwrite) BOOL dragging;           // The user is presently dragging the handle
@property (nonatomic, assign) CGFloat yOffset;         // The offset from the center of the thumb

@property (nonatomic, assign) BOOL disabled;           // Disabled when there's no point in displaying

- (void)setUp;
- (void)configureScrollView:(UIScrollView *)scrollView;
- (void)restoreScrollView:(UIScrollView *)scrollView;

- (void)updateStateForScrollView;
- (void)layoutInScrollView;
- (CGFloat)heightOfHandleForContentSize;

- (void)setScrollYOffsetForHandleYOffset:(CGFloat)yOffset;

+ (UIImage *)verticalCapsuleImageWithWidth:(CGFloat)width;

@end

/************************************************************************/

@implementation TOScrollBar

- (void)setUp
{
    if (!self.trackView) {
        self.trackView = [[UIImageView alloc] initWithImage:[TOScrollBar verticalCapsuleImageWithWidth:kTOScrollBarTrackWidth]];
        self.trackView.tintColor = [UIColor colorWithWhite:0.0f alpha:0.1f];
        [self addSubview:self.trackView];
    }
    
    if (!self.handleView) {
        self.handleView = [[UIImageView alloc] initWithImage:[TOScrollBar verticalCapsuleImageWithWidth:kTOScrollBarHandleWidth]];
        [self addSubview:self.handleView];
    }
}

- (void)dealloc
{
    [self restoreScrollView:self.scrollView];
}

- (void)configureScrollView:(UIScrollView *)scrollView
{
    if (scrollView == nil) {
        return;
    }
    
    // Make a copy of the scroll view's state and then configure
    _scrollViewState.showsVerticalScrollIndicator = self.scrollView.showsVerticalScrollIndicator;
    scrollView.showsVerticalScrollIndicator = NO;
    
    //Key-value Observers
    [scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [scrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)restoreScrollView:(UIScrollView *)scrollView
{
    if (scrollView == nil) {
        return;
    }
    
    // Restore the scroll view's state
    scrollView.showsVerticalScrollIndicator = _scrollView.showsVerticalScrollIndicator;
    
    //remove the observers
    [scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [scrollView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    [self setUp];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [self updateStateForScrollView];
    [self layoutInScrollView];
    [self setNeedsLayout];
}

- (CGFloat)heightOfHandleForContentSize
{
    if (self.scrollView == nil) {
        return kTOScrollBarHandleMinDefaultHeight;
    }

    CGFloat heightRatio = self.scrollView.frame.size.height / self.scrollView.contentSize.height;
    CGFloat height = self.frame.size.height * heightRatio;
    
    return MAX(floorf(height), kTOScrollBarHandleMinDefaultHeight);
}

- (void)layoutSubviews
{
    // The frame of the track
    CGRect frame = CGRectZero;
    frame.size.width = kTOScrollBarTrackWidth;
    frame.size.height = self.frame.size.height;
    frame.origin.x = floorf((self.frame.size.width - kTOScrollBarTrackWidth) * 0.5f);
    self.trackView.frame = CGRectIntegral(frame);
    
    // Don't handle automatic layout when dragging; we'll do that manually elsewhere
    if (self.dragging || self.disabled) {
        return;
    }
    
    // The frame of the handle
    frame = CGRectZero;
    frame.size.width = kTOScrollBarHandleWidth;
    frame.size.height = [self heightOfHandleForContentSize];
    frame.origin.x = ceilf((self.frame.size.width - kTOScrollBarHandleWidth) * 0.5f);
    
    // Work out the y offset of the handle
    UIEdgeInsets contentInset = self.scrollView.contentInset;
    CGPoint contentOffset     = self.scrollView.contentOffset;
    CGSize contentSize        = self.scrollView.contentSize;
    CGRect scrollViewFrame    = self.scrollView.frame;
    
    CGFloat scrollableHeight = (contentSize.height + contentInset.top + contentInset.bottom) - scrollViewFrame.size.height;
    CGFloat scrollProgress = (contentOffset.y + contentInset.top) / scrollableHeight;
    frame.origin.y = (self.frame.size.height - frame.size.height) * scrollProgress;
                       
    // If the scroll view expanded beyond its scrollable range, shrink the handle to match the rubber band effect
    if (contentOffset.y < -contentInset.top) { // The top
        frame.size.height -= (-contentOffset.y - contentInset.top);
        frame.size.height = MAX(frame.size.height, kTOScrollBarHandleMinScrollHeight);
    }
    else if (contentOffset.y + scrollViewFrame.size.height > contentSize.height + contentInset.bottom) { // The bottom
        CGFloat adjustedContentOffset = contentOffset.y + scrollViewFrame.size.height;
        CGFloat delta = adjustedContentOffset - (contentSize.height + contentInset.bottom);
        frame.size.height -= delta;
        frame.size.height = MAX(frame.size.height, kTOScrollBarHandleMinScrollHeight);
        frame.origin.y = self.frame.size.height - frame.size.height;
    }
    
    // Clamp to the bounds of the frame
    frame.origin.y = MAX(frame.origin.y, 0.0f);
    frame.origin.y = MIN(frame.origin.y, (self.frame.size.height - frame.size.height));
    
    self.handleView.frame = frame;
}

- (void)updateStateForScrollView
{
    BOOL disable = NO;
    
    CGRect frame = self.scrollView.frame;
    CGSize contentSize = self.scrollView.contentSize;
    
    if (contentSize.height < frame.size.height) {
        disable = YES;
    }
    
    self.disabled = disable;
    
    self.handleView.hidden = self.disabled;
}

- (void)layoutInScrollView
{
    CGRect scrollViewFrame = self.scrollView.frame;
    UIEdgeInsets insets = self.scrollView.contentInset;
    CGPoint contentOffset = self.scrollView.contentOffset;
    
    scrollViewFrame.size.height -= (insets.top + insets.bottom);
    CGFloat height = scrollViewFrame.size.height - (kTOScrollBarVerticalPadding * 2);
    
    CGRect frame = CGRectZero;
    frame.size.width = kTOScrollBarWidth;
    frame.size.height = height;
    frame.origin.x = scrollViewFrame.size.width - kTOScrollBarWidth;
    
    frame.origin.y = (scrollViewFrame.size.height - frame.size.height) * 0.5f;
    frame.origin.y += contentOffset.y;
    frame.origin.y += self.scrollView.contentInset.top;
    
    self.frame = frame;
}

- (void)setScrollYOffsetForHandleYOffset:(CGFloat)yOffset
{
    CGFloat heightRange = self.trackView.frame.size.height - self.handleView.frame.size.height;
    yOffset = MAX(0.0f, yOffset);
    yOffset = MIN(heightRange, yOffset);
    
    CGFloat positionRatio = yOffset / heightRange;
    
    CGRect frame = self.scrollView.frame;
    UIEdgeInsets inset = self.scrollView.contentInset;
    CGSize contentSize = self.scrollView.contentSize;
    
    CGFloat totalScrollSize = (contentSize.height + inset.top + inset.bottom) - frame.size.height;
    CGFloat scrollOffset = totalScrollSize * positionRatio;
    scrollOffset -= inset.top;
    
    CGPoint contentOffset = self.scrollView.contentOffset;
    contentOffset.y = scrollOffset;
    
    [self.scrollView setContentOffset:contentOffset animated:NO];
}

- (void)addToScrollView:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        return;
    }
    
    // Restore the previous scroll view
    [self restoreScrollView:self.scrollView];
    // Assign the new scroll view
    self.scrollView = scrollView;
    // Apply the observers/settings to the new scroll vie
    [self configureScrollView:scrollView];
    
    // Add the scroll bar to the scroll view's content view
    [self.scrollView addSubview:self];
    
    // Begin layout
    [self layoutInScrollView];
}

#pragma mark - User Interaction -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.disabled) {
        return;
    }
    
    self.scrollView.scrollEnabled = NO;
    self.dragging = YES;
    
    // Derive the touch from the scroll view as this view is moving up and down the scroll view
    CGPoint touchPoint = [touches.anyObject locationInView:self];
    
    // Check if the user tapped inside the handle
    CGRect handleFrame = self.handleView.frame;
    if (touchPoint.y > (handleFrame.origin.y - 20) &&
        touchPoint.y < handleFrame.origin.y + (handleFrame.size.height + 20))
    {
        self.yOffset = (touchPoint.y - handleFrame.origin.y);
        return;
    }
    
    // User tapped somewhere else, animate the handle to that point
    CGFloat halfHeight = (handleFrame.size.height * 0.5f);
    
    CGFloat destinationYOffset = touchPoint.y - halfHeight;
    destinationYOffset = MAX(0.0f, destinationYOffset);
    destinationYOffset = MIN(self.frame.size.height - halfHeight, destinationYOffset);
    
    self.yOffset = (touchPoint.y - destinationYOffset);
    handleFrame.origin.y = destinationYOffset;
    
    [UIView animateWithDuration:0.2f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.1f options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.handleView.frame = handleFrame;
                     } completion:nil];
    
    [self setScrollYOffsetForHandleYOffset:destinationYOffset];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.disabled) {
        return;
    }
    
    // Get the point that moved
    CGPoint touchPoint = [touches.anyObject locationInView:self];
   
    CGFloat delta = 0.0f;
    
    // Apply the updated Y value plus the original offset
    CGRect handleFrame = self.handleView.frame;
    delta = handleFrame.origin.y;
    handleFrame.origin.y = touchPoint.y - self.yOffset;
    handleFrame.origin.y = MAX(handleFrame.origin.y, 0.0f);
    handleFrame.origin.y = MIN(handleFrame.origin.y, self.trackView.frame.size.height - handleFrame.size.height);
    self.handleView.frame = handleFrame;
    
    delta -= handleFrame.origin.y;
    delta = fabs(delta);
    
    // If the user is doing really granualar swipes, animate the scrolling
    // so it's easier to track the scroll content
    BOOL animate = (delta < 3.0f);
    void (^offsetBlock)() = ^{ [self setScrollYOffsetForHandleYOffset:handleFrame.origin.y]; };
    
    // Update the scroll view without animation
    if (!animate) {
        offsetBlock();
        return;
    }
    
    // Animate
    [UIView animateWithDuration:0.3f
                          delay:0.0f
         usingSpringWithDamping:1.0f
          initialSpringVelocity:0.1f
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:offsetBlock
                     completion:nil];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.scrollView.scrollEnabled = YES;
    self.dragging = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.scrollView.scrollEnabled = YES;
    self.dragging = NO;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *result = [super hitTest:point withEvent:event];
    
    if (self.disabled || self.dragging) {
        return result;
    }
    
    // If the user comes in swiping, the scroll view will automatically
    // pick up that event unless we explicitly disable it
    
    self.scrollView.scrollEnabled = (result != self);
    return result;
}

#pragma mark - Accessors -
- (CGFloat)edgeInset
{
    if (_edgeInset < FLT_EPSILON) {
        _edgeInset = kTOScrollBarDefaultEdgeInset;
    }
    
    return _edgeInset;
}

#pragma mark - Image Generation -
+ (UIImage *)verticalCapsuleImageWithWidth:(CGFloat)width
{
    UIImage *image = nil;
    CGFloat radius = width * 0.5f;
    CGRect frame = (CGRect){0, 0, width+1, width+1};
    
    UIGraphicsBeginImageContextWithOptions(frame.size, NO, 0.0f);
    [[UIBezierPath bezierPathWithRoundedRect:frame cornerRadius:radius] fill];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(radius, radius, radius, radius) resizingMode:UIImageResizingModeStretch];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    return image;
}

@end
