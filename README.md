# UIWebView-PeekingSupport

[UIWebView 与 3D Touch 的自定义交互](https://blog.yeatse.com/2016/10/08/using-3d-touch-with-uiwebview/)

A UIWebView category which helps you implement 3D touch on UIWebView as any other UIView.

## Usage

Simply drag `UIWebView+PeekingSupport.h` and `UIWebView+PeekingSupport.m` into your project, you can now call `- [UIViewController registerForPreviewingWithDelegate:sourceView:]` with UIWebView as any other view.
