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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    Header *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Header" forIndexPath:indexPath];
    id <PHFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:indexPath.section];
    header.title = [sectionInfo name];
    return header;
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
    
    _fetchedResultsController = [[PHFetchedResultsController alloc] initWithAssetCollection:assetCollection sectionKey:PHFetchedResultsSectionKeyWeek mediaType:PHFetchedResultsMediaTypeImage ignoreLocalIDs:@[]];
    _fetchedResultsController.delegate = self;
    _fetchedResultsController.dateFormateForSectionTitle = @"yyyy.MM.DD";
    
    [_fetchedResultsController performFetch:nil];
    
    return _fetchedResultsController;
}

```
