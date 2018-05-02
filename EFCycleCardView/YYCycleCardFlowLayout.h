//
//  YYCycleCardFlowLayout.h
//  EFTrade
//
//  Created by zcs_yang on 2018/4/24.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, YYCycleCardFlowAdsorbStyle) {
    YYCycleCardFlowAdsorbStyleCenter = 0, // 居中吸附 default
    YYCycleCardFlowAdsorbStyleLeft // 左吸附
};

@interface YYCycleCardFlowLayout : UICollectionViewFlowLayout

/**
 缩放比例
 */
@property (nonatomic, assign) CGFloat scale;

/**
 吸附效果类型
 */
@property (nonatomic, assign) YYCycleCardFlowAdsorbStyle flowAdorbStyle;

@end
