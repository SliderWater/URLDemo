//
//  DownloadListController.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/11/30.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "DownloadListController.h"
#import "DownloadManager.h"
#import "DownloadListCell.h"
#import "MBProgressHUD+Demo.h"

@interface DownloadListController () <DownloadDelegate>

@property (nonatomic, strong) DownloadManager *manager;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableDictionary *velocityDict;
@property (nonatomic, strong) NSMutableDictionary *lastWrittenBytes;
@property (nonatomic, strong) NSMutableDictionary *currentWrittenBytes;

@end

@implementation DownloadListController

- (void)dealloc
{
    self.manager.delegate = nil;
    self.manager = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareData];
    [self.tableView registerNib:[UINib nibWithNibName:@"DownloadListCell" bundle:nil] forCellReuseIdentifier:@"DownloadListCell"];
    self.tableView.rowHeight = 60;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self prepareTimer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.timer invalidate];
    self.timer = nil;
}

- (void)prepareData
{
    _manager = [DownloadManager manager];
    _manager.delegate = self;
    _lastWrittenBytes = [NSMutableDictionary dictionary];
    _currentWrittenBytes = [NSMutableDictionary dictionary];
    _velocityDict = [NSMutableDictionary dictionary];
}

- (void)prepareTimer
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    __weak typeof(self) weakSelf = self;
    _timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {

        [weakSelf calculateVelocity];
        [weakSelf refreshVelocity];
    }];
}

- (void)calculateVelocity
{
    for (NSString *key in self.currentWrittenBytes) {
        NSNumber *currentWrittenB = self.currentWrittenBytes[key];
        [self.lastWrittenBytes setObject:currentWrittenB forKey:key];
    }
    for (DownloadItem *item in self.manager.downloadingItems) {
        [self.currentWrittenBytes setObject:@(item.totalBytesWritten) forKey:item.url];
    }
    for (NSString *key in self.currentWrittenBytes) {
        NSNumber *current = self.currentWrittenBytes[key];
        NSNumber *last = self.lastWrittenBytes[key];
        uint64_t bytes = current.unsignedLongLongValue;
        if (last) {
            bytes = current.unsignedLongLongValue - last.unsignedLongLongValue;
        }
        [self.velocityDict setObject:@(bytes) forKey:key];
    }
}

- (void)refreshVelocity
{
    uint64_t totalVelocity = 0;
    for (NSString *key in self.velocityDict) {
        NSNumber *velocityNumber = self.velocityDict[key];
        totalVelocity += velocityNumber.unsignedLongLongValue;
    }
    NSString *totalVelocityString = [self prettyDownloadVelocity:(double)totalVelocity];
    self.navigationItem.title = totalVelocityString;
    
    [self.tableView reloadData];
}

- (NSString *)prettyDownloadVelocity:(double)velocity
{
    NSString *unit = @"B/s";
    double value = velocity;
    if (velocity > 1024 * 1024) { //Mb
        unit = @"MB/s";
        value = velocity / 1024 / 1024;
    } else if (velocity > 1024) {
        unit = @"KB/s";
        value = velocity / 1024;
    }
    
    return [NSString stringWithFormat:@"%.1f %@", value, unit];
}

- (NSString *)prettyDownloadBytes:(uint64_t)bytes
{
    NSString *unit = @"B";
    double value = bytes;
    if (bytes > 1024 * 1024) { //Mb
        unit = @"MB";
        value = bytes / 1024 / 1024;
    } else if (bytes > 1024) {
        unit = @"KB";
        value = bytes / 1024;
    }
    
    return [NSString stringWithFormat:@"%.1f %@", value, unit];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.manager.downloadingItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadListCell" forIndexPath:indexPath];
    
    if (indexPath.row < self.manager.downloadingItems.count) {
        DownloadItem *item = self.manager.downloadingItems[indexPath.row];
        if (item.failed == NO)
        {
            double progressValue = (double)item.totalBytesWritten / (double)item.totalBytesExpectedToWrite * 100;
            NSString *progress = [NSString stringWithFormat:@"%d%%", (int)progressValue];
            NSNumber *velocityNumber = self.velocityDict[item.url];
            NSString *velocity = [self prettyDownloadVelocity:velocityNumber.doubleValue];
            NSString *totalSize = [self prettyDownloadBytes:item.totalBytesExpectedToWrite];
            BOOL paused = item.task.state == NSURLSessionTaskStateSuspended;
            [cell setFileName:item.fileName totalSize:totalSize progress:progress velocity:velocity paused:paused];
        }
        else
        {
            double progressValue = (double)item.totalBytesWritten / (double)item.totalBytesExpectedToWrite * 100;
            NSString *progress = [NSString stringWithFormat:@"%d%%", (int)progressValue];
            NSNumber *velocityNumber = self.velocityDict[item.url];
            NSString *velocity = [self prettyDownloadVelocity:velocityNumber.doubleValue];
            NSString *totalSize = [self prettyDownloadBytes:item.totalBytesExpectedToWrite];
//            BOOL paused = item.task.state == NSURLSessionTaskStateSuspended;
            [cell setFileName:item.fileName totalSize:totalSize progress:progress velocity:velocity paused:YES];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row < self.manager.downloadingItems.count) {
        DownloadItem *item = self.manager.downloadingItems[indexPath.row];
        NSString *fileName = item.fileName;
        CGFloat fileNameW = CGRectGetWidth(tableView.bounds) - 20 - 80;
        CGFloat fileNameH = [fileName boundingRectWithSize:CGSizeMake(fileNameW, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]} context:nil].size.height;
        return ceil(fileNameH) + 20 + 20 + 11 + 11;
    }
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DownloadItem *item = self.manager.downloadingItems[indexPath.row];
    if (item.task.state == NSURLSessionTaskStateRunning) {
        [self.manager pauseTaskAtIndex:indexPath.row];
    } else if (item.task.state == NSURLSessionTaskStateSuspended) {
        [self.manager resumeTaskAtIndex:indexPath.row];
    }
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        DownloadItem *item = weakSelf.manager.downloadingItems[indexPath.row];
        if (item.task.state == NSURLSessionTaskStateSuspended || item.task.state == NSURLSessionTaskStateRunning) {
            [weakSelf.manager cancelTaskAtIndex:indexPath.row];
        }
    }];
    
    return @[delete];
}

- (void)tableView:(UITableView *)tableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.timer setFireDate:[NSDate distantFuture]];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.timer setFireDate:[NSDate date]];
}

#pragma mark - DownloadDelegate

- (void)downloadUrl:(NSString *)url failedWithError:(NSError *)error
{
    [MBProgressHUD showText:error.localizedDescription onView:self.view];
}

- (void)downloadUrl:(NSString *)url successWithSavedPath:(NSString *)savedPath
{
    NSString *successText = [NSString stringWithFormat:@"%@ download success!", url];
    [MBProgressHUD showText:successText onView:self.view];
}


@end
