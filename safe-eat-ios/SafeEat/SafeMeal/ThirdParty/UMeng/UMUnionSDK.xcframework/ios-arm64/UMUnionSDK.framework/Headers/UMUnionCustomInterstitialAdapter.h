//
//  UMUnionCustomInterstitialAdapter.h
//  UMUnionSDK
//
//  Created by yanke on 2026/1/6.
//

#import <Foundation/Foundation.h>
#import "UMUnionCustomAdapter.h"
#import "UMUnionCustomInterstitialAdapterBridge.h"

NS_ASSUME_NONNULL_BEGIN

/// 自定义插屏广告的adapter广告协议
@protocol UMUnionCustomInterstitialAdapter <UMUnionCustomAdapter>

- (instancetype)initWithSlotID:(NSString *)slotID appID:(NSString *)appID parameter:(NSDictionary *)parameter;
- (void)loadAd;
- (void)showAd:(UIViewController *)vc;

@optional
/// 代理，开发者需使用该对象回调事件，Objective-C下自动生成无需设置，Swift需声明
@property (nonatomic, weak, nullable) id<UMUnionCustomInterstitialAdapterBridge> umBridge;
@end

NS_ASSUME_NONNULL_END
