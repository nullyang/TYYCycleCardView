//
//  YYCycleCardView.m
//  EFTrade
//
//  Created by zcs_yang on 2018/4/24.
//

#import "YYCycleCardView.h"
#import "YYCycleCardFlowLayout.h"
#import "UIView+Util.h"
#import <Masonry.h>

@interface YYCycleCardView() <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) YYCycleCardFlowLayout *flowLayout;

@property (nonatomic, assign) NSInteger itemsCount;
@property (nonatomic, assign) NSInteger currentIndex;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) NSArray <YYCycleCardItemConfigure> *items;

@end

@implementation YYCycleCardView

#pragma mark - UILife
- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self configureSubviews];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self configureSubviews];
    }
    return self;
}

- (void)configureSubviews
{
    [self initAttributes];
    [self addSubview:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
}

- (void)initAttributes
{
     // 默认是中间
    self.itemZoomScale = 1;
}

#pragma mark - Public
- (void)configureWithItems:(NSArray<YYCycleCardItemConfigure> *)items
{
    self.items = items;
    // 注册cell
    [self registCollectionViewCell];
    // 判断是否需要缩放
    [self judgeZoomEnabel];
    // 由于设计当前显示的cell的trancefrom改变了
    // 所以设计图上的间距和实际间距不一致，在这里处理
    [self dealActureItemSpacing];
    // 需要的cell数是实际数目的200倍
    self.itemsCount = self.items.count <= 1 || !self.isInfinite ? self.items.count : self.items.count * 200;
    [self.collectionView reloadData];
    [self.collectionView setContentOffset:CGPointZero];
    if (!self.adsorbLeft) {
        [self dealFirstPage];
    }
    if (self.isAutomatic) {
        [self startTimer];
    }
}

#pragma mark - override
- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    if (newWindow) {
        [self startTimer];
    }else {
        [self cancelTimer];
    }
}

#pragma mark - UICollectionViewDataSource/UICollectionViewDelegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.itemsCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<YYCycleCardItemConfigure> item = [self itemAtIndex:indexPath.row];
    if (!item) {
        [collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"errorCell"];
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"errorCell" forIndexPath:indexPath];
    }
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:item.cellClassString forIndexPath:indexPath];
    if ([cell conformsToProtocol:@protocol(YYCycleCardViewCellSetting)]) {
        UICollectionViewCell <YYCycleCardViewCellSetting>* sCell = (UICollectionViewCell <YYCycleCardViewCellSetting>*)cell;
        [sCell configureWithItem:item];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // 如果没有缩放
    if (self.itemZoomScale == 1) {
        NSInteger index = indexPath.item % self.items.count;
        if (self.didSelectedItem) {
            self.didSelectedItem(index, [self itemAtIndex:index]);
        }
        return;
    }
    CGPoint currentCellCenter = self.adsorbLeft ? CGPointMake(self.itemSpacing + 0.5*self.itemSize.width, 0.5*collectionView.height) : collectionView.center;
    CGPoint currentViewPoint = [self convertPoint:currentCellCenter toView:collectionView];
    NSInteger currentIndex = [collectionView indexPathForItemAtPoint:currentViewPoint].item;
    if (indexPath.item == currentIndex) {
        NSInteger index = indexPath.item % self.items.count;
        if (self.didSelectedItem) {
            self.didSelectedItem(index, [self itemAtIndex:index]);
        }
    }else {
        [self scrollToTargetIndex:indexPath.item animated:YES];
    }
}

