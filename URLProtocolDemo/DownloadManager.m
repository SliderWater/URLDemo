//
//  DownloadManager.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/11/30.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "DownloadManager.h"


@implementation DownloadItem

@end


@interface DownloadManager () <NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *queue;
//@property (nonatomic, strong) NSMutableDictionary *downloadItems;

@property (nonatomic, copy) NSString *downloadFileDirectory;

@property (nonatomic, strong) NSMutableDictionary *completionHandlerDictionary;

@end

@implementation DownloadManager
{
    NSMutableArray *_downloadingItems;
}

- (NSString *)downloadFileDirectory {
    if (!_downloadFileDirectory) {
        NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
        NSString *directory = [docPath stringByAppendingPathComponent:@"DemoDownloadFiles"];
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:directory]) {
            NSError *error;
            [fm createDirectoryAtPath:directory withIntermediateDirectories:NO attributes:nil error:&error];
            if (error) {
                NSLog(@"create download file directory error : %@", error.localizedDescription);
            }
        }
        _downloadFileDirectory = directory;
    }
    return _downloadFileDirectory;
}

+ (instancetype)manager
{
    static DownloadManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init];
        _instance.queue = [[NSOperationQueue alloc] init];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.xyzdm123.backG_session"];
        _instance.session = [NSURLSession sessionWithConfiguration:config delegate:_instance delegateQueue:_instance.queue];
        _instance->_downloadingItems = [NSMutableArray array];
        [_instance readFileFromUserDefaults];
    });
    return _instance;
}

- (NSURLSession *)bgSession
{
    return self.session;
}

- (void)addCompletionHandler:(kVoidBlockType)handler forSession:(NSString *)sessionIdentifier
{
    if (!_completionHandlerDictionary) {
        _completionHandlerDictionary = [NSMutableDictionary dictionary];
    }
    [self.completionHandlerDictionary setObject:handler forKey:sessionIdentifier];
}

- (void)download:(NSString *)url fileName:(NSString *)fileName
{
    NSLog(@"download url : %@", url);
    
    if (url.length == 0 || fileName.length == 0)
    {
        NSLog(@"url or filename is null!");
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadUrl:failedWithError:)])
        {
            NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:999 userInfo:@{NSLocalizedDescriptionKey: @"url or filename is null!"}];
            [self.delegate downloadUrl:@"null" failedWithError:err];
        }
    }
    
    DownloadItem *item = [self downloadItemForURL:url];
    if (item != nil) {
        NSLog(@"The file of url : \"%@\" is already downloading!", url);
        if (self.delegate && [self.delegate respondsToSelector:@selector(downloadUrl:failedWithError:)])
        {
            NSString *errorStr = [NSString stringWithFormat:@"The file of url : \"%@\" is already downloading!", url];
            NSError *err = [NSError errorWithDomain:NSURLErrorDomain code:999 userInfo:@{NSLocalizedDescriptionKey: errorStr}];
            [self.delegate downloadUrl:url failedWithError:err];
        }
        return;
    }
    
    item = [[DownloadItem alloc] init];
    item.url = url;
    item.fileName = fileName;
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    item.task = [self.session downloadTaskWithRequest:request];
    [_downloadingItems addObject:item];
    
    [item.task resume];
    
    [self userDefaultsStoreUrl:url file:fileName];
}

- (DownloadItem *)downloadItemForURL:(NSString *)url
{
    for (DownloadItem *item in _downloadingItems) {
        if ([item.url isEqualToString:url]) {
            return item;
        }
    }
    return nil;
}

- (NSArray<DownloadItem *> *)downloadingItems
{
    return _downloadingItems;
}

- (void)pauseTaskAtIndex:(NSUInteger)index
{
    if (index > self.downloadingItems.count) return;
    DownloadItem *item = self.downloadingItems[index];
    [item.task suspend];
}
- (void)resumeTaskAtIndex:(NSUInteger)index
{
    if (index > self.downloadingItems.count) return;
    DownloadItem *item = self.downloadingItems[index];
    [item.task resume];
}
- (void)cancelTaskAtIndex:(NSUInteger)index
{
    if (index > self.downloadingItems.count) return;
    DownloadItem *item = self.downloadingItems[index];
    [item.task cancel];
}

