//
//  TOScrollBar.h
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

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, TOScrollBarStyle) {
    TOScrollBarStyleDefault,
    TOScrollBarStyleDark
};

@interface TOScrollBar : UIView

/** The inset, in points of the track from the edge of the scroll view */
@property (nonatomic, assign) CGFloat edgeInset;

/** The tint color of the track */
@property (nonatomic, strong) UIColor *trackTintColor;

/** The tint color of the handle (Defaults to the system tint color) */
@property (nonatomic, strong) UIColor *handleTintColor;

/** The user is currently dragging the handle */
@property (nonatomic, assign, readonly) BOOL dragging;

/** 
 Creates a new instance of the scroll bar view 
 
 @param style The initial style of the scroll bar upon creation
 */
- (instancetype)initWithStyle:(TOScrollBarStyle)style;

/**
 Adds the scroll bar to a scroll view
 
 @param scrollView The scroll view that will receive this scroll bar
 */
- (void)addToScrollView:(UIScrollView *)scrollView;

/**
 Removes the scroll bar from the scroll view and resets the scroll view's state
 */
- (void)removeFromScrollView;

/**
 Shows or hides the scroll bar from the scroll view with an optional animation
 */
- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;

@end
