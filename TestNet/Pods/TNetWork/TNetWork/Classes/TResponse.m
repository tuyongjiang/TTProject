//
//  TResponse.m
//  TNetWork
//
//  Created by 涂永江 on 2021/1/21.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import "TResponse.h"

@implementation TResponse
+ (instancetype)responseWithSessionTask:(nullable NSURLSessionTask *)sessionTask
                         responseObject:(nullable id)responseObject
                                  error:(nullable NSError *)error{
    TResponse *Res = [TResponse new];
    Res->_sessionTask = sessionTask;
    Res->_responseObject = responseObject;
    Res->_error = error;
    return Res;
}
@end
