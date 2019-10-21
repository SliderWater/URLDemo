//
//  DownloadManager.h
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/11/30.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^kVoidBlockType)(void);

@interface DownloadItem : NSObject

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;

@property (nonatomic, assign) uint64_t totalBytesWritten; ///<已写入字节数
@property (nonatomic, assign) uint64_t totalBytesExpectedToWrite; ///<总共需要写入字节数

//@property (nonatomic, assign) NSTimeInterval lastTime;
//@property (nonatomic, assign) NSString *progress;
//@property (nonatomic, assign) NSString *velocity;

@property (nonatomic, assign) BOOL failed;

@end


@protocol DownloadDelegate <NSObject>

@optional
- (void)downloadUrl:(NSString *)url didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)downloadUrl:(NSString *)url successWithSavedPath:(NSString *)savedPath;
- (void)downloadUrl:(NSString *)url failedWithError:(NSError *)error;

@end


@interface DownloadManager : NSObject

@property (nonatomic, assign) id <DownloadDelegate> delegate;

+ (instancetype)manager;
- (NSURLSession *)bgSession;

- (void)download:(NSString *)url fileName:(NSString *)fileName;

- (NSArray <DownloadItem *> *)downloadingItems;

- (void)addCompletionHandler:(kVoidBlockType)handler forSession:(NSString *)sessionIdentifier;

- (void)pauseTaskAtIndex:(NSUInteger)index;
- (void)resumeTaskAtIndex:(NSUInteger)index;
- (void)cancelTaskAtIndex:(NSUInteger)index;

@end


