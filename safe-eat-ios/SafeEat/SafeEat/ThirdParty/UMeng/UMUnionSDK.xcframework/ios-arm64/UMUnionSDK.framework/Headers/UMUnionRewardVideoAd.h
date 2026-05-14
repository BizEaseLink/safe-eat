//
//  UMUnionRewardVideoAd.h
//  UMUnionSDK
//
//  Created by yanke on 2025/8/7.
//

#import <Foundation/Foundation.h>
#import <UMUnionSDK/UMUnionEnum.h>
#import <UMUnionSDK/UMUnionBiddingProtocol.h>
NS_ASSUME_NONNULL_BEGIN

@class UMUnionRewardVideoAd;

@protocol UMUnionRewardVideoAdDelegate <NSObject>
@optional
/// 请求广告数据成功回调
- (void)uadRewardVideoDidLoad:(UMUnionRewardVideoAd *)rewardVideoAd;

/// 请求广告数据失败回调
/// @param error 失败信息
- (void)uadRewardVideoDidLoad:(UMUnionRewardVideoAd *)rewardVideoAd failWithError:(NSError *_Nullable)error;

/// 广告渲染成功回调
/// 回调说明：媒体收到此回调后调用show接口
- (void)uadRewardVideoRenderSuccess:(UMUnionRewardVideoAd *)rewardVideoAd;

/// 广告渲染失败回调
/// 可能情况：渲染失败、展示时产生的异常
/// @param error 失败信息
- (void)uadRewardVideoRenderFail:(UMUnionRewardVideoAd *)rewardVideoAd error:(NSError *_Nullable)error;

/// 广告显示回调
- (void)uadRewardVideoExposeSuccess:(UMUnionRewardVideoAd *)rewardVideoAd;

/// 广告点击回调
- (void)uadRewardVideoClicked:(UMUnionRewardVideoAd *)rewardVideoAd;

/// 广告关闭回调
- (void)uadRewardVideoClose:(UMUnionRewardVideoAd *)rewardVideoAd;

/// 视频广告播放状态回调
- (void)uadRewardVideo:(UMUnionRewardVideoAd *)rewardVideoAd mediaPlayerStatus:(UMUnionMediaPlayerStatus)status;

/// 广告详情页即将打开
- (void)uadRewardVideoDetailViewWillPresent:(UMUnionRewardVideoAd *)rewardVideoAd;

/// 广告详情页关闭
- (void)uadRewardVideoDetailViewClosed:(UMUnionRewardVideoAd *)rewardVideoAd;

/// 激励视频广告播放达到激励条件回调，以此回调作为奖励依据
- (void)uadRewardVideoAdRewardDidSucceed:(UMUnionRewardVideoAd *)rewardVideoAd info:(nullable NSDictionary *)info verify:(BOOL)verify;

/// 激励视频广告未达到激励条件，校验失败
- (void)uadRewardVideoAdRewardDidFail:(UMUnionRewardVideoAd *)rewardVideoAd error:(NSError *_Nullable)error;

@end

@interface UMUnionRewardVideoAd : NSObject<UMUnionBiddingProtocol>

@property(nonatomic, weak) id<UMUnionRewardVideoAdDelegate> delegate;

/**
   可选.
   用户标识，服务端校验使用.
 */
@property (nonatomic, copy, nullable) NSString *userId;

//可选. serialized string.
@property (nonatomic, copy, nullable) NSString *extra;

/**
 *  构造方法
 *  slotId:代码位 ID
 */
- (instancetype)initWithSlotId:(NSString *)slotId;

/**
 *  广告请求并显示
 *  rootViewController：显示插播广告的UIViewController【必选】
 */
- (void)loadAdAndShow:(UIViewController *)rootViewController;
/**
 *  广告请求
 */
- (void)loadAd;
/**
 *  广告展示
 *  rootViewController：显示插播广告的UIViewController【必选】
 */
- (void)presentAdWithRootViewController:(UIViewController *)rootViewController;

/**
 *  广告价格：单位分
*/
- (NSNumber *)eCPM;

/**
 *  播放静音开关 YES:静音
 */
- (void)muteEnable:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END
