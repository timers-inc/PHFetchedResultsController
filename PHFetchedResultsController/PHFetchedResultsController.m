//
//  PHFetchedResultsController.m
//  PHFetchedResultsController
//
//  Created by 1amageek on 2015/11/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "PHFetchedResultsController.h"

@protocol PHFetchedResultsSectionInfoDelegate <NSObject>

- (PHFetchedResultsSectionKey)sectionInfoSectionKey;
- (NSDateFormatter *)dateFormatter;
- (NSArray <NSString *>*)ignoreLocalIDs;

@end

@interface PHFetchedResultsSectionInfo : NSObject <PHFetchedResultsSectionInfo>

@property (nonatomic, readonly) NSInteger year;
@property (nonatomic, readonly) NSInteger month;
@property (nonatomic, readonly) NSInteger day;
@property (nonatomic, readonly) PHFetchOptions *options;
@property (nonatomic, readonly) PHAssetCollection *assetCollection;
@property (nonatomic, readonly) NSDateComponents *dateComponents;
@property (nonatomic) NSUInteger numberOfObjects;
@property (nonatomic, weak) id <PHFetchedResultsSectionInfoDelegate> delegate;

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection
                                   date:(NSDate *)date
                                options:(PHFetchOptions *)options;

@end

@implementation PHFetchedResultsSectionInfo
{
    NSCache *_cache;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection
                                   date:(NSDate *)date
                                options:(PHFetchOptions *)options
{
    self = [super init];
    if (self) {
        _cache = [NSCache new];
        NSCalendar *calendar = [NSCalendar currentCalendar];
        _dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                      fromDate:date];
        _assetCollection = assetCollection;
        _options = options;
        _numberOfObjects = 1;
        
    }
    return self;
}

- (NSInteger)year
{
    return [self.dateComponents year];
}

- (NSInteger)month
{
    return [self.dateComponents month];
}

- (NSInteger)day
{
    return [self.dateComponents day];
}

#pragma mark - PHFetchedResultsSectionInfo

- (NSString *)name
{
    NSDateFormatter *dateFormatter = [self.delegate dateFormatter];
    NSDate *date = [[NSCalendar currentCalendar] dateFromComponents:self.dateComponents];
    return [dateFormatter stringFromDate:date];
}

- (NSString *)indexTitle
{
    return nil;
}

- (NSUInteger)numberOfObjects
{
    return _numberOfObjects;
}

- (PHFetchResult <PHAsset *>*)objects
{
    NSString *name = [self name];
    PHFetchResult *cacheResult = [_cache objectForKey:name];
    if (cacheResult) {
        return cacheResult;
    }
    
    PHFetchOptions *options = [PHFetchOptions new];
    NSDate *startDay = [[NSCalendar currentCalendar] dateFromComponents:self.dateComponents];
    
    options.sortDescriptors = self.options.sortDescriptors;
    
    PHFetchedResultsSectionKey sectionKey = [self.delegate sectionInfoSectionKey];
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    [dateComponents setYear:(self.year + (sectionKey == PHFetchedResultsSectionKeyYear ? 1 : 0))];
    [dateComponents setMonth:(self.month + (sectionKey == PHFetchedResultsSectionKeyMonth ? 1 : 0))];
    [dateComponents setDay:(self.day + (sectionKey == PHFetchedResultsSectionKeyDay ? 1 : 0))];
    NSDate *endDay = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    NSArray *ignoreLocalIDs = [self.delegate ignoreLocalIDs];
    
    if (ignoreLocalIDs.count) {
        options.predicate = [NSPredicate predicateWithFormat:@"(creationDate >= %@) AND (creationDate < %@) AND (NOT (localIdentifier IN %@))", startDay, endDay, ignoreLocalIDs];
    } else {
        options.predicate = [NSPredicate predicateWithFormat:@"(creationDate >= %@) AND (creationDate < %@)", startDay, endDay];
    }
    
    PHFetchResult <PHAsset *>*result = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:options];
    [_cache setObject:result forKey:name];
    return result;
}

- (PHAsset *)assetAtIndex:(NSInteger)index
{
    PHAsset *asset = self.objects[index];
    return asset;
}

