//
//  FileListController.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/12/3.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "FileListController.h"
#import <AVKit/AVKit.h>
#import "FileCell.h"

@interface DFileItem : NSObject
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, assign) int64_t seconds;
@property (nonatomic, assign) NSInteger size;
@end

@implementation DFileItem

@end

@interface FileListController ()
@property (nonatomic, strong) NSMutableArray <DFileItem *> *files;

@end

@implementation FileListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FileCell" bundle:nil] forCellReuseIdentifier:@"FileCell"];
    
    [self prepareNavigationItem];
    [self loadFiles];
}

- (void)loadFiles
{
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *directory = [docPath stringByAppendingPathComponent:@"DemoDownloadFiles"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray <NSString *> *files = [fm contentsOfDirectoryAtPath:directory error:nil];
    
    self.files = [NSMutableArray array];
    for (NSString *fileName in files) {
        NSString *filePath = [directory stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePath];
        AVURLAsset *fileAsset = [AVURLAsset assetWithURL:fileURL];
        CMTime fileDuration = fileAsset.duration;
        DFileItem *item = [[DFileItem alloc] init];
        item.fileName = fileName;
        item.seconds = fileDuration.value / fileDuration.timescale;
        NSDictionary *fileAttr = [fm attributesOfItemAtPath:filePath error:nil];
        item.size = [[fileAttr objectForKey:NSFileSize] integerValue];
        [self.files addObject:item];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.files.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FileCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FileCell" forIndexPath:indexPath];
    
    DFileItem *item = self.files[indexPath.row];
    cell.nameLabel.text = item.fileName;
    NSString *time = [NSString stringWithFormat:@"%lldm%llds", item.seconds/60, item.seconds%60];
    NSString *size = [self prettyDownloadBytes:item.size];
    cell.contentLabel.text = [NSString stringWithFormat:@"%@    %@", time, size];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DFileItem *item = self.files[indexPath.row];
    NSString *fileName = item.fileName;
    CGFloat w = CGRectGetWidth(tableView.bounds) - 16 - 16;
    CGFloat h = [fileName boundingRectWithSize:CGSizeMake(w, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]} context:nil].size.height;
    return ceil(h) + 20 + 20 + 11 + 11;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DFileItem *item = self.files[indexPath.row];
    NSString *fileName = item.fileName;
    [self showFile:fileName];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __weak typeof(self) weakSelf = self;
    UITableViewRowAction *delete = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"删除" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        DFileItem *item = self.files[indexPath.row];
        NSString *fileName = item.fileName;
        [weakSelf removeFileWithName:fileName];
    }];
    
    UITableViewRowAction *share = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"分享" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        DFileItem *item = self.files[indexPath.row];
        NSString *fileName = item.fileName;
        [weakSelf shareFile:fileName];
    }];
    
    UITableViewRowAction *edit = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"编辑" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        
        DFileItem *item = self.files[indexPath.row];
        NSString *fileName = item.fileName;
        [weakSelf editFile:fileName];
    }];
    
    return @[delete, share, edit];
}

#pragma mark - tools

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

- (void)editFile:(NSString *)file
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"rename" message:@"Input the new name" preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = file;
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    __weak typeof(ac) weakAc = ac;
    __weak typeof(self) weakSelf = self;
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        UITextField *tf = weakAc.textFields.firstObject;
        if (tf.text.length > 0) {
            [weakSelf renameFile:file toFileName:tf.text];
        }
    }];
    [ac addAction:cancel];
    [ac addAction:ok];
    [self presentViewController:ac animated:YES completion:nil];
}

- (void)renameFile:(NSString *)file toFileName:(NSString *)fileName
{
    NSURL *url = [self fileUrlOfName:file];
    NSURL *fileUrl = [self fileUrlOfName:fileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err;
    [fm moveItemAtURL:url toURL:fileUrl error:&err];
    if (err) {
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:err.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        __weak typeof(ac) weakAc = ac;
        __weak typeof(self) weakSelf = self;
        [self presentViewController:ac animated:YES completion:^{
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [weakAc dismissViewControllerAnimated:YES completion:nil];
                [weakSelf loadFiles];
            });
        }];
    }
}

- (void)showFile:(NSString *)file
{
    NSURL *url = [self fileUrlOfName:file];
    AVPlayer *player = [AVPlayer playerWithURL:url];
    AVPlayerViewController *pvc = [[AVPlayerViewController alloc] init];
    pvc.player = player;
    [self presentViewController:pvc animated:YES completion:nil];
}

- (void)shareFile:(NSString *)file
{
    NSURL *url = [self fileUrlOfName:file];
    UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    
    // Exclude all activities except AirDrop.
    //    NSArray *excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,
    //                                    UIActivityTypePostToWeibo,
    //                                    UIActivityTypeMessage, UIActivityTypeMail,
    //                                    UIActivityTypePrint, UIActivityTypeCopyToPasteboard,
    //                                    UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll,
    //                                    UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,
    //                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    //    avc.excludedActivityTypes = excludedActivities;
    
    [self presentViewController:avc animated:YES completion:nil];
}

- (NSURL *)fileUrlOfName:(NSString *)fileName
{
    NSString *docPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    NSString *directory = [docPath stringByAppendingPathComponent:@"DemoDownloadFiles"];
    NSString *filePath = [directory stringByAppendingPathComponent:fileName];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    return url;
}

- (void)removeFileWithName:(NSString *)name
{
    NSURL *url = [self fileUrlOfName:name];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *err = nil;
    [fm removeItemAtURL:url error:&err];
    if (err) {
        NSLog(@"remove file: %@ Error: %@", name, err.localizedDescription);
    } else {
        [self loadFiles];
    }
}

- (void)prepareNavigationItem
{
    UIBarButtonItem *right = [[UIBarButtonItem alloc] initWithTitle:@"Clear" style:UIBarButtonItemStylePlain target:self action:@selector(removeAllFiles)];
    self.navigationItem.rightBarButtonItem = right;
}

- (void)removeAllFiles
{
    UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:@"remove all files?" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];
    
    __weak typeof(self) weakSelf = self;
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"YES" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        for (NSString *fileName in weakSelf.files) {
            [weakSelf removeFileWithName:fileName];
        }
    }];
    
    [ac addAction:cancel];
    [ac addAction:ok];
    
    [self presentViewController:ac animated:YES completion:nil];
}


@end
