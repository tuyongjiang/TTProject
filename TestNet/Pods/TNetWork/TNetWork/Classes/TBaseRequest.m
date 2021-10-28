//
//  TBaseRequest.m
//  TNetWork
//
//  Created by 涂永江 on 2021/1/21.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import "TBaseRequest.h"
#import "TBaseRequest+instrument.h"
#import "TBaseRequest+preprocess.h"
#import "TNetworkManager.h"
#import "TResponse.h"
#import <pthread/pthread.h>
@interface TBaseRequest ()
@property (nonatomic , strong) TCache *cache;
@property (nonatomic , copy) TSuccessBlock success;
@property (nonatomic , copy) TFailureBlock failure;
@property (nonatomic , copy) TProgressBlock uploadProgress;
@property (nonatomic , strong) NSMutableSet<NSNumber *> *taskID;
@end

@implementation TBaseRequest
{
    pthread_mutex_t _lock;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        pthread_mutex_init(&_lock, NULL);
        self.releaseStrategy = TNetworkReleaseStrategyHoldRequest;
        self.repeatStrategy = TNetworkRepeatStrategyAllAllowed;
    }
    return self;
}

-(void)dealloc{
    pthread_mutex_destroy(&_lock);
    if(self.releaseStrategy == TNetworkReleaseStrategyWhenRequestDealloc){
        T_PTHREAD_LOCK( NSArray *removeArray = [self.taskID copy];
                       [self.taskID removeAllObjects];)
        [[TNetworkManager sharedInstance] cancelAllNetworking:removeArray];
    }
}

-(void)startRequest:(TSuccessBlock)success failure:(TFailureBlock)failure{
    self.success = success;
    self.failure = failure;
    [self startRequest];
}

- (void)startRequest:(TSuccessBlock)success
      uploadProgress:(TProgressBlock)uploadProgress
             failure:(TFailureBlock)failure{
    self.success = success;
    self.failure = failure;
    self.uploadProgress = uploadProgress;
    [self startRequest];
}

-(void)startRequest{
    BOOL isExecuting;
    T_PTHREAD_LOCK(isExecuting = self.taskID.count > 0;)
    if(isExecuting){
        switch (self.repeatStrategy) {
            case TNetworkRepeatStrategyAllAllowed:
                break;
            case TNetworkRepeatStrategyCancelOldest:{
                T_PTHREAD_LOCK( NSArray *removeArray = [self.taskID copy];
                               [self.taskID removeAllObjects];)
                [[TNetworkManager sharedInstance] cancelAllNetworking:removeArray];
            }
                break;
            case TNetworkRepeatStrategyCancelNewest:
                return;
        }
    }
    NSString *cacheKey = [self getCacheKey];
    if (self.cache.readCacheType == TNetWorkResponseCacheTypeNone) {
        [self request:cacheKey];
        return;
    }
    
    [self.cache objectForKey:cacheKey withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
        if(object){
            TResponse *response = [TResponse responseWithSessionTask:nil responseObject:object error:nil];
            [self responseSuccess:response taskIdentifier:nil cacheKey:cacheKey fromeCache:YES];
        }
        if(self.cache.readCacheType == TNetWorkReadResponseCacheTypeContinueNetWork){
            [self request:cacheKey];
        }else{
            [self clearRequestBlocks];
        }
    }];
}


- (void)request:(NSString *)cacheKey{
    __block NSNumber *taskIdentifier;
     if(self.releaseStrategy == TNetworkReleaseStrategyHoldRequest){
         taskIdentifier = [[TNetworkManager sharedInstance] sendNetWorkingRequest:self uploadProgress:^(NSProgress *progress) {
             [self responseUploadProgress:progress];
         } downloadProgress:^(NSProgress *progress) {
             [self responseDownloadProgress:progress];
         } completion:^(TResponse *response) {
             [self responseCompletion:response taskIdentifier:taskIdentifier cacheKey:cacheKey];
         }];
     }else{
         __weak typeof(self) this = self;
         taskIdentifier = [[TNetworkManager sharedInstance] sendNetWorkingRequest:self uploadProgress:^(NSProgress *progress) {
             __strong typeof(this) self = this;
             if(!self)return ;
             [self responseUploadProgress:progress];
         } downloadProgress:^(NSProgress *progress) {
             __strong typeof(this) self = this;
             if(!self)return ;
             [self responseDownloadProgress:progress];
         } completion:^(TResponse *response) {
             __strong typeof(this) self = this;
             if(!self)return ;
             [self responseCompletion:response taskIdentifier:taskIdentifier cacheKey:cacheKey];
         }];
     }

     T_PTHREAD_LOCK([self.taskID addObject:taskIdentifier];)
}