@end



@implementation PHFetchedResultsSectionChangeDetails
{
    NSMutableIndexSet *__removedIndexes;
    NSMutableIndexSet *__insertedIndexes;
    NSMutableIndexSet *__updatedIndexes;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        __removedIndexes = [NSMutableIndexSet indexSet];
        __insertedIndexes = [NSMutableIndexSet indexSet];
        __updatedIndexes = [NSMutableIndexSet indexSet];
    }
    return self;
}

- (void)addRemovedIndex:(NSUInteger)index
{
    if ([__removedIndexes containsIndex:index]) {
        return;
    }
    [__removedIndexes addIndex:index];
}

- (void)addInsertedIndex:(NSUInteger)index
{
    if ([__insertedIndexes containsIndex:index]) {
        return;
    }
    [__insertedIndexes addIndex:index];
}

- (void)addUpdatedIndex:(NSUInteger)index
{
    if ([__updatedIndexes containsIndex:index]) {
        return;
    }
    [__updatedIndexes addIndex:index];
}

- (NSIndexSet *)removedIndexes
{
    return (NSIndexSet *)__removedIndexes;
}

- (NSIndexSet *)insertedIndexes
{
    return (NSIndexSet *)__insertedIndexes;
}

- (NSIndexSet *)updatedIndexes
{
    return (NSIndexSet *)__updatedIndexes;
}

@end


@interface PHFetchedResultsController () <PHFetchedResultsSectionInfoDelegate, PHPhotoLibraryChangeObserver>

@property (nonatomic)   PHFetchOptions *options;
@property (nonatomic)   PHFetchResult <PHAsset *>*fetchResult;
@property (nonatomic)   NSMutableArray <PHFetchedResultsSectionInfo *>*mySections;

@end


@implementation PHFetchedResultsController

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection sectionKey:(PHFetchedResultsSectionKey)sectionKey cacheName:(nullable NSString *)name
{
    self = [super init];
    if (self) {
        
        _assetCollection = assetCollection;
        _sectionKey = sectionKey;
        
        _mySections = [NSMutableArray array];
        _options = [PHFetchOptions new];
        _options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        self.fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:_options];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        
    }
    return self;
}

- (void)dealloc {
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

- (void)setFetchResult:(PHFetchResult<PHAsset *> *)fetchResult
{
    _fetchResult = fetchResult;
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    __block NSInteger previousYear = 0;
    __block NSInteger previousMonth = 0;
    __block NSInteger previousDay = 0;
    
    __block PHFetchedResultsSectionInfo *sectionInfo = nil;
    
    [_fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        @autoreleasepool {
            NSDateComponents *dateComponets = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                          fromDate:asset.creationDate];
            
            NSInteger year = [dateComponets year];
            NSInteger month = [dateComponets month];
            NSInteger day = [dateComponets day];
            
            __block BOOL isYear = previousYear == year;
            __block BOOL isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? previousMonth == month : YES);
            __block BOOL isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? previousDay == day : YES);
            __block BOOL sectionExist = isYear && isMonth && isDay ;
            
            if (sectionExist) {
                
                sectionInfo.numberOfObjects ++;
                
            } else {
                [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    isYear = obj.year == year;
                    isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? obj.month == month : YES);
                    isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? obj.day == day : YES);
                    
                    if (isYear && isMonth && isDay) {
                        sectionExist = YES;
                        sectionInfo = obj;
                        *stop = YES;
                    }
                }];
                
                if (!sectionExist) {
                    PHFetchedResultsSectionInfo *info = [[PHFetchedResultsSectionInfo alloc] initWithAssetCollection:self.assetCollection date:asset.creationDate options:self.options];
                    info.delegate = self;
                    [_mySections addObject:info];
                    
                    previousYear = year;
                    previousMonth = month;
                    previousDay = day;
                    sectionInfo = info;
                    
                }
            }
        }
    
    }];
}

- (NSArray<id<PHFetchedResultsSectionInfo>> *)sections
{
    return (NSArray *)self.mySections;
}

- (PHFetchResult<PHAsset *> *)fetchedObjects
{
    return _fetchResult;
}

