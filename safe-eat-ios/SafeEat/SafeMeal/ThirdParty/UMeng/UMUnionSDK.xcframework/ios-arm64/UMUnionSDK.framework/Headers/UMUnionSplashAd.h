//
//  UMUnionSplashAd.h
//  UMUnionSDK
//
//  Created by yanke on 2022/1/25.
//

#import <Foundation/Foundation.h>
#import <UMUnionSDK/UMUnionEnum.h>
#import <UMUnionSDK/UMUnionBiddingProtocol.h>
NS_ASSUME_NONNULL_BEGIN

@class UMUnionSplashAd;

@protocol UMUnionSplashAdDelegate <NSObject>
@optional
/// 请求广告数据成功回调
- (void)uadSplashDidLoad:(UMUnionSplashAd *)splashAd;

/// 请求广告数据失败回调
/// @param error 失败信息
- (void)uadSplashDidLoad:(UMUnionSplashAd *)splashAd failWithError:(NSError *_Nullable)error;

/// 开屏广告渲染成功回调
/// 回调说明：媒体收到此回调后调用show接口
- (void)uadSplashRenderSuccess:(UMUnionSplashAd *)splashAd;

/// 开屏广告渲染失败回调
/// 可能情况：渲染失败、展示时产生的异常
/// @param error 失败信息
- (void)uadSplashRenderFail:(UMUnionSplashAd *)splashAd error:(NSError *_Nullable)error;

/// 广告显示回调
- (void)uadSplashExposeSuccess:(UMUnionSplashAd *)splashAd;

/// 广告点击回调
- (void)uadSplashClicked:(UMUnionSplashAd *)splashAd;

/// 广告关闭回调
- (void)uadSplashClose:(UMUnionSplashAd *)splashAd;

/// 广告剩余时间(s)
- (void)uadSplashTime:(NSUInteger)time;

/// 视频广告播放状态回调
- (void)uadSplash:(UMUnionSplashAd *)splashAd mediaPlayerStatus:(UMUnionMediaPlayerStatus)status;

/// 广告详情页即将打开
- (void)uadSplashDetailViewWillPresent:(UMUnionSplashAd *)splashAd;

/// 广告详情页关闭
- (void)uadSplashViewDetailViewClosed:(UMUnionSplashAd *)splashAd;

@end

@interface UMUnionSplashAd : NSObject<UMUnionBiddingProtocol>

@property(nonatomic, weak) id<UMUnionSplashAdDelegate> delegate;

/**
 *  拉取广告超时时间，默认为5秒
 *  如果拉取成功，立马展示开屏广告，否则放弃此次广告展示。
 */
@property(nonatomic, assign) CGFloat timeout;

/**
 *  关闭摇一摇
 */
@property(nonatomic, assign) BOOL disableShake;

/**
 *  构造方法
 *  slotId：代码位 ID
 */
- (instancetype)initWithSlotId:(NSString *)slotId;

/**
 *  广告请求
 */
- (void)loadAd;

/**
 *  展示半屏广告,调用此方法前需确保uadSplashDidLoad:已回调
 *  window：展示开屏的容器
 *  bottomView：自定义底部View
 *  skipView：自定义”跳过“View
 */
- (void)showAdInWindow:(UIWindow *)window withBottomView:(nullable UIView *)bottomView skipView:(nullable UIView *)skipView;

/**
 *  展示全屏广告,调用此方法前需确保uadSplashDidLoad:已回调
 *  skipView：自定义”跳过“View
 */
- (void)showFullScreenAdInWindow:(UIWindow *)window skipView:(nullable UIView *)skipView;

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
