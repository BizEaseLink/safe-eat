//
//  UMUnionCustomSplashAdapter.h
//  UMUnionSDK
//
//  Created by yanke on 2026/1/6.
//

#import <Foundation/Foundation.h>
#import "UMUnionCustomAdapter.h"
#import "UMUnionCustomSplashAdapterBridge.h"

NS_ASSUME_NONNULL_BEGIN

/// 开屏广告自定义实现协议
@protocol UMUnionCustomSplashAdapter <UMUnionCustomAdapter>

- (instancetype)initWithSlotID:(NSString *)slotID appID:(NSString *)appID parameter:(NSDictionary *)parameter;
- (void)loadAd;
- (void)addExtInfo:(NSDictionary *)extInfo;
- (void)showInWindow:(UIWindow *)window;

@optional

/// 代理，开发者需使用该对象回调事件，Objective-C下自动生成无需设置，Swift需声明
@property (nonatomic, weak, nullable) id<UMUnionCustomSplashAdapterBridge> umBridge;
@end

NS_ASSUME_NONNULL_END
