//
//  UMUnionClientBiddingProtocol.h
//
//
//  Created by yanke on 2023/8/28.
//
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, UMUnionBidLossReason)
{
    UMUnionBidLossLowPrice          = 1, //价格竞败
    UMUnionBidLossFloorPrice        = 2, //底价过滤
    UMUnionBidLossTimeout           = 3, //广告超时返回
    UMUnionBidLossFrequencyControl  = 4, //广告频控
    UMUnionBidLossOther             = 5, //其他原因
};

@protocol UMUnionBiddingProtocol <NSObject>

@optional
/**
 *  竞胜之后调用, 需要在调用广告 show 之前调用
 *
 *  @param secPrice 最高失败出价，竞价方第二名的价格
 *
 */
- (void)win:(nullable NSNumber*)secPrice;

/**
 *  竞败之后或未参竞调用
 *
 *  @param winPrice ：竞胜价格 (单位: 分)
 *  @param lossReason ：失败的原因
 *  @param winId  ：竞胜方ID
 */
- (void)loss:(nullable NSNumber*)winPrice lossReason:(nullable NSNumber*)lossReason winId:(nullable NSString*)winId;

@end
NS_ASSUME_NONNULL_END
