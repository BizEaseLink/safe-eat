//
//  UMUnionSdk.h
//  UMessage
//
//  Created by yanke on 2021/11/30.
//  Copyright © 2021 umeng.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UMUnionSDK/UMUnionBannerAd.h>

NS_ASSUME_NONNULL_BEGIN

@interface UMUnionAdSdk : NSObject
/**
 *  启动广告SDK
 */
+ (void)start;

/**
 *  自动加载浮窗广告
 *  slotId：代码位Id
 *  delegate:委托
 *  rootViewController：用于跳转广告的UIViewController
 */
+ (void)autoLoadBannerAdAndShowWithSlotId:(NSString *)slotId delegate:(id<UMUnionBannerAdDelegate> __nullable)delegate rootVC:(nullable UIViewController *)rootViewController;

/**
 *  关闭自动加载浮窗广告
 */
+ (void)endAutoLoadBannerAdAndShow;

/**
 *  是否打印日志
 */
+ (void)enableLogs:(BOOL)enable;

/**
 *  获取版本号
 */
+ (NSString *)sdkVersion;


+ (void)unionId:(NSString *)unionId unionIdVersion:(NSString *)unionIdVersion lastUnionId:(NSString *)lastUnionId lastUnionIdVersion:(NSString *)lastUnionIdVersion;
@end

NS_ASSUME_NONNULL_END
