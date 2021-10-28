//
//  TResponse.h
//  TNetWork
//
//  Created by 涂永江 on 2021/1/21.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TResponse : NSObject

@property (nonatomic ,strong,nullable) id responseObject;
@property (nonatomic ,strong,readonly,nullable) NSError *error;
@property (nonatomic, strong, readonly, nullable) NSURLSessionTask *sessionTask;
+ (instancetype)responseWithSessionTask:(nullable NSURLSessionTask *)sessionTask
                         responseObject:(nullable id)responseObject
                                  error:(nullable NSError *)error;

    
@end

NS_ASSUME_NONNULL_END
