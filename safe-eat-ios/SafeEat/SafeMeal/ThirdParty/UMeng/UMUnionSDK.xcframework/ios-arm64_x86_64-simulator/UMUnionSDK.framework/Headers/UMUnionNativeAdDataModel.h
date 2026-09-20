//
//  UMUnionNativeAdDataModel.h
//  UMessage
//
//  Created by yanke on 2021/12/1.
//  Copyright © 2021 umeng.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UMUnionNativeAdDataModel : NSObject

/**
 广告标题
 */
@property (nonatomic, copy, readonly) NSString *title;
/**
 广告内容描述
 */
@property (nonatomic, copy, readonly) NSString *content;
/**
 广告App 图标Url
 */
@property (nonatomic, copy, readonly) NSString *iconUrl;

/**
 iconUrl图片 宽度
 */
@property (nonatomic, readonly) NSInteger iconWidth;

/**
iconUrl图片 高度
 */
@property (nonatomic, readonly) NSInteger iconHeight;

/**
 广告大图Url
 */
@property (nonatomic, copy, readonly) NSString *imageUrl;

/**
 imageUrl图片 宽度
 */
@property (nonatomic, readonly) NSInteger imageWidth;

/**
imageUrl图片 高度
 */
@property (nonatomic, readonly) NSInteger imageHeight;

/**
 广告价格：单位分
*/
@property (nonatomic, strong, readonly) NSNumber *eCPM;

/**
 是否为视频广告
 */
@property (nonatomic, readonly) BOOL isVideoAd;

/**
 video 宽度
 */
@property (nonatomic, readonly) NSInteger videoWidth;

/**
video 高度
 */
@property (nonatomic, readonly) NSInteger videoHeight;
@end

NS_ASSUME_NONNULL_END
