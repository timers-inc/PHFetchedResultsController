//
//  PHFetchedResultsController.h
//  PHFetchedResultsController
//
//  Created by 1amageek on 2015/11/30.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

@import Foundation;
@import PhotosUI;
@import Photos;


typedef NS_ENUM(NSUInteger, PHFetchedResultsSectionKey) {
    PHFetchedResultsSectionKeyYear,
    PHFetchedResultsSectionKeyMonth,
    PHFetchedResultsSectionKeyDay
};

NS_ASSUME_NONNULL_BEGIN

@protocol PHFetchedResultsSectionInfo;

@interface PHFetchedResultsController : NSObject

- (instancetype)initWithAssetCollection:(PHAssetCollection *)assetCollection sectionKey:(PHFetchedResultsSectionKey)sectionKey cacheName:(nullable NSString *)name;

@property (nonatomic, readonly) PHAssetCollection *assetCollection;
@property (nonatomic, readonly) PHFetchedResultsSectionKey sectionKey;
@property (nullable, nonatomic, readonly) NSString *cacheName;


@property  (nullable, nonatomic, readonly) PHFetchResult <PHAsset *>*fetchedObjects;

/* Returns the fetched Asset at a given indexPath.
 */
- (PHAsset *)assetAtIndexPath:(NSIndexPath *)indexPath;

/* Returns the indexPath of a given object.
 */
- (nullable NSIndexPath *)indexPathForAsset:(PHAsset *)asset;

- (nullable NSString *)sectionIndexTitleForSectionName:(NSString *)sectionName;

@property (nonatomic, readonly) NSArray<NSString *> *sectionIndexTitles;



@property (nullable, nonatomic, readonly) NSArray<id<PHFetchedResultsSectionInfo>> *sections;

- (NSInteger)sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)sectionIndex;

@end

@protocol PHFetchedResultsSectionInfo

/* Name of the section
 */
@property (nonatomic, readonly) NSString *name;

/* Title of the section (used when displaying the index)
 */
@property (nullable, nonatomic, readonly) NSString *indexTitle;

/* Number of objects in section
 */
@property (nonatomic, readonly) NSUInteger numberOfObjects;

/* Returns the array of objects in the section.
 */
@property (nullable, nonatomic, readonly) NSArray *objects;

@end

NS_ASSUME_NONNULL_END
