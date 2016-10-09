//
//  ViewController.m
//  WebViewCustomPeeking
//
//  Created by yeatse on 16/10/9.
//  Copyright © 2016年 Yeatse. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()<UIWebViewDelegate, UIViewControllerPreviewingDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerForPreviewingWithDelegate:self sourceView:self.webView];
    self.webView.allowsLinkPreview = NO;
    if (!self.initialURLString) {
        self.initialURLString = @"https://github.com/yeatse";
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.initialURLString]]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

#pragma mark - UIViewControllerPreviewingDelegate

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    CGFloat verticalOffset = self.webView.scrollView.contentInset.top;
    NSString* script = [NSString stringWithFormat:@"function getRect(){var r = document.elementFromPoint(%f,%f).getBoundingClientRect();\
                        return '{{'+r.left+','+r.top+'},{'+r.width+','+r.height+'}}'};getRect()", location.x, location.y - verticalOffset];
    NSString* result = [self.webView stringByEvaluatingJavaScriptFromString:script];
    CGRect rect = CGRectFromString(result);
    if (CGRectIsNull(rect)) {
        return nil;
    } else {
        previewingContext.sourceRect = CGRectOffset(rect, 0, verticalOffset);
        ViewController* viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"Web View Controller"];
        return viewController;
    }
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit {
    [self showViewController:viewControllerToCommit sender:self];
}

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    UIPreviewAction* action1 = [UIPreviewAction actionWithTitle:@"喵喵喵" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
    }];
    UIPreviewAction* action2 = [UIPreviewAction actionWithTitle:@"汪汪汪" style:UIPreviewActionStyleSelected handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
    }];
    UIPreviewAction* action3 = [UIPreviewAction actionWithTitle:@"嘿嘿嘿" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
    }];
    return @[action1, action2, action3];
}

@end
