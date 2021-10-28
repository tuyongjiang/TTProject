//
//  TNetworkManager.h
//  TNetWork
//
//  Created by 涂永江 on 2021/1/21.
//  Copyright © 2021 涂永江. All rights reserved.
//
//单列
#import <Foundation/Foundation.h>
#import "TBaseRequest.h"
#import "TBaseRequest+instrument.h"
#import "TNetworkDefine.h"
NS_ASSUME_NONNULL_BEGIN

@interface TNetworkManager : NSObject
+ (instancetype) sharedInstance;

//请求方法
- (NSNumber *)sendNetWorkingRequest:(TBaseRequest *)baseRequest
                    uploadProgress:(TProgressBlock)uploadProgress
                  downloadProgress:(TProgressBlock)downloadProgress
                        completion:(TCompletionBlock)completion;

- (void)cancelNetworking:(NSNumber *)taskIdentifier;
- (void)cancelAllNetworking:(NSArray *)array;
@end

NS_ASSUME_NONNULL_END
