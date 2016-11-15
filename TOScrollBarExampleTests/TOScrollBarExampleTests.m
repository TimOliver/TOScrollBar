//
//  TOScrollBarExampleTests.m
//  TOScrollBarExampleTests
//
//  Created by Tim Oliver on 15/11/16.
//  Copyright © 2016 Tim Oliver. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TOScrollBar.h"

@interface TOScrollBarExampleTests : XCTestCase

@end

@implementation TOScrollBarExampleTests

- (void)testViewCreation {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    TOScrollBar *scrollBar = [[TOScrollBar alloc] initWithStyle:TOScrollBarStyleDefault];
    [scrollView to_addScrollBar:scrollBar];
    XCTAssert(scrollBar.scrollView != nil);
    [scrollView to_removeScrollbar];
}


@end
