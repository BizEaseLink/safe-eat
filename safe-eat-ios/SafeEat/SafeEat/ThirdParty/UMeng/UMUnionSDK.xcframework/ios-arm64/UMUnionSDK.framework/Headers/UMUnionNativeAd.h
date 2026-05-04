//
//  UMUnionNativeAd.h
//  UMessage
//
//  Created by yanke on 2021/11/30.
//  Copyright © 2021 umeng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UMUnionNativeAdDataModel,UMUnionNativeAd;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UMUnionNativeAdType) {
    /**自渲染小图*/
    UMUnionNativeAdTypeDefault = 0,
    /**自渲染大图*/
    UMUnionNativeAdTypeBigImg = 1,
    /**自渲染Feed*/
    UMUnionNativeAdTypeFeed = 2,
};

@protocol UMUnionNativeAdDelegate <NSObject>

/**
 *  广告数据回调
 *  nativeAdDataModel：广告数据
 *  error：错误信息
 */
- (void)nativeAdLoaded:(UMUnionNativeAdDataModel * _Nullable)nativeAdDataModel error:(NSError * _Nullable)error;

/// 素材渲染成功回调
/// 回调说明：媒体收到此回调后调用show接口
- (void)nativeAdRenderSuccess:(UMUnionNativeAd *)nativeAd model:(UMUnionNativeAdDataModel * _Nullable)nativeAdDataModel;

/// 素材渲染失败回调
/// 可能情况：渲染失败、展示时产生的异常
/// @param error 失败信息
- (void)nativeAdRenderFail:(UMUnionNativeAd *)nativeAd model:(UMUnionNativeAdDataModel * _Nullable)nativeAdDataModel error:(NSError *_Nullable)error;
@end

@interface UMUnionNativeAd : NSObject

/**
 *  构造方法
 *  slotId：代码位Id
 *  type：自渲染广告类型
 */
- (instancetype)initWithSlotId:(NSString *)slotId type:(UMUnionNativeAdType)type;

@property (nonatomic, weak) id<UMUnionNativeAdDelegate> delegate;
/**
 加载广告
 */
- (void)loadAd;
@end

NS_ASSUME_NONNULL_END
