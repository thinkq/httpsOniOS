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
        SecCertificateRef trustedCert = getTrustedCert();
        SecTrustRef serverTrust = addAnchorToTrust(challenge.protectionSpace.serverTrust, trustedCert);
        if ([self trustEvaluate:serverTrust]) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
            return;
        }
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}


SecCertificateRef getTrustedCert(){
    // 获取bundle指针
    NSBundle *bundle = [NSBundle mainBundle];
    // 获取本地内置证书路径
    NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];
    // 获取内置证书data（因为本地只内置一个证书，所以直接用下标0从路径中获取，正式项目中不要这么用）
    NSData *certificateData = [NSData dataWithContentsOfFile:paths[0]];
    // data转换成SecCertificateRef
    SecCertificateRef trustedCert = SecCertificateCreateWithData(NULL, (__bridge CFDataRef)certificateData);
    return trustedCert;
}


SecTrustRef addAnchorToTrust(SecTrustRef trust, SecCertificateRef trustedCert)
{
    // 创建一个新的空array，接下来将用作锚点证书集合
    CFMutableArrayRef newAnchorArray = CFArrayCreateMutable (kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    // 将证书添加到array
    CFArrayAppendValue(newAnchorArray, trustedCert);
    // 设置trust对象内部指针指向我们自己创建的锚点证书集合，接下来的验证会使用这个锚点集合而不是使用系统内置的
    SecTrustSetAnchorCertificates(trust, newAnchorArray);
    return trust;
}

- (BOOL)trustEvaluate:(SecTrustRef)trust {
    SecTrustResultType secresult = kSecTrustResultInvalid;
    if (SecTrustEvaluate(trust, &secresult) != errSecSuccess) {
        NSLog(@"NO:%d",secresult);
        return NO;
    }
    switch (secresult) {
        case kSecTrustResultUnspecified:
        case kSecTrustResultProceed:
        {
            NSLog(@"YES");
            return YES;
        }
        default:
            NSLog(@"NO:%d",secresult);
            return NO;
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
