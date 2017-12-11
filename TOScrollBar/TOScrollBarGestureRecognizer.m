//
//  TOScrollBarGestureRecognizer.m
//  TOScrollBarExample
//
//  Created by Tim Oliver on 12/9/17.
//  Copyright © 2017 Tim Oliver. All rights reserved.
//

#import "TOScrollBarGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

#import "TOScrollBar.h"

@interface TOScrollBarGestureRecognizer ()

@property (nonatomic, readonly) TOScrollBar *scrollBar; // The scroll bar this recognizer is attached to

@end

@implementation TOScrollBarGestureRecognizer

#pragma mark - Gesture Recognizer Filtering -
- (BOOL)canPreventGestureRecognizer:(UIGestureRecognizer *)preventedGestureRecognizer
{
    UIView *view = preventedGestureRecognizer.view;
    if ([view isEqual:self.scrollBar.scrollView]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Touch Interaction -
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateBegan;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateChanged;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateEnded;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    self.state = UIGestureRecognizerStateCancelled;
}

#pragma mark - Accessors -
- (TOScrollBar *)scrollBar
{
    if ([self.view isKindOfClass:[TOScrollBar class]] == NO) {
        return nil;
    }

    return (TOScrollBar *)self.view;
}

@end
