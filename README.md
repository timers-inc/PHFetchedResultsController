# PHFetchedResultsController
A fetchedResultsController for PhotoKit. It can be divided into sections by date PhotoKit

## Usage

``` objective-c

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return self.fetchedResultsController.sections.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    id <PHFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}


```


``` objective-c

- (PHFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    
    PHFetchResult *assetCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                               subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                               options:nil];
    PHAssetCollection *assetCollection = assetCollections.firstObject;
    
    _fetchedResultsController = [[PHFetchedResultsController alloc] initWithAssetCollection:assetCollection sectionKey:PHFetchedResultsSectionKeyDay cacheName:nil];
    
    return _fetchedResultsController;
}

```
