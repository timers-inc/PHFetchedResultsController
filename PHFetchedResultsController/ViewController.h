//
//  ViewController.h
//  STPBackgroundTransfer
//
//  Created by 1amageek on 2015/11/19.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSIndexSet+Convenience.h"
#import "UICollectionView+Convenience.h"
#import "GridCell.h"
#import "PHFetchedResultsController.h"

@import Photos;
@import PhotosUI;

@interface ViewController : UIViewController <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic) UICollectionView *collectionView;
@property (nonatomic) PHFetchedResultsController *fetchedResultsController;

+ (void)loadAssetsLibraryWithComplitionHandler:(void (^)(BOOL authorized))complition;

@end

