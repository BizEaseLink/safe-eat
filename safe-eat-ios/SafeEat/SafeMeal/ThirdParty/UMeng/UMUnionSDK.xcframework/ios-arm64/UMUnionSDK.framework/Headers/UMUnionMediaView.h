//
//  UMUnionMediaView.h
//  UMUnionSDK
//
//  Created by yanke on 2022/3/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UMUnionMediaView : UIView

/**
 * 广告时长(ms)
 */
- (CGFloat)videoDuration;

/**
 * 广告已播放时长(ms)
 */
- (CGFloat)videoPlayTime;

/**
 播放视频
 */
- (void)play;

/**
 暂停视频
 */
- (void)pause;

/**
 播放静音开关 YES:静音
 */
- (void)muteEnable:(BOOL)flag;

@end

NS_ASSUME_NONNULL_END
