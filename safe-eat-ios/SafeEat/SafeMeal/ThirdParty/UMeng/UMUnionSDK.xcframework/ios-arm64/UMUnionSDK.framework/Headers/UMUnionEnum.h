//
//  UMUnionEnum.h
//  UMUnionSDK
//
//  Created by yanke on 2022/3/2.
//

#ifndef UMUnionEnum_h
#define UMUnionEnum_h

/**
 *  视频播放器状态
 *
 *  播放器只可能处于以下状态中的一种
 *
 */
typedef NS_ENUM(NSUInteger, UMUnionMediaPlayerStatus) {
    UMUnionMediaPlayerStatusNone = 0,            // 初始状态
    UMUnionMediaPlayerStatusLoading = 1,         // 加载中
    UMUnionMediaPlayerStatusReadyToPlay = 2,     // 即将播放
    UMUnionMediaPlayerStatusStartPlay = 3,       // 开始播放
    UMUnionMediaPlayerStatusPaused = 4,          // 暂停
    UMUnionMediaPlayerStatusError = 5,           // 播放出错
    UMUnionMediaPlayerStatusFinish = 6,          // 播放结束
};

#endif /* UMUnionEnum_h */