#pragma mark - 私有方法
- (void)responseUploadProgress:(NSProgress *)progress{
    if(self.uploadProgress){
        self.uploadProgress(progress);
    }
    if(self.delegate && [self respondsToSelector:@selector(requestProgress:uploadProgress:)]){
        [self.delegate requestProgress:self uploadProgress:progress];
    }
}
- (void)responseDownloadProgress:(NSProgress *)progress{
    
}
- (void)responseCompletion:(TResponse *)response taskIdentifier:(NSNumber *)taskIdentifier cacheKey:(NSString *)cacheKey{
 
    if(response.error){
        [self responseFailure:response taskIdentifier:taskIdentifier];
    }else{
        [self responseSuccess:response taskIdentifier:taskIdentifier cacheKey:cacheKey fromeCache:NO];
    }

}

- (void)responseSuccess:(TResponse *)response taskIdentifier:(NSNumber *)taskIdentifier cacheKey:(NSString *)cacheKey fromeCache:(BOOL)fromeCache{
   TNETWORK_MAIN_QUEUE_ASYNC(^{
       if(fromeCache){
           if(self.delegate && [self.delegate respondsToSelector:@selector(requestSuccess:successWithResponse:)]){
               [self.delegate requestSuccess:self successWithResponse:response];
           }
           if(self.success){
               if(self.IsLog){
#ifdef DEBUG
                   NSLog(@"%@",response.responseObject);
#endif
               }
               self.success(response);
           }
           if(taskIdentifier){
               [self.taskID removeObject:taskIdentifier];
           }
       }else{
           if(self.delegate && [self.delegate respondsToSelector:@selector(requestSuccess:successWithResponse:)]){
               [self.delegate requestSuccess:self successWithResponse:response];
           }
           if(self.success){
               if(self.IsLog){
#ifdef DEBUG
                   NSLog(@"%@",response.responseObject);
#endif
               }
               self.success(response);
           }
           if(taskIdentifier){
               [self.taskID removeObject:taskIdentifier];
           }
           [self clearRequestBlocks];
           if(self.cache.shouldCacheBlock){
               BOOL isCache = self.cache.shouldCacheBlock(response);
               if(isCache){
                   [self.cache setObject:response.responseObject forKey:cacheKey];
               }
           }
       }
       
   })
    
}

- (void)responseFailure:(TResponse *)response taskIdentifier:(NSNumber *)taskIdentifier{
   TNETWORK_MAIN_QUEUE_ASYNC(^{
       if(self.delegate && [self.delegate respondsToSelector:@selector(requestFailure:failureWithResponse:)]){
           [self.delegate requestFailure:self failureWithResponse:response];
       }
       if(self.failure){
               if(self.IsLog){
#ifdef DEBUG
                   NSLog(@"%@",response.error);
#endif
               }
           self.failure(response);
       }
       if(taskIdentifier){
           [self.taskID removeObject:taskIdentifier];
       }
       [self clearRequestBlocks];
   })
}

#pragma mark - 请求信息
- (NSString *)requestMethodString{
    switch (self.requestType) {
        case TNetWorkRequestTypeGET:
            return @"GET";
        case TNetWorkRequestTypePOST:
            return @"POST";
        case TNetWorkRequestTypePUT:
            return  @"PUT";
        case TNetWorkRequestTypeDELETE:
            return  @"DELETE";
        case TRequestMethodTypeHEAD:
            return @"HEAD";
        case TRequestMethodTypePATCH:
            return @"PATCH";
    }
}

