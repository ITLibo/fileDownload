//
//  DownLoadFile.m
//  
//
//  Created by 李博 on 2017/8/25.
//
//

#import "DownLoadFile.h"

#import "NSString+Hash.h"

//声明 Block类型
typedef void (^LBDownLoadProgressBlock)(NSProgress *progress);
typedef void (^LBDownLoadError)(NSURL *targetPath,NSError *error);


@interface DownLoadFile () <NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *session;//会话对象
//@property (strong, nonatomic) NSURLSessionDataTask *task;//任务对象

@property (strong, nonatomic) NSOutputStream *stream;

@property (assign, nonatomic) NSInteger totalLength;//文件总大小

@property (assign, nonatomic) NSInteger currentLength;//下载总进度

@property (strong, nonatomic) NSString *filePath; //文件存储路径

@property (strong, nonatomic) NSProgress *progress;//保存文件下载大小

//@property (assign, nonatomic) NSError *error; //错误信息

@property (copy, nonatomic) LBDownLoadProgressBlock downloadProgressBlocks;//下载进度block 对象
@property (strong, nonatomic) LBDownLoadError downLoadError;//下载错误 block 对象


@end

static DownLoadFile *_downLoad;

@implementation DownLoadFile

//全局创建对象都指向同一快内存地址
+ (instancetype)allocWithZone:(struct _NSZone *)zone{

    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _downLoad = [super allocWithZone:zone];
        
    });
    
   return _downLoad;
    
}
//创建单例
+ (instancetype)shareDownLoadFile{

    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        _downLoad = [[self alloc]init];
        
    });
    
    return _downLoad;
}
//防止对象copy
- (id)copyWithZone:(NSZone *)zone{

    return _downLoad;
}

- (NSURLSession *)session{

    if (_session == nil) {
        
        //创建唯一的会话对象
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]  delegate:self delegateQueue:[[NSOperationQueue alloc]init]];
    }
    return _session;
}

- (NSOutputStream *)stream{

    if (_stream == nil) {
        
        //初始化输出流对象 并且设置文件保存路径
        _stream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:YES];
    }
    
    return _stream;
}

- (NSProgress *)progress{

    if (_progress == nil) {
        
        _progress = [[NSProgress alloc]init];
    }
    
    return _progress;
}

// 判断文件名和路径是否存在 如果不存在则 设置文件名和文件路径
- (BOOL)setFileNameWithFilePath:(NSString *)path{

    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    
    //获取唯一的文件名 用url进行MD5加密 生产唯一的标识名
    NSString *fileName = path.md5String;
    
    //生产唯一的文件路径
    self.filePath =[ cachePath stringByAppendingPathComponent:fileName];

    NSLog(@"%@",self.filePath);
    
    NSLog(@"%d",[[NSFileManager defaultManager] fileExistsAtPath:self.filePath]);
    
    
    return [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
}
// 获取下载文件的总大小
- (void)getDownLoadFileSize{

    //获取已经下载的文件属性
    NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:nil];
    //获取已经下载的文件大小
    self.currentLength = [dict[NSFileSize] integerValue];
    
    [self.progress setCompletedUnitCount:self.currentLength];
}


//下载文件
- (void)requestWithURL:(NSString *)url progress:(void (^)(NSProgress *))downloadProgressBlock completionHandler:(void (^)(NSURL *targetPath,NSError *error))downloaError{
    
    //配置信息
    if ([self setFileNameWithFilePath:url]) {
    
        NSLog(@"下载文件已经存在");
        //return ;
    }
    
    [self getDownLoadFileSize];
    
    //回调
    self.downloadProgressBlocks = downloadProgressBlock;
    self.downLoadError = downloaError;
    
//    NSProgress *pro = [NSProgress progressWithTotalUnitCount:self.currentLength];
//    
//    downloadProgressBlock(pro);

    //创建请求对象
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    //设置获取服务器文件大小
    [request setValue:[NSString stringWithFormat:@"bytes=%zd-",self.currentLength] forHTTPHeaderField:@"Range"];
    
    //创建任务
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request];
    
    //开始任务
    [task resume];
}


#pragma mark - NSURLSessionDataDelegate
//服务器 响应方法
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
//    { URL: http://120.25.226.186:32812/resources/videos/minion_14.mp4 } { status code: 200, headers {
//        "Accept-Ranges" = bytes;
//        "Content-Length" = 9584210;
//        "Content-Type" = "video/mp4";
//        Date = "Sat, 26 Aug 2017 02:10:09 GMT";
//        Etag = "W/\"9584210-1409456092000\"";
//        "Last-Modified" = "Sun, 31 Aug 2014 03:34:52 GMT";
//        Server = "Apache-Coyote/1.1";

    NSLog(@"%@",response);
    
    //获取本次服务器返回的文件总大小
    self.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + self.currentLength;
    
    [self.progress setTotalUnitCount:self.totalLength];
    
    //打开输出流
    [self.stream open];
    
    //接受请求
    completionHandler(NSURLSessionResponseAllow);
    
}
//服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{

    //每次下载的数据写入文件中
    [self.stream write:data.bytes maxLength:data.length];
    

    [self getDownLoadFileSize];
    
    self.downloadProgressBlocks(self.progress);
    
    
   // NSLog(@"%@",[NSThread currentThread]);
    
    NSLog(@"下载文件大小%f",1.0 * self.currentLength / self.totalLength);
    
}
//请求完成
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{

    //将下载结果Error 和 下载文件的路径 返回
 
    self.downLoadError([NSURL fileURLWithPath:self.filePath],error);
    
    //文件下载完成 关闭输出流
    [self.stream close];
    
    self.stream = nil;
    
    //销毁会话对象
    self.session = nil;
    
    
}


@end
