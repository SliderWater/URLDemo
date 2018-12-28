//
//  FileCell.h
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/12/13.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;

@end

NS_ASSUME_NONNULL_END
