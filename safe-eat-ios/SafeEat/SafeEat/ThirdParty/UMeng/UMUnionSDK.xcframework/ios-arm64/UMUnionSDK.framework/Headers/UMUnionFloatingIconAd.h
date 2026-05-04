//
//  UMUnionFloatingIconAd.h
//  UMUnionSDK
//
//  Created by yanke on 2022/1/17.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class UMUnionFloatingIconAd;

@protocol UMUnionFloatingIconAdDelegate <NSObject>
@optional
/// 请求广告数据成功回调
- (void)uadFloatingIconDidLoad:(UMUnionFloatingIconAd *)floatingIconAd;

/// 请求广告数据失败回调
/// @param error 失败信息
- (void)uadFloatingIconDidLoad:(UMUnionFloatingIconAd *)floatingIconAd failWithError:(NSError *_Nullable)error;

/// 广告显示回调
- (void)uadFloatingIconExposeSuccess:(UMUnionFloatingIconAd *)floatingIconAd;

/// 广告点击回调
- (void)uadFloatingIconClicked:(UMUnionFloatingIconAd *)floatingIconAd;

/// 广告关闭回调
- (void)uadFloatingIconClose:(UMUnionFloatingIconAd *)floatingIconAd;

/// 广告详情页即将打开
- (void)uadFloatingIconDetailViewWillPresent:(UMUnionFloatingIconAd *)floatingIconAd;

/// 广告详情页关闭
- (void)uadFloatingIconDetailViewClosed:(UMUnionFloatingIconAd *)floatingIconAd;

@end

@interface UMUnionFloatingIconAd : NSObject

@property(nonatomic, weak) id<UMUnionFloatingIconAdDelegate> delegate;
//父视图 不设置默认展示在keywindow
@property(nonatomic, weak) UIView *parentView;
//起始位置 不设置默认展示在右下脚
@property(nonatomic, assign) CGPoint startPoint;
//是否可移动 默认不能移动
@property(nonatomic, assign) BOOL canMove;

/**
 *  构造方法
 *  slotId:代码位 ID
 */
- (instancetype)initWithSlotId:(NSString *)slotId;

/**
 *  广告请求并显示
 */
- (void)loadAdAndShow:(UIViewController *)rootViewController;
/**
 *  广告请求
 */
- (void)loadAd;
/**
 *  广告展示
 */
- (void)presentAdWithRootViewController:(UIViewController *)rootViewController;
/**
 *  广告价格：单位分
*/
- (NSNumber *)eCPM;
@end

NS_ASSUME_NONNULL_END
