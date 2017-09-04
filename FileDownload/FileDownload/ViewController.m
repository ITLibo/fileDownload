//
//  ViewController.m
//  FileDownload
//
//  Created by 李博 on 2017/9/4.
//  Copyright © 2017年 李博. All rights reserved.
//

#import "ViewController.h"
#import "DownLoadFile.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    DownLoadFile *down = [[DownLoadFile alloc]init];
    
    
    DownLoadFile *down2 = [DownLoadFile shareDownLoadFile];
    
    NSLog(@"%@___%@___%@",down,down2,[down2 copy]);
    
    [[DownLoadFile shareDownLoadFile] requestWithURL:@"http://120.25.226.186:32812/resources/videos/minion_12.mp4" progress:^(NSProgress *progress) {
        
        //进度
        NSLog(@"%f",1.0*progress.completedUnitCount/progress.totalUnitCount);
        
    } completionHandler:^(NSURL *targetPath,NSError *error) {
        
        NSLog(@"%@___%@",targetPath,error);
        
        
    }];
    
}

@end
