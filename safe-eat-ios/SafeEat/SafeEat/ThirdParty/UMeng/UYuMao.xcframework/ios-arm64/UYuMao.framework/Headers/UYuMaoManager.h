//
//  UMRiskManager.h
//  UMRiskSDK
//
//  Created by yanke on 2022/10/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UYuMaoManager : NSObject

+ (NSString *)version;
+ (void)logEnable:(BOOL)enable;

+ (void)ym1Off DEPRECATED_MSG_ATTRIBUTE("Use enableYm1: instead");;
+ (void)ym2Off DEPRECATED_MSG_ATTRIBUTE("Use enableYm2: instead");
+ (void)ym3Off DEPRECATED_MSG_ATTRIBUTE("Use enableYm3: instead");

+ (void)enableYm1:(BOOL)enable;
+ (void)enableYm2:(BOOL)enable;
+ (void)enableYm3:(BOOL)enable;

@end

NS_ASSUME_NONNULL_END
