//
//  PHFetchedResultsController.m
//  PHFetchedResultsController
//
//  Created by 1amageek on 2015/11/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "PHFetchedResultsController.h"

@protocol PHFetchedResultsSectionInfoDelegate <NSObject>

- (NSDateFormatter *)dateFormatter;

@end

@interface PHFetchedResultsSectionInfo : NSObject <PHFetchedResultsSectionInfo>

@property (nonatomic, readonly) NSInteger year;
@property (nonatomic, readonly) NSInteger month;
@property (nonatomic, readonly) NSInteger day;
@property (nonatomic, readonly) PHFetchOptions *options;
@property (nonatomic, readonly) PHAssetCollection *assetCollection;
@property (nonatomic, readonly) NSDateComponents *dateComponents;
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
    return [self objects].count;
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
    
    NSDateComponents *dateComponents = [NSDateComponents new];
    [dateComponents setYear:self.year];
    [dateComponents setMonth:self.month];
    [dateComponents setDay:(self.day + 1)];
    NSDate *endDay = [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
    
    options.sortDescriptors = self.options.sortDescriptors;
    options.predicate = [NSPredicate predicateWithFormat:@"(creationDate >= %@) AND (creationDate < %@)", startDay, endDay];
    
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:self.assetCollection options:options];
    [_cache setObject:result forKey:name];
    
    return result;
}

@end



@interface PHFetchedResultsController () <PHFetchedResultsSectionInfoDelegate>

@property (nonatomic)   PHFetchOptions *options;
@property (nonatomic)   PHFetchResult <PHAsset *>*fetchResult;
@property (nonatomic)   NSMutableArray <PHFetchedResultsSectionInfo *>*mySections;

@end


@implementation PHFetchedResultsController
{
    NSInteger _previousYear;
    NSInteger _previousMonth;
    NSInteger _previousDay;
}

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection sectionKey:(PHFetchedResultsSectionKey)sectionKey cacheName:(nullable NSString *)name
{
    self = [super init];
    if (self) {
        
        _assetCollection = assetCollection;
        _sectionKey = sectionKey;
        
        _previousYear = 0;
        _previousMonth = 0;
        _previousDay = 0;
        
        _mySections = [NSMutableArray array];
        _options = [PHFetchOptions new];
        _options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        
        self.fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:_options];
        
    }
    return self;
}

- (void)setFetchResult:(PHFetchResult<PHAsset *> *)fetchResult
{
    _fetchResult = fetchResult;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [_fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSDateComponents *dateComponets = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                      fromDate:asset.creationDate];
        
        NSInteger year = [dateComponets year];
        NSInteger month = [dateComponets month];
        NSInteger day = [dateComponets day];
        
        __block BOOL isYear = _previousYear == year;
        __block BOOL isMonth = _previousMonth == month;
        __block BOOL isDay = _previousDay == day;
        
        __block BOOL sectionExist = isYear && isMonth && isDay;
        
        if (!sectionExist) {
            __block PHFetchedResultsSectionInfo *sectionInfo = nil;
            [_mySections enumerateObjectsUsingBlock:^(PHFetchedResultsSectionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                
                isYear = obj.year == year;
                isMonth = obj.month == month;
                isDay = obj.day == day;
                
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
    return sectionInfo.objects[indexPath.item];
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
        BOOL isMonth = obj.month == month;
        BOOL isDay = obj.day == day;
        
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

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex
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

#pragma mark - PHFetchedResultsSectionInfoDelegate

- (NSDateFormatter *)dateFormatter
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    return dateFormatter;
}

@end
