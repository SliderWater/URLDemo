//
//  DownloadListCell.h
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/12/3.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DownloadListCell : UITableViewCell

- (void)setFileName:(NSString *)fileName totalSize:(NSString *)totalSize progress:(NSString *)progress velocity:(NSString *)velocity paused:(BOOL)paused;

@end
