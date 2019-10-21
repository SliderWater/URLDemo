//
//  DemoViewController.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/11/30.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "DemoViewController.h"
#import "DownloadURLListController.h"
#import <WebKit/WebKit.h>
#import "DownloadListController.h"
#import "FileListController.h"

@interface DemoViewController () <WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *hud;
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSMutableArray *urlArray;
@property (nonatomic, copy) NSString *webTitle;

@end

@implementation DemoViewController

- (void)dealloc
{
    self.wkWebView.navigationDelegate = nil;
    self.wkWebView = nil;
    self.webView.delegate = nil;
}

- (NSMutableArray *)urlArray {
    if (!_urlArray) {
        _urlArray = [[NSMutableArray alloc] init];
    }
    return _urlArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareNavigationItems];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestURLChanged:) name:@"com.xyzdm123.demo.loading_url" object:nil];
    [self prepareWKWebView];
    NSString *urlString = self.urlString.length > 0 ? self.urlString : @"https://www.ku6.com";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *urlReq = [NSURLRequest requestWithURL:url];
    [self.wkWebView loadRequest:urlReq];
}

- (void)prepareWKWebView
{
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    _wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)-44) configuration:config];
    [self.view addSubview:self.wkWebView];
    self.wkWebView.navigationDelegate = self;
    
    
}

- (void)prepareNavigationItems
{
    UIBarButtonItem *left = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(goBack)];
    self.navigationItem.leftBarButtonItem = left;
    
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"Forward" style:UIBarButtonItemStylePlain target:self action:@selector(goForward)];
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refresh)];
    self.navigationItem.rightBarButtonItems = @[right, refresh];
}

- (void)refresh
{
    [self.wkWebView reload];
}

- (void)goBack
{
    if ([self.wkWebView canGoBack]) {
        [self.wkWebView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)goForward
{
    if ([self.wkWebView canGoForward]) {
        [self.wkWebView goForward];
    }
}

- (void)requestURLChanged:(NSNotification *)noti
{
    NSString *urlString = noti.object;
    if (![self.urlArray containsObject:urlString]) {
        [self.urlArray addObject:urlString];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.urlLabel.text = @"go to download ---->";
    });
}

- (IBAction)gotoDownload
{
    DownloadURLListController *dulc = [[DownloadURLListController alloc] initWithStyle:UITableViewStylePlain];
    dulc.urlArray = self.urlArray;
    dulc.urlWebTitle = self.webTitle;
    [self.navigationController pushViewController:dulc animated:YES];
    [self.urlArray removeAllObjects];
}

- (IBAction)gotoDownloadingList
{
    DownloadListController *dlc = [[DownloadListController alloc] init];
    [self.navigationController pushViewController:dlc animated:YES];
}

- (IBAction)gotoFileList
{
    FileListController *flc = [[FileListController alloc] init];
    [self.navigationController pushViewController:flc animated:YES];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    [self.hud startAnimating];
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    [self.hud stopAnimating];
    decisionHandler(WKNavigationResponsePolicyAllow);
    
    //获取标题
    __weak typeof(self) weakSelf = self;
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable item, NSError * _Nullable error) {
        
        NSLog(@"item : %@", item);
        if ([item isKindOfClass:[NSString class]]) {
            weakSelf.webTitle = (NSString *)item;
        }
    }];
}


@end




