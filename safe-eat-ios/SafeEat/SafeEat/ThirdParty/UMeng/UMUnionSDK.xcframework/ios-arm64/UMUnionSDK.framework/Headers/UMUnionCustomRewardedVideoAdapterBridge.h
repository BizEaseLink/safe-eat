//
//  UMUnionCustomRewardedVideoAdapterBridge.h
//  UMUnionSDK
//
//  Created by yanke on 2026/1/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UMUnionCustomRewardedVideoAdapter;

/// 自定义激励视频广告的adapter的回调协议
@protocol UMUnionCustomRewardedVideoAdapterBridge <NSObject>
@optional

/// 在广告加载完成时调用该方法，直接调用即可，无需做响应判断
/// @param adapter 当前适配器
/// @param ext 回传信息
- (void)rewardVideoAd:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter didLoadWithExt:(NSDictionary *)ext;
/// 在广告加载失败时调用该方法，直接调用即可，无需做响应判断
/// @param adapter 当前适配器
/// @param error 错误信息
/// @param ext 回传信息
- (void)rewardVideoAd:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter didLoadFailWithError:(NSError *_Nullable)error ext:(NSDictionary *)ext;
/// 广告展示
/// @param adapter 当前适配器
- (void)rewardVideoAdDidShow:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter;
/// 在广告点击事件触发时调用，直接调用即可，无需做响应判断
/// @param adapter 当前适配器
- (void)rewardVideoAdDidClick:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter;
/// 在广告关闭时调用，直接调用即可，无需做响应判断
/// @param adapter 当前适配器
- (void)rewardVideoAdDidClose:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter;
/// 在广告视频播放完成或者出错时调用，直接调用即可，无需做响应判断
/// @param adapter 当前适配器
/// @param error 播放错误
- (void)rewardVideoAd:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter didPlayFinishWithError:(NSError *)error;
/// 广告详情页关闭
- (void)rewardVideoViewDetailViewClosed:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter;
/// 激励结果调用，直接调用即可，无需做响应判断
/// @param adapter 当前适配器
/// @param info 辅助信息
/// @param error 错误信息
- (void)rewardVideoAdRewardDidSucceed:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter info:(nullable NSDictionary *)info error:(NSError *)error;
/// 在模板广告渲染成功时调用
/// @param adapter 当前适配器
- (void)rewardVideoAdDidRenderSuccess:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter;

/// 在广告渲染失败时调用
/// @param adapter 当前适配器
/// @param error 错误信息
/// @param ext 回传信息
- (void)rewardVideoAd:(id<UMUnionCustomRewardedVideoAdapter>_Nonnull)adapter didRenderFailedWithError:(NSError *)error ext:(nullable NSDictionary *)ext;

@end

NS_ASSUME_NONNULL_END
