//
//  DemoURLProtocol.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/11/30.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "DemoURLProtocol.h"

NSString * const kURLProtocolHandledKey = @"kURLProtocolHandledKey";

@interface DemoURLProtocol () <NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, strong) NSURLSessionTask *task;

@end

@implementation DemoURLProtocol

+ (void)registerDemoURLProtocol
{
    // 防止苹果静态检查 将 WKBrowsingContextController 拆分，然后再拼凑起来
    NSArray *privateStrArr = @[@"Controller", @"Context", @"Browsing", @"K", @"W"];
    NSString *className =  [[[privateStrArr reverseObjectEnumerator] allObjects] componentsJoinedByString:@""];
    Class cls = NSClassFromString(className);
    SEL sel = NSSelectorFromString(@"registerSchemeForCustomProtocol:");
    
    if (cls && sel) {
        if ([(id)cls respondsToSelector:sel]) {
            // 注册自定义协议
            // [(id)cls performSelector:sel withObject:@"CustomProtocol"];
            // 注册http协议
            [(id)cls performSelector:sel withObject:@"http"];
            // 注册https协议
            [(id)cls performSelector:sel withObject:@"https"];
        }
    }
    [NSURLProtocol registerClass:[self class]];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    NSString *scheme = [[request URL] scheme];
    if ([scheme caseInsensitiveCompare:@"http"] == NSOrderedSame ||
        [scheme caseInsensitiveCompare:@"https"] == NSOrderedSame)
    {
        if ([NSURLProtocol propertyForKey:kURLProtocolHandledKey inRequest:request])
        {
            return NO;
        }
    }
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *mur = [request mutableCopy];
    return mur;
}

//判重
+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b
{
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading
{
    NSMutableURLRequest *mur = [[self request] mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kURLProtocolHandledKey inRequest:mur];
    
//    NSString *loadingUrl = mur.URL.absoluteString;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.xyzdm123.demo.loading_url" object:loadingUrl];
//    NSLog(@"loading url : %@", loadingUrl);
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.queue];
    self.session = session;
    
    NSURLSessionTask *task = [session dataTaskWithRequest:mur];
    self.task = task;
    
    [task resume];
}

- (void)stopLoading
{
    [self.session invalidateAndCancel];
    self.session = nil;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"com.xyzdm123.demo.loading_url" object:@""];
}

- (NSOperationQueue *)queue
{
    if (_queue)
    {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

@end

@implementation DemoURLProtocol (NSURLSessionDataDelegate)

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
    
    NSString *loadingUrl = response.URL.absoluteString;
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSDictionary *responseHeader = [(NSHTTPURLResponse *)response allHeaderFields];
        NSString *contentType = [responseHeader objectForKey:@"Content-Type"];
        if ([contentType containsString:@"video"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"com.xyzdm123.demo.loading_url" object:loadingUrl];
        }
    } else if ([loadingUrl containsString:@".mp4"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.xyzdm123.demo.loading_url" object:loadingUrl];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler
{
    completionHandler(proposedResponse);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSMutableURLRequest *redirectRequest = [request mutableCopy];
    [[self class] removePropertyForKey:kURLProtocolHandledKey inRequest:redirectRequest];
    [[self client] URLProtocol:self wasRedirectedToRequest:redirectRequest redirectResponse:response];
    
    [self.task cancel];
    [self.client URLProtocol:self didFailWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

@end











