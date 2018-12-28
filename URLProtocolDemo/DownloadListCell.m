//
//  DownloadListCell.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/12/3.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "DownloadListCell.h"
#import "DownloadManager.h"

@interface DownloadListCell ()

@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UILabel *velocityLabel;

@end

@implementation DownloadListCell

- (void)setFileName:(NSString *)fileName totalSize:(NSString *)totalSize progress:(NSString *)progress velocity:(NSString *)velocity paused:(BOOL)paused
{
    self.fileNameLabel.text = fileName;
    self.totalSizeLabel.text = totalSize;
    self.progressLabel.text = progress;
    self.velocityLabel.text = velocity;
    if (paused) {
        self.fileNameLabel.textColor = [UIColor redColor];
    } else {
        self.fileNameLabel.textColor = [UIColor blackColor];
    }
}

@end
