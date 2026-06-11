//
//  UMUnionIntersititialAd.h
//  UMUnionSDK
//
//  Created by yanke on 2021/12/28.
//

#import <Foundation/Foundation.h>
#import <UMUnionSDK/UMUnionEnum.h>
#import <UMUnionSDK/UMUnionBiddingProtocol.h>
NS_ASSUME_NONNULL_BEGIN

@class UMUnionIntersititialAd;

@protocol UMUnionInterstitialAdDelegate <NSObject>
@optional
/// 请求广告数据成功回调
- (void)uadInterstitialDidLoad:(UMUnionIntersititialAd *)intersititialAd;

/// 请求广告数据失败回调
/// @param error 失败信息
- (void)uadInterstitialDidLoad:(UMUnionIntersititialAd *)intersititialAd failWithError:(NSError *_Nullable)error;

/// 广告渲染成功回调
/// 回调说明：媒体收到此回调后调用show接口
- (void)uadInterstitialRenderSuccess:(UMUnionIntersititialAd *)intersititialAd;

/// 广告渲染失败回调
/// 可能情况：渲染失败、展示时产生的异常
/// @param error 失败信息
- (void)uadInterstitialRenderFail:(UMUnionIntersititialAd *)intersititialAd error:(NSError *_Nullable)error;

/// 广告显示回调
- (void)uadInterstitialExposeSuccess:(UMUnionIntersititialAd *)intersititialAd;

/// 广告点击回调
- (void)uadInterstitialClicked:(UMUnionIntersititialAd *)intersititialAd;

/// 广告关闭回调
- (void)uadInterstitialClose:(UMUnionIntersititialAd *)intersititialAd;

/// 视频广告播放状态回调
- (void)uadInterstitial:(UMUnionIntersititialAd *)intersititialAd mediaPlayerStatus:(UMUnionMediaPlayerStatus)status;

/// 广告详情页即将打开
- (void)uadInterstitialDetailViewWillPresent:(UMUnionIntersititialAd *)intersititialAd;

/// 广告详情页关闭
- (void)uadInterstitialDetailViewClosed:(UMUnionIntersititialAd *)intersititialAd;

@end

@interface UMUnionIntersititialAd : NSObject<UMUnionBiddingProtocol>

@property(nonatomic, weak) id<UMUnionInterstitialAdDelegate> delegate;

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
