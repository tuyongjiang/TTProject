//
//  TCache.m
//  TNetWork
//
//  Created by 涂永江 on 2021/1/26.
//  Copyright © 2021 涂永江. All rights reserved.
//

#import "TCache.h"

@interface TCacheObject : NSObject <NSCoding>
@property (nonatomic , strong) id<NSCoding> object;
@property (nonatomic , strong) NSDate        *updateDate;
@end

@implementation TCacheObject

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [self init];
    if (self) {
        self.object = [coder decodeObjectForKey:NSStringFromSelector(@selector(object))];
        self.updateDate = [coder decodeObjectForKey:NSStringFromSelector(@selector(updateDate))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:self.object forKey:NSStringFromSelector(@selector(object))];
    [coder encodeObject:self.updateDate forKey:NSStringFromSelector(@selector(updateDate))];
}

@end


@interface TCache ()

@end

static NSString * const TCacheName = @"TCacheName";
static YYMemoryCache *_memoryCache;
static YYDiskCache   *_diskCache;
@implementation TCache

#pragma mark - pulic
+ (void)removeMemoryCache{
    [[TCache memoryCache] removeAllObjects];
}

+ (void)removeDiskCache{
    [[TCache diskCache] removeAllObjects];
}

+ (NSInteger)getDiskSize{
    return [TCache diskCache].totalCost / 1024.0 /1024.0;
}

- (void)setObject:(nullable id<NSCoding>)object forKey:(id)key{
    if(self.cacheType == TNetWorkResponseCacheTypeNone) return;
    TCacheObject *cacheObject = [TCacheObject new];
    cacheObject.object = object;
    cacheObject.updateDate = [NSDate date];
    if(self.cacheType & TNetWorkResponseCacheTypeMemory){
        [[TCache memoryCache] setObject:cacheObject forKey:key];
    }
    if(self.cacheType & TNetWorkResponseCacheTypeDisk){
        [[TCache diskCache] setObject:cacheObject forKey:key withBlock:^{}];
    }
}

- (void)objectForKey:(NSString *)key withBlock:(void(^)(NSString *key,id<NSCoding> _Nullable object))block{
    if (!block)return;
    
    void(^callBack)(id<NSCoding>) = ^(id<NSCoding> obj){
        if (obj && [(NSObject *)obj isKindOfClass:[TCacheObject class]]) {
            TCacheObject *cacheObject = (TCacheObject *)obj;
            block(key,cacheObject.object);
        }else{
            block(key,nil);
        }
    };
    
  id object = [[TCache memoryCache] objectForKey:key];
    if(object){
        callBack(object);
    }else{
        [[TCache diskCache] objectForKey:key withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
            if (object && ![TCache.memoryCache objectForKey:key]) {
                
                [[TCache memoryCache] setObject:object forKey:key];
            }
            callBack(object);
        }];
    }
}

+ (YYMemoryCache *)memoryCache{
    if(!_memoryCache){
        _memoryCache = [YYMemoryCache new];
        _memoryCache.name = TCacheName;
    }
    return _memoryCache;
}
+ (YYDiskCache *)diskCache{
    if(_diskCache){
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:TCacheName];
        _diskCache = [[YYDiskCache alloc]initWithPath:path];
    }
    return _diskCache;
}
@end
