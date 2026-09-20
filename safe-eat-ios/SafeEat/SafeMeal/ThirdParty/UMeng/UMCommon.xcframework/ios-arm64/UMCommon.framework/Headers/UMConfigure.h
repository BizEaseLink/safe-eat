//
//  UMConfigure.h
//  UMCommon
//
//  Created by San Zhang on 9/6/16.
//  Copyright © 2016 UMeng. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 归因结果回调 block。
 归因成功时 attribution 非空、errorCode=0；归因失败时 attribution 为 nil、errorCode=-1。
 */
typedef void(^UMAttributionResultBlock)(NSDictionary * _Nullable attribution, NSInteger errorCode);

@interface UMConfigure : NSObject

/** 初始化友盟所有组件产品
 @param appKey 开发者在友盟官网申请的appkey.
 @param channel 渠道标识，可设置nil表示"App Store".
 */
+ (void)initWithAppkey:(NSString *)appKey channel:(NSString *)channel;

/** 设置是否在console输出sdk的log信息.
 @param bFlag 默认NO(不输出log); 设置为YES, 输出可供调试参考的log信息. 发布产品时必须设置为NO.
 */
+ (void)setLogEnabled:(BOOL)bFlag;

/** 设置是否对日志信息进行加密, 默认NO(不加密).
 @param value 设置为YES, umeng SDK 会将日志信息做加密处理
 */
+ (void)setEncryptEnabled:(BOOL)value;

+ (NSString *)umidString;

/**
 集成测试需要device_id
 */
+ (NSString*)deviceIDForIntegration;

/** 是否开启统计，默认为YES(开启状态)
 @param value 设置为NO,可关闭友盟统计功能.
*/
+ (void)setAnalyticsEnabled:(BOOL)value;

//获取zid
+ (NSString *)getUmengZID;

//是否发送海外域名，默认为YES发送海外域名
+(void)isInernational:(BOOL)bFlag;

//获取本次SessionID
+ (NSString *)getSessionID;

+ (void)resetStorePrefix:(NSString *)prefix;
+ (void)resetStorePath;

/** 设置上报统计日志的主域名。此函数必须在SDK初始化函数调用之前调用。
 @param primaryDomain 传日志的主域名收数地址,参数不能为null或者空串。例如：https://www.umeng.com
*/
+ (void)setDomain:(NSString *)primaryDomain;

/** 进端采集开关
 @param flag YES 开启采集; NO 禁止采集
*/
+ (void)enablePi:(BOOL)flag;

/** 进端采集
 @param connectionOptions: UIScene模式下的启动参数
*/
+ (void)handleSceneWillConnectWithOptions:(id)connectionOptions;

/** ASA归因采集开关，默认为YES(开启)。
 需在 SDK 初始化前调用。
 @param enabled 设置为NO可关闭 ASA token 采集。
*/
+ (void)setASAEnabled:(BOOL)enabled;

/** SKAN 归因开关，默认为NO(关闭)。需在 SDK 初始化前调用。
 @param enabled 设置为YES可开启 SKAdNetwork 归因注册。
*/
+ (void)setSKANEnabled:(BOOL)enabled;

/** 注册安装归因结果回调。
 SDK 初始化后自动查询服务端归因结果，通过 block 回调给开发者。
 可在 initWithAppkey:channel: 前后调用，后注册覆盖前注册。
 回调始终在主线程执行。
 @param listener 归因结果回调 block，传 nil 可取消注册。
*/
+ (void)setOnAttributionResultListener:(nullable UMAttributionResultBlock)listener;

@end
