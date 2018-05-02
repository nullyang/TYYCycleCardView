//
//  YYCycleCardView.h
//  EFTrade
//
//  Created by zcs_yang on 2018/4/24.
//

#import <UIKit/UIKit.h>
#import "YYCycleCardItemConfigure.h"

@interface YYCycleCardView : UIView

/**
 是否定时滚动
 */
@property (nonatomic, assign) BOOL isAutomatic;

/**
 是否无限滚动
 */
@property (nonatomic, assign) BOOL isInfinite;

/**
 是否是左吸附，如果不是，那就是中心吸附
 */
@property (nonatomic, assign) BOOL adsorbLeft;

/**
 cell的size，如果itemZoomScale > 1,为最小尺寸，如果itemZoomScale < 1，为最大尺寸
 */
@property (nonatomic, assign) CGSize itemSize;

/**
 横向每个cell间距
 */
@property (nonatomic, assign) CGFloat itemSpacing;

/**
 缩放比例
 */
@property (nonatomic, assign) CGFloat itemZoomScale;

/**
 定时刷新时间
 */
@property (nonatomic, assign) NSTimeInterval timeInterval;

/**
 点击当前cell事件
 */
@property (nonatomic, copy) void (^didSelectedItem)(NSInteger index, id<YYCycleCardItemConfigure>item);

/**
 滚动事件
 */
@property (nonatomic, copy) void (^didScrollToIndex)(NSInteger index);

/**
 配置items

 @param items items
 */
- (void)configureWithItems:(NSArray <YYCycleCardItemConfigure> *)items;

@end
