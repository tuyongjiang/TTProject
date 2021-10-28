//
//  TNetworkManager.m
//  TNetWork
//
//  Created by 涂永江 on 2021/1/21.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import "TNetworkManager.h"
#import <AFNetworking/AFNetworking.h>
#import "TResponse.h"
#import <pthread/pthread.h>
@interface TNetworkManager ()
@property (nonatomic ,strong) AFHTTPSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSURLSessionTask *> *taskIdDic;
@end

@implementation TNetworkManager
{
    pthread_mutex_t _lock;
}
+(instancetype)sharedInstance{
    static TNetworkManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TNetworkManager alloc] init];
    });
    return sharedInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
         pthread_mutex_init(&_lock, NULL);
    }
    return self;
}
-(void)dealloc{
    pthread_mutex_destroy(&_lock);
}
-(NSMutableDictionary<NSNumber *,NSURLSessionTask *> *)taskIdDic{
    if(!_taskIdDic){
        _taskIdDic = [NSMutableDictionary dictionary];
    }
    return _taskIdDic;
}
- (NSNumber *)sendNetWorkingRequest:(TBaseRequest *)baseRequest
                    uploadProgress:(TProgressBlock)uploadProgress
                  downloadProgress:(TProgressBlock)downloadProgress
                        completion:(TCompletionBlock)completion{
    if(baseRequest.requestSerializer){
        self.sessionManager.requestSerializer = baseRequest.requestSerializer;
    }
    if(baseRequest.responseSerializer){
        self.sessionManager.responseSerializer = baseRequest.responseSerializer;
    }
    
    NSDictionary *customHeaders = [baseRequest addCustomHeaders];
    if ([customHeaders allKeys] > 0) {
        NSArray *allKeys = [customHeaders allKeys];
        if ([allKeys count] >0) {
            [customHeaders enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
                [self.sessionManager.requestSerializer setValue:value forHTTPHeaderField:key];
            }];
        }
    }
    
    NSError *serializationError = nil;
    NSMutableURLRequest *request = [self.sessionManager.requestSerializer requestWithMethod:[baseRequest requestMethodString] URLString:[baseRequest jointRequestUrlString] parameters:[baseRequest validRequestParameter] error:&serializationError];
    
    if (serializationError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
            TResponse *res = [TResponse responseWithSessionTask:nil responseObject:nil error:serializationError];
                completion(res);
            }
        });
        return 0;
    }
    __block NSURLSessionTask *task = [self.sessionManager dataTaskWithRequest:request uploadProgress:^(NSProgress * _Nonnull _uploadProgress) {
        if(uploadProgress){
            uploadProgress(_uploadProgress);
        }
    } downloadProgress:^(NSProgress * _Nonnull _downloadProgress) {
        if(downloadProgress){
            downloadProgress(_downloadProgress);
        }
    } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        T_PTHREAD_LOCK([self.taskIdDic removeObjectForKey:@(task.taskIdentifier)];)
        
        if (completion) {
           TResponse *res = [TResponse responseWithSessionTask:task responseObject:responseObject error:serializationError];
            completion(res);
        }
    }];
    NSNumber *taskIdentifier = @(task.taskIdentifier);
    T_PTHREAD_LOCK(self.taskIdDic[taskIdentifier] = task;)
    [task resume];
    return taskIdentifier;
}

-(void)cancelNetworking:(NSNumber *)taskIdentifier{
    T_PTHREAD_LOCK(if([self.taskIdDic objectForKey:taskIdentifier]){
        NSURLSessionTask *task = [self.taskIdDic objectForKey:taskIdentifier];
        [task cancel];
        [self.taskIdDic removeObjectForKey:taskIdentifier];
    })
}

- (void)cancelAllNetworking:(NSArray *)array{
    T_PTHREAD_LOCK(for(NSNumber *taskIdentifier in array){
        [self cancelNetworking:taskIdentifier];
    })
}

-(AFHTTPSessionManager *)sessionManager{
    if(!_sessionManager){
        _sessionManager = [AFHTTPSessionManager manager];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        [_sessionManager.requestSerializer setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [_sessionManager.requestSerializer setValue:@"application/json"
                                 forHTTPHeaderField:@"Content-Type"];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    }
    return _sessionManager;
}

@end
