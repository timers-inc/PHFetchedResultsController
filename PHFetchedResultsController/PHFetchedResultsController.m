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


@interface PHFetchedResultsController () <PHFetchedResultsSectionInfoDelegate>

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
        
    }
    return self;
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

@end
