//
//  YYCycleCardItemConfigure.h
//  YYTrade
//
//  Created by zcs_yang on 2018/4/24.
//

#import <Foundation/Foundation.h>

@protocol YYCycleCardItemConfigure <NSObject>

- (NSString *)cellClassString;

@end

@protocol YYCycleCardViewCellSetting <NSObject>

- (void)configureWithItem:(id<YYCycleCardItemConfigure>)item;

@end
