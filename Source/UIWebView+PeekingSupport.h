//
//  UIWebView+PeekingSupport.h
//  WebViewCustomPeeking
//
//  Created by yeatse on 16/10/9.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (PeekingSupport)

- (void)yt_setUpPreviewGestureObserver;
- (void)yt_tearDownPreviewGestureObserver;

@end
