//
//  UMUnionBannerAd.h
//  UMUnionSDK
//
//  Created by yanke on 2022/1/17.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class UMUnionBannerAd;

@protocol UMUnionBannerAdDelegate <NSObject>
@optional
/// 请求广告数据成功回调
- (void)uadBannerDidLoad:(UMUnionBannerAd *)bannerAd;

/// 请求广告数据失败回调
/// @param error 失败信息
- (void)uadBannerDidLoad:(UMUnionBannerAd *)bannerAd failWithError:(NSError *_Nullable)error;

/// 广告显示回调
- (void)uadBannerExposeSuccess:(UMUnionBannerAd *)bannerAd;

/// 广告点击回调
- (void)uadBannerClicked:(UMUnionBannerAd *)bannerAd;

/// 广告关闭回调
- (void)uadBannerClose:(UMUnionBannerAd *)bannerAd;

/// 广告详情页即将打开
- (void)uadBannerViewDetailViewWillPresent:(UMUnionBannerAd *)bannerAd;

/// 广告详情页关闭
- (void)uadBannerViewDetailViewClosed:(UMUnionBannerAd *)bannerAd;

@end

@interface UMUnionBannerAd : NSObject

/**
 *  构造方法
 *  slotId:代码位 ID
 */
- (instancetype)initWithSlotId:(NSString *)slotId;

/**
 *  委托
 */
@property(nonatomic, weak) id<UMUnionBannerAdDelegate> delegate;

/**
 *  是否自动加载
 */
@property(nonatomic, assign) BOOL isAuto;

/**
 *  广告请求并显示
 *  rootViewController:用于显示/跳转广告的UIViewController[非自动加载必选]
 */
- (void)loadAdAndShow:(nullable UIViewController *)rootViewController;

/**
 *  广告请求
 */
- (void)loadAd;

/**
 *  广告展示
 *  rootViewController:用于显示/跳转广告的UIViewController[必选]
 */
- (void)showWithRootViewController:(UIViewController *)rootViewController;

/**
 *  广告展示
 *  rootViewController:用于显示/跳转广告的UIViewController[必选]
 *  sView:用于显示广告的View[必选]
 */
- (void)showWithRootViewController:(UIViewController *)rootViewController superView:(UIView *)sView;

/**
 *广告价格：单位分
*/
- (NSNumber *)eCPM;

@end

NS_ASSUME_NONNULL_END