- (NSString *)jointRequestUrlString{
    if ([self.requestUrl hasPrefix:@"http"] ) {
        return self.requestUrl;
    } else {
        NSURL *baseUrl = [NSURL URLWithString:self.baseUrl];
        NSString *urlString = [NSURL URLWithString:self.requestUrl relativeToURL:baseUrl].absoluteString;
        return urlString;
    }
}

- (id)validRequestParameter{
    if([self respondsToSelector:@selector(t_preprocessParameter:)]){
        return [self t_preprocessParameter:self.requestParameter];
    }
    return self.requestParameter;
}

- (NSDictionary *)addCustomHeaders{
    if([self respondsToSelector:@selector(t_preprocessHTTPHeaderField:)]){
        return [self t_preprocessHTTPHeaderField:self.HTTPHeaderField];
    }
    return self.HTTPHeaderField;
}

- (NSString *)getCacheKey{
    return [NSString stringWithFormat:@"%@%@%@",[self requestMethodString],[self jointRequestUrlString],[self parameterToString:[self validRequestParameter]]];
}

- (NSString *)parameterToString:(NSDictionary *)parameter{
    NSMutableString *string = [NSMutableString string];
    NSArray *allKeys = [parameter.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [[NSString stringWithFormat:@"%@", obj1] compare:[NSString stringWithFormat:@"%@", obj2] options:NSLiteralSearch];
    }];
    for (id key in allKeys) {
        [string appendString:[NSString stringWithFormat:@"%@%@=%@", string.length > 0 ? @"&" : @"?", key, parameter[key]]];
    }
    return string;
}

- (void)clearRequestBlocks{
    self.success = nil;
    self.failure = nil;
    self.uploadProgress = nil;
}

-(TCache *)cache{
    if(!_cache){
        _cache = [[TCache alloc] init];
    }
    return _cache;
}
@end


///打印中文
#ifdef DEBUG
@implementation NSDictionary (Log)
- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level
{
    NSMutableString *mStr = [NSMutableString string];
    NSMutableString *tab = [NSMutableString stringWithString:@""];
    for (int i = 0; i < level; i++) {
        [tab appendString:@"\t"];
    }
    [mStr appendString:@"{\n"];
    NSArray *allKey = self.allKeys;
    for (int i = 0; i < allKey.count; i++) {
        id value = self[allKey[i]];
        NSString *lastSymbol = (allKey.count == i + 1) ? @"":@";";
        if ([value respondsToSelector:@selector(descriptionWithLocale:indent:)]) {

            [mStr appendFormat:@"\t%@%@ = %@%@\n",tab,allKey[i],[value descriptionWithLocale:locale indent:level + 1],lastSymbol];

        } else {

            [mStr appendFormat:@"\t%@%@ = %@%@\n",tab,allKey[i],value,lastSymbol];

        }
    }
    [mStr appendFormat:@"%@}",tab];
    return mStr;
}

@end

@implementation NSArray (Log)

- (NSString *)descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level{
    
    NSMutableString *mStr = [NSMutableString string];
    NSMutableString *tab = [NSMutableString stringWithString:@""];
    for (int i = 0; i < level; i++) {
        [tab appendString:@"\t"];
    }
    [mStr appendString:@"(\n"];
    for (int i = 0; i < self.count; i++) {
        NSString *lastSymbol = (self.count == i + 1) ? @"":@",";
        id value = self[i];
        if ([value respondsToSelector:@selector(descriptionWithLocale:indent:)]) {
            [mStr appendFormat:@"\t%@%@%@\n",tab,[value descriptionWithLocale:locale indent:level + 1],lastSymbol];
        } else {
            [mStr appendFormat:@"\t%@%@%@\n",tab,value,lastSymbol];
        }
    }
    [mStr appendFormat:@"%@)",tab];
    return mStr;
    
}
@end
#endif

