//
//  MBProgressHUD+Demo.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2019/10/21.
//  Copyright © 2019 xyzdm123. All rights reserved.
//

#import "MBProgressHUD+Demo.h"

@implementation MBProgressHUD (Demo)

+ (void)showText:(NSString *)text onView:(UIView *)view
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];

    // Set the text mode to show only text.
    hud.mode = MBProgressHUDModeText;
    hud.label.text = text;
    // Move to bottm center.
    hud.offset = CGPointMake(0.f, MBProgressMaxOffset);

    [hud hideAnimated:YES afterDelay:3.f];
}

@end
