//
//  YYCycleCardFlowLayout.m
//  EFTrade
//
//  Created by zcs_yang on 2018/4/24.
//

#import "YYCycleCardFlowLayout.h"
#import "UIView+Util.h"

@implementation YYCycleCardFlowLayout

- (void)prepareLayout
{
    [super prepareLayout];
    if (self.collectionView) {
        CGFloat offsetX;
        if (self.flowAdorbStyle == YYCycleCardFlowAdsorbStyleLeft) {
            offsetX = self.minimumLineSpacing;
        }else {
            offsetX = (self.collectionView.width - self.itemSize.width)/2;
        }
        CGFloat offsetY = 0.5 * (self.collectionView.height - self.itemSize.height);
        self.sectionInset = UIEdgeInsetsMake(offsetY, offsetX, offsetY, 0);
    }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    return YES;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    NSArray<UICollectionViewLayoutAttributes *> *attributes = [super layoutAttributesForElementsInRect:rect];
    UICollectionView *collectionView = self.collectionView;
    if (attributes && collectionView) {
        NSArray<UICollectionViewLayoutAttributes *> *attris = [[NSArray alloc]initWithArray:attributes copyItems:YES];
        for (UICollectionViewLayoutAttributes *attri in attris) {
            CGFloat scale = 1;
            CGFloat absOffset = 0;
            CGFloat centerX = collectionView.bounds.size.width*0.5 + collectionView.contentOffset.x;
            absOffset = fabs(attri.center.x - centerX);
            CGFloat distance = self.itemSize.width + self.minimumLineSpacing;
            if (absOffset < distance) {
                // 当前index
                scale = (1 - absOffset/distance)*(self.scale - 1) + 1;
                attri.zIndex = 1;
            }
            attri.transform = CGAffineTransformMakeScale(scale, scale);
        }
        return attris;
    }
    return attributes;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
    // 计算吸附所需要的偏移量
    CGFloat minSpace = CGFLOAT_MAX;
    CGPoint offset = proposedContentOffset;
    UICollectionView *collectionView = self.collectionView;
    if (collectionView) {
        CGFloat centerX;
        if (self.flowAdorbStyle == YYCycleCardFlowAdsorbStyleLeft) {
            centerX = offset.x + self.minimumLineSpacing + self.itemSize.width*0.5;
        }else {
            centerX = offset.x + collectionView.bounds.size.width/2;
        }
        CGRect visibleRect = CGRectMake(offset.x, 0, collectionView.width, collectionView.height);
        NSArray<UICollectionViewLayoutAttributes *> *attris = [self layoutAttributesForElementsInRect:visibleRect];
        if (attris) {
            for (UICollectionViewLayoutAttributes *attri in attris) {
                if (fabs(minSpace) > fabs(attri.center.x - centerX)) {
                    minSpace = attri.center.x - centerX;
                }
            }
        }
        offset.x += minSpace;
    }
    return offset;
}

- (void)setScale:(CGFloat)scale
{
    _scale = scale;
    if (_scale > 1) {
        [self invalidateLayout];
    }
}

@end
