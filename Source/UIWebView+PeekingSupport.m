//
//  UIWebView+PeekingSupport.m
//  WebViewCustomPeeking
//
//  Created by yeatse on 16/10/9.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "UIWebView+PeekingSupport.h"
#import <objc/runtime.h>

static char kObservingState;

static NSString* const RevealGestureRecognizer = @"RevealGestureRecognizer"; //  For KVO observing
static NSString* const PreviewGestureRecognizer = @"PreviewGestureRecognizer"; // For requirement setting

static void SwizzleSelectorsInClass(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@interface YTWebViewPreviewGestureObserver : NSObject

@property (nonatomic) CGPoint location;

- (instancetype)initWithWebView:(UIWebView*)webView;

@end

@implementation YTWebViewPreviewGestureObserver {
    UIWebView* __weak _webView;
    BOOL _shouldEmitSingleTapWhenTouchingEnd;
}

- (instancetype)initWithWebView:(UIWebView *)webView {
    self = [super init];
    if (self) {
        _webView = webView;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == &kObservingState) {
        UIGestureRecognizerState state = [change[NSKeyValueChangeNewKey] integerValue];
        switch (state) {
            case UIGestureRecognizerStateBegan:
                _shouldEmitSingleTapWhenTouchingEnd = YES;
                break;
            case UIGestureRecognizerStateChanged:
                _shouldEmitSingleTapWhenTouchingEnd = NO;
                break;
            case UIGestureRecognizerStateEnded:
                if (_shouldEmitSingleTapWhenTouchingEnd) {
                    UIView* browserView = [_webView valueForKeyPath:@"internal.browserView"];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    self.location = [object locationInView:browserView];
                    [browserView performSelector:NSSelectorFromString(@"_singleTapRecognized:") withObject:self];
#pragma clang diagnostic pop
                }
                break;
            default:
                break;
        }
    }
}

@end

@implementation UIWebView (PeekingSupport)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwizzleSelectorsInClass(self, @selector(removeGestureRecognizer:), @selector(yt_removeGestureRecognizer:));
    });
}

- (NSObject *)yt_previewGestureObserver {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setYt_previewGestureObserver:(NSObject *)yt_previewGestureObserver {
    objc_setAssociatedObject(self, @selector(yt_previewGestureObserver), yt_previewGestureObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIGestureRecognizer*)yt_gestureRecognizerWithClassName:(NSString*)className {
    return [self.gestureRecognizers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [NSStringFromClass([evaluatedObject class]) containsString:className];
    }]].firstObject;
}

- (void)yt_setUpPreviewGestureObserver {
    [self yt_tearDownPreviewGestureObserver];
    
    NSObject* observer = [[YTWebViewPreviewGestureObserver alloc] initWithWebView:self];
    self.yt_previewGestureObserver = observer;
    
    UIGestureRecognizer* revealGesture = [self yt_gestureRecognizerWithClassName:RevealGestureRecognizer];
    [revealGesture addObserver:observer forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:&kObservingState];
    
    UIView* browserView = [self valueForKeyPath:@"internal.browserView"];
    NSArray* arr = @[@"singleTapGestureRecognizer", @"longPressGestureRecognizer", @"highlightLongPressGestureRecognizer"];
    UIGestureRecognizer* recognizer = [self yt_gestureRecognizerWithClassName:PreviewGestureRecognizer];
    for (NSString* key in arr) {
        [[browserView valueForKey:key] requireGestureRecognizerToFail:recognizer];
    }
}

- (void)yt_tearDownPreviewGestureObserver {
    NSObject* observer = self.yt_previewGestureObserver;
    if (observer) {
        UIGestureRecognizer* recognizer = [self yt_gestureRecognizerWithClassName:RevealGestureRecognizer];
        [recognizer removeObserver:observer forKeyPath:@"state"];
        self.yt_previewGestureObserver = nil;
    }
}

- (void)yt_removeGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if ([NSStringFromClass(gestureRecognizer.class) containsString:RevealGestureRecognizer]) {
        [self yt_tearDownPreviewGestureObserver];
    }
    [self yt_removeGestureRecognizer:gestureRecognizer];
}

@end


@interface UIViewController (WebViewPeekingSupport)

@end

@implementation UIViewController (WebViewPeekingSupport)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SwizzleSelectorsInClass(self, @selector(registerForPreviewingWithDelegate:sourceView:), @selector(yt_registerForPreviewingWithDelegate:sourceView:));
        SwizzleSelectorsInClass(self, @selector(unregisterForPreviewingWithContext:), @selector(yt_unregisterForPreviewingWithContext:));
    });
}

- (id<UIViewControllerPreviewing>)yt_registerForPreviewingWithDelegate:(id<UIViewControllerPreviewingDelegate>)delegate sourceView:(UIView *)sourceView {
    id<UIViewControllerPreviewing> result = [self yt_registerForPreviewingWithDelegate:delegate sourceView:sourceView];
    if ([sourceView isKindOfClass:[UIWebView class]]) {
        [(UIWebView*)sourceView yt_setUpPreviewGestureObserver];
    }
    return result;
}

- (void)yt_unregisterForPreviewingWithContext:(id<UIViewControllerPreviewing>)previewing {
    if ([[previewing sourceView] isKindOfClass:[UIWebView class]]) {
        [(UIWebView*)[previewing sourceView] yt_tearDownPreviewGestureObserver];
    }
    [self yt_unregisterForPreviewingWithContext:previewing];
}

@end
