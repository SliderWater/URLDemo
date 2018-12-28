//
//  DownloadURLListController.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/12/3.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "DownloadURLListController.h"
#import "DownloadListController.h"
#import "DownloadManager.h"

@interface DownloadURLListController ()
@property (nonatomic, strong) NSMutableArray *rowHeights;
@end

@implementation DownloadURLListController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUrlArray:(NSArray *)urlArray
{
    _urlArray = [urlArray mutableCopy];
    [self calculateRowHeights];
}

- (void)calculateRowHeights
{
    NSMutableArray *temp = [NSMutableArray arrayWithCapacity:self.urlArray.count];
    for (NSString *url in self.urlArray) {
        CGFloat urlH = [url boundingRectWithSize:CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) - 40, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:15]} context:nil].size.height;
        CGFloat rowH = MAX(44, ceil(urlH) + 30);
        [temp addObject:@(rowH)];
    }
    self.rowHeights = temp;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.urlArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell" forIndexPath:indexPath];
    NSString *url = self.urlArray[indexPath.row];
    cell.textLabel.text = url;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.font = [UIFont systemFontOfSize:15];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumber *rowH = self.rowHeights[indexPath.row];
    return rowH ? rowH.doubleValue : 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *url = self.urlArray[indexPath.row];
    [self gotoDownloadListWithURLString:url];
}

- (void)gotoDownloadListWithURLString:(NSString *)urlString
{
    NSString *type = @".mp4";
    NSRange mp4Range = [urlString rangeOfString:type options:NSBackwardsSearch];
    NSString *urlStringToMp4 = mp4Range.location != NSNotFound ? [urlString substringToIndex:mp4Range.location] : urlString;
    NSRange xiexianRange = [urlStringToMp4 rangeOfString:@"/" options:NSBackwardsSearch];
    NSString *fileNameWithoutType = xiexianRange.location != NSNotFound ? [urlStringToMp4 substringFromIndex:xiexianRange.location+1] : urlStringToMp4;
    NSString *fileName = nil;
    if ([fileNameWithoutType containsString:@"video"]) {
        fileName = [self.urlWebTitle stringByAppendingString:type];
    } else {
        fileName = fileNameWithoutType.length > 0 ? [fileNameWithoutType stringByAppendingString:type] : [@"noName" stringByAppendingString:type];
    }
    
    [[DownloadManager manager] download:urlString fileName:fileName];
    
    DownloadListController *dlc = [[DownloadListController alloc] init];
    [self.navigationController pushViewController:dlc animated:YES];
}

@end
