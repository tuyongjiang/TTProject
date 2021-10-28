//
//  TNetworkDefine.h
//  TNetWork
//
//  Created by 涂永江 on 2021/1/21.
//  Copyright © 2021 涂永江. All rights reserved.
//

#ifndef TNetworkDefine_h
#define TNetworkDefine_h

#ifdef DEBUG
#define TLog(...) NSLog(@"%s line number:%d \n %@\n\n",__func__,__LINE__,[NSString stringWithFormat:__VA_ARGS__])
#else
#define TLog(...)
#endif

#define TNETWORK_QUEUE_ASYNC(queue, block)\
if (strcmp(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL), dispatch_queue_get_label(queue)) == 0) {\
block();\
} else {\
dispatch_async(queue, block);\
}

#define TNETWORK_MAIN_QUEUE_ASYNC(block) TNETWORK_QUEUE_ASYNC(dispatch_get_main_queue(), block)


#define T_PTHREAD_LOCK(...) \
pthread_mutex_lock(&self->_lock); \
__VA_ARGS__ \
pthread_mutex_unlock(&self->_lock);

typedef NS_ENUM (NSInteger,TNetWorkResponseCacheType){
    //不缓存
    TNetWorkResponseCacheTypeNone,
    //内存缓存
    TNetWorkResponseCacheTypeMemory,
    //磁盘缓存
    TNetWorkResponseCacheTypeDisk
};

typedef NS_ENUM(NSInteger ,TNetWorkReadResponseCacheType){
    //默认不取缓存
    TNetWorkReadResponseCacheTypeNone,
    //获取到缓存继续请求
    TNetWorkReadResponseCacheTypeContinueNetWork,
    //获取到缓存取消请求
    TNetWorkReadResponseCacheTypeCancelNetWork
};

typedef NS_ENUM(NSInteger,TNetWorkRequestType){
    TNetWorkRequestTypeGET,
    TNetWorkRequestTypePOST,
    TNetWorkRequestTypePUT,
    TNetWorkRequestTypeDELETE,
    TRequestMethodTypeHEAD,
    TRequestMethodTypePATCH
};

typedef NS_ENUM(NSInteger,TNetworkRepeatStrategy){
    //允许重复请求
    TNetworkRepeatStrategyAllAllowed,
    //取消最旧的网络请求
    TNetworkRepeatStrategyCancelOldest,
    //取消最新的网络请求
    TNetworkRepeatStrategyCancelNewest
};

typedef NS_ENUM(NSInteger,TNetworkReleaseStrategy) {
    // 网络任务会持有 YBBaseRequest 实例，网络任务完成 YBBaseRequest 实例才会释放
    TNetworkReleaseStrategyHoldRequest,
    // 网络请求将随着 YBBaseRequest 实例的释放而取消
    TNetworkReleaseStrategyWhenRequestDealloc,
};

@class TResponse;
@class TBaseRequest;
typedef void (^TCompletionBlock)(TResponse *response);
typedef void (^TProgressBlock)(NSProgress *progress);
typedef void (^TSuccessBlock)(TResponse *response);
typedef void (^TFailureBlock)(TResponse *response);


@protocol TResponseDelegate <NSObject>

- (void)requestSuccess:(TBaseRequest *)baseRequest successWithResponse:(TResponse *)response;

- (void)requestFailure:(TBaseRequest *)baseRequest failureWithResponse:(TResponse *)response;

- (void)requestProgress:(TBaseRequest *)baseRequest
         uploadProgress:(NSProgress *)uploadProgress;

@end

@protocol TResponseReformerDelegate <NSObject>
- (id)reformer:(TBaseRequest *)baseRequest response:(TResponse *)response;
@end
#endif /* TNetworkDefine_h */
