//
//  DownLoadFile.h
//  
//
//  Created by 李博 on 2017/8/25.
//
//

#import <Foundation/Foundation.h>

@interface DownLoadFile : NSObject<NSCopying>


//设置单例
+ (instancetype)shareDownLoadFile;

/* 
 progress:文件下载进度
 location:文件下载路径
 **/
- (void)requestWithURL:(NSString *)url progress:(void(^)(NSProgress *progress))downloadProgressBlock completionHandler:(void(^)(NSURL *targetPath,NSError *error))downloaError;
@end
