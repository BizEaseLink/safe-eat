//
//  UMUnionCustomAdapter.h
//  UMUnionSDK
//
//  Created by yanke on 2026/1/6.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 自定义adapter广告类型基本协议
@protocol UMUnionCustomAdapter <NSObject>

@optional
- (void)win:(nullable NSNumber *)secPrice;
- (void)loss:(nullable NSNumber *)winPrice lossReason:(nullable NSNumber *)lossReason winId:(nullable NSString *)winId;

@end

NS_ASSUME_NONNULL_END
