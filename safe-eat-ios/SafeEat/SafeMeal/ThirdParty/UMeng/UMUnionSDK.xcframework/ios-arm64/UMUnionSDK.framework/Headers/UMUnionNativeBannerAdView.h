//
//  UMUnionNativeAdView.h
//  UMessage
//
//  Created by yanke on 2021/11/30.
//  Copyright © 2021 umeng.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UMUnionSDK/UMUnionEnum.h>

@class UMUnionNativeBannerAdView,UMUnionNativeAdDataModel,UMUnionMediaView;

NS_ASSUME_NONNULL_BEGIN

@protocol UMUnionNativeAdViewDelegate <NSObject>

@optional
/**
 *  广告曝光回调
 *  nativeAdView UMUnionNativeBannerAdView 实例
 */
- (void)nativeAdViewExpose:(UMUnionNativeBannerAdView *)nativeAdView;

/**
 *  广告点击回调
 *  nativeAdView UMUnionNativeBannerAdView 实例
 */
- (void)nativeAdViewDidClick:(UMUnionNativeBannerAdView *)nativeAdView;

/**
 *  广告错误事件回调
 *  error 失败信息
 */
- (void)nativeAdViewWithError:(NSError *)error;

/**
 *  视频广告播放状态回调
 *  nativeAdView UMUnionNativeBannerAdView 实例
 *  status 广告播放状态
 */
- (void)nativeAdView:(UMUnionNativeBannerAdView *)nativeAdView mediaPlayerStatus:(UMUnionMediaPlayerStatus)status;

/**
 *  广告详情页即将打开
 *  nativeAdView UMUnionNativeBannerAdView 实例
*/
- (void)nativeAdViewDetailViewWillPresent:(UMUnionNativeBannerAdView *)nativeAdView;

/**
 *  广告详情页关闭
 *  nativeAdView UMUnionNativeBannerAdView 实例
 */
- (void)nativeAdViewDetailViewClosed:(UMUnionNativeBannerAdView *)nativeAdView;

@end

@interface UMUnionNativeBannerAdView : UIView

/**
 *  绑定的数据对象
 */
@property (nonatomic, strong, readonly) UMUnionNativeAdDataModel *dataModel;

/**
 *  广告View代理回调
 */
@property (nonatomic, weak) id<UMUnionNativeAdViewDelegate> delegate;

/**
 *  开发者需传入用来弹出目标页的ViewController，一般为当前ViewController
 */
@property (nonatomic, weak) UIViewController *viewController;

/**
 *  视频广告View，绑定数据对象后自动生成
 */
@property (nonatomic, strong, readonly) UMUnionMediaView *mediaView;

/**
 *  自渲染绑定模型
 *  dataModel：数据对象，必传字段
 *  clickableViews：可点击的视图数组，此数组内的广告元素才可以响应广告对应的点击事件
 */
- (void)bindDataModel:(UMUnionNativeAdDataModel *)dataModel
            clickableViews:(NSArray<UIView *> * __nonnull)clickableViews;

@end

NS_ASSUME_NONNULL_END
