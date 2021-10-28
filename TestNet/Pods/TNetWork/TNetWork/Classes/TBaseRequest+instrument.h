//
//  TBaseRequest+instrument.h
//  TNetWork
//
//  Created by 涂永江 on 2021/1/25.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import "TBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface TBaseRequest (instrument)
#pragma - 获取请求的信息
- (NSString *)requestMethodString;
- (NSString *)jointRequestUrlString;
- (id)validRequestParameter;
- (NSDictionary *)addCustomHeaders;

@end

NS_ASSUME_NONNULL_END
