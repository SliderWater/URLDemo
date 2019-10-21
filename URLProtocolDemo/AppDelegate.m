//
//  AppDelegate.m
//  URLProtocolDemo
//
//  Created by 杜淼 on 2018/11/30.
//  Copyright © 2018年 xyzdm123. All rights reserved.
//

#import "AppDelegate.h"
#import "DemoURLProtocol.h"
#import "DownloadManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [DemoURLProtocol registerDemoURLProtocol];
    [DownloadManager manager];
    
    return YES;
}


- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    NSLog(@"url session identifier : %@", identifier);
    [[DownloadManager manager] addCompletionHandler:completionHandler forSession:identifier];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    [self handleFileFromAirDrop];
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    NSLog(@"url : %@", url);
    [self handleFileFromAirDrop];
    return YES;
}

#pragma mark - custom function

- (void)handleFileFromAirDrop
{
    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *inboxPath = [documentPath stringByAppendingPathComponent:@"Inbox/"];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *files = [fm contentsOfDirectoryAtPath:inboxPath error:nil];
    
    if (files.count > 0) {
        
        NSString *TXTBookPath = [documentPath stringByAppendingPathComponent:@"ZipFiles/"];
        if (![fm fileExistsAtPath:TXTBookPath]) {
            BOOL ret = [fm createDirectoryAtPath:TXTBookPath withIntermediateDirectories:NO attributes:nil error:nil];
            if (!ret) {
                NSLog(@"Create received file path failed");
                return;
            }
        }
        
        NSMutableArray *hasNewFileStatusArray = [NSMutableArray array];
        for (NSString *fileName in files) {
            
            NSString *source = [inboxPath stringByAppendingPathComponent:fileName];
            NSString *dest = [TXTBookPath stringByAppendingPathComponent:fileName];
            
            //如果文件重名，在末尾添加"-1"
            int loopCount = 0;
            while ([fm fileExistsAtPath:dest]) {
                
                loopCount++;
                if (loopCount > 100) {
                    NSLog(@"Too many same name files!!! Remove the newest file!!!");
                    [fm removeItemAtPath:dest error:nil];
                    return;
                }
                NSString *fileName = dest.lastPathComponent;
                NSArray *nameAndType = [fileName componentsSeparatedByString:@"."];
                NSString *name = nameAndType.firstObject;
                NSString *newFileName = [name stringByAppendingFormat:@"-1.%@", nameAndType.lastObject];
                dest = [TXTBookPath stringByAppendingPathComponent:newFileName];
            }
            
            NSError *error = nil;
            [fm moveItemAtPath:source toPath:dest error:&error];
            if (error) {
                NSLog(@"Move file : %@\nerror : %@", fileName, error.localizedDescription);
                continue;
            }
            [hasNewFileStatusArray addObject:@"1"];
        }
        
        if (hasNewFileStatusArray.count > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"F123R_NEED_REFRESH_BOOK_LIST" object:nil];
        }
    }
}


@end
