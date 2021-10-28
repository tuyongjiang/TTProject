//
//  TCache.h
//  TNetWork
//
//  Created by 涂永江 on 2021/1/26.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TNetworkDefine.h"
#import <YYCache/YYCache.h>
NS_ASSUME_NONNULL_BEGIN

@interface TCache : NSObject

@property (nonatomic , assign) TNetWorkResponseCacheType cacheType;
@property (nonatomic , assign) TNetWorkReadResponseCacheType readCacheType;

//提供给外面检查数据是否可用在缓存.
@property (nonatomic , copy) BOOL(^shouldCacheBlock)(TResponse *response);

+ (void)removeMemoryCache;
+ (void)removeDiskCache;
+ (NSInteger)getDiskSize;


- (void)setObject:(nullable id<NSCoding>)object forKey:(id)key;
- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key,id<NSCoding> _Nullable object))block;
@end

NS_ASSUME_NONNULL_END