#pragma mark - UIScrollViewDelelgate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.isAutomatic) {
        [self cancelTimer];
    }
    if (self.isInfinite) {
        [self dealLastPage];
        [self dealFirstPage];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (self.isAutomatic) {
        [self startTimer];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    NSInteger index = self.currentIndex % self.items.count;
    if (self.didScrollToIndex) {
        self.didScrollToIndex(index);
    }
}

#pragma mark - Private
- (void)registCollectionViewCell
{
    NSMutableSet *cellClassSet = [NSMutableSet set];
    for (id<YYCycleCardItemConfigure>item in self.items) {
        [cellClassSet addObject:item.cellClassString];
    }
    for (NSString *cellClassString in cellClassSet) {
//        [self.collectionView registerClass:NSClassFromString(cellClassString) forCellWithReuseIdentifier:cellClassString];
        [self.collectionView registerNib:[UINib nibWithNibName:cellClassString bundle:[NSBundle mainBundle]] forCellWithReuseIdentifier:cellClassString];
    }
}

- (void)judgeZoomEnabel
{
    if (!self.isInfinite || !self.items.count) {
        return;
    }
    // 如果屏幕能展示超过两个cell，也没必要缩放了
    if (2 * self.itemSpacing + 2 * self.itemSize.width <= self.collectionView.width) {
        self.itemZoomScale = 1.0;
    }
    // 如果是完全展开的，就没必要无限循环了
    if (self.items.count * self.itemSize.width + self.items.count * self.itemSpacing + self.itemSpacing < self.collectionView.width) {
        self.isInfinite = NO;
        self.timeInterval = CGFLOAT_MAX;
    }
}

- (void)dealActureItemSpacing
{
    if (self.itemZoomScale == 1 || self.itemZoomScale <=0) {
        return;
    }
    CGFloat actualItemSpacing = self.itemSpacing + (self.itemZoomScale - 1) * self.itemSize.width * 0.5;
    if (self.itemSpacing != actualItemSpacing) {
        self.itemSpacing = actualItemSpacing;
    }
}

- (id<YYCycleCardItemConfigure>)itemAtIndex:(NSInteger)index
{
    if (self.items.count > index % self.items.count) {
        return self.items[index % self.items.count];
    }
    return nil;
}

- (void)dealFirstPage
{
    if (self.currentIndex == 0 && self.itemsCount > 1 && self.isInfinite) {
        NSInteger targetIndex = self.itemsCount / 2;
        [self scrollToTargetIndex:targetIndex animated:NO];
        if (self.didScrollToIndex) {
            self.didScrollToIndex(0);
        }
    }
}

- (void)dealLastPage
{
    if (self.currentIndex == self.itemsCount - 1 && self.isInfinite) {
        NSInteger targetIndex = self.itemsCount/2 - 1;
        [self scrollToTargetIndex:targetIndex animated:NO];
    }
}

- (void)scrollToTargetIndex:(NSInteger)targetIndex animated:(BOOL)animated
{
    if (self.adsorbLeft) {
        CGFloat targetOffsetX = self.flowLayout.sectionInset.left + targetIndex * self.flowLayout.itemSize.width + ((targetIndex <= 0 ?1:targetIndex) - 1)*self.flowLayout.minimumLineSpacing;
        CGFloat targetOffsetY = self.collectionView.contentOffset.y;
        CGPoint targetPoint = CGPointMake(targetOffsetX, targetOffsetY);
        [self.collectionView setContentOffset:targetPoint animated:animated];
    }else {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:targetIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:animated];
    }
}

- (void)startTimer
{
    if (!self.isAutomatic) {
        return;
    }
    if (self.itemsCount <= 1) {
        return;
    }
    [self cancelTimer];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.timeInterval target:self selector:@selector(timeRepeat) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)cancelTimer
{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)timeRepeat
{
    NSInteger targetIndex = self.currentIndex + 1;
    if (self.currentIndex == self.itemsCount - 1) {
        if (!self.isInfinite) {
            return;
        }
        [self dealLastPage];
        targetIndex = self.itemsCount / 2;
    }
    [self scrollToTargetIndex:targetIndex animated:YES];
}

- (NSInteger)currentIndex
{
    CGFloat itemWH = self.flowLayout.itemSize.width + self.itemSpacing;
    CGFloat offsetXY = self.collectionView.contentOffset.x;
    if (itemWH < 1) {
        return 0;
    }
    return (NSInteger)(round(offsetXY / itemWH));
}

#pragma mark - Setter
- (void)setItemSize:(CGSize)itemSize
{
    _itemSize = itemSize;
    self.flowLayout.itemSize = itemSize;
}

- (void)setAdsorbLeft:(BOOL)adsorbLeft
{
    _adsorbLeft = adsorbLeft;
    self.flowLayout.flowAdorbStyle = adsorbLeft ? YYCycleCardFlowAdsorbStyleLeft : YYCycleCardFlowAdsorbStyleCenter;
}

- (void)setItemZoomScale:(CGFloat)itemZoomScale
{
    _itemZoomScale = itemZoomScale;
    self.flowLayout.scale = itemZoomScale;
}

- (void)setItemSpacing:(CGFloat)itemSpacing
{
    _itemSpacing = itemSpacing;
    self.flowLayout.minimumLineSpacing = itemSpacing;
}

#pragma mark - UIGetter
- (YYCycleCardFlowLayout *)flowLayout
{
    if (_flowLayout) {
        return _flowLayout;
    }
    _flowLayout = [[YYCycleCardFlowLayout alloc]init];
    _flowLayout.minimumInteritemSpacing = 10000;
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    return _flowLayout;
}

- (UICollectionView *)collectionView
{
    if (_collectionView) {
        return _collectionView;
    }
    _collectionView = [[UICollectionView alloc]initWithFrame:self.bounds collectionViewLayout:self.flowLayout];
    _collectionView.bounces = NO;
    _collectionView.backgroundColor = [UIColor clearColor];
    _collectionView.showsVerticalScrollIndicator = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.scrollsToTop = NO;
    _collectionView.decelerationRate = 0;
    return _collectionView;
}

@end