- (PHAsset *)assetAtIndexPath:(NSIndexPath *)indexPath
{
    PHFetchedResultsSectionInfo *sectionInfo = self.mySections[indexPath.section];
    return [sectionInfo assetAtIndex:indexPath.item];
}

- (NSIndexPath *)indexPathForAsset:(PHAsset *)asset
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponets = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                  fromDate:asset.creationDate];
    
    NSInteger year = [dateComponets year];
    NSInteger month = [dateComponets month];
    NSInteger day = [dateComponets day];
    
    __block PHFetchedResultsSectionInfo *sectionInfo = nil;
    __block NSInteger section;
    
    [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        BOOL isYear = obj.year == year;
        BOOL isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? obj.month == month : YES);
        BOOL isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? obj.day == day : YES);
        
        if (isYear && isMonth && isDay) {
            sectionInfo = obj;
            section = idx;
            *stop = YES;
        }
        
    }];
    
    if (sectionInfo) {
        NSInteger index = [sectionInfo.objects indexOfObject:asset];
        return [NSIndexPath indexPathForItem:section inSection:index];
    }
    
    return nil;
}

- (NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName
{
    __block NSString *sectionIndexTitle = nil;
    [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.name isEqualToString:sectionName]) {
            sectionIndexTitle = obj.indexTitle;
        }
    }];
    return sectionIndexTitle;
}

- (NSUInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex
{
    return 0;
}

- (NSArray<NSString *> *)sectionIndexTitles
{
    NSMutableArray *titles = [NSMutableArray array];
    [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.name) {
            [titles addObject:obj.name];
        }
    }];
    return (NSArray *)titles;
}

- (NSUInteger)indexForSectionInfo:(PHFetchedResultsSectionInfo *)sectionInfo
{
    return [_mySections indexOfObject:sectionInfo];
}

#pragma mark - PHFetchedResultsSectionInfoDelegate

- (PHFetchedResultsSectionKey)sectionInfoSectionKey
{
    return self.sectionKey;
}

- (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    return dateFormatter;
}

