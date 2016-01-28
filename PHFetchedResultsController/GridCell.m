//
//  GridCell.m
//  STPBackgroundTransfer
//
//  Created by 1amageek on 2015/11/19.
//  Copyright © 2015年 Stamp inc. All rights reserved.
//

#import "GridCell.h"

@interface GridCell ()

@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UIImageView *livePhotoBadgeImageView;

@end

@implementation GridCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _imageView.clipsToBounds = YES;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _livePhotoBadgeImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        
        [self.contentView addSubview:self.imageView];
        [self.contentView addSubview:self.livePhotoBadgeImageView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.livePhotoBadgeImageView.frame = CGRectMake(2, 2, 16, 16);
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageView.image = nil;
    self.livePhotoBadgeImageView.image = nil;
}

- (void)setThumbnailImage:(UIImage *)thumbnailImage {
    _thumbnailImage = thumbnailImage;
    self.imageView.image = thumbnailImage;
}

- (void)setLivePhotoBadgeImage:(UIImage *)livePhotoBadgeImage {
    _livePhotoBadgeImage = livePhotoBadgeImage;
    self.livePhotoBadgeImageView.image = livePhotoBadgeImage;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    self.layer.borderColor = [UIColor greenColor].CGColor;
    self.layer.borderWidth = selected ? 2 : 0;
    
    [self setNeedsDisplay];
}


@end
