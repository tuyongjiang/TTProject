//
//  TBaseRequest+preprocess.h
//  TNetWork
//
//  Created by 涂永江 on 2021/1/25.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import "TBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface TBaseRequest (preprocess)
#pragma - 预处理
//当我们需要为请求加上默认参数,默认头,如设备id ,token ,那么直接重载方法即可.
- (NSDictionary *)t_preprocessParameter:(NSDictionary *)parameter;
- (NSDictionary *)t_preprocessHTTPHeaderField:(NSDictionary *)HTTPHeaderField;
@end

NS_ASSUME_NONNULL_END
