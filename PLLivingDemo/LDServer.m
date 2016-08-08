//
//  LDServer.m
//  PLLivingDemo
//
//  Created by TaoZeyu on 16/8/8.
//  Copyright © 2016年 com.pili-engineering. All rights reserved.
//

#import "LDServer.h"
#import "LDCookies.h"
#import "LDLivingConfiguration.h"

@implementation LDServer

static LDServer *_sharedInstance;

+ (void)initialize
{
    _sharedInstance = [[LDServer alloc] init];
}

+ (instancetype)sharedServer
{
    return _sharedInstance;
}

- (void)requestMobileCaptchaWithPhoneNumber:(NSString *)phoneNumber withComplete:(void (^)())complete withFail:(void (^)(NSError * _Nullable responseError))failBlock
{
    [self _url:[self _httpURLWithPath:@"/mobile"] request:^(NSMutableURLRequest *request) {
        
        request.HTTPMethod = @"POST";
        [self _setRequest:request WithHttpBodyParams:@{@"mobile": phoneNumber}];
        
    } success:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response) {
        
        complete();
        
    } fail:failBlock];
}

- (void)postMobileCaptcha:(NSString *)captcha withPhoneNumber:(NSString *)phoneNumber withComplete:(void (^)(BOOL valid))complete withFail:(void (^)(NSError * _Nullable responseError))failBlock
{
    [self _url:[self _httpURLWithPath:@"/mobile_verify"] request:^(NSMutableURLRequest *request) {
        
        request.HTTPMethod = @"POST";
        [self _setRequest:request WithHttpBodyParams:@{@"mobile": phoneNumber,
                                                       @"captcha": captcha}];
        
    } success:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response) {
        
        if (response.statusCode == 200) {
            complete(YES);
        } else if (response.statusCode == 400) {
            complete(NO);
        }
    } fail:failBlock];
}

- (void)postUserName:(NSString *)username withComplete:(void (^)())complete withFail:(void (^)(NSError * _Nullable responseError))failBlock
{
    [self _url:[self _httpURLWithPath:@"/name"] request:^(NSMutableURLRequest *request) {
        
        request.HTTPMethod = @"POST";
        [self _setRequest:request WithHttpBodyParams:@{@"name": username}];
        
    } success:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response) {
        
        complete();
        
    } fail:failBlock];
}

- (void)createNewRoomWithComplete:(void (^)())complete withFail:(void (^)(NSError * _Nullable responseError))failBlock
{
    [self _url:[self _httpURLWithPath:@"/stream"] request:^(NSMutableURLRequest *request) {
        
        request.HTTPMethod = @"POST";
        
    } success:^(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response) {
        
        
    } fail:failBlock];
}

- (NSURL *)_httpURLWithPath:(NSString *)path
{
    NSString *serverURL = [LDLivingConfiguration sharedLivingConfiguration].httpServerURL;
    serverURL = [serverURL stringByReplacingOccurrencesOfRegex:@"/$" withString:@""];
    path = [path stringByReplacingOccurrencesOfRegex:@"^/" withString:@""];
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@", serverURL, path]];
}

- (void)_setRequest:(NSMutableURLRequest *)request WithHttpBodyParams:(NSDictionary *)params
{
    NSMutableArray *entiyArray = [[NSMutableArray alloc] init];
    for (NSString *key in params) {
        NSString *value = params[key];
        [entiyArray addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }
    NSString *body = [entiyArray componentsJoinedByString:@"&"];
    NSData *data = [body dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", [data length]];
    
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:data];
    
    NSLog(@"HTTP BODY : %@", body);
}

- (void)_url:(NSURL *)url
     request:(void (^)(NSMutableURLRequest *request))requestSettingBlock
     success:(void (^)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response))successBlock
        fail:(void (^)(NSError * _Nullable responseError))failBlock
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request setTimeoutInterval:10];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    if (requestSettingBlock) {
        requestSettingBlock(request);
    }
    
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable responseError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSLog(@"requet %@ : status code %li", url, httpResponse.statusCode);
            
            NSError *error = responseError;
            if (error != nil || response == nil || data == nil) {
                NSLog(@"ERROR: %@", error);
                if (failBlock) {
                    failBlock(error);
                }
            } else {
                if (successBlock) {
                    successBlock(data, httpResponse);
                }
                [[LDCookies sharedCookies] store];
            }
        });
    }];
    [task resume];
}

@end
