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

static const CGFloat kTOScrollBarTrackWidth     = 1.0f;     // The default width of the scrollable space indicator
static const CGFloat kTOScrollBarHandleWidth    = 3.0f;     // The default width of the handle control
static const CGFloat kTOScrollBarRightMargin    = 8.0f;     // The distance from the right side of the view to the center of the track
static const CGFloat kTOScrollBarHandleMinHeight = 70.0f;   // The minimum size the handle may shrink to
static const CGFloat kTOScrollBarWidth          = 20.0f;    // The width of this control (44 is minimum recommended tapping space)
static const CGFloat kTOScrollBarVerticalPadding = 20.0f;   // The default padding at the top and bottom of the view

@interface TOScrollBar () <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIScrollView *scrollView;

@property (nonatomic, strong) UIImageView *trackView;  // The track indicating the scrollable distance
@property (nonatomic, strong) UIImageView *handleView; // The handle that may be dragged in the scroll bar

@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;

- (void)setUp;
- (void)layoutInScrollView;

+ (UIImage *)verticalCapsuleImageWithWidth:(CGFloat)width;

@end

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

- (void)layoutSubviews
{
    CGRect frame = CGRectZero;
    frame.size.width = kTOScrollBarTrackWidth;
    frame.size.height = self.frame.size.height;
    frame.origin.x = (self.frame.size.width - kTOScrollBarTrackWidth) * 0.5f;
    self.trackView.frame = CGRectIntegral(frame);
    
    frame = CGRectZero;
    frame.size.width = kTOScrollBarHandleWidth;
    frame.size.height = 50.0f;
    frame.origin.x = (self.frame.size.width - kTOScrollBarHandleWidth) * 0.5f;
    self.handleView.frame = CGRectIntegral(frame);
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

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    [self setUp];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    [self layoutInScrollView];
}

- (void)addToScrollView:(UIScrollView *)scrollView
{
    if (scrollView == self.scrollView) {
        return;
    }
    
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
    [self.scrollView removeObserver:self forKeyPath:@"frame"];
    self.scrollView = scrollView;
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    [self.scrollView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    self.scrollView.showsVerticalScrollIndicator = NO;
    
    [self.scrollView addSubview:self];
    
    //[self.scrollView.panGestureRecognizer requireGestureRecognizerToFail:self.panGestureRecognizer];
    [self layoutInScrollView];
}

#pragma mark - Gesture Recognizer Delegate -
- (BOOL)touchesShouldBegin:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view
{
    return NO;
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