#pragma mark - NSURLSessionDownloadDelegate

///下载失败
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error) {
        
        NSString *url = task.originalRequest.URL.absoluteString;
        DownloadItem *item = [self downloadItemForURL:url];
        if (!item) return;
        
        item.failed = YES;
        if ([self.delegate respondsToSelector:@selector(downloadUrl:failedWithError:)]) {
            [self.delegate downloadUrl:url failedWithError:error];
        }
    } else {
        NSLog(@"下载成功");
        [self userDefaultsDeleteUrl:task.originalRequest.URL.absoluteString];
    }
}

///下载完成
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    DownloadItem *item = [self downloadItemForURL:url];
    if (!item) return;
    
    NSString *savePath = [self pathForSavingFile:item.fileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    [fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:savePath] error:&error];
    if (error) {
        NSLog(@"save file error : %@", error.localizedDescription);
        item.failed = YES;
        if ([self.delegate respondsToSelector:@selector(downloadUrl:failedWithError:)]) {
            [self.delegate downloadUrl:url failedWithError:error];
        }
    } else {
        NSLog(@"下载并存储成功");
        [_downloadingItems removeObject:item];
        if ([self.delegate respondsToSelector:@selector(downloadUrl:successWithSavedPath:)]) {
            [self.delegate downloadUrl:url successWithSavedPath:savePath];
        }
    }
    
    [self userDefaultsDeleteUrl:url];
}

///更新下载进度
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
//    NSLog(@"bytesWritten : %lld", bytesWritten);
//    NSLog(@"totalBytesWritten : %lld", totalBytesWritten);
//    NSLog(@"totalBytesExpectedToWrite : %lld", totalBytesExpectedToWrite);
    
    NSString *url = downloadTask.originalRequest.URL.absoluteString;
    DownloadItem *item = [self downloadItemForURL:url];
    if (!item) return;
    
    item.totalBytesWritten = totalBytesWritten;
    item.totalBytesExpectedToWrite = totalBytesExpectedToWrite;

    if ([self.delegate respondsToSelector:@selector(downloadUrl:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
        [self.delegate downloadUrl:url didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
}

///重新下载之前失败的任务
//- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
//{
//
//}


///
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"Background session : %@ finished!", session);
    if (session.configuration.identifier) {
        kVoidBlockType handler = [self.completionHandlerDictionary objectForKey:session.configuration.identifier];
        if (handler) {
            NSLog(@"Invoke handler for session : %@", session.configuration.identifier);
            [self.completionHandlerDictionary removeObjectForKey:session.configuration.identifier];
            handler();
        }
    }
}

#pragma mark - file

- (NSString *)pathForSavingFile:(NSString *)file
{
    if (file.length > 1024) { //文件名过长
        return [self.downloadFileDirectory stringByAppendingPathComponent:[file substringToIndex:10]];
    }
    
    NSString *path = [self.downloadFileDirectory stringByAppendingPathComponent:file];
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:path] == NO) { //文件不存在
        return path;
    }
    
    NSString *aNewFile = [@"1-" stringByAppendingString:file];
    return [self pathForSavingFile:aNewFile];
}

#pragma mark - NSUserDefaults

- (void)userDefaultsStoreUrl:(NSString *)url file:(NSString *)fileName
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *downloadingFiles = [ud objectForKey:@"demoDownloadingFiles"];
    if (!downloadingFiles)
    {
        downloadingFiles = [NSMutableDictionary dictionary];
    }
    [downloadingFiles setObject:fileName forKey:url];
    [ud setObject:downloadingFiles forKey:@"demoDownloadingFiles"];
    [ud synchronize];
}

- (void)userDefaultsDeleteUrl:(NSString *)url
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *downloadingFiles = [ud objectForKey:@"demoDownloadingFiles"];
    if (downloadingFiles)
    {
        [downloadingFiles removeObjectForKey:url];
    }
    [ud synchronize];
}

- (void)readFileFromUserDefaults
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *downloadingFiles = [ud objectForKey:@"demoDownloadingFiles"];
    if (downloadingFiles)
    {
        for (NSString *url in downloadingFiles)
        {
            NSString *fileName = [downloadingFiles objectForKey:url];
            [self download:url fileName:fileName];
        }
    }
}

@end













