//
//  ViewController.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/11/30.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "ViewController.h"
#import "DemoViewController.h"
#import "DownloadListController.h"
#import "FileListController.h"

@interface ViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *urlField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

- (IBAction)click:(id)sender {
    [self goToNext];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self goToNext];
    return YES;
}

- (void)goToNext
{
    if ([self.urlField.text isEqualToString:@"DList!"]) {
        [self showDownloadList];
    } else if ([self.urlField.text isEqualToString:@"FList!"]) {
        [self showFileList];
    } else {
        [self pushDemoVC];
    }
}

- (void)showFileList {
    FileListController *flc = [[FileListController alloc] init];
    [self.navigationController pushViewController:flc animated:YES];
}

- (void)showDownloadList {
    DownloadListController *dlc = [[DownloadListController alloc] init];
    [self.navigationController pushViewController:dlc animated:YES];
}

- (void)pushDemoVC
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    DemoViewController *dvc = (DemoViewController *)[sb instantiateViewControllerWithIdentifier:@"DemoViewController"];
    dvc.urlString = self.urlField.text;
    [self.navigationController pushViewController:dvc animated:YES];
}








@end