- (NSArray <NSString *>*)ignoreLocalIDs
{
    if ([self.delegate respondsToSelector:@selector(controllerIgnoreLocalIDs:)]) {
        return [self.delegate controllerIgnoreLocalIDs:self];
    }
    return @[];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance
{
    PHFetchResultChangeDetails *changesDetails = [changeInstance changeDetailsForFetchResult:self.fetchResult];
    if (changesDetails == nil) {
        return;
    }
    
    if (![changesDetails hasIncrementalChanges] || [changesDetails hasMoves]) {
        _fetchResult = [changesDetails fetchResultAfterChanges];
    } else {

        NSCalendar *calendar = [NSCalendar currentCalendar];
        PHFetchedResultsSectionChangeDetails *sectionChangeDetails = [PHFetchedResultsSectionChangeDetails new];
        
        // remove
        NSArray <PHAsset *>*removedObjects = [changesDetails removedObjects];
        if (removedObjects.count > 0) {
          
            __block NSInteger previousYear = 0;
            __block NSInteger previousMonth = 0;
            __block NSInteger previousDay = 0;
            
            __block PHFetchedResultsSectionInfo *sectionInfo = nil;
            
            [removedObjects enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSDateComponents *dateComponets = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                              fromDate:asset.creationDate];
                NSInteger year = [dateComponets year];
                NSInteger month = [dateComponets month];
                NSInteger day = [dateComponets day];
                
                __block BOOL isYear = previousYear == year;
                __block BOOL isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? previousMonth == month : YES);
                __block BOOL isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? previousDay == day : YES);
                __block BOOL sectionExist = isYear && isMonth && isDay ;
                
                if (sectionExist) {
                    
                    sectionInfo.numberOfObjects --;
                    
                } else {
                    
                    [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        isYear = obj.year == year;
                        isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? obj.month == month : YES);
                        isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? obj.day == day : YES);
                        
                        if (isYear && isMonth && isDay) {
                            sectionExist = YES;
                            sectionInfo = obj;
                            sectionInfo.numberOfObjects --;
                            
                            previousYear = year;
                            previousMonth = month;
                            previousDay = day;
                            [sectionChangeDetails addUpdatedIndex:[self indexForSectionInfo:sectionInfo]];
                            *stop = YES;
                        }
                    }];
                }
                
                if (sectionInfo.numberOfObjects == 0) {
                    [sectionChangeDetails addRemovedIndex:[self indexForSectionInfo:sectionInfo]];
                    [_mySections removeObject:sectionInfo];
                }
            }];
        }
        
        // insert
        NSArray <PHAsset *>*insertedObjects = [changesDetails insertedObjects];
        if (insertedObjects.count > 0) {
            
            __block NSInteger previousYear = 0;
            __block NSInteger previousMonth = 0;
            __block NSInteger previousDay = 0;
            
            __block PHFetchedResultsSectionInfo *sectionInfo = nil;
            
            [insertedObjects enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSDateComponents *dateComponets = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                              fromDate:asset.creationDate];
                NSInteger year = [dateComponets year];
                NSInteger month = [dateComponets month];
                NSInteger day = [dateComponets day];
                
                __block BOOL isYear = previousYear == year;
                __block BOOL isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? previousMonth == month : YES);
                __block BOOL isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? previousDay == day : YES);
                __block BOOL sectionExist = isYear && isMonth && isDay ;
                
                if (sectionExist) {
                    
                    sectionInfo.numberOfObjects ++;
                    
                } else {
                    
                    [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        isYear = obj.year == year;
                        isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? obj.month == month : YES);
                        isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? obj.day == day : YES);
                        
                        if (isYear && isMonth && isDay) {
                            sectionExist = YES;
                            sectionInfo = obj;
                            [sectionChangeDetails addUpdatedIndex:[self indexForSectionInfo:sectionInfo]];
                            *stop = YES;
                        }
                    }];
                    
                    if (!sectionExist) {
                        PHFetchedResultsSectionInfo *info = [[PHFetchedResultsSectionInfo alloc] initWithAssetCollection:self.assetCollection date:asset.creationDate options:self.options];
                        info.delegate = self;
                        [_mySections addObject:info];
                        
                        previousYear = year;
                        previousMonth = month;
                        previousDay = day;
                        sectionInfo = info;
                        [sectionChangeDetails addInsertedIndex:[self indexForSectionInfo:sectionInfo]];
                    }
                    
                }
            }];
        }
        
        // change
        NSArray <PHAsset *>*updatedObjects = [changesDetails changedObjects];
        if (updatedObjects.count > 0) {
            __block NSInteger previousYear = 0;
            __block NSInteger previousMonth = 0;
            __block NSInteger previousDay = 0;
            
            __block PHFetchedResultsSectionInfo *sectionInfo = nil;
            
            [updatedObjects enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
                
                NSDateComponents *dateComponets = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                              fromDate:asset.creationDate];
                NSInteger year = [dateComponets year];
                NSInteger month = [dateComponets month];
                NSInteger day = [dateComponets day];
                
                __block BOOL isYear = previousYear == year;
                __block BOOL isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? previousMonth == month : YES);
                __block BOOL isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? previousDay == day : YES);
                __block BOOL sectionExist = isYear && isMonth && isDay ;
                
                if (!sectionExist) {
                    
                    [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        isYear = obj.year == year;
                        isMonth = (self.sectionKey >= PHFetchedResultsSectionKeyMonth ? obj.month == month : YES);
                        isDay = (self.sectionKey >= PHFetchedResultsSectionKeyDay ? obj.day == day : YES);
                        
                        if (isYear && isMonth && isDay) {
                            sectionExist = YES;
                            sectionInfo = obj;
                            
                            previousYear = year;
                            previousMonth = month;
                            previousDay = day;
                            sectionInfo = obj;
                            
                            [sectionChangeDetails addUpdatedIndex:[self indexForSectionInfo:sectionInfo]];
                            
                            *stop = YES;
                        }
                    }];
                    
                }
            }];
        }
        
        [self.delegate controller:self photoLibraryDidChange:sectionChangeDetails];
    }
}


@end
