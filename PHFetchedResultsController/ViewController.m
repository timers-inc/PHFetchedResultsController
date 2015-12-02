//
//  ViewController.m
//  STPBackgroundTransfer
//
//  Created by 1amageek on 2015/11/19.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <PHPhotoLibraryChangeObserver>
@property (nonatomic, strong) PHCachingImageManager *imageManager;
@property CGRect previousPreheatRect;

@end

@implementation ViewController

static NSString * const CellReuseIdentifier = @"Cell";
static CGSize AssetGridThumbnailSize;

+ (void)loadAssetsLibraryWithComplitionHandler:(void (^)(BOOL authorized))complition
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status) {
        case PHAuthorizationStatusNotDetermined:
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:{
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    complition(YES);
                } else {
                    complition(NO);
                }
            }];
            break;
        }
        case PHAuthorizationStatusAuthorized:
        default:{
            complition(YES);
            break;
        }
    }
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (PHCachingImageManager *)imageManager
{
    if (_imageManager) {
        return _imageManager;
    }
    _imageManager = [[PHCachingImageManager alloc] init];
    return _imageManager;
}

- (void)loadView
{
    [super loadView];
    [self.view addSubview:self.collectionView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.collectionView registerClass:[GridCell class] forCellWithReuseIdentifier:@"GridCell"];
    
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    [self resetCachedAssets];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    CGSize cellSize = CGSizeMake(80, 80);
    AssetGridThumbnailSize = CGSizeMake(cellSize.width, cellSize.height);
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Begin caching assets in and around collection view's visible rect.
    [self updateCachedAssets];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    
//    PHFetchResultChangeDetails *collectionChanges = [changeInstance changeDetailsForFetchResult:self.assetsFetchResults];
//    if (collectionChanges == nil) {
//        return;
//    }
//    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.assetsFetchResults = [collectionChanges fetchResultAfterChanges];
//        
//        UICollectionView *collectionView = self.collectionView;
//        
//        if (![collectionChanges hasIncrementalChanges] || [collectionChanges hasMoves]) {
//            [collectionView reloadData];
//            
//        } else {
//            [collectionView performBatchUpdates:^{
//                NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
//                if ([removedIndexes count] > 0) {
//                    [collectionView deleteItemsAtIndexPaths:[removedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                }
//                
//                NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
//                if ([insertedIndexes count] > 0) {
//                    [collectionView insertItemsAtIndexPaths:[insertedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                }
//                
//                NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
//                if ([changedIndexes count] > 0) {
//                    [collectionView reloadItemsAtIndexPaths:[changedIndexes aapl_indexPathsFromIndexesWithSection:0]];
//                }
//            } completion:NULL];
//        }
//        
//        [self resetCachedAssets];
//    });
}

- (UICollectionView *)collectionView
{
    if (_collectionView) {
        return _collectionView;
    }
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    _collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.allowsMultipleSelection = YES;
    return _collectionView;
}

- (UICollectionViewLayout *)collectionViewLayout
{
    return self.collectionView.collectionViewLayout;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <PHFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    PHAsset *asset = [self.fetchedResultsController assetAtIndexPath:indexPath];
    
    
    GridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GridCell" forIndexPath:indexPath];
    cell.representedAssetIdentifier = asset.localIdentifier;
    
    if (asset.mediaSubtypes & PHAssetMediaSubtypePhotoLive) {
        UIImage *badge = [PHLivePhotoView livePhotoBadgeImageWithOptions:PHLivePhotoBadgeOptionsOverContent];
        cell.livePhotoBadgeImage = badge;
    }
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize size = CGSizeMake(AssetGridThumbnailSize.width * scale, AssetGridThumbnailSize.height * scale);
    
    [self.imageManager requestImageForAsset:asset
                                 targetSize:size
                                contentMode:PHImageContentModeAspectFill
                                    options:nil
                              resultHandler:^(UIImage *result, NSDictionary *info) {
                                  // Set the cell's thumbnail image if it's still showing the same asset.
                                  if ([cell.representedAssetIdentifier isEqualToString:asset.localIdentifier]) {
                                      cell.thumbnailImage = result;
                                  }
                              }];
    
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return AssetGridThumbnailSize;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeMake([UIScreen mainScreen].bounds.size.width, 40);
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // Update cached assets for the new visible area.
    [self updateCachedAssets];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [self.imageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = self.collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(self.collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self.collectionView aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        PHImageRequestOptions *imageRequestOptions = [PHImageRequestOptions new];
        imageRequestOptions.resizeMode = PHImageRequestOptionsResizeModeNone;
        imageRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        imageRequestOptions.synchronous = YES;
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize size = CGSizeMake(AssetGridThumbnailSize.width * scale, AssetGridThumbnailSize.height * scale);
        
        // Update the assets the PHCachingImageManager is caching.
        [self.imageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:size
                                           contentMode:PHImageContentModeAspectFill
                                               options:imageRequestOptions];
        [self.imageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:size
                                          contentMode:PHImageContentModeAspectFill
                                              options:imageRequestOptions];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        PHAsset *asset = [self.fetchedResultsController assetAtIndexPath:indexPath];
        [assets addObject:asset];
    }
    
    return assets;
}

- (PHFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                               subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                               options:nil];
    PHAssetCollection *assetCollection = assetCollections.firstObject;
    
    _fetchedResultsController = [[PHFetchedResultsController alloc] initWithAssetCollection:assetCollection sectionKey:PHFetchedResultsSectionKeyYear cacheName:nil];
    return _fetchedResultsController;
}


@end
