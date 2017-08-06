//
//  ViewController.m
//  Session
//
//  Created by 赵清 on 2017/7/12.
//  Copyright © 2017年 赵清. All rights reserved.
//

#define BLog(formatString, ...) NSLog((@"%s " formatString), __PRETTY_FUNCTION__, ##__VA_ARGS__);

#import "ViewController.h"
#import <Foundation/Foundation.h>

static NSString *githubString = @"https://github.com/";
static NSString *localhostString = @"https://localhost:4443/";

@interface ViewController ()<NSURLSessionDelegate>
@property (weak, nonatomic) IBOutlet UIButton *beginButton;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, copy) NSMutableData *mutableData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _mutableData = [NSMutableData data];
    
    self.session = [self defaultSession];
    [self sessionTaskInit];
}

- (NSURLSession *)defaultSession {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    });
    return session;
}

- (void)sessionTaskInit {
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:localhostString]];
    self.dataTask = [self.session dataTaskWithRequest:request];
}

- (IBAction)buttonClick:(id)sender {
    [self resume];
    self.beginButton.enabled = NO;
}

- (void)resume {
    [self.dataTask resume];
}

#pragma mark - NSURLSessionDelegate

//- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
// completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler {
//    BLog();
//}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    BLog();
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    BLog();
    
    self.progressView.progress = totalBytesWritten/(float)totalBytesExpectedToWrite;
    self.progressLabel.text = [NSString stringWithFormat:@"%.2f",totalBytesWritten/(float)totalBytesExpectedToWrite];
    NSLog(@"%@",self.progressLabel.text);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    BLog();
    [self.mutableData appendData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(nullable NSError *)error {
    BLog();
    
    if (error) {
        NSLog(@"error:%@",error);
    }else {
        self.progressView.progress = 1;
        self.progressLabel.text = @"1";
        
        NSLog(@"success");
        NSLog(@"%@",[[NSString alloc] initWithData:self.mutableData encoding:NSUTF8StringEncoding]);
    }
    self.beginButton.enabled = YES;
}

@end
